import SwiftUI
import MailZenKit

/// "Did MailZen get it wrong?": the user says what the message really was. The correction
/// stays on the device; it can block or trust the sender, and be exported to retrain the
/// models.
struct FeedbackCard: View {
    let report: Report
    let message: EmailMessage

    private enum Choice { case scam, legit }
    @State private var choice: Choice?
    @State private var category: ScamCategory?
    @State private var listSender = true
    @State private var saved = false
    private var store: PersonalStore { PersonalStore.shared }

    private var sender: String? { message.fromAddress }
    private var senderKey: String? { sender.flatMap(PersonalLists.key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "graduationcap").foregroundStyle(Theme.cyanLight)
                Text(tr("MailZen s’est trompé ?", "Did MailZen get it wrong?", "¿MailZen se ha equivocado?"))
                    .font(.headline).foregroundStyle(Theme.text)
            }
            if saved {
                Label(tr("Merci : c’est noté, sur cet appareil uniquement.", "Thank you: noted, on this device only.", "Gracias: anotado, solo en este dispositivo."),
                      systemImage: "checkmark.circle.fill")
                    .font(.subheadline).foregroundStyle(Theme.safe)
                    .transition(.opacity)
                if let senderKey, store.isTrusted(sender) || store.isBlocked(sender) {
                    Text((store.isBlocked(sender) ? tr("Expéditeur bloqué : ", "Sender blocked: ", "Remitente bloqueado: ")
                                                  : tr("Expéditeur de confiance : ", "Trusted sender: ", "Remitente de confianza: ")) + senderKey)
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
            } else {
                Text(tr("Dites-moi ce qu’était vraiment ce message. Vos corrections servent à réentraîner les modèles, si vous choisissez de les exporter.",
                        "Tell me what this message really was. Your corrections are used to retrain the models, if you choose to export them.",
                        "Dime qué era realmente este mensaje. Tus correcciones sirven para reentrenar los modelos, si decides exportarlas."))
                    .font(.footnote).foregroundStyle(Theme.muted)
                HStack(spacing: 10) {
                    Button { withAnimation(.snappy) { choice = .scam } } label: {
                        Label(tr("Une arnaque", "A scam", "Una estafa"), systemImage: "xmark.shield")
                    }
                    .buttonStyle(GhostButtonStyle(tint: choice == .scam ? Theme.danger : Theme.muted))
                    Button { withAnimation(.snappy) { choice = .legit } } label: {
                        Label(tr("Légitime", "Legitimate", "Legítimo"), systemImage: "checkmark.shield")
                    }
                    .buttonStyle(GhostButtonStyle(tint: choice == .legit ? Theme.safe : Theme.muted))
                }
                if let choice {
                    details(choice).transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .card()
    }

    @ViewBuilder
    private func details(_ choice: Choice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if choice == .scam {
                Menu {
                    Button(tr("Je ne sais pas", "I don’t know", "No lo sé")) { category = nil }
                    ForEach(ScamCategory.allCases, id: \.self) { c in
                        Button(c.label.localized.prefix(1).uppercased() + c.label.localized.dropFirst()) { category = c }
                    }
                } label: {
                    HStack {
                        Text(tr("Type d’arnaque", "Kind of scam", "Tipo de estafa")).foregroundStyle(Theme.text)
                        Spacer()
                        Text(category?.label.localized ?? tr("Je ne sais pas", "I don’t know", "No lo sé"))
                            .foregroundStyle(Theme.cyanLight).lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(Theme.muted)
                    }
                    .font(.subheadline)
                }
                .onAppear { if category == nil { category = report.model?.category } }
            }
            if let senderKey {
                Toggle(isOn: $listSender) {
                    Text(choice == .scam
                         ? tr("Bloquer \(senderKey)", "Block \(senderKey)", "Bloquear \(senderKey)")
                         : tr("Faire confiance à \(senderKey)", "Trust \(senderKey)", "Confiar en \(senderKey)"))
                        .font(.subheadline).foregroundStyle(Theme.text).lineLimit(2)
                }
                .tint(choice == .scam ? Theme.danger : Theme.safe)
            }
            Button {
                store.correct(text: message.analysisText, scam: choice == .scam, category: category, sender: sender, report: report)
                if listSender, let sender {
                    if choice == .scam { store.block(sender) } else { store.trust(sender) }
                }
                withAnimation(.spring) { saved = true }
            } label: {
                Label(tr("Enregistrer", "Save", "Guardar"), systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
