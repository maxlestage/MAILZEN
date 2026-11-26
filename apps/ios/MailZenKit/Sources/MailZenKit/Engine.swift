import Foundation

// A deterministic analysis engine, independent of any AI: rules on the sender, the
// links, the attachments and the manipulation techniques of a message. The same rules
// as the demo of the website (src/engine.rs), plus the authentication results (SPF,
// DKIM, DMARC) and the reply address of real emails.

/// The four verdicts of a report.
public enum Verdict: String, CaseIterable, Codable, Sendable {
    case safe, caution, suspicious, danger

    public static func of(score: Int) -> Verdict {
        switch score {
        case ..<20: .safe
        case ..<45: .caution
        case ..<70: .suspicious
        default: .danger
        }
    }

    public var title: T3 {
        switch self {
        case .safe: T3("Aucun risque notable détecté", "No notable risk detected", "Ningún riesgo notable detectado")
        case .caution: T3("Vigilance", "Caution", "Precaución")
        case .suspicious: T3("Suspect", "Suspicious", "Sospechoso")
        case .danger: T3("Danger élevé", "High danger", "Peligro elevado")
        }
    }

    public var summary: T3 {
        switch self {
        case .safe: T3(
            "Les contrôles n’ont pas relevé de signal important. Cela ne garantit pas l’innocuité.",
            "The checks found no significant signal. This does not guarantee it is harmless.",
            "Los controles no detectaron señales importantes. Eso no garantiza que sea inofensivo.")
        case .caution: T3(
            "Quelques anomalies ou éléments à vérifier.",
            "A few anomalies or things to check.",
            "Algunas anomalías o elementos que verificar.")
        case .suspicious: T3(
            "Plusieurs indicateurs inquiétants.",
            "Several worrying indicators.",
            "Varios indicadores preocupantes.")
        case .danger: T3(
            "Des éléments sérieux indiquent un risque de fraude ou d’attaque.",
            "Serious elements point to a risk of fraud or attack.",
            "Elementos serios indican un riesgo de fraude o ataque.")
        }
    }

    public var advice: T3 {
        switch self {
        case .safe: T3(
            "Les contrôles effectués n’ont pas relevé de signal important. Restez attentif aux demandes inhabituelles.",
            "The checks found no significant signal. Stay alert to unusual requests.",
            "Los controles no han encontrado ninguna señal importante. Mantente atento a las peticiones inusuales.")
        case .caution: T3(
            "Avant d’agir, contactez l’expéditeur par un canal officiel que vous connaissez.",
            "Before acting, contact the sender through an official channel you already know.",
            "Antes de actuar, contacta con el remitente por un canal oficial que ya conozcas.")
        case .suspicious: T3(
            "Ne cliquez sur aucun lien, n’ouvrez aucune pièce jointe et vérifiez directement auprès du service concerné.",
            "Do not click any link, do not open any attachment, and check directly with the service concerned.",
            "No hagas clic en ningún enlace, no abras ningún adjunto y verifica directamente con el servicio afectado.")
        case .danger: T3(
            "Ne cliquez pas, ne répondez pas, ne payez rien. Passez par l’application officielle du service, puis signalez le message.",
            "Do not click, do not reply, do not pay. Go through the service’s official app, then report the message.",
            "No hagas clic, no respondas, no pagues nada. Usa la app oficial del servicio y denuncia el mensaje.")
        }
    }
}

/// The families of signals.
public enum Family: String, CaseIterable, Sendable {
    case sender, link, file, behavior, identity, technical, model

    public var label: T3 {
        switch self {
        case .sender: T3("Expéditeur", "Sender", "Remitente")
        case .link: T3("URL", "URL", "URL")
        case .file: T3("Fichier", "File", "Archivo")
        case .behavior: T3("Comportement", "Behavior", "Comportamiento")
        case .identity: T3("Identité", "Identity", "Identidad")
        case .technical: T3("Technique", "Technical", "Técnica")
        case .model: T3("Modèle entraîné", "Trained model", "Modelo entrenado")
        }
    }
}

/// What a rule found.
public enum Rule: String, CaseIterable, Codable, Sendable {
    case urgency, threat, sensitiveData, money, secrecy, reward, authority
    case lookalike, brandMismatch, freeMailer, replyToMismatch, authFailure
    case shortLink, ipLink, plainHttp, oddTld, deepSubdomains, loginWords
    case riskyFile, doubleExtension, macro, qrCode
    case typeMismatch, executable, scriptInDocument, autoAction, embeddedFile, officeMacros
    case externalContent, passwordForm, metaRefresh, archiveRisk, encryptedArchive, zipBomb, formulaInjection
    case modelScam, modelLink, blockedSender, userReported

