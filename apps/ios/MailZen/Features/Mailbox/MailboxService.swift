import Foundation
import Security
import SwiftData
import UserNotifications
import BackgroundTasks
import MailZenKit

/// The mailbox watched by MailZen, without its password (kept in the Keychain).
struct MailAccount: Codable, Equatable {
    var email: String
    var host: String
    var port: UInt16 = 993
    var lastUID: UInt32?
    var uidValidity: UInt32?
    var lastCheck: Date?
    var watching = true
}

/// The app-specific password, in the Keychain of this device only.
enum Keychain {
    static let service = "com.maxlestage.mailzen.imap"

    static func save(_ password: String, for account: String) {
        delete(account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(password.utf8),
            // Readable by the background check, never synchronized off the device.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func password(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
@Observable
final class MailboxService {
    static let shared = MailboxService()
    nonisolated static let refreshTaskID = "com.maxlestage.mailzen.refresh"
    nonisolated private static let accountKey = "mailAccount"

    private(set) var account: MailAccount?
    private(set) var checking = false
    var lastError: String?
    private(set) var lastFound = 0

    init() {
        account = Self.loadAccount()
    }

    var statusLine: String {
        guard let account else { return "" }
        if checking { return tr("Vérification…", "Checking…", "Comprobando…") }
        guard let last = account.lastCheck else { return tr("Jamais vérifiée", "Never checked", "Nunca comprobado") }
        return tr("Vérifiée ", "Checked ", "Comprobado ") + last.formatted(.relative(presentation: .named))
    }

    // MARK: Account

    /// Tries the address and password, analyzes the last messages, then saves the account.
    func connect(email: String, password: String, host: String, port: UInt16 = 993) async -> Bool {
        lastError = nil
        checking = true
        defer { checking = false }
        do {
            let check = try await MailboxWatcher.check(host: host, port: port, user: email, password: password, lastUID: nil, uidValidity: nil)
            var new = MailAccount(email: email, host: host, port: port)
            new.lastUID = check.lastUID
            new.uidValidity = check.uidValidity
            new.lastCheck = .now
            Keychain.save(password, for: email)
            save(new)
            Self.record(check, notify: false)
            lastFound = check.items.count
            await Self.requestNotifications()
            Self.scheduleRefresh()
            return true
        } catch {
            lastError = Self.describe(error)
            return false
        }
    }

    func disconnect() {
        if let account { Keychain.delete(account.email) }
        UserDefaults.standard.removeObject(forKey: Self.accountKey)
        account = nil
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
    }

    func setWatching(_ on: Bool) {
        guard var account else { return }
        account.watching = on
        save(account)
        if on {
            Self.scheduleRefresh()
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
        }
    }

    /// Checks the inbox now and records the new messages.
    func checkNow() async {
        guard let account, let password = Keychain.password(for: account.email) else { return }
        lastError = nil
        checking = true
        defer { checking = false }
        do {
            let check = try await MailboxWatcher.check(
                host: account.host, port: account.port, user: account.email, password: password,
                lastUID: account.lastUID, uidValidity: account.uidValidity)
            var updated = account
            updated.lastUID = check.lastUID
            updated.uidValidity = check.uidValidity
            updated.lastCheck = .now
            save(updated)
            Self.record(check, notify: true)
            lastFound = check.items.count
        } catch {
            lastError = Self.describe(error)
        }
    }

    private func save(_ new: MailAccount) {
        account = new
        if let data = try? JSONEncoder().encode(new) {
            UserDefaults.standard.set(data, forKey: Self.accountKey)
        }
    }

    nonisolated static func loadAccount() -> MailAccount? {
        guard let data = UserDefaults.standard.data(forKey: accountKey) else { return nil }
        return try? JSONDecoder().decode(MailAccount.self, from: data)
    }

    nonisolated static func describe(_ error: Error) -> String {
        if let imap = error as? IMAPError { return imap.message.localized }
        return error.localizedDescription
    }

    // MARK: Background

    /// Asks iOS to wake MailZen again in about 15 minutes.
    nonisolated static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// The background check: new messages are analyzed, the dangerous ones notified.
    nonisolated static func backgroundRefresh() async {
        guard var account = loadAccount(), account.watching,
              let password = Keychain.password(for: account.email) else { return }
        scheduleRefresh()
        guard let check = try? await MailboxWatcher.check(
            host: account.host, port: account.port, user: account.email, password: password,
            lastUID: account.lastUID, uidValidity: account.uidValidity) else { return }
        account.lastUID = check.lastUID
        account.uidValidity = check.uidValidity
        account.lastCheck = .now
        if let data = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(data, forKey: accountKey)
        }
        let saved = account
        await MainActor.run {
            record(check, notify: true)
            shared.account = saved
        }
    }

    /// Saves the analyses in the history and notifies the dangerous messages.
    @MainActor
    static func record(_ check: MailboxCheck, notify: Bool) {
        let context = Store.container.mainContext
        for item in check.items {
            let raw = item.message.analysisText
            let input = ScanInput(kind: .text, raw: raw, source: tr("Boîte mail", "Mailbox", "Buzón"))
            let record = AnalysisRecord(input: input, report: item.report)
            if let subject = item.message.subject { record.title = subject }
            context.insert(record)
            if notify && (item.report.verdict == .danger || item.report.verdict == .suspicious) {
                post(item)
            }
        }
        try? context.save()
    }

    nonisolated static func requestNotifications() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    nonisolated static func post(_ item: MailboxCheck.Item) {
        let content = UNMutableNotificationContent()
        let verdict = item.report.verdict
        content.title = (verdict == .danger ? "⛔️ " : "⚠️ ") + verdict.title.localized + " (\(item.report.score)/100)"
        let from = item.message.fromAddress ?? item.message.from ?? ""
        content.body = [from, item.message.subject ?? ""].filter { !$0.isEmpty }.joined(separator: " — ")
        content.subtitle = item.report.signals.first?.rule.title.localized ?? ""
        content.sound = .default
        let request = UNNotificationRequest(identifier: "mail-\(item.uid)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
