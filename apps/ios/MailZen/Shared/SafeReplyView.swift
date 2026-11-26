import SwiftUI
import MailZenKit

/// Safe Reply: messages ready to send, without answering the suspicious email.
struct SafeReplyView: View {
    let report: Report
    let message: EmailMessage?
    @State private var copied: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(eyebrow: "Safe Reply", title: tr("Répondre sans prendre de risque", "Reply without taking risks", "Responder sin riesgos"))
                Text(tr("MailZen ne répond jamais automatiquement à un email suspect. Voici des messages à envoyer vous-même, par un canal officiel ou à un proche.",
                        "MailZen never replies automatically to a suspicious email. Here are messages to send yourself, through an official channel or to a relative.",
                        "MailZen nunca responde automáticamente a un correo sospechoso. Aquí tienes mensajes para enviar tú, por un canal oficial o a un familiar."))
                    .font(.subheadline).foregroundStyle(Theme.muted)
                ForEach(SafeReply.templates(report: report, message: message), id: \.self) { template in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(template.title.localized).font(.headline).foregroundStyle(Theme.text)
                        Text(template.text)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .textSelection(.enabled)
                        HStack(spacing: 10) {
                            Button {
                                UIPasteboard.general.string = template.text
                                withAnimation { copied = template.text }
                            } label: {
                                Label(copied == template.text ? tr("Copié", "Copied", "Copiado") : tr("Copier", "Copy", "Copiar"),
                                      systemImage: copied == template.text ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(GhostButtonStyle())
                            ShareLink(item: template.text) {
                                Label(tr("Envoyer", "Send", "Enviar"), systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(GhostButtonStyle(tint: Theme.cyanLight))
                        }
                    }
                    .card()
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("Safe Reply")
        .navigationBarTitleDisplayMode(.inline)
    }
}
