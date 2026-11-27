import Foundation
import Security
import SwiftData
import UserNotifications
import BackgroundTasks
import MailZenKit

/// The mailbox watched by MailZen, without its password (kept in the Keychain).
struct MailAccount: Codable, Equatable, Hashable, Identifiable {
    var id: String { email }
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
    nonisolated private static let accountsKey = "mailAccounts"
    nonisolated private static let legacyAccountKey = "mailAccount"

    /// Every connected mailbox.
    private(set) var accounts: [MailAccount] = []
    private(set) var checking = false
    var lastError: String?
    private(set) var lastFound = 0

    /// The first mailbox (for the summaries of the home screen).
    var account: MailAccount? { accounts.first }

    init() {
        accounts = Self.loadAccounts()
    }

    var statusLine: String {
        if checking { return tr("Vérification…", "Checking…", "Comprobando…") }
        guard let last = accounts.compactMap(\.lastCheck).max() else {
            return accounts.isEmpty ? "" : tr("Jamais vérifiée", "Never checked", "Nunca comprobado")
        }
        return tr("Vérifiée ", "Checked ", "Comprobado ") + last.formatted(.relative(presentation: .named))
    }

    func status(of account: MailAccount) -> String {
        guard let last = account.lastCheck else { return tr("Jamais vérifiée", "Never checked", "Nunca comprobado") }
        return tr("Vérifiée ", "Checked ", "Comprobado ") + last.formatted(.relative(presentation: .named))
    }

    // MARK: Accounts

    /// Tries the address and password, analyzes the last messages, then adds the mailbox.
    func connect(email: String, password: String, host: String, port: UInt16 = 993) async -> Bool {
        let provider = MailProvider.all.first { $0.host == host } ?? MailProvider.guess(for: email)
        let password = provider.normalizedPassword(password)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
            update(new)
            Self.record(check, notify: false)
            lastFound = check.items.count
            await Self.requestNotifications()
            Self.scheduleRefresh()
            return true
        } catch {
            lastError = Self.describe(error, provider: provider)
            return false
        }
    }

    func disconnect(_ account: MailAccount) {
        Keychain.delete(account.email)
        accounts.removeAll { $0.email == account.email }
        persist()
        if !accounts.contains(where: \.watching) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
        }
    }

    func setWatching(_ account: MailAccount, _ on: Bool) {
        var changed = account
        changed.watching = on
        update(changed)
        if on {
            Self.scheduleRefresh()
        } else if !accounts.contains(where: \.watching) {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
        }
    }

    func password(for account: MailAccount) -> String? { Keychain.password(for: account.email) }

    /// Checks the inbox of every watched mailbox now and records the new messages.
    func checkNow() async {
        guard !checking else { return }
        lastError = nil
        checking = true
        defer { checking = false }
        var found = 0
        for account in accounts where account.watching {
            guard let password = Keychain.password(for: account.email) else { continue }
            do {
                let check = try await MailboxWatcher.check(
                    host: account.host, port: account.port, user: account.email, password: password,
                    lastUID: account.lastUID, uidValidity: account.uidValidity)
                var updated = account
                updated.lastUID = check.lastUID
                updated.uidValidity = check.uidValidity
                updated.lastCheck = .now
                update(updated)
                Self.record(check, notify: true)
                found += check.items.count
            } catch {
                lastError = account.email + " : " + Self.describe(error, provider: MailProvider.all.first { $0.host == account.host })
            }
        }
        lastFound = found
    }

    private func update(_ account: MailAccount) {
        if let i = accounts.firstIndex(where: { $0.email == account.email }) {
            accounts[i] = account
        } else {
            accounts.append(account)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: Self.accountsKey)
        }
    }

    nonisolated static func loadAccounts() -> [MailAccount] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: accountsKey), let saved = try? JSONDecoder().decode([MailAccount].self, from: data) {
            return saved
        }
        // The single mailbox of earlier versions.
        if let data = defaults.data(forKey: legacyAccountKey), let old = try? JSONDecoder().decode(MailAccount.self, from: data) {
            if let encoded = try? JSONEncoder().encode([old]) { defaults.set(encoded, forKey: accountsKey) }
            defaults.removeObject(forKey: legacyAccountKey)
            return [old]
        }
        return []
    }

    nonisolated static func describe(_ error: Error, provider: MailProvider? = nil) -> String {
        if let imap = error as? IMAPError {
            if imap.isAuthenticationFailure { return (provider ?? MailProvider.all[3]).authenticationHelp.localized }
            return imap.message.localized
        }
        return error.localizedDescription
    }

    // MARK: Background

    /// Asks iOS to wake MailZen again in about 15 minutes.
    nonisolated static func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// The background check of every watched mailbox: new messages are analyzed, the
    /// dangerous ones notified.
    nonisolated static func backgroundRefresh() async {
        var accounts = loadAccounts()
        guard accounts.contains(where: \.watching) else { return }
        scheduleRefresh()
        var checks: [MailboxCheck] = []
        for (i, account) in accounts.enumerated() where account.watching {
            guard let password = Keychain.password(for: account.email),
                  let check = try? await MailboxWatcher.check(
                    host: account.host, port: account.port, user: account.email, password: password,
                    lastUID: account.lastUID, uidValidity: account.uidValidity) else { continue }
            accounts[i].lastUID = check.lastUID
            accounts[i].uidValidity = check.uidValidity
            accounts[i].lastCheck = .now
            checks.append(check)
        }
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
        let saved = accounts
        let found = checks
        await MainActor.run {
            for check in found { record(check, notify: true) }
            shared.accounts = saved
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
        let request = UNNotificationRequest(identifier: "mail-\(item.uid)-\(item.message.messageID ?? item.message.subject ?? "")", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
