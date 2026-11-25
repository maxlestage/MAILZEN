import Foundation

/// The languages of MailZen: French, English and Spanish.
public enum AppLanguage: String, CaseIterable, Sendable {
    case fr, en, es

    /// The language of the device among the three, English otherwise.
    public static var current: AppLanguage {
        for tag in Locale.preferredLanguages {
            if let lang = AppLanguage(rawValue: String(tag.prefix(2)).lowercased()) {
                return lang
            }
        }
        return .en
    }
}

/// A text in the three languages: forgetting a translation does not compile.
public struct T3: Hashable, Sendable {
    public let fr: String
    public let en: String
    public let es: String

    public init(_ fr: String, _ en: String, _ es: String) {
        self.fr = fr
        self.en = en
        self.es = es
    }

    /// The text in `language`.
    public func text(_ language: AppLanguage) -> String {
        switch language {
        case .fr: fr
        case .en: en
        case .es: es
        }
    }

    /// The text in the language of the device.
    public var localized: String { text(.current) }
}

/// A text in the language of the device: `tr("Bonjour", "Hello", "Hola")`.
public func tr(_ fr: String, _ en: String, _ es: String) -> String {
    T3(fr, en, es).localized
}
