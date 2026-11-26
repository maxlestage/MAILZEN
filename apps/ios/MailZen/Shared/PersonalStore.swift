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
    /// Whether the trained model may decide the verdict by itself when it is sure.
    private(set) var autonomous: Bool
    /// What MailZen learned from the corrections, on this device.
    private(set) var learned = PersonalModel()
    /// A training is running.
    private(set) var learning = false

    func setUseModels(_ value: Bool) {
        useModels = value
        defaults.set(value, forKey: Keys.useModels)
        Engine.useModels = value
    }

    func setAutonomous(_ value: Bool) {
        autonomous = value
        defaults.set(value, forKey: Keys.autonomous)
        Engine.autonomous = value
    }

    private enum Keys {
        static let lists = "personalLists"
        static let useModels = "useModels"
        static let autonomous = "autonomousModel"
    }

    /// The App Group shared by the app and the share extension: what is learned in one is
    /// known by the other. Without it (a build without entitlements), each keeps its own.
    static let appGroup = "group.com.maxlestage.mailzen"
    private let defaults = UserDefaults(suiteName: PersonalStore.appGroup) ?? .standard

    private func file(_ name: String) -> URL? {
        if let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup) {
            return shared.appendingPathComponent(name)
        }
        return try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(name)
    }

    private var correctionsURL: URL? { file("corrections.json") }
    private var learnedURL: URL? { file("personal-model.json") }

    private init() {
        useModels = true
        autonomous = true
        reload()
    }

    /// Reads what the app or the share extension saved last.
    func reload() {
        useModels = defaults.object(forKey: Keys.useModels) as? Bool ?? true
        autonomous = defaults.object(forKey: Keys.autonomous) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.lists), let saved = try? JSONDecoder().decode(PersonalLists.self, from: data) {
            lists = saved
        }
        if let url = correctionsURL, let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([Correction].self, from: data) {
            corrections = saved
        }
        if let url = learnedURL, let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(PersonalModel.self, from: data) {
            learned = saved
        }
        apply()
        // Corrections without their training (an update, a missing file): learn them now.
        if Set(corrections.map(\.text)).count != learned.examples { relearn() }
    }

    /// Hands the settings to the engine, before any analysis.
    func apply() {
        Engine.useModels = useModels
        Engine.autonomous = autonomous
        Engine.personal = lists
        Engine.learned = learned
    }

    /// Retrains the personal layer from every correction, on the device, in the
    /// background: a fraction of a second. No server, no computer.
    private func relearn() {
        let examples = corrections.sorted { $0.date < $1.date }.map { PersonalModel.Example(text: $0.text, scam: $0.label == 1) }
        learning = true
        Task.detached(priority: .userInitiated) {
            let model = PersonalModel.train(examples)
            await MainActor.run {
                self.learned = model
                Engine.learned = model
                self.learning = false
                if let url = self.learnedURL, let data = try? JSONEncoder().encode(model) {
                    try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                }
            }
        }
    }

    private func saveLists() {
        if let data = try? JSONEncoder().encode(lists) {
            defaults.set(data, forKey: Keys.lists)
        }
        Engine.personal = lists
    }

    private func saveCorrections() {
        guard let url = correctionsURL, let data = try? JSONEncoder().encode(corrections) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
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
        relearn()
    }

    func deleteCorrections(at offsets: IndexSet) {
        let sorted = corrections.sorted { $0.date > $1.date }
        let ids = Set(offsets.map { sorted[$0].id })
        corrections.removeAll { ids.contains($0.id) }
        saveCorrections()
        relearn()
    }

    func eraseCorrections() {
        corrections = []
        saveCorrections()
        relearn()
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
