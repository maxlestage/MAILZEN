import Foundation
import Testing
@testable import MailZenKit

@Suite struct MailBrowserTests {
    /// A folder of 75 messages: UIDs 1…75, the last ones dangerous.
    static let big: [UInt32: String] = Dictionary(uniqueKeysWithValues: (1...75).map { uid in
        let body = uid > 70
            ? "From: Service PayPal <service@paypaI-check.example>\r\nSubject: Urgent \(uid)\r\nDate: Thu, 26 Nov 2026 10:\(String(format: "%02d", uid % 60)):00 +0100\r\n\r\nVotre compte sera suspendu sous 24 heures. Mot de passe : http://paypal.secure-login.account.example/x\r\n"
            : "From: \"Julie Martin\" <julie@example.org>\r\nSubject: Message \(uid)\r\nDate: Wed, 25 Nov 2026 09:15:00 +0100\r\n\r\nBonjour, voici le compte rendu numéro \(uid).\r\n"
        return (UInt32(uid), body)
    })

    @Test func foldersAreListedDecodedAndOrdered() async throws {
        let folders = try await MailBrowser.folders(transport: FakeServer(mailbox: [:]), user: "me", password: "good")
        #expect(folders.map(\.kind) == [.inbox, .sent, .junk, .other, .other])
        #expect(!folders.contains { $0.name == "[Gmail]" }, "a folder that cannot be opened is left out")
        #expect(folders.contains { $0.name == "Projets/2026 " }, "a name sent as a literal")
        #expect(folders.contains { $0.displayName == "Reçus" }, "modified UTF-7 is decoded")
        #expect(folders[0].displayName == tr("Boîte de réception", "Inbox", "Bandeja de entrada"))
        #expect(IMAPFolder.decodeModifiedUTF7("Envoy&AOk-s &- archives") == "Envoyés & archives")
    }

    @Test func aFolderIsReadPageByPageFromTheNewest() async throws {
        let first = try await MailBrowser.page(transport: FakeServer(mailbox: Self.big), user: "me", password: "good", folder: "INBOX", size: 30)
        #expect(first.uids.count == 75)
        #expect(first.items.map(\.uid) == Array((46...75).reversed()))
        #expect(first.items.first?.report.verdict == .danger)
        #expect(first.items.first?.date != nil)
        #expect(first.items.last?.sender == "Julie Martin")
        // The next page reuses the UIDs: no new search.
        let server = FakeServer(mailbox: Self.big)
        let second = try await MailBrowser.page(transport: server, user: "me", password: "good", folder: "INBOX",
                                                knownUIDs: first.uids, uidValidity: first.uidValidity, before: first.items.last?.uid)
        #expect(second.items.map(\.uid) == Array((16...45).reversed()))
        let commands = await server.commands
        #expect(!commands.contains { $0.contains("UID SEARCH") })
        #expect(commands.contains { $0.contains("BODY.PEEK[]<0.\(MailBrowser.previewBytes)>") }, "only the start, and left unread")
        let last = try await MailBrowser.page(transport: FakeServer(mailbox: Self.big), user: "me", password: "good", folder: "INBOX",
                                              knownUIDs: first.uids, uidValidity: first.uidValidity, before: 16)
        #expect(last.items.map(\.uid) == Array((1...15).reversed()))
    }

    @Test func onlyNewMessagesAreFetchedOnRefresh() async throws {
        let new = try await MailBrowser.newer(transport: FakeServer(mailbox: Self.big), user: "me", password: "good", folder: "INBOX", after: 72)
        #expect(new.items.map(\.uid) == [75, 74, 73])
        let none = try await MailBrowser.newer(transport: FakeServer(mailbox: Self.big), user: "me", password: "good", folder: "INBOX", after: 75)
        #expect(none.items.isEmpty)
    }

    @Test func anEmptyFolderGivesAnEmptyPage() async throws {
        let page = try await MailBrowser.page(transport: FakeServer(mailbox: [:]), user: "me", password: "good", folder: "Junk")
        #expect(page.items.isEmpty && page.uids.isEmpty)
    }

    @Test func aWholeMessageCanBeOpened() async throws {
        let message = try await MailBrowser.message(transport: FakeServer(mailbox: Self.big), user: "me", password: "good", folder: "INBOX", uid: 74)
        #expect(message?.subject == "Urgent 74")
    }

    @Test func datesAreParsed() {
        #expect(MailSummary.parseDate("Thu, 26 Nov 2026 10:05:00 +0100") != nil)
        #expect(MailSummary.parseDate("26 Nov 2026 10:05:00 +0000 (UTC)") != nil)
        #expect(MailSummary.parseDate("n'importe quoi") == nil)
    }
}
