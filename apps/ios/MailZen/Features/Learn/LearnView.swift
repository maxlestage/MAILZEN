import SwiftUI
import MailZenKit

/// ZenLearn: a quiz, the manipulation techniques, the families of scams.
struct LearnView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionTitle(eyebrow: "ZenLearn", title: tr("Vrai ou faux lien ?", "Real or fake link?", "¿Enlace real o falso?"))
                QuizView().card()
                SectionTitle(eyebrow: "Social engineering", title: tr("Les techniques de manipulation", "Manipulation techniques", "Técnicas de manipulación"))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(Content.techniques.enumerated()), id: \.offset) { index, t in
                        VStack(alignment: .leading, spacing: 8) {
                            IconBox(systemName: symbol(t.icon), tint: Theme.suspicious, size: 38)
                            Text(t.name.localized).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Text(t.example.localized).font(.caption).italic().foregroundStyle(Theme.muted)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .card(padding: 12)
                        .appear(delay: Double(index % 4) * 0.05)
                    }
                }
                SectionTitle(eyebrow: "Scam Intelligence", title: tr("Les familles d’arnaques", "Families of scams", "Familias de estafas"))
                ForEach(Array(Content.categories.enumerated()), id: \.offset) { _, c in
                    HStack(spacing: 14) {
                        IconBox(systemName: symbol(c.icon))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.title.localized).font(.headline).foregroundStyle(Theme.text)
                            Text(c.text.localized).font(.subheadline).foregroundStyle(Theme.muted)
                        }
                    }
                    .card()
                }
                SectionTitle(eyebrow: tr("Bibliothèque", "Library", "Biblioteca"), title: tr("Toutes les arnaques connues", "Every known scam", "Todas las estafas conocidas"))
                ChipCloud(items: Content.scams.map(\.localized), tint: Theme.danger)
                SectionTitle(eyebrow: tr("Cours", "Lessons", "Lecciones"), title: tr("Bientôt dans ZenLearn", "Coming to ZenLearn", "Próximamente en ZenLearn"))
                ChipCloud(items: Content.learnTopics.map(\.localized))
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle(tr("Apprendre", "Learn", "Aprender"))
    }
}

/// Six links: real or fake?
struct QuizView: View {
    @State private var index = 0
    @State private var answer: Bool?
    @State private var score = 0
    @AppStorage("bestQuizScore") private var best = 0

    var body: some View {
        if index >= Content.quiz.count {
            VStack(spacing: 12) {
                Image(systemName: "rosette")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.gradient)
                    .symbolEffect(.bounce, value: score)
                Text("\(score)/\(Content.quiz.count)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text(badge).font(.headline).foregroundStyle(Theme.cyanLight)
                Text(tr("Meilleur score : ", "Best score: ", "Mejor puntuación: ") + "\(best)/\(Content.quiz.count)")
                    .font(.caption).foregroundStyle(Theme.muted)
                Button(tr("Rejouer", "Play again", "Jugar otra vez")) {
                    withAnimation { index = 0; score = 0; answer = nil }
                }
                .buttonStyle(GhostButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .onAppear { best = max(best, score) }
        } else {
            let question = Content.quiz[index]
            VStack(alignment: .leading, spacing: 14) {
                ProgressView(value: Double(index), total: Double(Content.quiz.count)).tint(Theme.cyan)
                Text(tr("Question", "Question", "Pregunta") + " \(index + 1)/\(Content.quiz.count)")
                    .font(.caption.monospaced()).foregroundStyle(Theme.muted)
                Text(tr("Ce lien est-il authentique ?", "Is this link genuine?", "¿Este enlace es auténtico?"))
                    .font(.headline).foregroundStyle(Theme.text)
                Text(question.url)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.cyanLight)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                HStack(spacing: 10) {
                    Button { reply(true) } label: { Label(tr("Vrai", "Real", "Real"), systemImage: "checkmark") }
                        .buttonStyle(GhostButtonStyle(tint: Theme.safe))
                    Button { reply(false) } label: { Label(tr("Faux", "Fake", "Falso"), systemImage: "xmark") }
                        .buttonStyle(GhostButtonStyle(tint: Theme.danger))
                }
                .disabled(answer != nil)
                if let answer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(answer ? tr("Bien vu !", "Well spotted!", "¡Bien visto!") : tr("Pas tout à fait.", "Not quite.", "No exactamente."))
                            .font(.headline)
                            .foregroundStyle(answer ? Theme.safe : Theme.danger)
                        Text(question.why.localized).font(.subheadline).foregroundStyle(Theme.muted)
                        Button(tr("Suivant", "Next", "Siguiente")) {
                            withAnimation(.spring) { self.answer = nil; index += 1 }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: answer)
        }
    }

    private var badge: String {
        switch score {
        case 6: tr("Gardien zen", "Zen guardian", "Guardián zen")
        case 4, 5: tr("Œil de lynx", "Eagle eye", "Ojo de lince")
        default: tr("Apprenti vigilant", "Vigilant apprentice", "Aprendiz atento")
        }
    }

    private func reply(_ real: Bool) {
        let right = Content.quiz[index].real == real
        if right { score += 1 }
        UINotificationFeedbackGenerator().notificationOccurred(right ? .success : .error)
        withAnimation { answer = right }
    }
}
