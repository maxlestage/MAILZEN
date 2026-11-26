import SwiftUI
import SwiftData
import MailZenKit

/// MailZen Radar: the protection at a glance.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(MailboxService.self) private var mailbox
    @Query(sort: \AnalysisRecord.date, order: .reverse) private var records: [AnalysisRecord]

    private var suspicious: Int { records.filter { $0.verdict == .suspicious || $0.verdict == .danger }.count }
    private var riskyLinks: Int { records.prefix(200).reduce(0) { $0 + $1.linkCount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                stats
                actions
                mailboxCard
                if !records.isEmpty { latest }
                tip
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("MailZen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { model.showSOS = true } label: {
                    Image(systemName: "lifepreserver").foregroundStyle(Theme.danger)
                }
                .accessibilityLabel("SOS Cyber")
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                RadarView()
                    .frame(width: 240, height: 240)
                    .background(Circle().fill(Theme.cyan.opacity(0.06)))
                    .overlay(Circle().stroke(Theme.cyan.opacity(0.3), lineWidth: 1))
                    .shadow(color: Theme.cyan.opacity(0.35), radius: 30)
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(Theme.gradient)
                    .padding(22)
                    .background(Circle().fill(Theme.background.opacity(0.85)))
            }
            HStack(spacing: 8) {
                Circle().fill(Theme.safe).frame(width: 9, height: 9)
                Text(tr("Protection active", "Protection on", "Protección activa")).font(.headline).foregroundStyle(Theme.text)
            }
            Text(tr("Avant de cliquer, vérifiez.", "Before you click, check.", "Antes de hacer clic, verifica."))
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.gradient)
        }
        .frame(maxWidth: .infinity)
        .appear()
    }

    private var stats: some View {
        let items: [(String, Int, String, Color)] = [
            (tr("Analyses", "Analyses", "Análisis"), records.count, "envelope.fill", Theme.cyan),
            (tr("Suspects", "Suspicious", "Sospechosos"), suspicious, "exclamationmark.triangle.fill", Theme.suspicious),
            (tr("Liens à risque", "Risky links", "Enlaces de riesgo"), riskyLinks, "link", Theme.danger),
            (tr("Boîtes veillées", "Watched mailboxes", "Buzones vigilados"), mailbox.accounts.count, "tray.full.fill", Theme.safe),
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: item.2).foregroundStyle(item.3)
                    Text("\(item.1)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.text)
                        .contentTransition(.numericText(value: Double(item.1)))
                    Text(item.0).font(.caption).foregroundStyle(Theme.muted)
                }
                .card()
                .appear(delay: 0.1 + Double(index) * 0.06)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button { model.tab = .scanner } label: {
                Label(tr("Analyser un message", "Analyze a message", "Analizar un mensaje"), systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(PrimaryButtonStyle())
            HStack(spacing: 12) {
                Button { model.showSOS = true } label: {
                    Label("SOS Cyber", systemImage: "lifepreserver")
                }
                .buttonStyle(GhostButtonStyle(tint: Theme.danger))
                NavigationLink { MailboxView() } label: {
                    Label(tr("Boîte mail", "Mailbox", "Buzón"), systemImage: "tray.full")
                }
                .buttonStyle(GhostButtonStyle())
            }
            NavigationLink { BrandCheckView() } label: {
                Label("Brand Check", systemImage: "checkmark.seal")
            }
            .buttonStyle(GhostButtonStyle(tint: Theme.cyanLight))
        }
        .appear(delay: 0.3)
    }

    private var mailboxCard: some View {
        NavigationLink { MailboxView() } label: {
            HStack(spacing: 14) {
                IconBox(systemName: mailbox.account == nil ? "tray" : "tray.full.fill", tint: mailbox.account == nil ? Theme.cyanLight : Theme.safe)
                VStack(alignment: .leading, spacing: 4) {
                    if let account = mailbox.account {
                        Text(mailbox.accounts.count > 1
                             ? tr("\(mailbox.accounts.count) boîtes mail", "\(mailbox.accounts.count) mailboxes", "\(mailbox.accounts.count) buzones")
                             : account.email)
                            .font(.headline).foregroundStyle(Theme.text)
                        Text(mailbox.statusLine).font(.caption).foregroundStyle(Theme.muted)
                    } else {
                        Text(tr("Connectez votre boîte mail", "Connect your mailbox", "Conecta tu buzón")).font(.headline).foregroundStyle(Theme.text)
                        Text(tr("MailZen vous prévient quand un email dangereux arrive.", "MailZen warns you when a dangerous email arrives.", "MailZen te avisa cuando llega un correo peligroso."))
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
            }
            .card()
        }
        .buttonStyle(.plain)
        .appear(delay: 0.35)
    }

    private var latest: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(eyebrow: "Radar", title: tr("Dernières analyses", "Latest analyses", "Últimos análisis"))
            ForEach(records.prefix(4)) { record in
                NavigationLink {
                    RecordReportView(record: record, onSOS: { model.showSOS = true })
                } label: {
                    HistoryRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tip: some View {
        let topics = Library.techniques
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        let technique = topics[day % topics.count]
        return VStack(alignment: .leading, spacing: 10) {
            Label(tr("Conseil du jour", "Tip of the day", "Consejo del día"), systemImage: "lightbulb.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.caution)
            Text(technique.name.localized).font(.headline).foregroundStyle(Theme.text)
            Text(tr("Exemple : ", "Example: ", "Ejemplo: ") + technique.example.localized).font(.subheadline).foregroundStyle(Theme.muted)
            Text(tr("Quand un message joue sur ce levier, prenez le temps de vérifier par un canal officiel.",
                    "When a message pulls this lever, take the time to check through an official channel.",
                    "Cuando un mensaje usa esta palanca, tómate tiempo para verificar por un canal oficial."))
                .font(.footnote).foregroundStyle(Theme.muted)
        }
        .card(tint: Theme.caution.opacity(0.35))
    }
}

/// A row of the history.
struct HistoryRow: View {
    let record: AnalysisRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.verdict.symbol)
                .font(.title3)
                .foregroundStyle(record.verdict.color)
                .frame(width: 40, height: 40)
                .background(record.verdict.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title.isEmpty ? record.source : record.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text("\(record.source) · \(record.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            if record.favorite {
                Image(systemName: "star.fill").font(.caption).foregroundStyle(Theme.caution)
            }
            Text("\(record.score)")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(record.verdict.color)
        }
        .card(padding: 12)
    }
}