    public var family: Family {
        switch self {
        case .urgency, .threat, .sensitiveData, .money, .secrecy, .reward, .qrCode: .behavior
        case .authority, .brandMismatch: .identity
        case .lookalike, .freeMailer, .replyToMismatch: .sender
        case .authFailure: .technical
        case .shortLink, .ipLink, .plainHttp, .oddTld, .deepSubdomains, .loginWords: .link
        case .riskyFile, .doubleExtension, .macro: .file
        case .typeMismatch, .executable, .scriptInDocument, .autoAction, .embeddedFile, .officeMacros,
             .externalContent, .passwordForm, .metaRefresh, .archiveRisk, .encryptedArchive, .zipBomb, .formulaInjection: .file
        case .modelScam, .modelLink: .model
        case .blockedSender: .sender
        case .userReported: .model
        }
    }

    public var weight: Int {
        switch self {
        case .urgency: 14
        case .threat: 14
        case .sensitiveData: 20
        case .money: 12
        case .secrecy: 14
        case .reward: 12
        case .authority: 6
        case .lookalike: 28
        case .brandMismatch: 22
        case .freeMailer: 10
        case .replyToMismatch: 16
        case .authFailure: 24
        case .shortLink: 14
        case .ipLink: 22
        case .plainHttp: 8
        case .oddTld: 8
        case .deepSubdomains: 10
        case .loginWords: 8
        case .riskyFile: 22
        case .doubleExtension: 30
        case .macro: 18
        case .qrCode: 8
        case .typeMismatch: 34
        case .executable: 40
        case .scriptInDocument: 26
        case .autoAction: 26
        case .embeddedFile: 18
        case .officeMacros: 30
        case .externalContent: 12
        case .passwordForm: 30
        case .metaRefresh: 16
        case .archiveRisk: 30
        case .encryptedArchive: 18
        case .zipBomb: 40
        case .formulaInjection: 26
        case .modelScam: 16
        case .modelLink: 14
        case .blockedSender: 45
        case .userReported: 70
        }
    }

    /// A manipulation technique, shown apart from the technical signals.
    public var isManipulation: Bool {
        switch self {
        case .urgency, .threat, .sensitiveData, .money, .secrecy, .reward, .authority: true
        default: false
        }
    }

    public var title: T3 {
        switch self {
        case .urgency: T3("Pression temporelle", "Time pressure", "Presión de tiempo")
        case .threat: T3("Menace", "Threat", "Amenaza")
        case .sensitiveData: T3("Demande d’informations sensibles", "Request for sensitive information", "Petición de datos sensibles")
        case .money: T3("Demande de paiement", "Payment request", "Petición de pago")
        case .secrecy: T3("Secret exigé", "Secrecy demanded", "Se exige secreto")
        case .reward: T3("Récompense promise", "Promised reward", "Recompensa prometida")
        case .authority: T3("Autorité invoquée", "Authority invoked", "Autoridad invocada")
        case .lookalike: T3("Domaine ressemblant", "Lookalike domain", "Dominio parecido")
        case .brandMismatch: T3("Marque citée, domaine différent", "Brand named, different domain", "Marca citada, dominio distinto")
        case .freeMailer: T3("Messagerie gratuite", "Free mailbox", "Correo gratuito")
        case .replyToMismatch: T3("Adresse de réponse différente", "Different reply address", "Dirección de respuesta distinta")
        case .authFailure: T3("Authentification en échec", "Authentication failed", "Autenticación fallida")
        case .shortLink: T3("Lien raccourci", "Shortened link", "Enlace acortado")
        case .ipLink: T3("Lien vers une adresse IP", "Link to an IP address", "Enlace a una dirección IP")
        case .plainHttp: T3("Lien non chiffré", "Unencrypted link", "Enlace sin cifrar")
        case .oddTld: T3("Extension de domaine inhabituelle", "Unusual domain extension", "Extensión de dominio inusual")
        case .deepSubdomains: T3("Sous-domaines en cascade", "Cascading subdomains", "Subdominios en cascada")
        case .loginWords: T3("Motif de vérification de compte", "Account verification pattern", "Patrón de verificación de cuenta")
        case .riskyFile: T3("Pièce jointe à risque", "Risky attachment", "Adjunto de riesgo")
        case .doubleExtension: T3("Double extension", "Double extension", "Doble extensión")
        case .macro: T3("Activation de macros demandée", "Macros requested", "Se piden macros")
        case .qrCode: T3("QR code à scanner", "QR code to scan", "Código QR para escanear")
        case .typeMismatch: T3("Type réel différent de l’extension", "Real type differs from the extension", "Tipo real distinto de la extensión")
        case .executable: T3("Programme exécutable", "Executable program", "Programa ejecutable")
        case .scriptInDocument: T3("Script dans le document", "Script inside the document", "Script dentro del documento")
        case .autoAction: T3("Action automatique à l’ouverture", "Automatic action on opening", "Acción automática al abrir")
        case .embeddedFile: T3("Fichier caché à l’intérieur", "File hidden inside", "Archivo oculto dentro")
        case .officeMacros: T3("Macros Office", "Office macros", "Macros de Office")
        case .externalContent: T3("Contenu externe chargé", "External content loaded", "Contenido externo cargado")
        case .passwordForm: T3("Formulaire de mot de passe", "Password form", "Formulario de contraseña")
        case .metaRefresh: T3("Redirection automatique", "Automatic redirect", "Redirección automática")
        case .archiveRisk: T3("Archive contenant un fichier à risque", "Archive holding a risky file", "Archivo comprimido con un fichero de riesgo")
        case .encryptedArchive: T3("Archive chiffrée", "Encrypted archive", "Archivo cifrado")
        case .zipBomb: T3("Bombe de décompression", "Decompression bomb", "Bomba de descompresión")
        case .formulaInjection: T3("Formule dangereuse (CSV)", "Dangerous formula (CSV)", "Fórmula peligrosa (CSV)")
        case .modelScam: T3("Ressemble à des arnaques connues", "Looks like known scams", "Se parece a estafas conocidas")
        case .modelLink: T3("Lien proche de liens de phishing connus", "Link close to known phishing links", "Enlace parecido a enlaces de phishing conocidos")
        case .blockedSender: T3("Expéditeur que vous avez bloqué", "Sender you blocked", "Remitente que has bloqueado")
        case .userReported: T3("Message que vous avez signalé", "Message you reported", "Mensaje que has denunciado")
        }
    }

