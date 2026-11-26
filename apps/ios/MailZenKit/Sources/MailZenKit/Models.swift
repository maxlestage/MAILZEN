import Foundation

// The trained models of MailZen (ml/train.py), run on the device. Their features are those
// of ml/features.py, reproduced here exactly: the golden tests check both agree.

/// The features of a text: hashed words, pairs of words and character trigrams.
public enum Featurizer {
    public static let dimension: UInt32 = 1 << 18
    static let maxScalars = 3000
    static let maxTokens = 400

    static func fnv1a(_ s: String) -> UInt32 {
        var h: UInt32 = 0x811C_9DC5
        for byte in s.utf8 {
            h ^= UInt32(byte)
            h = h &* 0x0100_0193
        }
        return h
    }

    static func isWord(_ s: Unicode.Scalar) -> Bool {
        switch s.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
             .decimalNumber, .letterNumber, .otherNumber:
            true
        default:
            false
        }
    }

    static func tokens(_ text: String) -> [String] {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: text.unicodeScalars.prefix(maxScalars))
        let lowered = String(view).lowercased()
        var out: [String] = []
        var current = String.UnicodeScalarView()
        for scalar in lowered.unicodeScalars {
            if isWord(scalar) {
                current.append((48...57).contains(scalar.value) ? "0" : scalar)
            } else if !current.isEmpty {
                out.append(String(current))
                current = String.UnicodeScalarView()
            }
        }
        if !current.isEmpty { out.append(String(current)) }
        return Array(out.prefix(maxTokens))
    }

    /// The sorted, unique feature indices of a text.
    public static func features(_ text: String) -> [UInt32] {
        let toks = tokens(text)
        var set = Set<UInt32>()
        for (i, t) in toks.enumerated() {
            set.insert(fnv1a("w:" + t) % dimension)
            if i + 1 < toks.count {
                set.insert(fnv1a("b:" + t + " " + toks[i + 1]) % dimension)
            }
            let scalars = Array(t.unicodeScalars)
            if scalars.count >= 4 {
                let framed: [Unicode.Scalar] = ["<"] + scalars + [">"]
                for j in 0..<(framed.count - 2) {
                    var tri = String.UnicodeScalarView()
                    tri.append(contentsOf: framed[j..<(j + 3)])
                    set.insert(fnv1a("c:" + String(tri)) % dimension)
                }
            }
        }
        return set.sorted()
    }
}

/// The features of a link (ml/url_features.py, reproduced exactly).
public enum URLFeaturizer {
    static let maxScalars = 300

    static func scalars(_ s: String) -> [Unicode.Scalar] { Array(s.unicodeScalars) }

    /// Trimmed, `&amp;` decoded, lowercased, cut, without scheme, leading `www.` and
    /// trailing slashes.
    static func normalize(_ url: String) -> String {
        let lowered = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&").lowercased()
        var view = String.UnicodeScalarView()
        view.append(contentsOf: lowered.unicodeScalars.prefix(maxScalars))
        var u = String(view)
        for scheme in ["https://", "http://"] where u.hasPrefix(scheme) {
            u = String(u.unicodeScalars.dropFirst(scheme.unicodeScalars.count))
            break
        }
        if u.hasPrefix("www.") { u = String(u.unicodeScalars.dropFirst(4)) }
        while u.unicodeScalars.last == "/" { u = String(u.unicodeScalars.dropLast()) }
        return u
    }

    static func split(_ u: String) -> (host: String, rest: String, at: Bool, port: Bool) {
        let s = scalars(u)
        let end = s.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? s.count
        var host = Array(s[0..<end])
        let rest = String(String.UnicodeScalarView(s[end...]))
        let at = host.contains("@")
        if at, let i = host.lastIndex(of: "@") { host = Array(host[(i + 1)...]) }
        let port = host.contains(":")
        if port, let i = host.firstIndex(of: ":") { host = Array(host[..<i]) }
        return (String(String.UnicodeScalarView(host)), rest, at, port)
    }

    static func string(_ s: ArraySlice<Unicode.Scalar>) -> String { String(String.UnicodeScalarView(s)) }

