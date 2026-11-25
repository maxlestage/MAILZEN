import SwiftUI
import MailZenKit

/// SOS Cyber: what to do after a mistake, step by step, without judgment.
struct SOSView: View {
    @Environment(\.dismiss) private var dismiss

    static let resources: [(String, String)] = [
        ("Cybermalveillance.gouv.fr", "https://www.cybermalveillance.gouv.fr/"),
        ("17Cyber", "https://www.17cyber.gouv.fr/"),
        ("Pharos", "https://www.internet-signalement.gouv.fr/"),
        ("Signal Spam", "https://www.signal-spam.fr/"),
        ("33700", "https://www.33700.fr/"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    PulseIcon(systemName: "lifepreserver", tint: Theme.danger)
                    Text(tr("Pas de panique. Que s’est-il passé ?", "Don’t panic. What happened?", "Que no cunda el pánico. ¿Qué ha pasado?"))
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(Theme.text)
                    Text(tr("Ce n’est pas votre faute : ces messages sont conçus pour tromper.", "It is not your fault: these messages are designed to deceive.", "No es culpa tuya: estos mensajes están hechos para engañar."))
                        .font(.subheadline).foregroundStyle(Theme.muted)
                }
                ForEach(Array(Library.scenarios.enumerated()), id: \.offset) { index, scenario in
                    NavigationLink {
                        ScenarioView(scenario: scenario)
                    } label: {
                        HStack(spacing: 14) {
                            IconBox(systemName: symbol(scenario.icon), tint: Theme.danger, size: 40)
                            Text(scenario.title.localized).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .card(padding: 12)
                    }
                    .buttonStyle(.plain)
                    .appear(delay: Double(index) * 0.04)
                }
                SectionTitle(eyebrow: tr("En France", "In France", "En Francia"), title: tr("Signaler et se faire aider", "Report and get help", "Denunciar y pedir ayuda"))
                ForEach(Self.resources, id: \.0) { name, url in
                    if let link = URL(string: url) {
                        Link(destination: link) {
                            HStack {
                                Text(name).foregroundStyle(Theme.text)
                                Spacer()
                                Image(systemName: "arrow.up.right.square").foregroundStyle(Theme.cyan)
                            }
                            .card(padding: 14)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("SOS Cyber")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(tr("Fermer", "Close", "Cerrar")) { dismiss() }
            }
        }
    }
}

struct ScenarioView: View {
    let scenario: Scenario
    @State private var done: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    IconBox(systemName: symbol(scenario.icon), tint: Theme.danger)
                    Text(scenario.title.localized).font(.title3.weight(.bold)).foregroundStyle(Theme.text)
                }
                ForEach(Array(scenario.steps.enumerated()), id: \.offset) { index, step in
                    Button {
                        withAnimation(.spring) {
                            if done.contains(index) { done.remove(index) } else { done.insert(index) }
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle().fill(done.contains(index) ? Theme.safe : Theme.safe.opacity(0.14))
                                if done.contains(index) {
                                    Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Theme.background)
                                } else {
                                    Text("\(index + 1)").font(.caption.bold().monospaced()).foregroundStyle(Theme.safe)
                                }
                            }
                            .frame(width: 30, height: 30)
                            Text(step.localized)
                                .font(.subheadline)
                                .foregroundStyle(done.contains(index) ? Theme.muted : Theme.text)
                                .strikethrough(done.contains(index), color: Theme.muted)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .card(padding: 12)
                    }
                    .buttonStyle(.plain)
                    .appear(delay: 0.1 + Double(index) * 0.08)
                }
                if done.count == scenario.steps.count {
                    Label(tr("Bravo, vous avez fait le nécessaire.", "Well done, you did what was needed.", "Bien hecho, has hecho lo necesario."), systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.safe)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("SOS Cyber")
        .navigationBarTitleDisplayMode(.inline)
    }
}
