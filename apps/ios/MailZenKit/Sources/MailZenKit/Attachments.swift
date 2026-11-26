import Foundation

// Attachment Guard: a static analysis of a file, on the device. Its real type (from its
// first bytes, whatever its name says), its SHA-256 fingerprint, and what it hides: the
// scripts and automatic actions of a PDF, the macros of an Office document, the content
// of an archive, the forms of an HTML page, the formulas of a CSV file. Static analysis
// cannot find every malware: it finds the classic traps.

/// What a file really is.
public enum FileKind: String, Sendable {
    case pdf, ooxml, zip, ole, executable, archive, image, html, svg, csv, rtf, text, unknown

    public var label: T3 {
        switch self {
        case .pdf: T3("Document PDF", "PDF document", "Documento PDF")
        case .ooxml: T3("Document Office (Word, Excel, PowerPoint)", "Office document (Word, Excel, PowerPoint)", "Documento de Office (Word, Excel, PowerPoint)")
        case .zip: T3("Archive ZIP", "ZIP archive", "Archivo ZIP")
        case .ole: T3("Ancien document Office (.doc, .xls, .ppt, .msg)", "Legacy Office document (.doc, .xls, .ppt, .msg)", "Documento antiguo de Office (.doc, .xls, .ppt, .msg)")
        case .executable: T3("Programme exécutable", "Executable program", "Programa ejecutable")
        case .archive: T3("Archive (RAR, 7z, gzip)", "Archive (RAR, 7z, gzip)", "Archivo comprimido (RAR, 7z, gzip)")
        case .image: T3("Image", "Image", "Imagen")
        case .html: T3("Page HTML", "HTML page", "Página HTML")
        case .svg: T3("Image SVG", "SVG image", "Imagen SVG")
        case .csv: T3("Tableau CSV", "CSV spreadsheet", "Tabla CSV")
        case .rtf: T3("Document RTF", "RTF document", "Documento RTF")
        case .text: T3("Texte", "Text", "Texto")
        case .unknown: T3("Type inconnu", "Unknown type", "Tipo desconocido")
        }
    }
}

/// The analysis of a file.
public struct FileReport: Sendable {
    public let filename: String
    public let size: Int
    public let sha256: String
    public let kind: FileKind
    /// The files inside an archive or an Office document.
    public let entries: [String]
    public let links: [String]
    /// What could not be analyzed (an encrypted archive, a RAR…).
    public let limits: [T3]
    public let report: Report
}

public enum FileAnalyzer {
    /// Files above this size are only fingerprinted and typed.
    public static let maxAnalyzedSize = 25 * 1_024 * 1_024

