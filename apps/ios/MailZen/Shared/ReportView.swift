import SwiftUI
import MailZenKit

/// A security report: the verdict, the score, why, and what to do.
struct ReportView: View {
    let report: Report
    var title: String? = nil
    var message: EmailMessage? = nil
    var file: FileReport? = nil
    var onSOS: (() -> Void)? = nil

    private var shareText: String {
        var lines = [
            "MailZen — \(report.verdict.title.localized) (\(report.score)/100)",
            report.verdict.summary.localized,
        ]
        lines += report.signals.map { "• \($0.rule.title.localized) : \($0.evidence)" }
        lines.append(report.verdict.advice.localized)
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let file { FileCard(file: file) }
                HStack(spacing: 10) {
                    NavigationLink {
                        ZenAIView(report: report, message: message)
                    } label: {
                        Label("ZenAI", systemImage: "sparkles")
                    }
                    .buttonStyle(GhostButtonStyle(tint: Theme.cyanLight))
                    NavigationLink {
                        SafeReplyView(report: report, message: message)
                    } label: {
                        Label("Safe Reply", systemImage: "arrowshape.turn.up.left")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                if !report.technicalSignals.isEmpty {
                    SectionTitle(eyebrow: tr("Pourquoi", "Why", "Por qué"), title: tr("Signaux détectés", "Signals detected", "Señales detectadas"))
                    ForEach(Array(report.technicalSignals.enumerated()), id: \.offset) { index, signal in
                        signalRow(signal).appear(delay: 0.2 + Double(index) * 0.08)
                    }
                }
                if !report.manipulationSignals.isEmpty {
                    SectionTitle(eyebrow: "Social engineering", title: tr("Techniques de manipulation", "Manipulation techniques", "Técnicas de manipulación"))
                    FlowLayout {
                        ForEach(Array(report.manipulationSignals.enumerated()), id: \.offset) { index, signal in
                            Chip(text: signal.rule.title.localized, tint: Theme.suspicious)
                                .appear(delay: 0.3 + Double(index) * 0.07)
                        }
                    }
                }
                if !report.links.isEmpty {
                    SectionTitle(eyebrow: "Link Guard", title: tr("Liens analysés", "Links analyzed", "Enlaces analizados"))
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(report.links, id: \.self) { link in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: link.risky ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundStyle(link.risky ? Theme.danger : Theme.safe)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(link.host)
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(Theme.text)
                                        .textSelection(.enabled)
                                    if Brands.official(link.host) != nil {
                                        Text(tr("Domaine officiel vérifié", "Verified official domain", "Dominio oficial verificado"))
                                            .font(.caption2).foregroundStyle(Theme.safe)
                                    } else if let p = link.modelProbability {
                                        Text(tr("Modèle des liens", "Link model", "Modelo de enlaces") + " : \(Int((p * 100).rounded())) % phishing")
                                            .font(.caption2).foregroundStyle(p >= 0.95 ? Theme.danger : Theme.muted)
                                    }
                                }
                            }
                        }
                        Text(tr("MailZen n’ouvre jamais ces liens à votre place.", "MailZen never opens these links for you.", "MailZen nunca abre estos enlaces por ti."))
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    .card()
                }
                advice
                if let message, !message.analysisText.isEmpty {
                    FeedbackCard(report: report, message: message)
                }
                if report.verdict != .safe, let onSOS {
                    Button(action: onSOS) {
                        Label(tr("J’ai déjà cliqué, que faire ?", "I already clicked, what now?", "Ya hice clic, ¿qué hago?"), systemImage: "lifepreserver")
                    }
                    .buttonStyle(GhostButtonStyle(tint: Theme.danger))
                }
                ShareLink(item: shareText) {
                    Label(tr("Partager le rapport", "Share the report", "Compartir el informe"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(GhostButtonStyle())
                Text(tr(
                    "Analyse faite sur cet appareil par le moteur de règles et les modèles entraînés de MailZen. Elle ne garantit ni l’innocuité ni la dangerosité d’un message.",
                    "Analysis made on this device by MailZen’s rules engine and trained models. It guarantees neither that a message is harmless nor that it is dangerous.",
                    "Análisis hecho en este dispositivo por el motor de reglas y los modelos entrenados de MailZen. No garantiza que un mensaje sea inofensivo ni peligroso."))
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Rapport", "Report", "Informe"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 14) {
            GaugeView(score: report.score, color: report.verdict.color)
            VerdictBadge(verdict: report.verdict)
            if let title {
                Text(title).font(.headline).foregroundStyle(Theme.text).multilineTextAlignment(.center).lineLimit(3)
            }
            Text(report.verdict.summary.localized)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            if report.trustedSender {
                Label(tr("Expéditeur de confiance", "Trusted sender", "Remitente de confianza"), systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.safe)
            }
            if report.userVerdict == true {
                Label(tr("Vous avez signalé ce message", "You reported this message", "Denunciaste este mensaje"), systemImage: "hand.raised.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.danger)
            } else if report.userVerdict == false {
                Label(tr("Vous avez jugé ce message légitime", "You judged this message legitimate", "Juzgaste legítimo este mensaje"), systemImage: "hand.thumbsup.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.safe)
            } else if report.learnedLegit {
                Label(tr("Ressemble à des messages que vous avez jugés légitimes", "Resembles messages you judged legitimate", "Se parece a mensajes que juzgaste legítimos"), systemImage: "graduationcap.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.safe).multilineTextAlignment(.center)
            } else if let shift = report.model?.personal, shift >= 1 {
                Label(tr("Appris de vos corrections", "Learned from your corrections", "Aprendido de tus correcciones"), systemImage: "graduationcap.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.cyanLight)
            }
            if report.decidedByModel {
                Label(tr("Verdict fixé par le modèle entraîné", "Verdict set by the trained model", "Veredicto fijado por el modelo entrenado"), systemImage: "cpu.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(report.verdict.color)
            }
            if let model = report.model {
                HStack(spacing: 8) {
                    Image(systemName: "cpu").foregroundStyle(Theme.cyanLight)
                    Text(tr("Modèle entraîné", "Trained model", "Modelo entrenado") + " : \(Int((model.probability * 100).rounded())) %"
                         + (model.category.map { " · " + $0.label.localized } ?? ""))
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
            }
            HStack(spacing: 16) {
                Label("\(report.signals.count) " + tr("indicateurs", "indicators", "indicadores"), systemImage: "list.bullet.rectangle")
                Label(tr("Confiance", "Confidence", "Confianza") + " : " + report.confidenceLabel.localized, systemImage: "gauge.with.dots.needle.50percent")
            }
            .font(.caption)
            .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .card(tint: report.verdict.color.opacity(0.45), padding: 20)
        .appear()
    }

    private func signalRow(_ signal: Signal) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconBox(systemName: signal.rule.family.symbol, tint: report.verdict.color, size: 38)
            VStack(alignment: .leading, spacing: 4) {
                Text(signal.rule.family.label.localized.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(report.verdict.color)
                Text(signal.rule.title.localized).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                Text(signal.rule.explanation.localized).font(.footnote).foregroundStyle(Theme.muted)
                Text(signal.evidence)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(2)
            }
        }
        .card()
    }

    private var advice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title2)
                .foregroundStyle(report.verdict.color)
            VStack(alignment: .leading, spacing: 4) {
                Text(tr("Recommandation", "Recommendation", "Recomendación")).font(.headline).foregroundStyle(Theme.text)
                Text(report.verdict.advice.localized).font(.subheadline).foregroundStyle(Theme.muted)
            }
        }
        .card(tint: report.verdict.color.opacity(0.4))
    }
}
