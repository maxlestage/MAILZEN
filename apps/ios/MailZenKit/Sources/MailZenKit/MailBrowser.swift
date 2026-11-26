import Foundation

// Browsing a mailbox: its folders, and every message, page by page from the newest, each
// with its verdict, without marking anything as read. Each call is a short session
// (login, read-only EXAMINE, one command, logout), so nothing stays open in the background.

/// A folder of a mailbox (IMAP LIST).
public struct IMAPFolder: Identifiable, Hashable, Sendable, Codable {
    public enum Kind: String, Sendable, Codable, CaseIterable {
        case inbox, sent, drafts, junk, trash, archive, all, flagged, other
    }

    /// The name used in commands (modified UTF-7, as the server sends it).
    public let name: String
    public let delimiter: String?
    public let flags: [String]
    public var id: String { name }

    public init(name: String, delimiter: String?, flags: [String]) {
        self.name = name
        self.delimiter = delimiter
        self.flags = flags
    }

    public var selectable: Bool {
        !flags.contains { $0.caseInsensitiveCompare("\\Noselect") == .orderedSame || $0.caseInsensitiveCompare("\\NonExistent") == .orderedSame }
    }

    /// The full name, decoded (modified UTF-7 → Unicode).
    public var decodedName: String { Self.decodeModifiedUTF7(name) }

    /// The last part of the name, for display.
    public var displayName: String {
        if kind == .inbox { return tr("Boîte de réception", "Inbox", "Bandeja de entrada") }
        let full = decodedName
        guard let delimiter, !delimiter.isEmpty else { return full }
        return full.components(separatedBy: delimiter).last ?? full
    }

    /// How deep the folder is in the tree (0 at the top).
    public var depth: Int {
        guard let delimiter, !delimiter.isEmpty, kind == .other else { return 0 }
        return max(0, decodedName.components(separatedBy: delimiter).count - 1 - (decodedName.hasPrefix("INBOX" + delimiter) ? 1 : 0))
    }

    /// What the folder is for: the special-use flags (RFC 6154), else its usual names.
    public var kind: Kind {
        if name.caseInsensitiveCompare("INBOX") == .orderedSame { return .inbox }
        let lower = flags.map { $0.lowercased() }
        if lower.contains("\\sent") { return .sent }
        if lower.contains("\\drafts") { return .drafts }
        if lower.contains("\\junk") { return .junk }
        if lower.contains("\\trash") { return .trash }
        if lower.contains("\\archive") { return .archive }
        if lower.contains("\\all") { return .all }
        if lower.contains("\\flagged") { return .flagged }
        let leaf = (delimiter.flatMap { decodedName.components(separatedBy: $0).last } ?? decodedName).lowercased()
        switch leaf {
        case "sent", "sent messages", "sent items", "envoyés", "éléments envoyés", "messages envoyés", "enviados", "elementos enviados": return .sent
        case "drafts", "brouillons", "borradores": return .drafts
        case "junk", "spam", "bulk mail", "courrier indésirable", "indésirables", "correo no deseado": return .junk
        case "trash", "deleted messages", "deleted items", "corbeille", "éléments supprimés", "papelera", "eliminados": return .trash
        case "archive", "archives", "archivo", "archivos": return .archive
        default: return .other
        }
    }

    /// The order of the folders in a list: inbox first, then the usual ones.
    public var rank: Int {
        switch kind {
        case .inbox: 0
        case .flagged: 1
        case .drafts: 2
        case .sent: 3
        case .archive: 4
        case .junk: 5
        case .trash: 6
        case .all: 8
        case .other: 7
        }
    }

    /// Decodes an IMAP modified UTF-7 name (RFC 3501, 5.1.3): `&AOk-` is `é`, `&-` is `&`.
    public static func decodeModifiedUTF7(_ s: String) -> String {
        guard s.contains("&") else { return s }
        var out = ""
        var i = s.startIndex
        while i < s.endIndex {
            let c = s[i]
            guard c == "&" else { out.append(c); i = s.index(after: i); continue }
            guard let end = s[s.index(after: i)...].firstIndex(of: "-") else { out += s[i...]; break }
            let chunk = s[s.index(after: i)..<end]
            if chunk.isEmpty {
                out.append("&")
            } else {
                var b64 = chunk.replacingOccurrences(of: ",", with: "/")
                while b64.count % 4 != 0 { b64 += "=" }
                if let data = Data(base64Encoded: b64), let text = String(data: data, encoding: .utf16BigEndian) {
                    out += text
                } else {
                    out += "&" + chunk + "-"
                }
            }
            i = s.index(after: end)
        }
        return out
    }
}

