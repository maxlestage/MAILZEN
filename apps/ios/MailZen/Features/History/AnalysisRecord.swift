import Foundation
import SwiftData
import MailZenKit

/// What was analyzed, kept on this device only.
struct ScanInput: Identifiable, Hashable {
    enum Kind: String, Codable {
        /// Text pasted, read from a screenshot, or a link.
        case text
        /// A raw email (`.eml` file, or fetched from the mailbox).
        case email
    }

    let id = UUID()
    let kind: Kind
    let raw: String
    let source: String

    var report: Report {
        switch kind {
        case .text: Engine.analyze(raw)
        case .email: Engine.analyze(EmailMessage(raw: raw))
        }
    }

    /// A short title: the subject of an email, or the first words.
    var title: String {
        if kind == .email, let subject = EmailMessage(raw: raw).subject, !subject.isEmpty { return subject }
        let message = EmailMessage(raw: raw)
        if let subject = message.subject, !subject.isEmpty { return subject }
        let line = raw.split(separator: "\n").first { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? ""
        return String(line.prefix(80))
    }
}

@Model
final class AnalysisRecord {
    var id: UUID
    var date: Date
    var kindRaw: String
    var source: String
    var title: String
    var raw: String
    var score: Int
    var verdictRaw: String
    var favorite: Bool

    init(input: ScanInput, report: Report, date: Date = .now) {
        id = UUID()
        self.date = date
        kindRaw = input.kind.rawValue
        source = input.source
        title = input.title
        raw = input.raw
        score = report.score
        verdictRaw = report.verdict.rawValue
        favorite = false
    }

    var verdict: Verdict { Verdict(rawValue: verdictRaw) ?? .safe }
    var input: ScanInput { ScanInput(kind: ScanInput.Kind(rawValue: kindRaw) ?? .text, raw: raw, source: source) }
    var linkCount: Int { input.report.links.filter(\.risky).count }
}
