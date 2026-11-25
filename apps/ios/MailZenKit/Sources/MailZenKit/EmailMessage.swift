import Foundation

/// An email read from a `.eml` file or fetched over IMAP (RFC 5322 and MIME): its
/// headers, its text, the links hidden in its HTML, and its attachments.
public struct EmailMessage: Sendable, Hashable {
    public struct Attachment: Sendable, Hashable {
        public let filename: String
        public let mimeType: String
        public let size: Int
    }

    public let from: String?
    public let replyTo: String?
    public let subject: String?
    public let date: String?
    public let messageID: String?
    /// `spf=fail`, `dkim=fail` or `dmarc=fail` when a server reported it.
    public let failedAuthentication: String?
    public let bodyText: String
    /// The links of the HTML part (`href`), which the visible text may hide.
    public let links: [String]
    public let attachments: [Attachment]

    /// The address alone: `service@example.com` for `Service <service@example.com>`.
    public var fromAddress: String? { from.map(Self.address) }

    /// The text given to the engine.
    public var analysisText: String {
        var parts: [String] = []
        if let from { parts.append("From: \(from)") }
        if let replyTo { parts.append("Reply-To: \(replyTo)") }
        if let subject { parts.append("Subject: \(subject)") }
        parts.append("")
        parts.append(bodyText)
        let hidden = links.filter { !bodyText.contains($0) }
        if !hidden.isEmpty {
            parts.append("")
            parts.append(hidden.joined(separator: "\n"))
        }
        if !attachments.isEmpty {
            parts.append("")
            parts.append(attachments.map(\.filename).joined(separator: "\n"))
        }
        return parts.joined(separator: "\n")
    }

    public static func == (a: EmailMessage, b: EmailMessage) -> Bool {
        a.from == b.from && a.subject == b.subject && a.bodyText == b.bodyText && a.messageID == b.messageID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(subject)
        hasher.combine(messageID)
    }

    // MARK: Parsing

    /// Parses a raw message (the bytes of a `.eml` file or of an IMAP `BODY[]`).
    public init(data: Data) {
        self.init(raw: String(data: data, encoding: .utf8) ?? (String(data: data, encoding: .isoLatin1) ?? ""))
    }

    /// Parses a raw message given as text.
    public init(raw: String) {
        let raw = raw.replacingOccurrences(of: "\r\n", with: "\n")
        let (headers, body) = MIME.splitHeaders(raw)
        func header(_ name: String) -> String? {
            headers.first { $0.0 == name }.map { MIME.decodeWords($0.1) }
        }
        // A pasted email often keeps the labels of the mail app: « De : », « Objet : ».
        from = header("from") ?? header("de") ?? header("remitente")
        replyTo = header("reply-to") ?? header("répondre à")
        subject = header("subject") ?? header("objet") ?? header("asunto")
        date = header("date")
        messageID = header("message-id")
        failedAuthentication = MIME.failedAuthentication(headers.filter { $0.0 == "authentication-results" }.map(\.1))

        var collector = MIME.Collector()
        MIME.walk(headers: headers, body: body, into: &collector, depth: 0)
        var text = collector.plain.joined(separator: "\n\n")
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text = collector.html.map(MIME.htmlToText).joined(separator: "\n\n")
        }
        if text.isEmpty && headers.isEmpty {
            // Not an email: plain text pasted or shared.
            text = raw
        }
        bodyText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var hrefs: [String] = []
        for html in collector.html {
            for link in MIME.hrefs(html) where !hrefs.contains(link) {
                hrefs.append(link)
            }
        }
        links = hrefs
        attachments = collector.attachments
    }

    static func address(_ value: String) -> String {
        if let open = value.lastIndex(of: "<"), let close = value.lastIndex(of: ">"), open < close {
            return String(value[value.index(after: open)..<close])
        }
        return value.trimmingCharacters(in: .whitespaces)
    }
}

/// MIME helpers: headers, parts, transfer encodings, charsets.
enum MIME {
    struct Collector {
        var plain: [String] = []
        var html: [String] = []
        var attachments: [EmailMessage.Attachment] = []
    }