    /// Why it matters, in one sentence.
    public var explanation: T3 {
        switch self {
        case .urgency: T3("Vous presser vous empêche de vérifier.", "Rushing you stops you from checking.", "Meterte prisa te impide verificar.")
        case .threat: T3("La peur fait agir sans réfléchir.", "Fear makes people act without thinking.", "El miedo hace actuar sin pensar.")
        case .sensitiveData: T3("Aucun service sérieux ne demande ces informations par email.", "No serious service asks for this by email.", "Ningún servicio serio pide estos datos por correo.")
        case .money: T3("Un paiement demandé sous pression est un signal classique d’arnaque.", "A payment requested under pressure is a classic scam signal.", "Un pago pedido bajo presión es una señal clásica de estafa.")
        case .secrecy: T3("Exiger le secret sert à vous isoler de ceux qui vous alerteraient.", "Demanding secrecy isolates you from those who would warn you.", "Exigir secreto sirve para aislarte de quien te advertiría.")
        case .reward: T3("Un gain inattendu sert d’appât.", "An unexpected gain is bait.", "Una ganancia inesperada es un cebo.")
        case .authority: T3("Se réclamer d’une autorité rend la demande plus crédible.", "Claiming authority makes the request more credible.", "Invocar una autoridad hace la petición más creíble.")
        case .lookalike: T3("Un caractère imite un autre pour tromper l’œil.", "A character imitates another to fool the eye.", "Un carácter imita a otro para engañar a la vista.")
        case .brandMismatch: T3("Le lien ne mène pas au domaine de la marque citée.", "The link does not lead to the named brand’s domain.", "El enlace no lleva al dominio de la marca citada.")
        case .freeMailer: T3("Une organisation officielle n’écrit pas depuis une messagerie gratuite.", "An official organization does not write from a free mailbox.", "Una organización oficial no escribe desde un correo gratuito.")
        case .replyToMismatch: T3("Votre réponse partirait vers une autre adresse que l’expéditeur.", "Your reply would go to another address than the sender’s.", "Tu respuesta iría a otra dirección distinta del remitente.")
        case .authFailure: T3("Le serveur n’a pas pu confirmer que l’email vient bien de ce domaine.", "The server could not confirm the email really comes from this domain.", "El servidor no pudo confirmar que el correo viene de ese dominio.")
        case .shortLink: T3("Un lien raccourci cache sa vraie destination.", "A short link hides its real destination.", "Un enlace acortado oculta su verdadero destino.")
        case .ipLink: T3("Les vrais services utilisent un nom de domaine, pas une adresse IP.", "Real services use a domain name, not an IP address.", "Los servicios reales usan un dominio, no una IP.")
        case .plainHttp: T3("Une page sans chiffrement ne devrait jamais demander de données.", "A page without encryption should never ask for data.", "Una página sin cifrado nunca debería pedir datos.")
        case .oddTld: T3("Cette extension est souvent utilisée par des sites jetables.", "This extension is often used by throwaway sites.", "Esta extensión la usan a menudo sitios desechables.")
        case .deepSubdomains: T3("Le vrai domaine se cache derrière une cascade de sous-domaines.", "The real domain hides behind a cascade of subdomains.", "El dominio real se esconde tras una cascada de subdominios.")
        case .loginWords: T3("Les mots « login », « verify » ou « secure » dans un lien sont un leurre fréquent.", "Words like “login”, “verify” or “secure” in a link are a common decoy.", "Palabras como «login», «verify» o «secure» en un enlace son un señuelo frecuente.")
        case .riskyFile: T3("Ce type de fichier peut exécuter du code.", "This kind of file can run code.", "Este tipo de archivo puede ejecutar código.")
        case .doubleExtension: T3("Le fichier se fait passer pour un document alors qu’il s’exécute.", "The file poses as a document but runs as a program.", "El archivo se hace pasar por un documento pero se ejecuta.")
        case .macro: T3("Activer les macros peut installer un logiciel malveillant.", "Enabling macros can install malware.", "Activar macros puede instalar software malicioso.")
        case .qrCode: T3("Un QR code cache sa destination : vérifiez-la avant d’ouvrir.", "A QR code hides its destination: check it before opening.", "Un código QR oculta su destino: compruébalo antes de abrir.")
        case .typeMismatch: T3("Le contenu du fichier ne correspond pas à son nom : il se déguise.", "The file’s content does not match its name: it is in disguise.", "El contenido no corresponde a su nombre: va disfrazado.")
        case .executable: T3("Ouvrir ce fichier lancerait un programme sur l’appareil.", "Opening this file would run a program on the device.", "Abrir este archivo ejecutaría un programa en el dispositivo.")
        case .scriptInDocument: T3("Un document n’a pas besoin de code pour être lu.", "A document needs no code to be read.", "Un documento no necesita código para leerse.")
        case .autoAction: T3("Le document tente d’agir dès qu’on l’ouvre.", "The document tries to act as soon as it is opened.", "El documento intenta actuar en cuanto se abre.")
        case .embeddedFile: T3("Un autre fichier est caché dans celui-ci.", "Another file is hidden inside this one.", "Hay otro archivo escondido dentro de este.")
        case .officeMacros: T3("Les macros peuvent installer un logiciel malveillant si on les active.", "Macros can install malware if they are enabled.", "Las macros pueden instalar malware si se activan.")
        case .externalContent: T3("Le fichier va chercher du contenu sur Internet à l’ouverture.", "The file fetches content from the Internet when opened.", "El archivo busca contenido en Internet al abrirse.")
        case .passwordForm: T3("Une page jointe à un email qui demande un mot de passe est un piège classique.", "An attached page asking for a password is a classic trap.", "Una página adjunta que pide una contraseña es una trampa clásica.")
        case .metaRefresh: T3("La page vous envoie ailleurs sans que vous cliquiez.", "The page sends you elsewhere without a click.", "La página te envía a otro sitio sin hacer clic.")
        case .archiveRisk: T3("L’archive cache un programme ou un fichier déguisé.", "The archive hides a program or a disguised file.", "El archivo comprimido oculta un programa o un fichero disfrazado.")
        case .encryptedArchive: T3("Une archive protégée par mot de passe échappe aux antivirus : c’est voulu.", "A password-protected archive escapes antivirus scans: on purpose.", "Un archivo protegido con contraseña escapa a los antivirus: a propósito.")
        case .zipBomb: T3("Décompresser ce fichier saturerait l’appareil.", "Decompressing this file would overwhelm the device.", "Descomprimir este archivo saturaría el dispositivo.")
        case .formulaInjection: T3("Ouvert dans un tableur, il exécuterait une formule ou une commande.", "Opened in a spreadsheet, it would run a formula or a command.", "Abierto en una hoja de cálculo, ejecutaría una fórmula o un comando.")
        case .modelScam: T3("Le modèle entraîné de MailZen reconnaît dans ce texte les tournures de très nombreuses arnaques.", "MailZen’s trained model recognizes in this text the wording of many scams.", "El modelo entrenado de MailZen reconoce en este texto la redacción de muchas estafas.")
        case .modelLink: T3("Le modèle des liens, entraîné sur des centaines de milliers d’adresses, reconnaît la forme d’un lien de phishing.", "The link model, trained on hundreds of thousands of addresses, recognizes the shape of a phishing link.", "El modelo de enlaces, entrenado con cientos de miles de direcciones, reconoce la forma de un enlace de phishing.")
        case .blockedSender: T3("Vous avez déjà signalé cet expéditeur comme malveillant.", "You already reported this sender as malicious.", "Ya marcaste a este remitente como malicioso.")
        case .userReported: T3("Vous avez vous-même indiqué que ce message était une arnaque.", "You said yourself that this message was a scam.", "Tú mismo indicaste que este mensaje era una estafa.")
        }
    }
}