    /// The sorted, unique feature indices of a link.
    public static func features(_ url: String) -> [UInt32] {
        let u = normalize(url)
        guard !u.isEmpty else { return [] }
        let (host, rest, at, port) = split(u)
        var names: [String] = []
        let framed = scalars("^" + host + "$")
        for n in 3...5 where framed.count >= n {
            for j in 0...(framed.count - n) { names.append("h\(n):" + string(framed[j..<(j + n)])) }
        }
        let labels = host.split(separator: ".", omittingEmptySubsequences: true).map(String.init)
        for l in labels { names.append("hl:" + l) }
        if let last = labels.last {
            names.append("tld:" + last)
            names.append("rd:" + labels.suffix(2).joined(separator: "."))
        }
        let restScalars = scalars(rest)
        let head = Array(restScalars.prefix(120))
        for n in 3...4 where head.count >= n {
            for j in 0...(head.count - n) { names.append("p\(n):" + string(head[j..<(j + n)])) }
        }
        var tokens: [String] = []
        var current = String.UnicodeScalarView()
        for scalar in restScalars {
            if Featurizer.isWord(scalar) {
                current.append((48...57).contains(scalar.value) ? "0" : scalar)
            } else if !current.isEmpty {
                tokens.append(String(current))
                current = String.UnicodeScalarView()
            }
        }
        if !current.isEmpty { tokens.append(String(current)) }
        for t in tokens.prefix(40) { names.append("pt:" + t) }
        let hostScalars = scalars(host)
        names.append("hlen:\(min(hostScalars.count / 4, 15))")
        names.append("dots:\(min(hostScalars.filter { $0 == "." }.count, 8))")
        names.append("hyph:\(min(hostScalars.filter { $0 == "-" }.count, 5))")
        if hostScalars.contains(where: { (48...57).contains($0.value) }) { names.append("hdig") }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 4, parts.allSatisfy({ p in !p.isEmpty && p.unicodeScalars.allSatisfy { (48...57).contains($0.value) } && (Int(p) ?? 999) < 256 }) {
            names.append("ip")
        }
        if at { names.append("at") }
        if port { names.append("port") }
        let length = restScalars.count
        names.append("plen:\(length == 0 ? 0 : Int.bitWidth - length.leadingZeroBitCount)")
        if restScalars.contains("?") { names.append("q") }
        var path = restScalars
        for c: Unicode.Scalar in ["?", "#"] {
            if let i = path.firstIndex(of: c) { path = Array(path[..<i]) }
        }
        let segments = string(path[...]).split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        names.append("nseg:\(min(segments.count, 8))")
        if let last = segments.last, last.contains(".") {
            let ext = last.split(separator: ".", omittingEmptySubsequences: false).last.map(String.init) ?? ""
            let n = ext.unicodeScalars.count
            if n > 0 && n <= 5 && ext.unicodeScalars.allSatisfy({ ("a"..."z").contains($0) || ("A"..."Z").contains($0) || ("0"..."9").contains($0) }) {
                names.append("ext:" + ext)
            }
        }
        return Set(names.map { Featurizer.fnv1a($0) % Featurizer.dimension }).sorted()
    }
}

/// A linear model with 8-bit weights (a `.mzm` file).
public struct LinearModel: Sendable {
    public let classes: [String]
    let scale: Double
    let bias: [Double]
    /// The feature indices that have weights, sorted.
    let indices: [UInt32]
    /// `classes.count` weights per index.
    let weights: [Int8]

    public init?(data: Data) {
        let bytes = [UInt8](data)
        var offset = 0
        func read<T: FixedWidthInteger>(_: T.Type) -> T? {
            let size = MemoryLayout<T>.size
            guard offset + size <= bytes.count else { return nil }
            var value: T = 0
            for i in 0..<size { value |= T(bytes[offset + i]) << (8 * i) }
            offset += size
            return value
        }
        func float() -> Double? { read(UInt32.self).map { Double(Float(bitPattern: $0)) } }
        guard bytes.count > 4, Array(bytes[0..<4]) == Array("MZM1".utf8) else { return nil }
        offset = 4
        guard let dim = read(UInt32.self), dim == Featurizer.dimension,
              let k = read(UInt16.self), k > 0,
              let nameLength = read(UInt32.self), offset + Int(nameLength) <= bytes.count else { return nil }
        classes = String(decoding: bytes[offset..<(offset + Int(nameLength))], as: UTF8.self).components(separatedBy: "\n")
        offset += Int(nameLength)
        guard classes.count == Int(k), let s = float() else { return nil }
        scale = s
        var b: [Double] = []
        for _ in 0..<k {
            guard let v = float() else { return nil }
            b.append(v)
        }
        bias = b
        guard let n = read(UInt32.self), offset + Int(n) * (4 + Int(k)) <= bytes.count else { return nil }
        var idx: [UInt32] = []
        var w: [Int8] = []
        idx.reserveCapacity(Int(n))
        w.reserveCapacity(Int(n) * Int(k))
        for _ in 0..<n {
            guard let i = read(UInt32.self) else { return nil }
            idx.append(i)
            for c in 0..<Int(k) { w.append(Int8(bitPattern: bytes[offset + c])) }
            offset += Int(k)
        }
        indices = idx
        weights = w
    }

