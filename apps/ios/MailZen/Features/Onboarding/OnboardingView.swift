import SwiftUI
import MailZenKit

/// Three pages, the first time.
struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, T3, T3)] = [
        ("envelope.badge.shield.half.filled",
         T3("Avant de cliquer, vérifiez.", "Before you click, check.", "Antes de hacer clic, verifica."),
         T3("MailZen analyse emails, liens, pièces jointes, captures et QR codes, et vous explique les risques simplement.",
            "MailZen analyzes emails, links, attachments, screenshots and QR codes, and explains the risks simply.",
            "MailZen analiza correos, enlaces, adjuntos, capturas y códigos QR, y te explica los riesgos con sencillez.")),
        ("lock.shield.fill",
         T3("Tout reste sur votre iPhone.", "Everything stays on your iPhone.", "Todo se queda en tu iPhone."),
         T3("L’analyse se fait sur l’appareil. Pas de compte obligatoire, pas de publicité, aucune revente de données.",
            "The analysis runs on the device. No mandatory account, no ads, no data resale.",
            "El análisis se hace en el dispositivo. Sin cuenta obligatoria, sin publicidad, sin reventa de datos.")),
        ("bell.badge.fill",
         T3("Prévenu avant d’ouvrir.", "Warned before you open.", "Avisado antes de abrir."),
         T3("Connectez votre boîte mail : MailZen vous prévient quand un email dangereux arrive. Et si vous avez déjà cliqué, SOS Cyber vous guide.",
            "Connect your mailbox: MailZen warns you when a dangerous email arrives. And if you already clicked, SOS Cyber guides you.",
            "Conecta tu buzón: MailZen te avisa cuando llega un correo peligroso. Y si ya hiciste clic, SOS Cyber te guía.")),
    ]

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 24) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 24) {
                            ZStack {
                                if index == 0 {
                                    RadarView().frame(width: 230, height: 230)
                                }
                                Image(systemName: item.0)
                                    .font(.system(size: 64, weight: .semibold))
                                    .foregroundStyle(Theme.gradient)
                                    .symbolEffect(.pulse, options: .repeating)
                            }
                            .frame(height: 240)
                            Text(item.1.localized)
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(Theme.text)
                                .multilineTextAlignment(.center)
                            Text(item.2.localized)
                                .font(.body)
                                .foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 28)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                Button {
                    if page < pages.count - 1 {
                        withAnimation(.spring) { page += 1 }
                    } else {
                        onDone()
                    }
                } label: {
                    Text(page < pages.count - 1 ? tr("Continuer", "Continue", "Continuar") : tr("Commencer", "Get started", "Empezar"))
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}