    /// Lowercased header names and their unfolded values, then the body.
    static func splitHeaders(_ raw: String) -> ([(String, String)], String) {
        let (head, body): (Substring, String)
        if let blank = raw.range(of: "\n\n") {
            head = raw[..<blank.lowerBound]
            body = String(raw[blank.upperBound...])
        } else {
            head = raw[...]
            body = ""
        }
        var headers: [(String, String)] = []
        for line in head.split(separator: "\n", omittingEmptySubsequences: false) {
            if let first = line.first, first == " " || first == "\t", !headers.isEmpty {
                headers[headers.count - 1].1 += " " + line.trimmingCharacters(in: .whitespaces)
            } else if let colon = line.firstIndex(of: ":") {
                let name = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
                guard !name.isEmpty, !name.contains(" ") else { return ([], raw) }
                headers.append((name, line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)))
            } else {
                // A line of the head that is no header: this is not an email.
                return ([], raw)
            }
        }
        return (headers, body)
    }

    /// A parameter of a header value: `boundary`, `charset`, `filename`, `name`.
    static func parameter(_ value: String, _ name: String) -> String? {
        for part in value.split(separator: ";").dropFirst() {
            let pair = part.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }
            let key = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
            var v = pair[1].trimmingCharacters(in: .whitespaces)
            if v.hasPrefix("\""), v.hasSuffix("\""), v.count >= 2 { v = String(v.dropFirst().dropLast()) }
            if key == name { return decodeWords(v) }
            if key == name + "*" {
                // RFC 2231: utf-8''name%20with%20spaces
                let pieces = v.components(separatedBy: "''")
                return (pieces.last ?? v).removingPercentEncoding ?? v
            }
        }
        return nil
    }

    static func walk(headers: [(String, String)], body: String, into collector: inout Collector, depth: Int) {
        guard depth < 8 else { return }
        func header(_ name: String) -> String? { headers.first { $0.0 == name }?.1 }
        let contentType = header("content-type") ?? "text/plain; charset=us-ascii"
        let mimeType = contentType.split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? "text/plain"
        let disposition = header("content-disposition") ?? ""
        let filename = parameter(disposition, "filename") ?? parameter(contentType, "name")

        if mimeType.hasPrefix("multipart/"), let boundary = parameter(contentType, "boundary") {
            for part in splitParts(body, boundary: boundary) {
                let (h, b) = splitHeaders(part)
                walk(headers: h, body: b, into: &collector, depth: depth + 1)
            }
            return
        }
        if mimeType == "message/rfc822" {
            let (h, b) = splitHeaders(body)
            walk(headers: h, body: b, into: &collector, depth: depth + 1)
            return
        }
        let encoding = (header("content-transfer-encoding") ?? "7bit").lowercased()
        let data = decodeTransfer(body, encoding: encoding)
        let isAttachment = disposition.lowercased().hasPrefix("attachment") || (filename != nil && !mimeType.hasPrefix("text/"))
        if isAttachment || !(mimeType == "text/plain" || mimeType == "text/html") {
            if let filename {
                collector.attachments.append(.init(filename: filename, mimeType: mimeType, size: data.count))
            }
            return
        }
        let text = decodeCharset(data, charset: parameter(contentType, "charset"))
        if mimeType == "text/html" {
            collector.html.append(text)
        } else {
            collector.plain.append(text)
        }
    }

    static func splitParts(_ body: String, boundary: String) -> [String] {
        let delimiter = "--" + boundary
        var parts: [String] = []
        var current: [Substring]? = nil
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == delimiter + "--" {
                if let current { parts.append(current.joined(separator: "\n")) }
                return parts
            }
            if trimmed == delimiter {
                if let current { parts.append(current.joined(separator: "\n")) }
                current = []
                continue
            }
            current?.append(line)
        }
        if let current { parts.append(current.joined(separator: "\n")) }
        return parts
    }

    static func decodeTransfer(_ body: String, encoding: String) -> Data {
        switch encoding {
        case "base64":
            let compact = body.filter { !$0.isWhitespace }
            return Data(base64Encoded: compact, options: .ignoreUnknownCharacters) ?? Data(body.utf8)
        case "quoted-printable":
            return quotedPrintable(body, underscoreIsSpace: false)
        default:
            return Data(body.utf8)
        }
    }

    static func quotedPrintable(_ text: String, underscoreIsSpace: Bool) -> Data {
        var bytes: [UInt8] = []
        let utf8 = Array(text.utf8)
        var i = 0
        func hex(_ b: UInt8) -> UInt8? {
            switch b {
            case 48...57: b - 48
            case 65...70: b - 55
            case 97...102: b - 87
            default: nil
            }
        }
        while i < utf8.count {
            let b = utf8[i]
            if b == UInt8(ascii: "=") {
                if i + 1 < utf8.count, utf8[i + 1] == UInt8(ascii: "\n") {
                    i += 2
                    continue
                }
                if i + 2 < utf8.count, let h = hex(utf8[i + 1]), let l = hex(utf8[i + 2]) {
                    bytes.append(h << 4 | l)
                    i += 3
                    continue
                }
            }
            bytes.append(underscoreIsSpace && b == UInt8(ascii: "_") ? UInt8(ascii: " ") : b)
            i += 1
        }
        return Data(bytes)
    }

    static func decodeCharset(_ data: Data, charset: String?) -> String {
        let name = (charset ?? "utf-8").lowercased()
        let encoding: String.Encoding
        switch name {
        case "iso-8859-1", "latin1", "iso-8859-15": encoding = .isoLatin1
        case "windows-1252", "cp1252": encoding = .windowsCP1252
        case "us-ascii", "ascii": encoding = .ascii
        default: encoding = .utf8
        }
        return String(data: data, encoding: encoding)
            ?? String(data: data, encoding: .utf8)
            ?? (String(data: data, encoding: .isoLatin1) ?? "")
    }

    /// RFC 2047: `=?UTF-8?B?...?=` and `=?ISO-8859-1?Q?...?=` in headers.
    static func decodeWords(_ value: String) -> String {
        guard value.contains("=?") else { return value }
        var out = ""
        var rest = Substring(value)
        var lastWasEncoded = false
        while let start = rest.range(of: "=?") {
            let between = rest[..<start.lowerBound]
            if !(lastWasEncoded && between.allSatisfy(\.isWhitespace)) {
                out += between
            }
            let after = rest[start.upperBound...]
            let pieces = after.split(separator: "?", maxSplits: 3, omittingEmptySubsequences: false)
            guard pieces.count == 4, pieces[3].hasPrefix("=") else {
                out += "=?"
                rest = after
                lastWasEncoded = false
                continue
            }
            let charset = String(pieces[0])
            let mode = pieces[1].uppercased()
            let text = String(pieces[2])
            let data = mode == "B"
                ? (Data(base64Encoded: text, options: .ignoreUnknownCharacters) ?? Data())
                : quotedPrintable(text, underscoreIsSpace: true)
            out += decodeCharset(data, charset: charset)
            rest = pieces[3].dropFirst()
            lastWasEncoded = true
        }
        out += rest
        return out
    }

    /// `spf=fail`, `dkim=fail` or `dmarc=fail`, from `Authentication-Results`.
    static func failedAuthentication(_ values: [String]) -> String? {
        for value in values {
            let lower = value.lowercased()
            for check in ["dmarc=fail", "spf=fail", "spf=softfail", "dkim=fail"] where lower.contains(check) {
                return check
            }
        }
        return nil
    }

    /// The visible text of an HTML part.
    static func htmlToText(_ html: String) -> String {
        var text = html
        for (pattern, replacement) in [
            ("(?is)<(script|style)[^>]*>.*?</\\1>", " "),
            ("(?i)<br\\s*/?>", "\n"),
            ("(?i)</(p|div|tr|li|h[1-6])>", "\n"),
            ("(?s)<[^>]+>", " "),
        ] {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        for (entity, char) in [("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'")] {
            text = text.replacingOccurrences(of: entity, with: char)
        }
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n\\s*\\n+", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The `href` of every link of an HTML part.
    static func hrefs(_ html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "(?i)href\\s*=\\s*[\"']([^\"']+)[\"']") else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            Range(match.range(at: 1), in: html).map { String(html[$0]).replacingOccurrences(of: "&amp;", with: "&") }
        }.filter { $0.lowercased().hasPrefix("http") }
    }
}
