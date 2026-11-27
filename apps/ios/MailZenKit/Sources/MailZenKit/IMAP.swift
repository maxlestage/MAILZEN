import Foundation

// A small IMAP4rev1 client (RFC 3501), enough to watch a mailbox: log in with an
// app-specific password, select the inbox, find the new messages and fetch them
// without marking them as read (`BODY.PEEK`). The network is behind `IMAPTransport`,
// so the protocol is tested without a server.

/// The bytes to and from the server.
public protocol IMAPTransport: Sendable {
    func send(_ data: Data) async throws
    /// The next bytes from the server; empty when the connection is closed.
    func receive() async throws -> Data
    func close() async
}

public enum IMAPError: Error, Equatable, Sendable {
    case closed
    case rejected(String)
    case unexpected(String)
    case timeout

    public var message: T3 {
        switch self {
        case .closed: T3("La connexion a été fermée par le serveur.", "The server closed the connection.", "El servidor cerró la conexión.")
        case .rejected(let text): T3("Le serveur a refusé : \(text)", "The server refused: \(text)", "El servidor rechazó: \(text)")
        case .unexpected(let text): T3("Réponse inattendue : \(text)", "Unexpected answer: \(text)", "Respuesta inesperada: \(text)")
        case .timeout: T3("Le serveur ne répond pas.", "The server does not answer.", "El servidor no responde.")
        }
    }

    /// The server refused the address or the password.
    public var isAuthenticationFailure: Bool {
        guard case .rejected(let text) = self else { return false }
        let t = text.lowercased()
        return ["authenticationfailed", "invalid credentials", "authentication failed", "login failed",
                "invalid login", "incorrect", "authorizationfailed", "web login required"].contains { t.contains($0) }
    }
}

/// A line of an IMAP response, with the literals (`{n}` followed by n bytes) it carries.
public struct IMAPLine: Sendable, Equatable {
    public var text: String
    public var literals: [Data]
}

/// A fetched message: its UID and its raw bytes.
public struct FetchedMessage: Sendable {
    public let uid: UInt32
    public let data: Data
}

/// The state of the inbox after `SELECT`.
public struct MailboxStatus: Sendable, Equatable {
    public var exists: Int = 0
    public var uidValidity: UInt32 = 0
    public var uidNext: UInt32 = 0
}