/// A signal and the text that triggered it.
public struct Signal: Hashable, Sendable {
    public let rule: Rule
    public let evidence: String
}

/// A link found in the message.
public struct DetectedLink: Hashable, Sendable {
    public let url: String
    public let host: String
    public let risky: Bool
    /// The probability given by the link model, when it ran (never for an official domain).
    public var modelProbability: Double? = nil
}

/// The senders the user trusts or blocked, by domain (or full address), kept on the device.
public struct PersonalLists: Sendable, Hashable, Codable {
    public var trusted: Set<String> = []
    public var blocked: Set<String> = []
    public init(trusted: Set<String> = [], blocked: Set<String> = []) {
        self.trusted = trusted
        self.blocked = blocked
    }

    /// The key of an address: its domain, lowercased; a free mailbox keeps its full address.
    public static func key(of address: String) -> String? {
        guard let domain = emailDomain(address)?.lowercased() else { return nil }
        if Keywords.freeMail.contains(where: { domain.hasPrefix($0) }) || ["orange.fr", "free.fr", "laposte.net", "sfr.fr"].contains(domain) {
            let inner = address.split(separator: "<").last.map(String.init) ?? address
            return inner.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).lowercased()
        }
        return registrableDomain(domain)
    }

    func contains(_ set: Set<String>, _ address: String?) -> Bool {
        guard let address, let key = Self.key(of: address) else { return false }
        return set.contains(key)
    }
}

