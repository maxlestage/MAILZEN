import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import VisionKit
import MailZenKit

/// Mail Scanner: paste a message, import an `.eml`, read a screenshot, scan a QR code
/// or check a link. Everything is analyzed on the device.
struct ScannerView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case text, file, screenshot, qr, link
        var id: String { rawValue }

        var label: String {
            switch self {
            case .text: tr("Texte", "Text", "Texto")
            case .file: tr("Fichier", "File", "Archivo")
            case .screenshot: tr("Capture", "Screenshot", "Captura")
            case .qr: "QR"
            case .link: tr("Lien", "Link", "Enlace")
            }
        }

        var symbol: String {
            switch self {
            case .text: "text.alignleft"
            case .file: "doc.text"
            case .screenshot: "camera.viewfinder"
            case .qr: "qrcode.viewfinder"
            case .link: "link"
            }
        }
    }

    @Environment(AppModel.self) private var model
    @State private var mode: Mode = .text
    @State private var text = ""
    @State private var link = ""
    @State private var result: ScanInput?
    @State private var importing = false
    @State private var photo: PhotosPickerItem?
    @State private var reading = false
    @State private var scanningQR = false
    @State private var qrPayload: String?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionTitle(eyebrow: "Mail Scanner", title: tr("Un doute ? Vérifiez.", "In doubt? Check.", "¿Dudas? Verifica."))
                modePicker
                Group {
                    switch mode {
                    case .text: textMode
                    case .file: fileMode
                    case .screenshot: screenshotMode
                    case .qr: qrMode
                    case .link: linkMode
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
                }
                Label(tr("Analyse sur l’appareil : rien n’est envoyé.", "Analyzed on the device: nothing is sent.", "Análisis en el dispositivo: no se envía nada."), systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.safe)
            }
            .padding()
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: mode)
        }
        .background(AppBackground())
        .navigationTitle(tr("Scanner", "Scanner", "Escáner"))
        .navigationDestination(item: $result) { input in
            ScanResultView(input: input)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: Self.fileTypes) { picked in
            load(picked)
        }
        .onChange(of: photo) { _, item in
            if let item { read(item) }
        }
        .sheet(isPresented: $scanningQR) {
            QRScannerSheet { payload in
                scanningQR = false
                qrPayload = payload
            }
        }
        .onAppear(perform: takePending)
        .onChange(of: model.pending) { _, _ in takePending() }
    }

    static let fileTypes: [UTType] = [UTType(filenameExtension: "eml") ?? .data, .emailMessage, .plainText, .text, .html]

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Mode.allCases) { m in
                    Button {
                        withAnimation { mode = m }
                    } label: {
                        Label(m.label, systemImage: m.symbol)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .foregroundStyle(mode == m ? Color(red: 0.016, green: 0.063, blue: 0.094) : Theme.text)
                            .background(mode == m ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.surface), in: Capsule())
                            .overlay(Capsule().stroke(Theme.line, lineWidth: mode == m ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Modes

    private var textMode: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(Content.samples.enumerated()), id: \.offset) { _, sample in
                        Button { text = sample.text.localized } label: { Chip(text: sample.label.localized) }
                            .buttonStyle(.plain)
                    }
                }
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(.footnote, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 220)
                    .padding(8)
                if text.isEmpty {
                    Text(tr("Collez ici un email, un SMS ou un message…", "Paste an email, a text or a message here…", "Pega aquí un correo, un SMS o un mensaje…"))
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }
            .background(Theme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
            HStack(spacing: 10) {
                Button {
                    if let pasted = UIPasteboard.general.string { text = pasted }
                } label: {
                    Label(tr("Coller", "Paste", "Pegar"), systemImage: "doc.on.clipboard")
                }
                .buttonStyle(GhostButtonStyle())
                Button { text = "" } label: {
                    Label(tr("Effacer", "Clear", "Borrar"), systemImage: "xmark")
                }
                .buttonStyle(GhostButtonStyle())
            }
            Button { analyze(ScanInput(kind: .email, raw: text, source: tr("Texte collé", "Pasted text", "Texto pegado"))) } label: {
                Label(tr("Analyser", "Analyze", "Analizar"), systemImage: "dot.radiowaves.left.and.right")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var fileMode: some View {
        VStack(spacing: 16) {
            PulseIcon(systemName: "doc.text.magnifyingglass")
            Text(tr("Importez un email enregistré (.eml) ou un fichier texte. Les en-têtes, les liens cachés et les pièces jointes sont analysés.",
                    "Import a saved email (.eml) or a text file. Headers, hidden links and attachments are analyzed.",
                    "Importa un correo guardado (.eml) o un archivo de texto. Se analizan las cabeceras, los enlaces ocultos y los adjuntos."))
                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            Button { importing = true } label: {
                Label(tr("Choisir un fichier", "Choose a file", "Elegir un archivo"), systemImage: "folder")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .card()
    }

    private var screenshotMode: some View {
        VStack(spacing: 16) {
            PulseIcon(systemName: "camera.viewfinder")
            Text(tr("Une capture d’un email, d’un SMS ou d’une notification suffit : le texte, les liens et les QR codes sont lus sur l’appareil.",
                    "A screenshot of an email, a text or a notification is enough: text, links and QR codes are read on the device.",
                    "Basta una captura de un correo, un SMS o una notificación: el texto, los enlaces y los códigos QR se leen en el dispositivo."))
                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            PhotosPicker(selection: $photo, matching: .images) {
                Label(reading ? tr("Lecture…", "Reading…", "Leyendo…") : tr("Choisir une capture", "Choose a screenshot", "Elegir una captura"), systemImage: "photo.on.rectangle")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(reading)
        }
        .card()
    }

    private var qrMode: some View {
        VStack(spacing: 16) {
            PulseIcon(systemName: "qrcode.viewfinder")
            Text(tr("QR Guard affiche la destination avant toute ouverture. Un QR code n’est jamais ouvert automatiquement.",
                    "QR Guard shows the destination before anything opens. A QR code is never opened automatically.",
                    "QR Guard muestra el destino antes de abrir nada. Un código QR nunca se abre automáticamente."))
                .font(.subheadline).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            if let qrPayload {
                VStack(alignment: .leading, spacing: 6) {
                    Text(tr("Destination", "Destination", "Destino")).font(.caption.weight(.bold)).foregroundStyle(Theme.cyanLight)
                    Text(qrPayload).font(.system(.footnote, design: .monospaced)).foregroundStyle(Theme.text).textSelection(.enabled)
                }
                .card()
                Button { analyze(ScanInput(kind: .text, raw: "QR code : " + qrPayload, source: "QR code")) } label: {
                    Label(tr("Analyser la destination", "Analyze the destination", "Analizar el destino"), systemImage: "dot.radiowaves.left.and.right")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            Button { scanningQR = true } label: {
                Label(tr("Scanner un QR code", "Scan a QR code", "Escanear un código QR"), systemImage: "camera")
            }
            .buttonStyle(qrPayload == nil ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(GhostButtonStyle()))
        }
        .card()
    }

    private var linkMode: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("https://", text: $link)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.system(.body, design: .monospaced))
                .padding(14)
                .background(Theme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
            Text(tr("Domaine réel, raccourcisseurs, typosquatting, caractères trompeurs : Link Guard décortique l’adresse sans l’ouvrir.",
                    "Real domain, shorteners, typosquatting, deceptive characters: Link Guard takes the address apart without opening it.",
                    "Dominio real, acortadores, typosquatting, caracteres engañosos: Link Guard descompone la dirección sin abrirla."))
                .font(.footnote).foregroundStyle(Theme.muted)
            Button {
                var url = link.trimmingCharacters(in: .whitespacesAndNewlines)
                if !url.lowercased().hasPrefix("http") && !url.lowercased().hasPrefix("www.") { url = "https://" + url }
                analyze(ScanInput(kind: .text, raw: url, source: tr("Lien", "Link", "Enlace")))
            } label: {
                Label(tr("Vérifier le lien", "Check the link", "Verificar el enlace"), systemImage: "link")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(link.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: Actions

    private func analyze(_ input: ScanInput) {
        error = nil
        result = input
    }

    private func takePending() {
        if let pending = model.pending {
            model.pending = nil
            analyze(pending)
        }
    }

    private func load(_ picked: Result<URL, Error>) {
        switch picked {
        case .success(let url):
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                error = tr("Ce fichier ne peut pas être lu.", "This file cannot be read.", "No se puede leer este archivo.")
                return
            }
            let raw = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
            analyze(ScanInput(kind: .email, raw: raw, source: url.lastPathComponent))
        case .failure(let failure):
            error = failure.localizedDescription
        }
    }

    private func read(_ item: PhotosPickerItem) {
        reading = true
        Task {
            defer { reading = false; photo = nil }
            guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                error = tr("Cette image ne peut pas être lue.", "This image cannot be read.", "No se puede leer esta imagen.")
                return
            }
            let ocr = await OCR.read(image)
            var raw = ocr.text
            if !ocr.qrPayloads.isEmpty {
                raw += "\n\nQR code :\n" + ocr.qrPayloads.joined(separator: "\n")
            }
            guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                error = tr("Aucun texte trouvé sur cette image.", "No text found in this image.", "No se encontró texto en esta imagen.")
                return
            }
            analyze(ScanInput(kind: .text, raw: raw, source: tr("Capture d’écran", "Screenshot", "Captura de pantalla")))
        }
    }
}

/// A button style chosen at run time.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}

/// The scan animation, then the report; the analysis is saved in the history.
struct ScanResultView: View {
    let input: ScanInput
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var model
    @State private var report: Report?

    var body: some View {
        Group {
            if let report {
                ReportView(report: report, title: input.title, onSOS: { model.showSOS = true })
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScanFlowView {
                    let computed = input.report
                    context.insert(AnalysisRecord(input: input, report: computed))
                    try? context.save()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { report = computed }
                    let feedback = UINotificationFeedbackGenerator()
                    feedback.notificationOccurred(computed.verdict == .safe ? .success : (computed.verdict == .danger ? .error : .warning))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppBackground())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// QR codes, live from the camera (VisionKit), when the device can.
struct QRScannerSheet: View {
    let onFound: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    QRScannerView(onFound: onFound).ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        tr("Caméra indisponible", "Camera unavailable", "Cámara no disponible"),
                        systemImage: "camera.badge.ellipsis",
                        description: Text(tr("Autorisez la caméra dans Réglages, ou utilisez une capture d’écran du QR code.",
                                             "Allow the camera in Settings, or use a screenshot of the QR code.",
                                             "Permite la cámara en Ajustes o usa una captura del código QR.")))
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Fermer", "Close", "Cerrar")) { dismiss() }
                }
            }
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    let onFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning { try? scanner.startScanning() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onFound: (String) -> Void
        private var found = false

        init(onFound: @escaping (String) -> Void) {
            self.onFound = onFound
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue, !found {
                    found = true
                    dataScanner.stopScanning()
                    onFound(payload)
                }
            }
        }
    }
}
