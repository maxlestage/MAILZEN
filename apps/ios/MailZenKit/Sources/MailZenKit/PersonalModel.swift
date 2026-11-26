import Foundation

// MailZen learns from its user, on the device, with no server and no computer: each
// correction ("this was a scam", "this was legitimate") retrains a small personal layer
// added to the scam model. It is trained here, in Swift, in a fraction of a second.

/// The reference messages shipped with the app (ml/train.py, anchors.json): while it
/// learns from corrections, the personal layer must keep answering the same on them, so
/// that one correction changes what resembles it and nothing else.
enum Anchors {
    static let texts: [String] = {
        guard let url = Bundle.module.url(forResource: "anchors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return texts
    }()

    static let features: [[UInt32]] = texts.map(Featurizer.features)
}

/// What MailZen learned from the corrections of its user.
public struct PersonalModel: Codable, Sendable, Hashable {
    /// A message judged by the user.
    public struct Example: Codable, Sendable, Hashable {
        public let text: String
        public let scam: Bool
        public init(text: String, scam: Bool) {
            self.text = text
            self.scam = scam
        }
    }

    /// Weights added to those of the scam model, by feature.
    public private(set) var weights: [UInt32: Float] = [:]
    /// The messages the user judged themselves: fingerprint of the text → a scam or not.
    public private(set) var memory: [String: Bool] = [:]

    public init() {}

    /// How many corrections it learned from.
    public var examples: Int { memory.count }
    public var isEmpty: Bool { memory.isEmpty }

    /// The fingerprint of a text: its first 3000 code points, lowercased, spaces collapsed.
    static func key(_ text: String) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: text.unicodeScalars.prefix(Featurizer.maxScalars))
        let words = String(view).lowercased().split(whereSeparator: \.isWhitespace)
        return SHA256.hex(Data(words.joined(separator: " ").utf8))
    }

    /// What the user said of this very message, if they judged it.
    public func verdict(of text: String) -> Bool? {
        memory.isEmpty ? nil : memory[Self.key(text)]
    }

    /// What the personal layer adds to the score of the scam model (in logits), for a
    /// message with these features. Bounded, so that it never overrides everything.
    public func adjustment(_ features: [UInt32]) -> Double {
        guard !weights.isEmpty, !features.isEmpty else { return 0 }
        var sum: Float = 0
        for f in features {
            if let w = weights[f] { sum += w }
        }
        let value = Double(sum) / Double(features.count).squareRoot()
        return min(max(value, -8), 8)
    }

    /// Learns from the corrections, from scratch (they are few): a logistic regression on
    /// top of the frozen scam model, by gradient descent. Only the features of the
    /// corrected messages can move, and the reference messages pull them back to zero
    /// wherever they would change an answer that was not corrected.
    public static func train(_ examples: [Example], models: Models? = Models.shared, epochs: Int = 60) -> PersonalModel {
        var model = PersonalModel()
        for example in examples { model.memory[key(example.text)] = example.scam }
        guard let models, !examples.isEmpty else { return model }

        // The last word of the user on a message wins.
        var latest: [String: Example] = [:]
        var order: [String] = []
        for example in examples {
            let k = key(example.text)
            if latest[k] == nil { order.append(k) }
            latest[k] = example
        }

        struct Row {
            let indices: [Int]
            let norm: Float
            let base: Float
            let target: Float
        }
        var dense: [UInt32: Int] = [:]
        var ids: [UInt32] = []
        var corrections: [Row] = []
        for k in order {
            guard let example = latest[k] else { continue }
            let features = Featurizer.features(example.text)
            guard !features.isEmpty else { continue }
            let indices = features.map { f -> Int in
                if let i = dense[f] { return i }
                dense[f] = ids.count
                ids.append(f)
                return ids.count - 1
            }
            corrections.append(Row(indices: indices, norm: 1 / Float(features.count).squareRoot(),
                                   base: Float(models.scam.logits(features)[0]), target: example.scam ? 1 : 0))
        }
        guard !corrections.isEmpty else { return model }

        // The reference messages, seen through the features that can move.
        var anchors: [Row] = []
        for features in Anchors.features where !features.isEmpty {
            let indices = features.compactMap { dense[$0] }
            guard !indices.isEmpty else { continue }
            let base = Float(models.scam.logits(features)[0])
            anchors.append(Row(indices: indices, norm: 1 / Float(features.count).squareRoot(),
                               base: base, target: 1 / (1 + exp(-base))))
        }

        func sigmoid(_ z: Float) -> Float { 1 / (1 + exp(-z)) }
        var w = [Float](repeating: 0, count: ids.count)
        let rate: Float = 1.0
        let anchorRate: Float = 2.0
        let margin: Float = 0.97
        for _ in 0..<epochs {
            var satisfied = true
            for row in corrections {
                var sum: Float = 0
                for i in row.indices { sum += w[i] }
                let p = sigmoid(row.base + sum * row.norm)
                // Beyond the margin, the correction is learned: no need to push further.
                if (row.target == 1 && p >= margin) || (row.target == 0 && p <= 1 - margin) { continue }
                satisfied = false
                let step = rate * (p - row.target) * row.norm
                for i in row.indices { w[i] -= step }
            }
            for row in anchors {
                var sum: Float = 0
                for i in row.indices { sum += w[i] }
                guard sum != 0 else { continue }
                let drift = sigmoid(row.base + sum * row.norm) - row.target
                guard abs(drift) > 0.02 else { continue }
                let step = anchorRate * drift * row.norm
                for i in row.indices { w[i] -= step }
            }
            if satisfied { break }
        }
        for (i, value) in w.enumerated() where abs(value) > 1e-4 {
            model.weights[ids[i]] = value
        }
        return model
    }
}