/// The result of an analysis.
public struct Report: Hashable, Sendable {
    public internal(set) var score: Int
    public internal(set) var verdict: Verdict
    /// 0 (low) to 2 (high).
    public let confidence: Int
    public let signals: [Signal]
    public let links: [DetectedLink]
    /// What the trained models say, when they ran.
    public var model: ModelInsight? = nil
    /// The sender is on the user's trusted list.
    public var trustedSender = false
    /// The trained model raised the verdict by itself (autonomous mode).
    public var decidedByModel = false
    /// What the user said of this very message, if they judged it: a scam or not.
    public var userVerdict: Bool? = nil
    /// The score was lowered because the message resembles ones the user judged legitimate.
    public var learnedLegit = false

    public var confidenceLabel: T3 {
        switch confidence {
        case 0: T3("Faible", "Low", "Baja")
        case 1: T3("Moyen", "Medium", "Media")
        default: T3("Élevé", "High", "Alta")
        }
    }

    /// The report of a message from a trusted sender: the text signals stay visible, but
    /// the score is lowered, unless an attachment, an authentication failure or a lookalike
    /// shows that someone poses as that sender.
    func trusted() -> Report {
        guard var r = lowered(to: 19) else { return self }
        r.trustedSender = true
        return r
    }

    /// Signs that someone poses as a sender, or that a file is dangerous: nothing the user
    /// taught MailZen lowers a score that has one of them.
    static let hard: Set<Rule> = [.authFailure, .lookalike, .executable, .typeMismatch, .doubleExtension, .archiveRisk, .zipBomb, .passwordForm, .blockedSender, .userReported]

    func lowered(to ceiling: Int, alsoBlockedBy more: Set<Rule> = []) -> Report? {
        guard !signals.contains(where: { Self.hard.contains($0.rule) || more.contains($0.rule) }) else { return nil }
        var r = self
        r.score = min(score, ceiling)
        r.verdict = .of(score: r.score)
        r.decidedByModel = decidedByModel && r.score == score
        return r
    }

    public var technicalSignals: [Signal] { signals.filter { !$0.rule.isManipulation } }
    public var manipulationSignals: [Signal] { signals.filter { $0.rule.isManipulation } }
}

// MARK: - Keywords

enum Keywords {
    static let urgency = [
        "24 heures", "24h", "immédiatement", "urgent", "sans délai", "dernier rappel", "avant ce soir",
        "expire", "maintenant", "within 24 hours", "24 hours", "immediately", "final notice",
        "right now", "act now", "today only", "tonight", "24 horas", "inmediatamente", "urgente",
        "último aviso", "caduca", "esta noche", "ahora mismo",
    ]
    static let threat = [
        "suspendu", "bloqué", "fermé", "compromis", "renvoyé", "poursuites", "suspended", "locked",
        "closed", "compromised", "returned to sender", "legal action", "suspendida", "bloqueada",
        "cerrada", "comprometida", "devuelto",
    ]
    static let sensitive = [
        "mot de passe", "identifiant", "carte bancaire", "numéro de carte", "cryptogramme", "code sms",
        "code reçu", "iban", "rib", "password", "credit card", "card number", "security code", "cvv",
        "login details", "sms code", "contraseña", "tarjeta", "número de tarjeta", "código sms",
        "datos bancarios", "identidad",
    ]
    static let money = [
        "virement", "payer", "frais", "régler", "réglez", "remboursement", "wire transfer", "transfer",
        "pay", "fee", "refund", "transferencia", "pagar", "tasa", "reembolso", "bitcoin", "crypto",
        "€", "$",
    ]
    static let secrecy = [
        "à personne", "confidentiel", "ne partagez pas", "discrétion", "don't tell", "do not tell",
        "confidential", "keep this between", "do not share", "a nadie", "confidencial",
        "no compartas",
    ]
    static let reward = [
        "gagné", "cadeau", "gratuit", "félicitations", "won", "you have won", "gift", "free",
        "congratulations", "prize", "ganado", "regalo", "gratis", "enhorabuena", "premio",
    ]
    static let authority = [
        "gouvernement", "police", "impôts", "officiel", "direction", "service sécurité", "government",
        "official", "tax office", "security team", "ceo", "gobierno", "policía", "hacienda",
        "oficial", "dirección",
    ]
    static let brands = [
        "paypal", "amazon", "netflix", "apple", "microsoft", "google", "facebook", "instagram",
        "whatsapp", "dhl", "ups", "fedex", "chronopost", "colissimo", "laposte", "correos", "ameli",
        "impots", "hacienda", "irs",
    ]
    static let shorteners = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "cutt.ly", "ow.ly", "rebrand.ly", "t.ly",
        "shorturl.at",
    ]
    static let freeMail = ["gmail.", "outlook.", "hotmail.", "yahoo.", "proton.", "gmx.", "icloud."]
    static let oddTlds = [".xyz", ".top", ".click", ".zip", ".mov", ".tk", ".gq", ".cf", ".work", ".rest", ".cam"]
    static let loginWords = [
        "login", "verify", "verification", "secure", "account", "update", "confirm", "signin",
        "connexion", "verificar", "cuenta",
    ]
    static let riskyExtensions = [
        ".exe", ".scr", ".js", ".vbs", ".bat", ".cmd", ".jar", ".iso", ".apk", ".msi", ".hta",
        ".lnk", ".docm", ".xlsm",
    ]
    static let documentExtensions = [".pdf", ".doc", ".docx", ".jpg", ".png", ".xlsx", ".txt"]
    static let macro = [
        "activer le contenu", "activer les macros", "enable content", "enable macros",
        "habilitar contenido", "habilitar macros",
    ]
    static let qr = ["qr code", "code qr", "código qr", "qr-code"]
}