    public static func analyze(data: Data, filename: String) -> FileReport {
        let bytes = [UInt8](data.prefix(maxAnalyzedSize))
        let name = filename.lowercased()
        let ext = name.split(separator: ".").count > 1 ? "." + (name.split(separator: ".").last.map(String.init) ?? "") : ""
        let kind = detect(bytes, ext: ext)
        var signals: [Signal] = []
        var entries: [String] = []
        var links: [String] = []
        var limits: [T3] = []
        func push(_ rule: Rule, _ evidence: String) {
            if !signals.contains(where: { $0.rule == rule }) { signals.append(Signal(rule: rule, evidence: evidence)) }
        }

        // The name.
        if let risky = Keywords.riskyExtensions.first(where: { name.hasSuffix($0) }) {
            let stem = String(name.dropLast(risky.count))
            if Keywords.documentExtensions.contains(where: { stem.hasSuffix($0) }) {
                push(.doubleExtension, filename)
            } else {
                push(.riskyFile, filename)
            }
        }
        if [".docm", ".xlsm", ".pptm"].contains(ext) { push(.officeMacros, filename) }

        // The real type against the name.
        if kind == .executable {
            push(.executable, filename)
            if ![".exe", ".msi", ".scr", ".com", ".dll", ".bin", ".app", ""].contains(ext) {
                push(.typeMismatch, "\(ext) → " + FileKind.executable.label.localized)
            }
        }
        let expected: [String: [FileKind]] = [
            ".pdf": [.pdf], ".docx": [.ooxml], ".xlsx": [.ooxml], ".pptx": [.ooxml], ".docm": [.ooxml], ".xlsm": [.ooxml],
            ".doc": [.ole, .rtf], ".xls": [.ole], ".ppt": [.ole], ".zip": [.zip, .ooxml], ".jpg": [.image], ".jpeg": [.image],
            ".png": [.image], ".gif": [.image],
        ]
        if kind != .executable, let allowed = expected[ext], !allowed.contains(kind), kind != .unknown || !bytes.isEmpty {
            push(.typeMismatch, "\(ext) → \(kind.label.localized)")
        }

        switch kind {
        case .pdf:
            let text = latin1(bytes)
            if text.contains("/JavaScript") || text.range(of: "/JS[ (<]", options: .regularExpression) != nil {
                push(.scriptInDocument, "/JavaScript")
            }
            for action in ["/Launch", "/OpenAction", "/AA"] where text.contains(action) {
                push(.autoAction, action)
                break
            }
            if text.contains("/EmbeddedFile") { push(.embeddedFile, "/EmbeddedFile") }
            links = matches(text, "/URI\\s*\\(([^)]{4,})\\)")
        case .zip, .ooxml:
            if let archive = ZipDirectory(bytes) {
                entries = archive.entries.map(\.name)
                if kind == .ooxml {
                    if let macro = entries.first(where: { $0.hasSuffix("vbaProject.bin") }) { push(.officeMacros, macro) }
                    if let external = entries.first(where: { $0.contains("externalLinks/") }) { push(.externalContent, external) }
                    if let embedded = entries.first(where: { $0.contains("embeddings/") || $0.contains("oleObject") }) { push(.embeddedFile, embedded) }
                } else {
                    for entry in archive.entries {
                        let n = entry.name.lowercased()
                        if Keywords.riskyExtensions.contains(where: { n.hasSuffix($0) }) {
                            push(.archiveRisk, entry.name)
                        }
                    }
                }
                if let locked = archive.entries.first(where: \.encrypted) {
                    push(.encryptedArchive, locked.name)
                    limits.append(T3("Le contenu chiffré n’a pas pu être analysé.", "The encrypted content could not be analyzed.", "No se pudo analizar el contenido cifrado."))
                }
                let packed = archive.entries.reduce(0) { $0 + $1.compressedSize }
                let unpacked = archive.entries.reduce(0) { $0 + $1.uncompressedSize }
                if unpacked > 2_000_000_000 || (unpacked > 50_000_000 && unpacked / max(packed, 1) > 100) {
                    push(.zipBomb, "\(packed / 1024) Ko → \(unpacked / 1_048_576) Mo")
                }
            } else {
                limits.append(T3("Le sommaire de l’archive est illisible.", "The archive’s directory is unreadable.", "El índice del archivo es ilegible."))
            }
        case .ole:
            let text = latin1(bytes)
            let utf16 = String(decoding: bytes.filter { $0 != 0 }, as: UTF8.self)
            if text.contains("_VBA_PROJECT") || utf16.contains("_VBA_PROJECT") || utf16.contains("VBA") && utf16.contains("Macros") {
                push(.officeMacros, "_VBA_PROJECT")
            }
        case .html, .svg:
            let text = String(decoding: bytes, as: UTF8.self)
            if text.range(of: "(?i)<script", options: .regularExpression) != nil
                || (kind == .svg && text.range(of: "(?i)\\son[a-z]+\\s*=", options: .regularExpression) != nil)
            {
                push(.scriptInDocument, "<script>")
            }
            if text.range(of: "(?i)<input[^>]*type\\s*=\\s*[\"']?password", options: .regularExpression) != nil {
                push(.passwordForm, "<input type=password>")
            }
            if text.range(of: "(?i)http-equiv\\s*=\\s*[\"']?refresh", options: .regularExpression) != nil {
                push(.metaRefresh, "http-equiv=refresh")
            }
            if let action = matches(text, "(?i)<form[^>]*action\\s*=\\s*[\"']?(https?://[^\"'\\s>]+)").first {
                push(.externalContent, action)
            }
            links = MIME.hrefs(text) + extractURLs(MIME.htmlToText(text))
        case .csv:
            let text = String(decoding: bytes, as: UTF8.self)
            for line in text.split(whereSeparator: \.isNewline).prefix(5000) {
                for cell in line.split(whereSeparator: { $0 == "," || $0 == ";" || $0 == "\t" }) {
                    var c = cell.trimmingCharacters(in: .whitespaces)
                    if c.hasPrefix("\"") { c.removeFirst() }
                    guard let first = c.first, "=+-@".contains(first), c.count > 1 else { continue }
                    let rest = c.dropFirst()
                    if rest.contains(where: \.isLetter) || rest.contains("|") {
                        push(.formulaInjection, String(c.prefix(60)))
                    }
                }
            }
            links = extractURLs(text)
        case .text, .rtf:
            links = extractURLs(String(decoding: bytes, as: UTF8.self))
        case .archive:
            limits.append(T3("Les archives RAR, 7z et gzip ne sont pas ouvertes : seuls leur type et leur empreinte sont vérifiés.",
                             "RAR, 7z and gzip archives are not opened: only their type and fingerprint are checked.",
                             "Los archivos RAR, 7z y gzip no se abren: solo se comprueban su tipo y su huella."))
        case .executable, .image, .unknown:
            break
        }
        if data.count > maxAnalyzedSize {
            limits.append(T3("Seuls les 25 premiers Mo ont été analysés.", "Only the first 25 MB were analyzed.", "Solo se analizaron los primeros 25 MB."))
        }

        // The links found inside, through the link rules of the engine.
        var unique: [String] = []
        for link in links where !unique.contains(link) { unique.append(link) }
        let linked = Engine.analyze(unique.joined(separator: "\n"))
        for signal in linked.signals where !signal.rule.isManipulation { push(signal.rule, signal.evidence) }

        let score = min(signals.reduce(0) { $0 + $1.rule.weight }, 98)
        let report = Report(
            score: score, verdict: .of(score: score),
            confidence: kind == .unknown || !limits.isEmpty ? 1 : 2,
            signals: signals, links: linked.links)
        return FileReport(filename: filename, size: data.count, sha256: SHA256.hex(data), kind: kind,
                          entries: entries, links: unique, limits: limits, report: report)
    }