    /// The raw scores of each class.
    func logits(_ features: [UInt32]) -> [Double] {
        let k = classes.count
        var sums = [Int](repeating: 0, count: k)
        for f in features {
            var lo = 0, hi = indices.count - 1
            while lo <= hi {
                let mid = (lo + hi) / 2
                if indices[mid] == f {
                    for c in 0..<k { sums[c] += Int(weights[mid * k + c]) }
                    break
                } else if indices[mid] < f {
                    lo = mid + 1
                } else {
                    hi = mid - 1
                }
            }
        }
        let norm = features.isEmpty ? 0 : 1 / Double(features.count).squareRoot()
        return (0..<k).map { bias[$0] + scale * Double(sums[$0]) * norm }
    }

    /// The share of these features the model has weights for: low for words it never saw.
    public func coverage(_ features: [UInt32]) -> Double {
        guard !features.isEmpty else { return 0 }
        var known = 0
        for f in features {
            var lo = 0, hi = indices.count - 1
            while lo <= hi {
                let mid = (lo + hi) / 2
                if indices[mid] == f { known += 1; break }
                if indices[mid] < f { lo = mid + 1 } else { hi = mid - 1 }
            }
        }
        return Double(known) / Double(features.count)
    }

    /// The probabilities: one (logistic) for a binary model, a distribution otherwise.
    public func probabilities(_ text: String) -> [Double] {
        probabilities(features: Featurizer.features(text))
    }

    public func probabilities(features: [UInt32]) -> [Double] {
        let z = logits(features)
        if z.count == 1 { return [1 / (1 + exp(-z[0]))] }
        let m = z.max() ?? 0
        let e = z.map { exp($0 - m) }
        let total = e.reduce(0, +)
        return e.map { $0 / total }
    }

    /// The most likely class and its probability.
    public func best(_ text: String) -> (label: String, probability: Double) {
        let p = probabilities(text)
        let i = p.indices.max { p[$0] < p[$1] } ?? 0
        return (classes[i], p[i])
    }
}

/// What the training measured, as written by ml/train.py (models.json).
public struct ModelManifest: Codable, Sendable, Hashable {
    public struct Scam: Codable, Sendable, Hashable {
        public let accuracy: Double, auc: Double, falsePositives09: Double, recall09: Double
        public let messages: Int, weights: Int
    }
    public struct Category: Codable, Sendable, Hashable { public let accuracy: Double, families: Int, weights: Int }
    public struct Intent: Codable, Sendable, Hashable { public let accuracy: Double, intents: Int, weights: Int }
    public struct Link: Codable, Sendable, Hashable {
        public let auc: Double, falsePositives095: Double, recall095: Double
        public let links: Int, weights: Int
    }
    public let version: String
    public let scam: Scam
    public let category: Category
    public let intent: Intent
    public let url: Link
    public let feedback: Int
}

/// The four models of MailZen, loaded once from the package's resources.
public final class Models: Sendable {
    public let scam: LinearModel
    public let categories: LinearModel
    public let intents: LinearModel
    public let links: LinearModel
    public let manifest: ModelManifest?

    public static let shared: Models? = Models()

    init?() {
        func load(_ name: String) -> LinearModel? {
            guard let url = Bundle.module.url(forResource: name, withExtension: "mzm") ?? Bundle.module.url(forResource: name, withExtension: "mzm", subdirectory: "Resources"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return LinearModel(data: data)
        }
        guard let s = load("scam"), let c = load("category"), let i = load("intent"), let u = load("url") else { return nil }
        scam = s
        categories = c
        intents = i
        links = u
        manifest = (Bundle.module.url(forResource: "models", withExtension: "json"))
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(ModelManifest.self, from: $0) }
    }

    /// The probability that a link leads to phishing.
    public func linkProbability(_ url: String) -> Double { links.probabilities(features: URLFeaturizer.features(url))[0] }

    /// The probability that a message is a scam, a phishing or a spam.
    public func scamProbability(_ text: String) -> Double { scam.probabilities(text)[0] }

    /// The family of scam a message looks like.
    public func category(_ text: String) -> (label: String, probability: Double) { categories.best(text) }

    /// What is asked to ZenAI.
    public func intent(_ text: String) -> (label: String, probability: Double) { intents.best(text) }
}

/// The families of scam the category model knows.
public enum ScamCategory: String, CaseIterable, Sendable {
    case bank, delivery, government, business, investment, romance, blackmail
    case techSupport = "tech_support"
    case prize, account

