import SwiftUI
import MailZenKit

/// Attachment Guard: what a file really is.
struct FileCard: View {
    let file: FileReport
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                IconBox(systemName: "doc.badge.gearshape", tint: file.report.verdict.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename).font(.headline).foregroundStyle(Theme.text).lineLimit(2)
                    Text(file.kind.label.localized + " · " + ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SHA-256").font(.caption2.weight(.bold)).foregroundStyle(Theme.cyanLight)
                Text(file.sha256)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = file.sha256
                    withAnimation { copied = true }
                } label: {
                    Label(copied ? tr("Empreinte copiée", "Fingerprint copied", "Huella copiada") : tr("Copier l’empreinte", "Copy the fingerprint", "Copiar la huella"),
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption.weight(.semibold))
                }
            }
            if !file.entries.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("Contenu (\(file.entries.count))", "Contents (\(file.entries.count))", "Contenido (\(file.entries.count))"))
                        .font(.caption2.weight(.bold)).foregroundStyle(Theme.cyanLight)
                    ForEach(file.entries.prefix(12), id: \.self) { entry in
                        Text(entry).font(.system(.caption2, design: .monospaced)).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
            }
            ForEach(Array(file.limits.enumerated()), id: \.offset) { _, limit in
                Label(limit.localized, systemImage: "info.circle").font(.caption).foregroundStyle(Theme.caution)
            }
            Text(tr("Analyse statique sur l’appareil : elle repère les pièges classiques, pas tous les malwares.",
                    "Static analysis on the device: it spots the classic traps, not every malware.",
                    "Análisis estático en el dispositivo: detecta las trampas clásicas, no todo el malware."))
                .font(.caption2).foregroundStyle(Theme.muted)
        }
        .card(tint: file.report.verdict.color.opacity(0.4))
        .appear(delay: 0.1)
    }
}