// MARK: - Text helpers

extension Character {
    var isWordCharacter: Bool { isLetter || isNumber }
}

/// Whether `text` contains `word`, not as a part of a longer word: `irs` is not found
/// in `first`.
public func containsWord(_ text: String, _ word: String) -> Bool {
    guard let first = word.first, let last = word.last else { return false }
    var searchRange = text.startIndex..<text.endIndex
    while let found = text.range(of: word, range: searchRange) {
        let before = found.lowerBound > text.startIndex ? text[text.index(before: found.lowerBound)] : nil
        let after = found.upperBound < text.endIndex ? text[found.upperBound] : nil
        let okBefore = !(first.isWordCharacter && (before?.isWordCharacter ?? false))
        let okAfter = !(last.isWordCharacter && (after?.isWordCharacter ?? false))
        if okBefore && okAfter { return true }
        searchRange = text.index(after: found.lowerBound)..<text.endIndex
    }
    return false
}

func find(_ text: String, _ list: [String]) -> String? {
    list.first { containsWord(text, $0) }
}

/// Every URL of the text: `http://…`, `https://…` and `www.…`.
public func extractURLs(_ text: String) -> [String] {
    var found: [String] = []
    let separators: Set<Character> = ["<", ">", "\"", "(", ")"]
    let words = text.split { $0.isWhitespace || separators.contains($0) }
    for word in words {
        let w = String(word)
        let starts = ["https://", "http://", "www."].compactMap { w.range(of: $0)?.lowerBound }
        guard let start = starts.min() else { continue }
        var url = String(w[start...])
        while let lastChar = url.last, ".,;:!?'".contains(lastChar) {
            url.removeLast()
        }
        if url.count > 6 && !found.contains(url) {
            found.append(url)
        }
    }
    return found
}

/// The host of a URL, as written (case kept, to spot `paypaI`).
public func host(of url: String) -> String {
    var rest = Substring(url)
    for scheme in ["https://", "http://"] where rest.hasPrefix(scheme) {
        rest = rest.dropFirst(scheme.count)
    }
    let end = rest.firstIndex { "/?#:".contains($0) } ?? rest.endIndex
    let hostPart = rest[..<end]
    if let at = hostPart.lastIndex(of: "@") {
        return String(hostPart[hostPart.index(after: at)...])
    }
    return String(hostPart)
}

/// The domain of an address `Name <user@domain>` or `user@domain`.
public func emailDomain(_ line: String) -> String? {
    guard let at = line.lastIndex(of: "@") else { return nil }
    let rest = line[line.index(after: at)...]
    let end = rest.firstIndex { $0 == ">" || $0.isWhitespace } ?? rest.endIndex
    let domain = String(rest[..<end])
    return domain.contains(".") ? domain : nil
}

/// A domain that imitates a brand: characters that look alike (`I` for `l`, `0` for
/// `o`, `rn` for `m`), or letters from other alphabets.
public func imitatesBrand(_ domain: String) -> String? {
    if domain.unicodeScalars.contains(where: { !$0.isASCII }) {
        return "unicode"
    }
    let hasLower = domain.contains { $0.isLowercase }
    let lowered = domain.lowercased()
    let normalized = String(domain.map { c -> Character in
        switch c {
        case "I" where hasLower: "l"
        case "0": "o"
        case "1": "l"
        case "3": "e"
        case "5": "s"
        default: Character(c.lowercased())
        }
    }).replacingOccurrences(of: "rn", with: "m")
    return Keywords.brands.first { normalized.contains($0) && !lowered.contains($0) }
}

func isIP(_ host: String) -> Bool {
    let parts = host.split(separator: ".", omittingEmptySubsequences: false)
    return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil }
}

