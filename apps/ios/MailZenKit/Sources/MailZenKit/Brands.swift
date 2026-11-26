import Foundation

/// The official domains of well-known brands and organizations, as published by
/// themselves. Only domains that are certain are listed: MailZen never invents an
/// official domain. A link to one of them is no impersonation.
public enum Brands {
    public struct Brand: Sendable, Hashable {
        public let key: String
        public let name: String
        public let domains: [String]
    }

    public static let all: [Brand] = [
        Brand(key: "paypal", name: "PayPal", domains: ["paypal.com"]),
        Brand(key: "amazon", name: "Amazon", domains: ["amazon.com", "amazon.fr", "amazon.es", "amazon.de", "amazon.co.uk"]),
        Brand(key: "apple", name: "Apple", domains: ["apple.com", "icloud.com"]),
        Brand(key: "microsoft", name: "Microsoft", domains: ["microsoft.com", "live.com", "outlook.com", "office.com"]),
        Brand(key: "google", name: "Google", domains: ["google.com", "google.fr", "google.es", "gmail.com", "youtube.com"]),
        Brand(key: "netflix", name: "Netflix", domains: ["netflix.com"]),
        Brand(key: "facebook", name: "Facebook", domains: ["facebook.com", "meta.com"]),
        Brand(key: "instagram", name: "Instagram", domains: ["instagram.com"]),
        Brand(key: "whatsapp", name: "WhatsApp", domains: ["whatsapp.com"]),
        Brand(key: "dhl", name: "DHL", domains: ["dhl.com", "dhl.de", "dhl.fr"]),
        Brand(key: "ups", name: "UPS", domains: ["ups.com"]),
        Brand(key: "fedex", name: "FedEx", domains: ["fedex.com"]),
        Brand(key: "chronopost", name: "Chronopost", domains: ["chronopost.fr"]),
        Brand(key: "colissimo", name: "Colissimo", domains: ["laposte.fr", "colissimo.fr"]),
        Brand(key: "laposte", name: "La Poste", domains: ["laposte.fr", "laposte.net"]),
        Brand(key: "correos", name: "Correos", domains: ["correos.es"]),
        Brand(key: "ameli", name: "Ameli (Assurance maladie)", domains: ["ameli.fr"]),
        Brand(key: "impots", name: "Impots.gouv.fr", domains: ["impots.gouv.fr"]),
        Brand(key: "caf", name: "CAF", domains: ["caf.fr"]),
        Brand(key: "service-public", name: "Service-Public.fr", domains: ["service-public.fr"]),
        Brand(key: "edf", name: "EDF", domains: ["edf.fr"]),
        Brand(key: "orange", name: "Orange", domains: ["orange.fr"]),
        Brand(key: "sfr", name: "SFR", domains: ["sfr.fr"]),
        Brand(key: "free", name: "Free", domains: ["free.fr"]),
        Brand(key: "hacienda", name: "Agencia Tributaria", domains: ["agenciatributaria.gob.es"]),
        Brand(key: "irs", name: "IRS", domains: ["irs.gov"]),
    ]

    /// Two-level public suffixes, so that the registrable domain of `www.impots.gouv.fr`
    /// is `impots.gouv.fr`.
    static let publicSuffixes: Set<String> = [
        "gouv.fr", "co.uk", "org.uk", "gov.uk", "ac.uk", "gob.es", "com.es", "org.es", "com.au", "co.jp", "com.br", "co.nz",
    ]

    /// Whether `host` is `domain` or one of its subdomains.
    static func host(_ host: String, isOn domain: String) -> Bool {
        let h = host.lowercased()
        return h == domain || h.hasSuffix("." + domain)
    }

    /// The brand whose official domain `host` belongs to.
    public static func official(_ host: String) -> Brand? {
        all.first { $0.domains.contains { Self.host(host, isOn: $0) } }
    }

    /// The brands named in a text or matching a search.
    public static func find(_ query: String) -> [Brand] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return all.filter { $0.key.contains(q) || $0.name.lowercased().contains(q) || q.contains($0.key) }
    }

    /// What MailZen can say about a domain or a brand name.
    public enum Check: Sendable, Equatable {
        /// An official domain of this brand.
        case official(Brand)
        /// Imitates this brand, or carries its name without being official.
        case imitation(Brand, reason: T3)
        /// A brand: its official domains.
        case brand(Brand)
        /// Nothing known: no verdict without evidence.
        case unknown
    }

    public static func check(_ input: String) -> Check {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.contains("/") || text.contains("@") {
            text = text.contains("@") ? (emailDomain(text) ?? text) : MailZenKit.host(of: text)
        }
        let lower = text.lowercased()
        guard lower.contains(".") else {
            return find(lower).first.map(Check.brand) ?? .unknown
        }
        if let brand = official(lower) { return .official(brand) }
        if let imitated = imitatesBrand(text), let brand = all.first(where: { $0.key == imitated }) {
            return .imitation(brand, reason: T3(
                "Des caractères y imitent le nom « \(brand.name) ».",
                "Some characters imitate the name “\(brand.name)”.",
                "Algunos caracteres imitan el nombre «\(brand.name)»."))
        }
        if let brand = all.first(where: { lower.contains($0.key) }) {
            return .imitation(brand, reason: T3(
                "Le nom « \(brand.name) » y figure, mais ce n’est pas l’un de ses domaines officiels.",
                "It contains the name “\(brand.name)”, but it is not one of its official domains.",
                "Contiene el nombre «\(brand.name)», pero no es uno de sus dominios oficiales."))
        }
        return .unknown
    }
}
