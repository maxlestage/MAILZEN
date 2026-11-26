import SwiftUI
import MailZenKit

/// A folder of a mailbox to list.
struct MailSource: Hashable, Identifiable {
    let account: MailAccount
    let folder: IMAPFolder
    var id: String { account.email + "/" + folder.name }
}

/// The messages of one or several folders, loaded page by page from the newest: a page
/// at first, the next ones only when the list is scrolled to its end, and the new ones on
/// each refresh.
@MainActor
@Observable
final class MailListModel {
    let sources: [MailSource]
    let pageSize = 30

    private struct Cursor {
        var uidValidity: UInt32?
        var uids: [UInt32]?
        var oldest: UInt32?
        var newest: UInt32 = 0
        var done = false
    }

    private var cursors: [String: Cursor] = [:]
    private(set) var items: [MailSummary] = []
    private(set) var loading = false
    private(set) var refreshing = false
    private(set) var loadedOnce = false
    var error: String?

    init(sources: [MailSource]) {
        self.sources = sources
    }

    var hasMore: Bool { sources.contains { !(cursors[$0.id]?.done ?? false) } }

    /// How many messages each folder holds, as far as known.
    var total: Int { cursors.values.reduce(0) { $0 + ($1.uids?.count ?? 0) } }

    private func merge(_ new: [MailSummary]) {
        var seen = Set(items.map(\.id))
        items += new.filter { seen.insert($0.id).inserted }
        items.sort { a, b in
            switch (a.date, b.date) {
            case let (x?, y?) where x != y: return x > y
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.uid > b.uid
            }
        }
    }

    /// The next page of every folder that has more.
    func loadMore() async {
        guard !loading, hasMore else { return }
        loading = true
        error = nil
        defer { loading = false; loadedOnce = true }
        let size = max(15, pageSize / max(sources.count, 1))
        await withTaskGroup(of: (String, Result<MailPage, Error>).self) { group in
            for source in sources where !(cursors[source.id]?.done ?? false) {
                guard let password = Keychain.password(for: source.account.email) else { continue }
                let cursor = cursors[source.id] ?? Cursor()
                let account = source.account, folder = source.folder.name, id = source.id
                group.addTask {
                    do {
                        let page = try await MailBrowser.page(host: account.host, port: account.port, user: account.email, password: password,
                                                              folder: folder, knownUIDs: cursor.uids, uidValidity: cursor.uidValidity,
                                                              before: cursor.oldest, size: size)
                        return (id, .success(page))
                    } catch {
                        return (id, .failure(error))
                    }
                }
            }
            for await (id, result) in group {
                switch result {
                case .success(let page):
                    var cursor = cursors[id] ?? Cursor()
                    if cursor.uidValidity != nil, cursor.uidValidity != page.uidValidity {
                        // The folder was rebuilt by the server: start over.
                        items.removeAll { $0.id.hasPrefix(id + "/") }
                        cursor = Cursor()
                    }
                    cursor.uidValidity = page.uidValidity
                    cursor.uids = page.uids
                    if let oldest = page.items.map(\.uid).min() { cursor.oldest = oldest }
                    cursor.newest = max(cursor.newest, page.uids.last ?? 0)
                    let remaining = page.uids.filter { $0 < (cursor.oldest ?? .max) }
                    cursor.done = page.items.isEmpty || remaining.isEmpty
                    cursors[id] = cursor
                    merge(page.items)
                case .failure(let failure):
                    error = MailboxService.describe(failure)
                }
            }
        }
    }

    /// The messages arrived since the last load.
    func refresh() async {
        guard !refreshing, !loading else { return }
        guard loadedOnce else { await loadMore(); return }
        refreshing = true
        defer { refreshing = false }
        for source in sources {
            guard let cursor = cursors[source.id], let password = Keychain.password(for: source.account.email) else { continue }
            let account = source.account
            do {
                let new = try await MailBrowser.newer(host: account.host, port: account.port, user: account.email, password: password,
                                                      folder: source.folder.name, after: cursor.newest)
                var updated = cursor
                if let top = new.items.map(\.uid).max() {
                    updated.newest = max(updated.newest, top)
                    updated.uids = (updated.uids ?? []) + new.items.map(\.uid).sorted().filter { $0 > cursor.newest }
                }
                cursors[source.id] = updated
                merge(new.items)
            } catch {
                self.error = MailboxService.describe(error)
            }
        }
    }
}