/// The registrable domain (the last two labels): `a.b.example.com` → `example.com`.
public func registrableDomain(_ host: String) -> String {
    let labels = host.lowercased().split(separator: ".")
    let lastTwo = labels.suffix(2).joined(separator: ".")
    if Brands.publicSuffixes.contains(lastTwo) {
        return labels.suffix(3).joined(separator: ".")
    }
    return lastTwo
}

// MARK: - Engine

public enum Engine {
    /// Analyzes a message: the pasted text of an email, an SMS, a link…
    public static func analyze(_ text: String) -> Report {
        analyze(text: text, extra: [])
    }

    /// Analyzes a parsed email: its text, plus its authentication results and reply
    /// address.
    public static func analyze(_ message: EmailMessage, personal lists: PersonalLists? = nil, learned: PersonalModel? = nil) -> Report {
        let personal = lists ?? Self.personal
        var extra: [Signal] = []
        if let failed = message.failedAuthentication {
            extra.append(Signal(rule: .authFailure, evidence: failed))
        }
        if let from = message.fromAddress.flatMap(emailDomain),
           let reply = message.replyTo.flatMap(emailDomain),
           registrableDomain(from) != registrableDomain(reply)
        {
            extra.append(Signal(rule: .replyToMismatch, evidence: "\(from) → \(reply)"))
        }
        // Each attachment, through Attachment Guard.
        for attachment in message.attachments {
            for signal in attachment.analysis.report.signals where !extra.contains(where: { $0.rule == signal.rule }) {
                extra.append(signal)
            }
        }
        if personal.contains(personal.blocked, message.fromAddress) {
            extra.append(Signal(rule: .blockedSender, evidence: message.fromAddress ?? ""))
        }
        var report = analyze(text: message.analysisText, extra: extra, personal: personal, learned: learned)
        if personal.contains(personal.trusted, message.fromAddress) { report = report.trusted() }
        return report
    }

    /// Whether the trained models take part (the rules alone otherwise).
    nonisolated(unsafe) public static var useModels = true
    /// The senders the user trusts or blocked (set by the app).
    nonisolated(unsafe) public static var personal = PersonalLists()
    /// What MailZen learned from the corrections of its user (set by the app).
    nonisolated(unsafe) public static var learned = PersonalModel()
    /// Whether the trained model may decide the verdict by itself when it is sure: at
    /// least "suspicious" from 90 %, "danger" from 98 % (0.17 % and 0.06 % of false alarms
    /// on real messages kept for the test). Otherwise it only adds a signal to the rules.
    nonisolated(unsafe) public static var autonomous = true
    static let suspiciousFrom = 0.9
    static let dangerFrom = 0.98

