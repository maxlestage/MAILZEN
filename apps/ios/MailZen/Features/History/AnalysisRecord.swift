import Foundation
import SwiftUI
import SwiftData
import MailZenKit

/// What was analyzed, kept on this device only.
struct ScanInput: Identifiable, Hashable {
    enum Kind: String, Codable {
        /// Text pasted, read from a screenshot, or a link.
        case text
        /// A raw email (`.eml` file, or fetched from the mailbox).
        case email
        /// Any file, for Attachment Guard (`raw` holds its bytes in base64).
        case file
    }

    let id = UUID()
    let kind: Kind
    let raw: String
    let source: String

    var report: Report {
        switch kind {
        case .text: Engine.analyze(raw)
        case .email: Engine.analyze(EmailMessage(raw: raw))
        case .file: fileReport?.report ?? Engine.analyze("")
        }
    }

    /// The parsed message, for ZenAI and Safe Reply.
    var message: EmailMessage? {
        kind == .file ? nil : EmailMessage(raw: raw)
    }

    /// The analysis of a file.
    var fileReport: FileReport? {
        guard kind == .file, let data = Data(base64Encoded: raw) else { return nil }
        return FileAnalyzer.analyze(data: data, filename: source)
    }

    /// A short title: the subject of an email, the name of a file, or the first words.
    var title: String {
        if kind == .file { return source }
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
    var riskyLinks: Int = 0

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
        riskyLinks = report.links.filter(\.risky).count
    }

    var verdict: Verdict { Verdict(rawValue: verdictRaw) ?? .safe }
    var input: ScanInput { ScanInput(kind: ScanInput.Kind(rawValue: kindRaw) ?? .text, raw: raw, source: source) }
    var linkCount: Int { riskyLinks }
}

/// The report of a saved analysis, computed when it is opened.
struct RecordReportView: View {
    let record: AnalysisRecord
    var onSOS: (() -> Void)? = nil
    @State private var computed: (Report, EmailMessage?, FileReport?)?

    var body: some View {
        Group {
            if let computed {
                ReportView(report: computed.0, title: record.title, message: computed.1, file: computed.2, onSOS: onSOS)
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(AppBackground())
            }
        }
        .task {
            guard computed == nil else { return }
            let input = record.input
            let file = input.fileReport
            computed = (file?.report ?? input.report, input.message, file)
        }
    }
}
