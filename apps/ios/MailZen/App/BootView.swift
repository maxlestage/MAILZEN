import SwiftUI
import MailZenKit

/// The boot screen: it takes over from the system launch screen (the same logo), loads
/// what the app needs, so that the first analysis is instant, then fades into the app.
struct BootView: View {
    let onReady: () -> Void

    private struct Step: Identifiable {
        let id: Int
        let label: String
        let work: @Sendable () async -> Void
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var current = 0
    @State private var progress = 0.0
    @State private var spin = false
    @State private var pulse = false
    @State private var shown = false
    @State private var leaving = false

    private var steps: [Step] {
        [
            Step(id: 0, label: tr("Chargement des modèles entraînés", "Loading the trained models", "Cargando los modelos entrenados")) {
                _ = await Task.detached(priority: .userInitiated) { Models.warmUp() }.value
            },
            Step(id: 1, label: tr("Préparation de l’apprentissage sur l’appareil", "Preparing on-device learning", "Preparando el aprendizaje en el dispositivo")) {
                await MainActor.run { PersonalStore.shared.reload() }
            },
            Step(id: 2, label: tr("Ouverture de l’historique", "Opening the history", "Abriendo el historial")) {
                await MainActor.run { _ = Store.container.mainContext }
            },
            Step(id: 3, label: tr("Connexion des boîtes mail", "Connecting the mailboxes", "Conectando los buzones")) {
                await MainActor.run { _ = MailboxService.shared.accounts.count }
            },
        ]
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 26) {
                Spacer()
                logo
                VStack(spacing: 8) {
                    Text("MailZen")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gradient)
                    Text(tr("Avant de cliquer, vérifiez.", "Before you click, check.", "Antes de hacer clic, verifica."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 12)
                Spacer()
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surface)
                            Capsule().fill(Theme.gradient).frame(width: max(8, geo.size.width * progress))
                        }
                    }
                    .frame(height: 6)
                    Text(steps[min(current, steps.count - 1)].label)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .contentTransition(.opacity)
                        .id(current)
                        .transition(.opacity)
                }
                .padding(.horizontal, 48)
                .opacity(shown ? 1 : 0)
                Text("© 2026 Maxime Nathan Lestage")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted.opacity(0.7))
                    .padding(.bottom, 8)
                    .opacity(shown ? 1 : 0)
            }
        }
        .scaleEffect(leaving ? 1.06 : 1)
        .opacity(leaving ? 0 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("MailZen. " + steps[min(current, steps.count - 1)].label)
        .task { await boot() }
    }

    private var logo: some View {
        ZStack {
            if !reduceMotion {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Theme.cyan.opacity(0.5), lineWidth: 1.2)
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulse ? 2.2 : 1)
                        .opacity(pulse ? 0 : 0.7)
                        .animation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: pulse)
                }
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(AngularGradient(colors: [Theme.cyan.opacity(0), Theme.cyan], center: .center), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 168, height: 168)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1.6).repeatForever(autoreverses: false), value: spin)
            }
            Image("LaunchLogo")
                .resizable()
                .frame(width: 120, height: 120)
                .shadow(color: Theme.cyan.opacity(0.55), radius: pulse ? 28 : 12)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(), value: pulse)
        }
        .frame(width: 200, height: 200)
    }

    private func boot() async {
        let start = Date.now
        spin = true
        pulse = true
        withAnimation(.easeOut(duration: 0.5)) { shown = true }
        for (index, step) in steps.enumerated() {
            withAnimation(.easeInOut(duration: 0.25)) { current = index }
            await step.work()
            withAnimation(.easeInOut(duration: 0.35)) { progress = Double(index + 1) / Double(steps.count) }
        }
        // Long enough to be read, never longer than needed.
        let elapsed = Date.now.timeIntervalSince(start)
        if elapsed < 1.3 { try? await Task.sleep(for: .seconds(1.3 - elapsed)) }
        withAnimation(.easeIn(duration: 0.35)) { leaving = true }
        try? await Task.sleep(for: .seconds(0.3))
        onReady()
    }
}