/// A message of a list: what is needed to show it and its verdict, analyzed from its first
/// bytes (the whole message is fetched when it is opened).
public struct MailSummary: Identifiable, Hashable, Sendable {
    public let uid: UInt32
    public let folder: String
    /// The account it comes from (its address).
    public let account: String
    public let message: EmailMessage
    public let report: Report
    public let date: Date?
    public var id: String { "\(account)/\(folder)/\(uid)" }

    public var sender: String {
        guard let from = message.from, !from.isEmpty else { return message.fromAddress ?? tr("(expéditeur inconnu)", "(unknown sender)", "(remitente desconocido)") }
        if let lt = from.firstIndex(of: "<") {
            let name = from[..<lt].trimmingCharacters(in: CharacterSet(charactersIn: " \""))
            if !name.isEmpty { return name }
        }
        return message.fromAddress ?? from
    }

    public var subject: String {
        let s = message.subject?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? tr("(sans objet)", "(no subject)", "(sin asunto)") : s
    }

    /// The first words of the body.
    public var preview: String {
        String(message.bodyText.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(140))
    }

    /// The date of an email header (RFC 5322), in its usual forms.
    public static func parseDate(_ text: String?) -> Date? {
        guard var text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if let paren = text.firstIndex(of: "(") { text = text[..<paren].trimmingCharacters(in: .whitespaces) }
        for format in ["EEE, d MMM yyyy HH:mm:ss Z", "d MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm Z", "EEE, d MMM yy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm:ss zzz"] {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = format
            if let d = f.date(from: text) { return d }
        }
        return nil
    }
}

/// A page of a folder.
public struct MailPage: Sendable {
    public let uidValidity: UInt32
    /// Every UID of the folder, from the oldest (to page through it without searching again).
    public let uids: [UInt32]
    /// The messages of this page, from the newest.
    public let items: [MailSummary]
}

extension IMAPClient {
    /// The folders of the mailbox.
    public func list() async throws -> [IMAPFolder] {
        let lines = try await command("LIST \"\" \"*\"")
        return lines.compactMap(Self.parseList)
    }

    /// One `* LIST (flags) "delimiter" name` line.
    static func parseList(_ line: IMAPLine) -> IMAPFolder? {
        var rest = Substring(line.text)
        guard rest.hasPrefix("* LIST ") || rest.hasPrefix("* XLIST ") else { return nil }
        rest = rest.drop { $0 != "(" }
        guard let close = rest.firstIndex(of: ")") else { return nil }
        let flags = rest[rest.index(after: rest.startIndex)..<close].split(separator: " ").map(String.init)
        rest = rest[rest.index(after: close)...].drop { $0 == " " }
        var delimiter: String?
        if rest.hasPrefix("NIL") {
            rest = rest.dropFirst(3)
        } else if rest.hasPrefix("\"") {
            var d = ""
            var i = rest.index(after: rest.startIndex)
            while i < rest.endIndex, rest[i] != "\"" {
                if rest[i] == "\\", rest.index(after: i) < rest.endIndex { i = rest.index(after: i) }
                d.append(rest[i])
                i = rest.index(after: i)
            }
            delimiter = d
            rest = i < rest.endIndex ? rest[rest.index(after: i)...] : ""
        }
        rest = rest.drop { $0 == " " }
        let name: String
        if rest.hasPrefix("{"), let literal = line.literals.first {
            name = String(decoding: literal, as: UTF8.self)
        } else if rest.hasPrefix("\"") {
            var n = ""
            var i = rest.index(after: rest.startIndex)
            while i < rest.endIndex, rest[i] != "\"" {
                if rest[i] == "\\", rest.index(after: i) < rest.endIndex { i = rest.index(after: i) }
                n.append(rest[i])
                i = rest.index(after: i)
            }
            name = n
        } else {
            name = String(rest).trimmingCharacters(in: .whitespaces)
        }
        guard !name.isEmpty else { return nil }
        return IMAPFolder(name: name, delimiter: delimiter, flags: flags)
    }
}

