import SwiftUI
import SwiftData
import MailZenKit

@main
struct MailZenApp: App {
    @State private var model = AppModel()
    @State private var mailbox = MailboxService.shared
    @AppStorage("onboarded") private var onboarded = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // The user's settings and lists reach the engine before any analysis.
        PersonalStore.shared.apply()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded {
                    RootView()
                } else {
                    OnboardingView { withAnimation(.spring) { onboarded = true } }
                }
            }
            .environment(model)
            .environment(mailbox)
            .preferredColorScheme(.dark)
            .tint(Theme.cyan)
            .onOpenURL { url in model.open(url) }
            .onChange(of: scenePhase) { _, phase in
                // The share extension may have learned something meanwhile.
                if phase == .active { PersonalStore.shared.reload() }
            }
        }
        .modelContainer(Store.container)
        .backgroundTask(.appRefresh(MailboxService.refreshTaskID)) {
            await MailboxService.backgroundRefresh()
        }
    }
}

/// The local database (SwiftData): the history of analyses, on this device only.
enum Store {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: AnalysisRecord.self)
        } catch {
            fatalError("SwiftData: \(error)")
        }
    }()
}

/// The tabs of the app.
enum Tab: Hashable {
    case home, scanner, history, learn, settings
}

/// What the screens share: the selected tab and a message to analyze.
@Observable
final class AppModel {
    var tab: Tab = .home
    /// A message handed to the scanner (a file opened with MailZen, an example…).
    var pending: ScanInput?
    var showSOS = false

    func open(_ url: URL) {
        guard url.isFileURL else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        if let data = try? Data(contentsOf: url) {
            pending = ScanInput(kind: .email, raw: String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self), source: url.lastPathComponent)
            tab = .scanner
        }
    }
}