    public var label: T3 {
        switch self {
        case .bank: T3("fausse alerte bancaire", "fake bank alert", "falsa alerta bancaria")
        case .delivery: T3("faux colis", "fake parcel", "paquete falso")
        case .government: T3("fausse administration (impôts, santé, amende)", "fake government notice (tax, health, fine)", "falsa administración (impuestos, salud, multa)")
        case .business: T3("fraude au président, faux fournisseur ou faux emploi", "CEO fraud, fake supplier or fake job", "fraude del CEO, falso proveedor o falso empleo")
        case .investment: T3("faux investissement ou crypto", "fake investment or crypto", "falsa inversión o cripto")
        case .romance: T3("arnaque sentimentale", "romance scam", "estafa romántica")
        case .blackmail: T3("chantage ou sextorsion", "blackmail or sextortion", "chantaje o sextorsión")
        case .techSupport: T3("faux support technique", "fake tech support", "falso soporte técnico")
        case .prize: T3("faux gain ou cadeau", "fake prize or gift", "falso premio o regalo")
        case .account: T3("faux message de compte (suspension, paiement, mot de passe)", "fake account notice (suspension, payment, password)", "falso aviso de cuenta (suspensión, pago, contraseña)")
        }
    }

    /// The SOS Cyber scenario that matches the usual next step of this scam.
    public var advice: T3 {
        switch self {
        case .bank: T3("Votre banque ne vous demandera jamais un code ou vos identifiants : appelez le numéro au dos de votre carte.", "Your bank will never ask for a code or your login: call the number on the back of your card.", "Tu banco nunca te pedirá un código ni tus claves: llama al número del dorso de tu tarjeta.")
        case .delivery: T3("Les transporteurs ne réclament pas de frais par SMS : suivez le colis sur le site officiel, avec le numéro donné par le vendeur.", "Carriers do not ask for fees by text: track the parcel on the official site, with the number from the seller.", "Las empresas de transporte no piden tasas por SMS: sigue el paquete en la web oficial con el número del vendedor.")
        case .government: T3("Les administrations vous écrivent dans votre espace personnel officiel : connectez-vous vous-même pour vérifier.", "Government services write to you in your official personal space: sign in yourself to check.", "Las administraciones te escriben en tu área personal oficial: entra tú mismo para comprobarlo.")
        case .business: T3("Vérifiez toujours un changement de RIB ou un virement urgent par téléphone, au numéro habituel.", "Always check a change of bank details or an urgent transfer by phone, at the usual number.", "Verifica siempre un cambio de cuenta o una transferencia urgente por teléfono, al número habitual.")
        case .investment: T3("Aucun placement ne garantit un rendement élevé sans risque. Ne payez jamais de « frais de déblocage ».", "No investment guarantees high returns without risk. Never pay “unlocking fees”.", "Ninguna inversión garantiza alta rentabilidad sin riesgo. Nunca pagues «comisiones de desbloqueo».")
        case .romance: T3("N’envoyez jamais d’argent à quelqu’un que vous n’avez jamais rencontré, quelle que soit l’histoire.", "Never send money to someone you have never met, whatever the story.", "Nunca envíes dinero a alguien que no conoces en persona, sea cual sea la historia.")
        case .blackmail: T3("Ne payez pas et ne répondez pas : ces messages sont envoyés en masse, sans vidéo réelle. Changez le mot de passe cité.", "Do not pay or reply: these messages are sent in bulk, without any real video. Change the password mentioned.", "No pagues ni respondas: estos mensajes se envían en masa, sin vídeo real. Cambia la contraseña citada.")
        case .techSupport: T3("Microsoft, Apple ou Google n’appellent jamais spontanément. N’installez rien et ne donnez pas l’accès à votre appareil.", "Microsoft, Apple or Google never call out of the blue. Install nothing and do not give access to your device.", "Microsoft, Apple o Google nunca llaman por iniciativa propia. No instales nada ni des acceso a tu dispositivo.")
        case .prize: T3("On ne gagne pas à un jeu auquel on n’a pas joué : ne payez aucun frais d’envoi.", "You cannot win a game you did not play: pay no shipping fees.", "No se gana un juego al que no has jugado: no pagues gastos de envío.")
        case .account: T3("Ouvrez l’application officielle du service pour vérifier votre compte, jamais le lien du message.", "Open the service’s official app to check your account, never the link in the message.", "Abre la app oficial del servicio para comprobar tu cuenta, nunca el enlace del mensaje.")
        }
    }
}

/// What the models say about a message.
public struct ModelInsight: Hashable, Sendable {
    /// The probability that it is a scam.
    public let probability: Double
    /// The family it looks like, when the models think it is a scam.
    public let category: ScamCategory?
    public let categoryProbability: Double
    /// What the user's corrections added to the model's score (in logits; 0 when nothing
    /// was learned that concerns this message).
    public var personal: Double = 0
}