    /// The real type of a file, from its first bytes.
    static func detect(_ b: [UInt8], ext: String) -> FileKind {
        func starts(_ prefix: [UInt8]) -> Bool { b.count >= prefix.count && Array(b.prefix(prefix.count)) == prefix }
        if starts([0x25, 0x50, 0x44, 0x46]) { return .pdf }
        if starts([0x50, 0x4B, 0x03, 0x04]) || starts([0x50, 0x4B, 0x05, 0x06]) {
            let head = latin1(Array(b.prefix(65_536)))
            return head.contains("[Content_Types].xml") ? .ooxml : .zip
        }
        if starts([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]) { return .ole }
        if starts([0x4D, 0x5A]) || starts([0x7F, 0x45, 0x4C, 0x46]) || starts([0xCF, 0xFA, 0xED, 0xFE])
            || starts([0xFE, 0xED, 0xFA, 0xCF]) || starts([0xCA, 0xFE, 0xBA, 0xBE]) { return .executable }
        if starts(Array("Rar!".utf8)) || starts([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C]) || starts([0x1F, 0x8B]) { return .archive }
        if starts([0x89, 0x50, 0x4E, 0x47]) || starts([0xFF, 0xD8, 0xFF]) || starts(Array("GIF8".utf8))
            || (b.count > 12 && Array(b[8..<12]) == Array("WEBP".utf8)) || (b.count > 12 && Array(b[4..<8]) == Array("ftyp".utf8)) { return .image }
        if starts(Array("{\\rtf".utf8)) { return .rtf }
        let head = String(decoding: b.prefix(4096), as: UTF8.self).lowercased()
        if head.contains("<svg") { return .svg }
        if head.contains("<html") || head.contains("<!doctype html") || head.contains("<script") || head.contains("<form") { return .html }
        if ext == ".csv" { return .csv }
        let printable = b.prefix(4096).filter { $0 == 9 || $0 == 10 || $0 == 13 || $0 >= 32 }.count
        if !b.isEmpty && printable * 100 / min(b.count, 4096) > 95 { return .text }
        return .unknown
    }

    static func latin1(_ bytes: [UInt8]) -> String {
        String(bytes.map { Character(Unicode.Scalar($0)) })
    }

    static func matches(_ text: String, _ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { m in
            Range(m.range(at: 1), in: text).map { String(text[$0]) }
        }
    }
}

/// The central directory of a ZIP archive (and of Office documents, which are ZIPs).
struct ZipDirectory {
    struct Entry {
        let name: String
        let compressedSize: Int
        let uncompressedSize: Int
        let encrypted: Bool
    }

    let entries: [Entry]

    init?(_ b: [UInt8]) {
        func u16(_ i: Int) -> Int { i + 1 < b.count ? Int(b[i]) | Int(b[i + 1]) << 8 : 0 }
        func u32(_ i: Int) -> Int { i + 3 < b.count ? u16(i) | u16(i + 2) << 16 : 0 }
        guard b.count >= 22 else { return nil }
        var end = -1
        var i = b.count - 22
        let floor = max(0, b.count - 65_557)
        while i >= floor {
            if b[i] == 0x50, b[i + 1] == 0x4B, b[i + 2] == 0x05, b[i + 3] == 0x06 { end = i; break }
            i -= 1
        }
        guard end >= 0 else { return nil }
        let count = u16(end + 10)
        var p = u32(end + 16)
        var found: [Entry] = []
        for _ in 0..<min(count, 10_000) {
            guard p + 46 <= b.count, u32(p) == 0x0201_4B50 else { break }
            let flags = u16(p + 8)
            let compressed = u32(p + 20)
            let uncompressed = u32(p + 24)
            let nameLength = u16(p + 28)
            let extra = u16(p + 30)
            let comment = u16(p + 32)
            guard p + 46 + nameLength <= b.count else { break }
            let name = String(decoding: b[(p + 46)..<(p + 46 + nameLength)], as: UTF8.self)
            found.append(Entry(name: name, compressedSize: compressed, uncompressedSize: uncompressed, encrypted: flags & 1 == 1))
            p += 46 + nameLength + extra + comment
        }
        entries = found
    }
}
