import UIKit
import SwiftUI
import UniformTypeIdentifiers
import MailZenKit

/// "Share → MailZen": text, a link, an `.eml` file or a screenshot shared from another
/// app is analyzed right in the share sheet.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.024, green: 0.043, blue: 0.102, alpha: 1)
        let root = ShareRoot(load: { [weak self] in await self?.loadInput() ?? nil },
                             close: { [weak self] in self?.extensionContext?.completeRequest(returningItems: nil) })
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// The first thing shared that MailZen can read.
    private func loadInput() async -> (String, Report)? {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        var texts: [String] = []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
               let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL,
               let data = try? Data(contentsOf: url)
            {
                if let image = UIImage(data: data) {
                    let ocr = await OCR.read(image)
                    texts.append(ocr.text + "\n" + ocr.qrPayloads.joined(separator: "\n"))
                } else {
                    let message = EmailMessage(data: data)
                    return (message.subject ?? url.lastPathComponent, Engine.analyze(message))
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                      let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
            {
                texts.append(url.absoluteString)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                      let item = try? await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            {
                let image = (item as? UIImage) ?? (item as? Data).flatMap(UIImage.init(data:)) ?? (item as? URL).flatMap { try? Data(contentsOf: $0) }.flatMap(UIImage.init(data:))
                if let image {
                    let ocr = await OCR.read(image)
                    texts.append(ocr.text + "\n" + ocr.qrPayloads.joined(separator: "\n"))
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                      let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String
            {
                texts.append(text)
            }
        }
        if let text = items.first?.attributedContentText?.string, !text.isEmpty, !texts.contains(text) {
            texts.insert(text, at: 0)
        }
        let joined = texts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !joined.isEmpty else { return nil }
        let message = EmailMessage(raw: joined)
        return (message.subject ?? String(joined.prefix(80)), Engine.analyze(message))
    }
}

struct ShareRoot: View {
    let load: () async -> (String, Report)?
    let close: () -> Void
    @State private var result: (String, Report)?
    @State private var animated = false
    @State private var empty = false

    var body: some View {
        NavigationStack {
            Group {
                if let result, animated {
                    ReportView(report: result.1, title: result.0)
                } else if empty {
                    ContentUnavailableView(
                        tr("Rien à analyser", "Nothing to analyze", "Nada que analizar"),
                        systemImage: "tray",
                        description: Text(tr("Partagez un texte, un lien, un email (.eml) ou une capture.", "Share a text, a link, an email (.eml) or a screenshot.", "Comparte un texto, un enlace, un correo (.eml) o una captura.")))
                } else {
                    ScanFlowView { withAnimation(.spring) { animated = true } }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppBackground())
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Terminé", "Done", "Listo"), action: close)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.cyan)
        .task {
            result = await load()
            if result == nil { empty = true }
        }
    }
}