/// Every message of one or several folders, each with its verdict.
struct MailListView: View {
    let title: String
    @State private var model: MailListModel
    @State private var filter = Filter.all

    enum Filter: String, CaseIterable, Identifiable {
        case all, risky
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: tr("Tous", "All", "Todos")
            case .risky: tr("À risque", "Risky", "De riesgo")
            }
        }
    }

    init(title: String, sources: [MailSource]) {
        self.title = title
        _model = State(initialValue: MailListModel(sources: sources))
    }

    private var shown: [MailSummary] {
        filter == .all ? model.items : model.items.filter { $0.report.verdict != .safe }
    }

    var body: some View {
        List {
            Section {
                Picker(tr("Filtre", "Filter", "Filtro"), selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                if model.loadedOnce {
                    Text(summaryLine).font(.caption).foregroundStyle(Theme.muted).listRowBackground(Color.clear)
                }
            }
            Section {
                ForEach(shown) { item in
                    NavigationLink {
                        MailDetailView(summary: item, account: account(of: item))
                    } label: {
                        MailRow(item: item, showAccount: model.sources.count > 1)
                    }
                    .listRowBackground(Theme.surface)
                    .onAppear {
                        // Close to the end: the next page.
                        if let index = shown.firstIndex(of: item), index >= shown.count - 6 {
                            Task { await model.loadMore() }
                        }
                    }
                }
                if model.hasMore || model.loading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Text(tr("Chargement…", "Loading…", "Cargando…")).font(.caption).foregroundStyle(Theme.muted)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .onAppear { Task { await model.loadMore() } }
                } else if model.loadedOnce && shown.isEmpty {
                    ContentUnavailableView(filter == .risky ? tr("Aucun email à risque", "No risky email", "Ningún correo de riesgo") : tr("Aucun email", "No email", "Ningún correo"),
                                           systemImage: filter == .risky ? "checkmark.shield" : "tray")
                        .listRowBackground(Color.clear)
                } else if model.loadedOnce {
                    Text(tr("Tous les emails sont chargés.", "Every email is loaded.", "Todos los correos están cargados."))
                        .font(.caption).foregroundStyle(Theme.muted).frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
            }
            if let error = model.error {
                Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.refresh() }
        .task {
            if !model.loadedOnce { await model.loadMore() }
            // Regular loading: the new messages, every minute, while the list is open.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if Task.isCancelled { break }
                await model.refresh()
            }
        }
    }

    private var summaryLine: String {
        let risky = model.items.filter { $0.report.verdict == .suspicious || $0.report.verdict == .danger }.count
        return tr("\(model.items.count) sur \(model.total) emails chargés · \(risky) à risque",
                  "\(model.items.count) of \(model.total) emails loaded · \(risky) risky",
                  "\(model.items.count) de \(model.total) correos cargados · \(risky) de riesgo")
    }

    private func account(of item: MailSummary) -> MailAccount {
        model.sources.first { $0.account.email == item.account }?.account ?? model.sources[0].account
    }
}