public enum MailBrowser {
    /// The bytes read of each message of a list: enough for its headers and the start of
    /// its text, so that a page stays light.
    public static let previewBytes = 24_576
    /// The bytes read of an opened message (attachments included, up to this size).
    public static let fullBytes = 8_000_000

    static func session<T: Sendable>(_ transport: IMAPTransport, user: String, password: String,
                                     _ body: (IMAPClient) async throws -> T) async throws -> T {
        let client = IMAPClient(transport: transport)
        do {
            try await client.greeting()
            try await client.login(user: user, password: password)
            let value = try await body(client)
            await client.logout()
            return value
        } catch {
            await client.logout()
            throw error
        }
    }

    static func summaries(_ fetched: [FetchedMessage], folder: String, account: String) -> [MailSummary] {
        fetched.map { f in
            let message = EmailMessage(data: f.data)
            return MailSummary(uid: f.uid, folder: folder, account: account, message: message,
                               report: Engine.analyze(message), date: MailSummary.parseDate(message.date))
        }
        .sorted { $0.uid > $1.uid }
    }

    /// The folders of a mailbox, in a useful order.
    public static func folders(transport: IMAPTransport, user: String, password: String) async throws -> [IMAPFolder] {
        let all = try await session(transport, user: user, password: password) { try await $0.list() }
        var seen = Set<String>()
        return all.filter { $0.selectable && seen.insert($0.name).inserted }
            .sorted { ($0.rank, $0.decodedName.lowercased()) < ($1.rank, $1.decodedName.lowercased()) }
    }

    /// A page of a folder, from the newest: the `size` messages before `before` (from the
    /// top when nil). `knownUIDs`, from an earlier page with the same `uidValidity`, saves
    /// searching the folder again.
    public static func page(transport: IMAPTransport, user: String, password: String, folder: String,
                            knownUIDs: [UInt32]? = nil, uidValidity: UInt32? = nil,
                            before: UInt32? = nil, size: Int = 30) async throws -> MailPage {
        try await session(transport, user: user, password: password) { client in
            let status = try await client.select(folder)
            var uids = knownUIDs ?? []
            if knownUIDs == nil || uidValidity != status.uidValidity {
                uids = status.exists == 0 ? [] : try await client.uidSearch("ALL")
            }
            let older = before.map { b in uids.filter { $0 < b } } ?? uids
            let chosen = Array(older.suffix(size))
            let fetched = try await client.fetch(uids: chosen, maxBytes: previewBytes)
            return MailPage(uidValidity: status.uidValidity, uids: uids,
                            items: summaries(fetched, folder: folder, account: user))
        }
    }

    /// The messages arrived after `after` in a folder (at most `limit`, the newest).
    public static func newer(transport: IMAPTransport, user: String, password: String, folder: String,
                             after: UInt32, limit: Int = 50) async throws -> (uidValidity: UInt32, items: [MailSummary]) {
        try await session(transport, user: user, password: password) { client in
            let status = try await client.select(folder)
            let uids = status.exists == 0 ? [] : Array(try await client.uidSearch("UID \(after + 1):*").filter { $0 > after }.suffix(limit))
            let fetched = try await client.fetch(uids: uids, maxBytes: previewBytes)
            return (status.uidValidity, summaries(fetched, folder: folder, account: user))
        }
    }

    /// A whole message, to open it (left unread).
    public static func message(transport: IMAPTransport, user: String, password: String, folder: String, uid: UInt32) async throws -> EmailMessage? {
        try await session(transport, user: user, password: password) { client in
            _ = try await client.select(folder)
            return try await client.fetch(uids: [uid], maxBytes: fullBytes).first.map { EmailMessage(data: $0.data) }
        }
    }
}