    static func analyze(text: String, extra: [Signal], models: Bool = true, personal lists: PersonalLists? = nil, learned taught: PersonalModel? = nil) -> Report {
        let personal = lists ?? Self.personal
        let learned = taught ?? Self.learned
        let lower = text.lowercased()
        var signals: [Signal] = []
        func push(_ rule: Rule, _ evidence: String) {
            if !signals.contains(where: { $0.rule == rule }) {
                signals.append(Signal(rule: rule, evidence: evidence))
            }
        }
        for signal in extra { push(signal.rule, signal.evidence) }
        // What the user said of this very message.
        let said = text.isEmpty ? nil : learned.verdict(of: text)
        if said == true { push(.userReported, "") }

        // Sender.
        let senderLine = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.first { line in
            let l = line.lowercased()
            return ["de :", "de:", "from:", "from :", "remitente:"].contains { l.hasPrefix($0) }
        }
        if let line = senderLine, personal.contains(personal.blocked, line) {
            push(.blockedSender, emailDomain(line) ?? line)
        }
        if let line = senderLine, let domain = emailDomain(line) {
            if imitatesBrand(domain) != nil {
                push(.lookalike, domain)
            }
            let d = domain.lowercased()
            if Keywords.freeMail.contains(where: { d.hasPrefix($0) }) {
                let name = line.lowercased()
                if find(name, Keywords.authority) != nil || Keywords.brands.contains(where: { containsWord(name, $0) }) {
                    push(.freeMailer, domain)
                }
            }
        }

        // Links.
        var links: [DetectedLink] = []
        for url in extractURLs(text) {
            let h = host(of: url)
            let lh = h.lowercased()
            var risky = false
            if imitatesBrand(h) != nil { push(.lookalike, h); risky = true }
            if Keywords.shorteners.contains(where: { lh == $0 || lh.hasSuffix("." + $0) }) { push(.shortLink, h); risky = true }
            if isIP(lh) { push(.ipLink, h); risky = true }
            if url.lowercased().hasPrefix("http://") { push(.plainHttp, url); risky = true }
            if Keywords.oddTlds.contains(where: { lh.hasSuffix($0) }) { push(.oddTld, h); risky = true }
            let official = Brands.official(lh) != nil
            if lh.split(separator: ".").count >= 4 && !official { push(.deepSubdomains, h); risky = true }
            if !official, let word = find(lh, Keywords.loginWords) { push(.loginWords, word); risky = true }
            if let brand = Keywords.brands.first(where: { containsWord(lower, $0) }),
               !registrableDomain(lh).contains(brand), !isIP(lh),
               Brands.official(lh) == nil
            {
                push(.brandMismatch, "\(brand) → \(h)")
                risky = true
            }
            var link = DetectedLink(url: url, host: h, risky: risky)
            if useModels, models, !official, !isIP(lh), let m = Models.shared {
                let p = m.linkProbability(url)
                link.modelProbability = p
                if p >= 0.95 {
                    push(.modelLink, "\(h) (\(Int((p * 100).rounded())) %)")
                    link = DetectedLink(url: url, host: h, risky: true, modelProbability: p)
                }
            }
            links.append(link)
        }

        // Attachments.
        let wordSeparators: Set<Character> = [",", ";", ":", "(", ")"]
        for raw in lower.split(whereSeparator: { $0.isWhitespace || wordSeparators.contains($0) }) {
            var word = String(raw)
            while let lastChar = word.last, ".!?".contains(lastChar) { word.removeLast() }
            guard word.contains("."), !word.contains("/"), !word.contains("@") else { continue }
            if let ext = Keywords.riskyExtensions.first(where: { word.hasSuffix($0) }) {
                let stem = String(word.dropLast(ext.count))
                if Keywords.documentExtensions.contains(where: { stem.hasSuffix($0) }) {
                    push(.doubleExtension, word)
                } else {
                    push(.riskyFile, word)
                }
            }
        }
        if let m = find(lower, Keywords.macro) { push(.macro, m) }
        if let q = find(lower, Keywords.qr) { push(.qrCode, q) }

        // Manipulation.
        let techniques: [(Rule, [String])] = [
            (.urgency, Keywords.urgency), (.threat, Keywords.threat), (.sensitiveData, Keywords.sensitive),
            (.secrecy, Keywords.secrecy), (.reward, Keywords.reward), (.authority, Keywords.authority),
        ]
        for (rule, list) in techniques {
            if let word = find(lower, list) { push(rule, word) }
        }
        // Money alone is ordinary: it counts with another sign of pressure.
        if let word = find(lower, Keywords.money), signals.contains(where: { $0.rule.isManipulation }) {
            push(.money, word)
        }

        let words = lower.split(whereSeparator: \.isWhitespace).count
        // The trained models: a signal when they are very sure, and the family of scam.
        var insight: ModelInsight?
        var floor = 0
        if useModels, models, words >= 5, let models = Models.shared {
            let features = Featurizer.features(text)
            // The scam model, plus what the user taught it on this device.
            let personalShift = learned.adjustment(features)
            let p = 1 / (1 + exp(-(models.scam.logits(features)[0] + personalShift)))
            var category: ScamCategory?
            var categoryProbability = 0.0
            if p >= 0.5 {
                let c = models.category(text)
                if c.probability >= 0.4 {
                    category = ScamCategory(rawValue: c.label)
                    categoryProbability = c.probability
                }
            }
            insight = ModelInsight(probability: p, category: category, categoryProbability: categoryProbability, personal: personalShift)
            // A message whose links all lead to verified official domains is no
            // impersonation, however much its wording looks like one.
            let allOfficial = !links.isEmpty && links.allSatisfy { Brands.official($0.host) != nil }
            if p >= suspiciousFrom && !allOfficial {
                push(.modelScam, "\(Int((p * 100).rounded())) %")
                if autonomous { floor = p >= dangerFrom ? 70 : 45 }
            }
        }

        let raw = signals.reduce(0) { $0 + $1.rule.weight }
        // Authority alone (a newsletter from a city hall) is no danger.
        let ruled = (signals.count == 1 && signals[0].rule == .authority) ? 4 : min(raw, 98)
        // The model decides by itself when it is sure and the rules saw less.
        let score = max(ruled, floor)
        let confidence: Int
        switch (words, signals.count) {
        case (0...8, _): confidence = 0
        case (_, 0...1): confidence = 1
        case (_, 2...3) where score < 70: confidence = 1
        default: confidence = 2
        }
        var report = Report(score: score, verdict: .of(score: score), confidence: confidence, signals: signals, links: links, model: insight)
        report.decidedByModel = floor > ruled
        report.userVerdict = said
        if said == false, let lowered = report.lowered(to: 19) {
            // The user judged this very message legitimate.
            report = lowered
        } else if said == nil, let m = insight, m.personal <= -1.5, m.probability < 0.2,
                  let lowered = report.lowered(to: 30, alsoBlockedBy: [.modelLink, .brandMismatch, .shortLink, .ipLink, .riskyFile, .macro]),
                  lowered.score < report.score {
            // It resembles messages the user judged legitimate.
            report = lowered
            report.learnedLegit = true
        }
        return report
    }
}
