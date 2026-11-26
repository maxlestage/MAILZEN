import Foundation
import Observation
import MailZenKit

/// A correction given by the user: "this was a scam" or "this was legitimate". Kept on the
/// device; exported only when the user chooses to, to retrain the models (ml/train.py
/// --feedback).
struct Correction: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    /// The text that was analyzed, as the models saw it.
    var text: String
    /// 1: a scam, 0: legitimate.
    var label: Int
    /// The family of scam, when the user named it (ScamCategory raw value).
    var category: String?
    var sender: String?
    /// What MailZen said.
    var score: Int
    var verdict: String
}

/// What the user taught MailZen: trusted and blocked senders, corrections, and whether the
/// trained models take part. Everything stays on this device.
@MainActor
@Observable
final class PersonalStore {
    static let shared = PersonalStore()

    private(set) var lists = PersonalLists()
    private(set) var corrections: [Correction] = []
    private(set) var useModels: Bool

    func setUseModels(_ value: Bool) {
        useModels = value
        UserDefaults.standard.set(value, forKey: Keys.useModels)
        Engine.useModels = value
    }

    private enum Keys {
        static let lists = "personalLists"
        static let useModels = "useModels"
    }

    private var correctionsURL: URL? {
        try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("corrections.json")
    }

    private init() {
        let defaults = UserDefaults.standard
        useModels = defaults.object(forKey: Keys.useModels) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.lists), let saved = try? JSONDecoder().decode(PersonalLists.self, from: data) {
            lists = saved
        }
        if let url = correctionsURL, let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([Correction].self, from: data) {
            corrections = saved
        }
        apply()
    }

    /// Hands the settings to the engine, before any analysis.
    func apply() {
        Engine.useModels = useModels
        Engine.personal = lists
    }

    private func saveLists() {
        if let data = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(data, forKey: Keys.lists)
        }
        Engine.personal = lists
    }

    private func saveCorrections() {
        guard let url = correctionsURL, let data = try? JSONEncoder().encode(corrections) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    // MARK: Senders

    func trust(_ address: String) {
        guard let key = PersonalLists.key(of: address) else { return }
        lists.blocked.remove(key)
        lists.trusted.insert(key)
        saveLists()
    }

    func block(_ address: String) {
        guard let key = PersonalLists.key(of: address) else { return }
        lists.trusted.remove(key)
        lists.blocked.insert(key)
        saveLists()
    }

    func remove(_ key: String) {
        lists.trusted.remove(key)
        lists.blocked.remove(key)
        saveLists()
    }

    func isTrusted(_ address: String?) -> Bool {
        address.flatMap(PersonalLists.key).map { lists.trusted.contains($0) } ?? false
    }

    func isBlocked(_ address: String?) -> Bool {
        address.flatMap(PersonalLists.key).map { lists.blocked.contains($0) } ?? false
    }

    // MARK: Corrections

    func correct(text: String, scam: Bool, category: ScamCategory?, sender: String?, report: Report) {
        let trimmed = String(text.unicodeScalars.prefix(3000).map(Character.init))
        corrections.removeAll { $0.text == trimmed }
        corrections.append(Correction(text: trimmed, label: scam ? 1 : 0, category: scam ? category?.rawValue : nil,
                                      sender: sender, score: report.score, verdict: report.verdict.rawValue))
        saveCorrections()
    }

    func deleteCorrections(at offsets: IndexSet) {
        let sorted = corrections.sorted { $0.date > $1.date }
        let ids = Set(offsets.map { sorted[$0].id })
        corrections.removeAll { ids.contains($0.id) }
        saveCorrections()
    }

    func eraseCorrections() {
        corrections = []
        saveCorrections()
    }

    /// The corrections as JSON lines, the format of `train.py --feedback`.
    func exportFile() -> URL? {
        struct Line: Encodable { let text: String; let label: Int; let category: String? }
        let encoder = JSONEncoder()
        let lines = corrections.compactMap { c in
            (try? encoder.encode(Line(text: c.text, label: c.label, category: c.category))).map { String(decoding: $0, as: UTF8.self) }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mailzen-corrections.jsonl")
        do {
            try (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