public actor IMAPClient {
    private let transport: IMAPTransport
    private var buffer = Data()
    private var counter = 0

    public init(transport: IMAPTransport) {
        self.transport = transport
    }

    // MARK: Commands

    /// Reads the greeting of the server (`* OK …`).
    public func greeting() async throws {
        let line = try await readLine()
        guard line.text.hasPrefix("* OK") || line.text.hasPrefix("* PREAUTH") else {
            throw IMAPError.unexpected(line.text)
        }
    }

    public func login(user: String, password: String) async throws {
        _ = try await command("LOGIN \(Self.quote(user)) \(Self.quote(password))", secret: true)
    }

    @discardableResult
    public func select(_ mailbox: String = "INBOX") async throws -> MailboxStatus {
        let lines = try await command("EXAMINE \(Self.quote(mailbox))")
        var status = MailboxStatus()
        for line in lines {
            let parts = line.text.split(separator: " ")
            if parts.count >= 3, parts[2] == "EXISTS", let n = Int(parts[1]) { status.exists = n }
            if let v = Self.bracketValue(line.text, "UIDVALIDITY") { status.uidValidity = v }
            if let v = Self.bracketValue(line.text, "UIDNEXT") { status.uidNext = v }
        }
        return status
    }

    /// The UIDs matching a search, e.g. `UID 120:*` or `ALL`.
    public func uidSearch(_ criteria: String) async throws -> [UInt32] {
        let lines = try await command("UID SEARCH \(criteria)")
        var uids: [UInt32] = []
        for line in lines where line.text.hasPrefix("* SEARCH") {
            uids += line.text.split(separator: " ").dropFirst(2).compactMap { UInt32($0) }
        }
        return uids.sorted()
    }

    /// The first `maxBytes` of each message, left unread.
    public func fetch(uids: [UInt32], maxBytes: Int = 65_536) async throws -> [FetchedMessage] {
        guard !uids.isEmpty else { return [] }
        let set = uids.map(String.init).joined(separator: ",")
        let lines = try await command("UID FETCH \(set) (UID BODY.PEEK[]<0.\(maxBytes)>)")
        return lines.compactMap { line in
            guard line.text.contains(" FETCH "), let data = line.literals.first,
                  let uid = Self.number(after: "UID ", in: line.text) else { return nil }
            return FetchedMessage(uid: uid, data: data)
        }
    }

    public func logout() async {
        _ = try? await command("LOGOUT")
        await transport.close()
    }

    // MARK: Protocol

    /// Sends a tagged command and returns the untagged lines before its `OK`.
    func command(_ text: String, secret: Bool = false) async throws -> [IMAPLine] {
        counter += 1
        let tag = "a\(counter)"
        try await transport.send(Data("\(tag) \(text)\r\n".utf8))
        var lines: [IMAPLine] = []
        while true {
            let line = try await readLine()
            if line.text.hasPrefix(tag + " ") {
                let status = line.text.dropFirst(tag.count + 1)
                if status.hasPrefix("OK") { return lines }
                let reason = String(status.drop { $0 != " " }.dropFirst())
                throw IMAPError.rejected(secret ? reason : reason)
            }
            if line.text.hasPrefix("+") {
                throw IMAPError.unexpected(line.text)
            }
            lines.append(line)
        }
    }

    /// One response line, with its literals read in full.
    func readLine() async throws -> IMAPLine {
        var line = IMAPLine(text: "", literals: [])
        while true {
            let part = try await readRawLine()
            line.text += part
            // A literal: `{123}` at the end of the line, then 123 bytes, then the rest.
            if part.hasSuffix("}"), let open = part.lastIndex(of: "{"),
               let size = Int(part[part.index(after: open)..<part.index(before: part.endIndex)])
            {
                line.literals.append(try await readBytes(size))
                continue
            }
            return line
        }
    }

    private func readRawLine() async throws -> String {
        while true {
            if let end = buffer.firstIndex(of: 0x0A) {
                var lineData = buffer[buffer.startIndex..<end]
                if lineData.last == 0x0D { lineData = lineData.dropLast() }
                buffer = Data(buffer[buffer.index(after: end)...])
                return String(data: lineData, encoding: .utf8) ?? String(data: lineData, encoding: .isoLatin1) ?? ""
            }
            try await fill()
        }
    }

    private func readBytes(_ count: Int) async throws -> Data {
        while buffer.count < count {
            try await fill()
        }
        let data = Data(buffer.prefix(count))
        buffer = Data(buffer.dropFirst(count))
        return data
    }

    private func fill() async throws {
        let more = try await transport.receive()
        if more.isEmpty { throw IMAPError.closed }
        buffer.append(more)
    }

    // MARK: Helpers

    /// An IMAP quoted string.
    static func quote(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    static func bracketValue(_ text: String, _ key: String) -> UInt32? {
        guard let range = text.range(of: "[\(key) ") else { return nil }
        let digits = text[range.upperBound...].prefix { $0.isNumber }
        return UInt32(digits)
    }

    static func number(after key: String, in text: String) -> UInt32? {
        guard let range = text.range(of: key) else { return nil }
        return UInt32(text[range.upperBound...].prefix { $0.isNumber })
    }
}

// MARK: - Providers

/// A mail service and how to reach it over IMAP.
public struct MailProvider: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let host: String
    public let port: UInt16
    /// Where to create an app-specific password.
    public let passwordHelp: URL?
    public let note: T3

    public static let all: [MailProvider] = [
        MailProvider(
            id: "icloud", name: "iCloud Mail", host: "imap.mail.me.com", port: 993,
            passwordHelp: URL(string: "https://support.apple.com/102654"),
            note: T3("Créez un mot de passe pour app sur account.apple.com (Connexion et sécurité).",
                     "Create an app-specific password at account.apple.com (Sign-In and Security).",
                     "Crea una contraseña para apps en account.apple.com (Inicio de sesión y seguridad).")),
        MailProvider(
            id: "gmail", name: "Gmail", host: "imap.gmail.com", port: 993,
            passwordHelp: URL(string: "https://myaccount.google.com/apppasswords"),
            note: T3("Activez la validation en deux étapes, puis créez un mot de passe d’application.",
                     "Turn on 2-Step Verification, then create an app password.",
                     "Activa la verificación en dos pasos y crea una contraseña de aplicación.")),
        MailProvider(
            id: "yahoo", name: "Yahoo Mail", host: "imap.mail.yahoo.com", port: 993,
            passwordHelp: URL(string: "https://login.yahoo.com/account/security"),
            note: T3("Générez un mot de passe d’application dans la sécurité du compte.",
                     "Generate an app password in the account security settings.",
                     "Genera una contraseña de aplicación en la seguridad de la cuenta.")),
        MailProvider(
            id: "other", name: "IMAP", host: "", port: 993,
            passwordHelp: nil,
            note: T3("Serveur IMAP de votre fournisseur, connexion chiffrée (port 993).",
                     "Your provider’s IMAP server, encrypted connection (port 993).",
                     "El servidor IMAP de tu proveedor, conexión cifrada (puerto 993).")),
    ]

    /// The password as the server expects it. App passwords are shown with spaces
    /// (“abcd efgh ijkl mnop”) that are not part of them: they are removed for the services
    /// that use such passwords.
    public func normalizedPassword(_ password: String) -> String {
        switch id {
        case "gmail", "yahoo", "icloud": password.filter { !$0.isWhitespace }
        default: password.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// What to check when the server refuses the address or the password.
    public var authenticationHelp: T3 {
        switch id {
        case "gmail":
            T3("Gmail a refusé l’adresse ou le mot de passe. Vérifiez l’adresse, puis utilisez un mot de passe d’application de 16 lettres (créé dans votre compte Google, validation en deux étapes activée), pas le mot de passe de votre compte. Les comptes Google d’entreprise ou d’école peuvent les interdire.",
               "Gmail refused the address or the password. Check the address, then use a 16-letter app password (created in your Google Account, with 2-Step Verification on), not your account password. Work or school Google accounts may forbid them.",
               "Gmail rechazó la dirección o la contraseña. Comprueba la dirección y usa una contraseña de aplicación de 16 letras (creada en tu cuenta de Google, con la verificación en dos pasos activada), no la contraseña de tu cuenta. Las cuentas de Google de empresa o escuela pueden prohibirlas.")
        case "icloud":
            T3("iCloud a refusé l’adresse ou le mot de passe. Utilisez votre adresse @icloud.com et un mot de passe pour app (xxxx-xxxx-xxxx-xxxx) créé sur account.apple.com, pas le mot de passe de votre identifiant Apple.",
               "iCloud refused the address or the password. Use your @icloud.com address and an app-specific password (xxxx-xxxx-xxxx-xxxx) created at account.apple.com, not your Apple Account password.",
               "iCloud rechazó la dirección o la contraseña. Usa tu dirección @icloud.com y una contraseña para apps (xxxx-xxxx-xxxx-xxxx) creada en account.apple.com, no la de tu cuenta de Apple.")
        case "yahoo":
            T3("Yahoo a refusé l’adresse ou le mot de passe. Utilisez un mot de passe d’application généré dans la sécurité du compte Yahoo, pas votre mot de passe habituel.",
               "Yahoo refused the address or the password. Use an app password generated in the Yahoo account security settings, not your usual password.",
               "Yahoo rechazó la dirección o la contraseña. Usa una contraseña de aplicación generada en la seguridad de la cuenta de Yahoo, no tu contraseña habitual.")
        default:
            T3("Le serveur a refusé l’adresse ou le mot de passe. Vérifiez-les, ainsi que l’adresse du serveur IMAP ; certains fournisseurs demandent un mot de passe d’application.",
               "The server refused the address or the password. Check them, and the IMAP server address; some providers require an app password.",
               "El servidor rechazó la dirección o la contraseña. Compruébalos, así como la dirección del servidor IMAP; algunos proveedores exigen una contraseña de aplicación.")
        }
    }

    /// The provider of an address, from its domain.
    public static func guess(for email: String) -> MailProvider {
        let domain = email.split(separator: "@").last.map { $0.lowercased() } ?? ""
        switch domain {
        case "icloud.com", "me.com", "mac.com": return all[0]
        case "gmail.com", "googlemail.com": return all[1]
        case let d where d.hasPrefix("yahoo."): return all[2]
        default: return all[3]
        }
    }
}

// MARK: - Watching a mailbox

/// What a check of the inbox found.
public struct MailboxCheck: Sendable {
    public struct Item: Sendable {
        public let uid: UInt32
        public let message: EmailMessage
        public let report: Report
    }

    public let uidValidity: UInt32
    public let lastUID: UInt32
    public let items: [Item]
}

public enum MailboxWatcher {
    /// Fetches and analyzes the messages arrived since `lastUID` (the last `firstRun`
    /// ones the first time), without marking them as read.
    public static func check(
        transport: IMAPTransport, user: String, password: String,
        lastUID: UInt32?, uidValidity: UInt32?, firstRun: Int = 10
    ) async throws -> MailboxCheck {
        let client = IMAPClient(transport: transport)
        try await client.greeting()
        try await client.login(user: user, password: password)
        let status = try await client.select("INBOX")
        var uids: [UInt32]
        if let lastUID, uidValidity == status.uidValidity {
            uids = try await client.uidSearch("UID \(lastUID + 1):*").filter { $0 > lastUID }
        } else {
            uids = Array(try await client.uidSearch("ALL").suffix(firstRun))
        }
        uids = Array(uids.suffix(50))
        let fetched = try await client.fetch(uids: uids)
        await client.logout()
        let items = fetched.map { f -> MailboxCheck.Item in
            let message = EmailMessage(data: f.data)
            return .init(uid: f.uid, message: message, report: Engine.analyze(message))
        }
        return MailboxCheck(
            uidValidity: status.uidValidity,
            lastUID: max(uids.max() ?? 0, lastUID ?? 0),
            items: items
        )
    }
}
