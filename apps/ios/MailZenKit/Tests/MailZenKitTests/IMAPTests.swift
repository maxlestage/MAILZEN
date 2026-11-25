import Foundation
import Testing
@testable import MailZenKit

/// A server that answers each command from a script.
actor FakeServer: IMAPTransport {
    private var pending: [Data] = [Data("* OK IMAP4rev1 ready\r\n".utf8)]
    private(set) var commands: [String] = []
    private let mailbox: [UInt32: String]

    init(mailbox: [UInt32: String]) {
        self.mailbox = mailbox
    }

    func send(_ data: Data) async throws {
        let line = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines)
        commands.append(line)
        let parts = line.split(separator: " ", maxSplits: 1)
        let tag = String(parts[0])
        let command = String(parts[1])
        var reply = ""
        if command.hasPrefix("LOGIN") {
            reply = command.contains("\"good\"") ? "\(tag) OK LOGIN completed\r\n" : "\(tag) NO [AUTHENTICATIONFAILED] Invalid credentials\r\n"
        } else if command.hasPrefix("EXAMINE") {
            reply = "* \(mailbox.count) EXISTS\r\n* OK [UIDVALIDITY 42] UIDs valid\r\n* OK [UIDNEXT 9] next\r\n\(tag) OK [READ-ONLY] done\r\n"
        } else if command.hasPrefix("UID SEARCH") {
            var uids = mailbox.keys.sorted()
            if let r = command.range(of: "UID SEARCH UID "), let from = UInt32(command[r.upperBound...].prefix { $0.isNumber }) {
                // Like real servers, `n:*` returns the last message even below n.
                uids = uids.filter { $0 >= from }
                if uids.isEmpty, let last = mailbox.keys.max() { uids = [last] }
            }
            reply = "* SEARCH \(uids.map(String.init).joined(separator: " "))\r\n\(tag) OK SEARCH done\r\n"
        } else if command.hasPrefix("UID FETCH") {
            let set = command.split(separator: " ")[2].split(separator: ",").compactMap { UInt32($0) }
            for (n, uid) in set.enumerated() {
                let body = Data(mailbox[uid]!.utf8)
                reply += "* \(n + 1) FETCH (UID \(uid) BODY[]<0> {\(body.count)}\r\n"
                reply += String(decoding: body, as: UTF8.self) + ")\r\n"
            }
            reply += "\(tag) OK FETCH done\r\n"
        } else if command.hasPrefix("LOGOUT") {
            reply = "* BYE\r\n\(tag) OK LOGOUT\r\n"
        }
        // Delivered in small pieces, as a network would.
        let bytes = Data(reply.utf8)
        stride(from: 0, to: bytes.count, by: 7).forEach { start in
            pending.append(bytes.subdata(in: start..<min(start + 7, bytes.count)))
        }
    }

    func receive() async throws -> Data {
        pending.isEmpty ? Data() : pending.removeFirst()
    }

    func close() async {}
}

@Suite struct IMAPTests {
    static let mailbox: [UInt32: String] = [
        5: "From: Bibliothèque <contact@bibliotheque.example>\r\nSubject: Ateliers\r\n\r\nLe programme des ateliers.\r\n",
        7: "From: Livraison <x@colis.example>\r\nSubject: Colis\r\n\r\nFrais de 1,99 € à régler avant ce soir : https://bit.ly/c0lis\r\n",
        8: "From: Service PayPal <service@paypaI-check.example>\r\nSubject: Urgent\r\n\r\nVotre compte sera suspendu sous 24 heures. Mot de passe : http://paypal.secure-login.account.example/x\r\n",
    ]

    @Test func theFirstCheckAnalyzesTheLastMessages() async throws {
        let server = FakeServer(mailbox: Self.mailbox)
        let check = try await MailboxWatcher.check(transport: server, user: "me@example.org", password: "good", lastUID: nil, uidValidity: nil)
        #expect(check.uidValidity == 42)
        #expect(check.lastUID == 8)
        #expect(check.items.map(\.uid) == [5, 7, 8])
        #expect(check.items.map(\.report.verdict) == [.safe, .caution, .danger])
        let commands = await server.commands
        #expect(commands.contains { $0.contains("BODY.PEEK[]") }, "messages stay unread")
    }

    @Test func laterChecksOnlyFetchNewMessages() async throws {
        let server = FakeServer(mailbox: Self.mailbox)
        let check = try await MailboxWatcher.check(transport: server, user: "me", password: "good", lastUID: 7, uidValidity: 42)
        #expect(check.items.map(\.uid) == [8])
        let none = try await MailboxWatcher.check(transport: FakeServer(mailbox: Self.mailbox), user: "me", password: "good", lastUID: 8, uidValidity: 42)
        #expect(none.items.isEmpty)
        #expect(none.lastUID == 8)
    }

    @Test func aWrongPasswordIsReported() async {
        await #expect(throws: IMAPError.rejected("[AUTHENTICATIONFAILED] Invalid credentials")) {
            try await MailboxWatcher.check(transport: FakeServer(mailbox: [:]), user: "me", password: "bad", lastUID: nil, uidValidity: nil)
        }
    }

    @Test func providersAreGuessedFromTheAddress() {
        #expect(MailProvider.guess(for: "a@icloud.com").host == "imap.mail.me.com")
        #expect(MailProvider.guess(for: "a@gmail.com").host == "imap.gmail.com")
        #expect(MailProvider.guess(for: "a@yahoo.fr").id == "yahoo")
        #expect(MailProvider.guess(for: "a@orange.fr").id == "other")
        #expect(IMAPClient.quote("a\"b\\c") == "\"a\\\"b\\\\c\"")
    }
}
