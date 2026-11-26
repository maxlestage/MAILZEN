import SwiftUI
import SwiftData
import MailZenKit

struct SettingsView: View {
    @Environment(MailboxService.self) private var mailbox
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @Query private var records: [AnalysisRecord]
    @AppStorage("onboarded") private var onboarded = true
    @State private var confirmErase = false

    /// The creator of MailZen.
    static let author = "Maxime Nathan Lestage"

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        List {
            Section(tr("Boîte mail", "Mailbox", "Buzón")) {
                NavigationLink { MailboxView() } label: {
                    Label(mailbox.accounts.isEmpty ? tr("Connecter une boîte mail", "Connect a mailbox", "Conectar un buzón")
                          : mailbox.accounts.count == 1 ? mailbox.accounts[0].email
                          : tr("\(mailbox.accounts.count) boîtes mail", "\(mailbox.accounts.count) mailboxes", "\(mailbox.accounts.count) buzones"),
                          systemImage: "tray.full")
                }
            }
            Section(tr("Analyse", "Analysis", "Análisis")) {
                LabeledContent(tr("Mode", "Mode", "Modo"), value: tr("Local, sur l’appareil", "Local, on the device", "Local, en el dispositivo"))
                NavigationLink { ModelsView() } label: {
                    Label(tr("Intelligence sur l’appareil", "On-device intelligence", "Inteligencia en el dispositivo"), systemImage: "cpu")
                }
                Text(tr("Les analyses cloud facultatives (réputation, sandbox) arriveront avec votre consentement explicite.",
                        "Optional cloud analyses (reputation, sandbox) will come with your explicit consent.",
                        "Los análisis opcionales en la nube (reputación, sandbox) llegarán con tu consentimiento explícito."))
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            Section(tr("Langue et notifications", "Language and notifications", "Idioma y notificaciones")) {
                LabeledContent(tr("Langue", "Language", "Idioma"), value: AppLanguage.current.rawValue.uppercased())
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Label(tr("Ouvrir les réglages de MailZen", "Open MailZen’s settings", "Abrir los ajustes de MailZen"), systemImage: "gear")
                }
            }
            Section("PrivacyZen") {
                ForEach(Array(Library.privacy.prefix(8).enumerated()), id: \.offset) { _, item in
                    Label(item.localized, systemImage: "checkmark.shield").foregroundStyle(Theme.text)
                }
            }
            Section(tr("Données", "Data", "Datos")) {
                LabeledContent(tr("Analyses enregistrées", "Saved analyses", "Análisis guardados"), value: "\(records.count)")
                Button(role: .destructive) { confirmErase = true } label: {
                    Label(tr("Effacer l’historique", "Erase the history", "Borrar el historial"), systemImage: "trash")
                }
                .disabled(records.isEmpty)
                Button { onboarded = false } label: {
                    Label(tr("Revoir la présentation", "See the introduction again", "Ver de nuevo la presentación"), systemImage: "sparkles")
                }
            }
            Section(tr("À propos", "About", "Acerca de")) {
                LabeledContent("Version", value: version)
                HStack(spacing: 14) {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.cyan)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("Créé par", "Created by", "Creado por")).foregroundStyle(Theme.text)
                        Text(Self.author).foregroundStyle(Theme.muted)
                    }
                }
                .accessibilityElement(children: .combine)
                Link(destination: URL(string: "https://maxlestage.github.io/MAILZEN/")!) {
                    Label(tr("Site de MailZen", "MailZen website", "Sitio de MailZen"), systemImage: "globe")
                }
                Link(destination: URL(string: "https://maxlestage.github.io/MAILZEN/\(AppLanguage.current.rawValue)/privacy/")!) {
                    Label(tr("Confidentialité", "Privacy", "Privacidad"), systemImage: "hand.raised")
                }
                Link(destination: URL(string: "https://maxlestage.github.io/MAILZEN/\(AppLanguage.current.rawValue)/legal/")!) {
                    Label(tr("Mentions légales", "Legal notice", "Aviso legal"), systemImage: "doc.plaintext")
                }
                Text("© 2026 \(Self.author). " + tr("Tous droits réservés.", "All rights reserved.", "Todos los derechos reservados."))
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Réglages", "Settings", "Ajustes"))
        .confirmationDialog(tr("Effacer tout l’historique ?", "Erase the whole history?", "¿Borrar todo el historial?"), isPresented: $confirmErase, titleVisibility: .visible) {
            Button(tr("Effacer", "Erase", "Borrar"), role: .destructive) {
                for record in records { context.delete(record) }
            }
        }
    }
}
