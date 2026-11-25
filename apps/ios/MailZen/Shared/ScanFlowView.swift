import SwiftUI
import MailZenKit

/// The five steps of a scan, played one after the other, then `onDone`.
struct ScanFlowView: View {
    let onDone: () -> Void
    @State private var step = 0

    static let steps: [(String, T3)] = [
        ("square.and.arrow.down", T3("Import du message", "Importing the message", "Importando el mensaje")),
        ("square.stack.3d.up", T3("Extraction : expéditeur, liens, fichiers", "Extracting: sender, links, files", "Extrayendo: remitente, enlaces, archivos")),
        ("dot.radiowaves.left.and.right", T3("Détection des menaces", "Detecting threats", "Detectando amenazas")),
        ("brain.head.profile", T3("Analyse du contexte et de la manipulation", "Analyzing context and manipulation", "Analizando contexto y manipulación")),
        ("doc.text.magnifyingglass", T3("Rédaction du rapport", "Writing the report", "Redactando el informe")),
    ]

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                RadarView().frame(width: 190, height: 190)
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.gradient)
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().stroke(index < step ? Theme.safe : Theme.line, lineWidth: 1.5)
                            if index < step {
                                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Theme.safe)
                                    .transition(.scale.combined(with: .opacity))
                            } else if index == step {
                                ProgressView().controlSize(.small).tint(Theme.cyan)
                            } else {
                                Image(systemName: item.0).font(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                        .frame(width: 30, height: 30)
                        Text(item.1.localized)
                            .font(.subheadline.weight(index == step ? .semibold : .regular))
                            .foregroundStyle(index <= step ? Theme.text : Theme.muted.opacity(0.6))
                    }
                }
            }
            .card()
        }
        .padding()
        .task {
            for i in 1...Self.steps.count {
                try? await Task.sleep(for: .milliseconds(520))
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { step = i }
            }
            try? await Task.sleep(for: .milliseconds(250))
            onDone()
        }
    }
}