/// A message in a list: who, what, when, and its verdict.
struct MailRow: View {
    let item: MailSummary
    var showAccount = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(item.report.verdict.color.opacity(0.18)).frame(width: 40, height: 40)
                Text("\(item.report.score)").font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(item.report.verdict.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.sender).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text).lineLimit(1)
                    Spacer(minLength: 6)
                    if let date = item.date {
                        Text(Self.format(date)).font(.caption2).foregroundStyle(Theme.muted)
                    }
                }
                Text(item.subject).font(.footnote).foregroundStyle(Theme.text).lineLimit(1)
                if !item.preview.isEmpty {
                    Text(item.preview).font(.caption).foregroundStyle(Theme.muted).lineLimit(2)
                }
                HStack(spacing: 6) {
                    if item.report.verdict != .safe {
                        Text(item.report.verdict.title.localized)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(item.report.verdict.color)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(item.report.verdict.color.opacity(0.15), in: Capsule())
                    }
                    if !item.message.attachments.isEmpty {
                        Image(systemName: "paperclip").font(.caption2).foregroundStyle(Theme.muted)
                    }
                    if showAccount {
                        Text(item.account).font(.caption2).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    static func format(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return date.formatted(date: .omitted, time: .shortened) }
        if Calendar.current.isDateInYesterday(date) { return tr("Hier", "Yesterday", "Ayer") }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

/// An opened message: fetched whole (still unread), then its full report.
struct MailDetailView: View {
    let summary: MailSummary
    let account: MailAccount
    @State private var full: EmailMessage?
    @State private var failed = false

    var body: some View {
        Group {
            if let full {
                ReportView(report: Engine.analyze(full), title: full.subject ?? summary.subject, message: full)
            } else if failed {
                ReportView(report: summary.report, title: summary.subject, message: summary.message)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(tr("Ouverture de l’email…", "Opening the email…", "Abriendo el correo…")).font(.footnote).foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppBackground())
            }
        }
        .task {
            guard full == nil, let password = Keychain.password(for: account.email) else { failed = true; return }
            do {
                full = try await MailBrowser.message(host: account.host, port: account.port, user: account.email, password: password,
                                                     folder: summary.folder, uid: summary.uid)
                if full == nil { failed = true }
            } catch {
                failed = true
            }
        }
    }
}

/// The folders of a mailbox.
struct AccountFoldersView: View {
    let account: MailAccount
    @State private var folders: [IMAPFolder] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        List {
            Section {
                ForEach(folders) { folder in
                    NavigationLink {
                        MailListView(title: folder.displayName, sources: [MailSource(account: account, folder: folder)])
                    } label: {
                        Label {
                            Text(folder.displayName).foregroundStyle(Theme.text)
                        } icon: {
                            Image(systemName: Self.symbol(folder.kind)).foregroundStyle(folder.kind == .junk ? Theme.suspicious : Theme.cyanLight)
                        }
                        .padding(.leading, CGFloat(folder.depth) * 16)
                    }
                    .listRowBackground(Theme.surface)
                }
                if loading {
                    HStack { Spacer(); ProgressView(); Spacer() }.listRowBackground(Color.clear)
                }
            } header: {
                Text(account.email)
            } footer: {
                Text(tr("Tous les dossiers du compte, en lecture seule. Les indésirables méritent un œil : MailZen y repère aussi les arnaques.",
                        "Every folder of the account, read-only. Junk deserves a look: MailZen spots scams there too.",
                        "Todas las carpetas de la cuenta, en solo lectura. El correo no deseado merece un vistazo: MailZen también detecta ahí las estafas."))
            }
            if let error {
                Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Dossiers", "Folders", "Carpetas"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { if folders.isEmpty { await load() } }
    }

    private func load() async {
        guard let password = Keychain.password(for: account.email) else {
            error = tr("Mot de passe introuvable : reconnectez la boîte.", "Password not found: connect the mailbox again.", "Contraseña no encontrada: vuelve a conectar el buzón.")
            loading = false
            return
        }
        loading = true
        defer { loading = false }
        do {
            folders = try await MailBrowser.folders(host: account.host, port: account.port, user: account.email, password: password)
            error = nil
        } catch {
            self.error = MailboxService.describe(error)
            if folders.isEmpty { folders = [MailboxView.inbox] }
        }
    }

    static func symbol(_ kind: IMAPFolder.Kind) -> String {
        switch kind {
        case .inbox: "tray"
        case .sent: "paperplane"
        case .drafts: "doc"
        case .junk: "xmark.bin"
        case .trash: "trash"
        case .archive: "archivebox"
        case .all: "tray.2"
        case .flagged: "flag"
        case .other: "folder"
        }
    }
}
