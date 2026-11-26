//! A small, deterministic analysis engine for the interactive demo of the home page.
//!
//! It is pedagogical: a few rules in the spirit of MailZen Core (sender, links,
//! attachments, manipulation techniques), run in the browser (WebAssembly) on the text
//! the visitor types. Nothing is sent anywhere. It does not replace the real engine.

use crate::i18n::T3;
use crate::models::{self, Models};

/// The four verdicts of a report.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verdict {
    Safe,
    Caution,
    Suspicious,
    Danger,
}

impl Verdict {
    pub fn of(score: u32) -> Verdict {
        match score {
            0..=19 => Verdict::Safe,
            20..=44 => Verdict::Caution,
            45..=69 => Verdict::Suspicious,
            _ => Verdict::Danger,
        }
    }

    /// The CSS modifier (`verdict--safe`…).
    pub fn class(self) -> &'static str {
        match self {
            Verdict::Safe => "safe",
            Verdict::Caution => "caution",
            Verdict::Suspicious => "suspicious",
            Verdict::Danger => "danger",
        }
    }

    pub fn title(self) -> &'static T3 {
        match self {
            Verdict::Safe => &[
                "Aucun risque notable détecté",
                "No notable risk detected",
                "Ningún riesgo notable detectado",
            ],
            Verdict::Caution => &["Vigilance", "Caution", "Precaución"],
            Verdict::Suspicious => &["Suspect", "Suspicious", "Sospechoso"],
            Verdict::Danger => &["Danger élevé", "High danger", "Peligro elevado"],
        }
    }

    pub fn advice(self) -> &'static T3 {
        match self {
            Verdict::Safe => &[
                "Les contrôles effectués n’ont pas relevé de signal important. Cela ne garantit pas l’innocuité : restez attentif aux demandes inhabituelles.",
                "The checks found no significant signal. This does not guarantee the message is harmless: stay alert to unusual requests.",
                "Los controles no han encontrado ninguna señal importante. Eso no garantiza que sea inofensivo: mantente atento a las peticiones inusuales.",
            ],
            Verdict::Caution => &[
                "Quelques éléments sont à vérifier. Avant d’agir, contactez l’expéditeur par un canal officiel que vous connaissez.",
                "A few things deserve a check. Before acting, contact the sender through an official channel you already know.",
                "Hay algunos elementos que verificar. Antes de actuar, contacta con el remitente por un canal oficial que ya conozcas.",
            ],
            Verdict::Suspicious => &[
                "Plusieurs indicateurs sont inquiétants. Ne cliquez sur aucun lien, n’ouvrez aucune pièce jointe et vérifiez directement auprès du service concerné.",
                "Several indicators are worrying. Do not click any link, do not open any attachment, and check directly with the service concerned.",
                "Varios indicadores son preocupantes. No hagas clic en ningún enlace, no abras ningún adjunto y verifica directamente con el servicio afectado.",
            ],
            Verdict::Danger => &[
                "Ne cliquez pas, ne répondez pas, ne payez rien. Accédez au service officiel par son application ou en tapant son adresse vous-même, puis signalez le message.",
                "Do not click, do not reply, do not pay. Go to the official service through its app or by typing its address yourself, then report the message.",
                "No hagas clic, no respondas, no pagues nada. Accede al servicio oficial desde su app o escribiendo tú mismo su dirección y denuncia el mensaje.",
            ],
        }
    }
}

/// The families of signals (the "Les familles de signaux" table).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Family {
    Sender,
    Link,
    File,
    Behavior,
    Identity,
    Model,
}

impl Family {
    pub fn label(self) -> &'static T3 {
        match self {
            Family::Sender => &["Expéditeur", "Sender", "Remitente"],
            Family::Link => &["URL", "URL", "URL"],
            Family::File => &["Fichier", "File", "Archivo"],
            Family::Behavior => &["Comportement", "Behavior", "Comportamiento"],
            Family::Identity => &["Identité", "Identity", "Identidad"],
            Family::Model => &["Modèle", "Model", "Modelo"],
        }
    }
}

/// What a rule found.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Rule {
    Urgency,
    Threat,
    SensitiveData,
    Money,
    Secrecy,
    Reward,
    Authority,
    Lookalike,
    BrandMismatch,
    FreeMailer,
    ShortLink,
    IpLink,
    PlainHttp,
    OddTld,
    DeepSubdomains,
    LoginWords,
    RiskyFile,
    DoubleExtension,
    Macro,
    QrCode,
    ModelScam,
    ModelLink,
}

impl Rule {
    pub fn family(self) -> Family {
        use Rule::*;
        match self {
            Urgency | Threat | SensitiveData | Money | Secrecy | Reward | QrCode => {
                Family::Behavior
            }
            Authority | BrandMismatch => Family::Identity,
            Lookalike | FreeMailer => Family::Sender,
            ShortLink | IpLink | PlainHttp | OddTld | DeepSubdomains | LoginWords => Family::Link,
            RiskyFile | DoubleExtension | Macro => Family::File,
            ModelScam | ModelLink => Family::Model,
        }
    }

    pub fn weight(self) -> u32 {
        use Rule::*;
        match self {
            Urgency => 14,
            Threat => 14,
            SensitiveData => 20,
            Money => 12,
            Secrecy => 14,
            Reward => 12,
            Authority => 6,
            Lookalike => 28,
            BrandMismatch => 22,
            FreeMailer => 10,
            ShortLink => 14,
            IpLink => 22,
            PlainHttp => 8,
            OddTld => 8,
            DeepSubdomains => 10,
            LoginWords => 8,
            RiskyFile => 22,
            DoubleExtension => 30,
            Macro => 18,
            QrCode => 8,
            ModelScam => 16,
            ModelLink => 14,
        }
    }

    /// A manipulation technique (urgency, fear…), shown apart from technical signals.
    pub fn is_manipulation(self) -> bool {
        use Rule::*;
        matches!(
            self,
            Urgency | Threat | SensitiveData | Money | Secrecy | Reward | Authority
        )
    }

    pub fn title(self) -> &'static T3 {
        use Rule::*;
        match self {
            Urgency => &["Pression temporelle", "Time pressure", "Presión de tiempo"],
            Threat => &["Menace", "Threat", "Amenaza"],
            SensitiveData => &[
                "Demande d’informations sensibles",
                "Request for sensitive information",
                "Petición de datos sensibles",
            ],
            Money => &["Demande de paiement", "Payment request", "Petición de pago"],
            Secrecy => &["Secret exigé", "Secrecy demanded", "Se exige secreto"],
            Reward => &[
                "Récompense promise",
                "Promised reward",
                "Recompensa prometida",
            ],
            Authority => &[
                "Autorité invoquée",
                "Authority invoked",
                "Autoridad invocada",
            ],
            Lookalike => &[
                "Domaine ressemblant",
                "Lookalike domain",
                "Dominio parecido",
            ],
            BrandMismatch => &[
                "Marque citée, domaine différent",
                "Brand named, different domain",
                "Marca citada, dominio distinto",
            ],
            FreeMailer => &["Messagerie gratuite", "Free mailbox", "Correo gratuito"],
            ShortLink => &["Lien raccourci", "Shortened link", "Enlace acortado"],
            IpLink => &[
                "Lien vers une adresse IP",
                "Link to an IP address",
                "Enlace a una dirección IP",
            ],
            PlainHttp => &["Lien non chiffré", "Unencrypted link", "Enlace sin cifrar"],
            OddTld => &[
                "Extension de domaine inhabituelle",
                "Unusual domain extension",
                "Extensión de dominio inusual",
            ],
            DeepSubdomains => &[
                "Sous-domaines en cascade",
                "Cascading subdomains",
                "Subdominios en cascada",
            ],
            LoginWords => &[
                "Motif de vérification de compte",
                "Account verification pattern",
                "Patrón de verificación de cuenta",
            ],
            RiskyFile => &[
                "Pièce jointe à risque",
                "Risky attachment",
                "Adjunto de riesgo",
            ],
            DoubleExtension => &["Double extension", "Double extension", "Doble extensión"],
            Macro => &[
                "Activation de macros demandée",
                "Macros requested",
                "Se piden macros",
            ],
            QrCode => &[
                "QR code à scanner",
                "QR code to scan",
                "Código QR para escanear",
            ],
            ModelScam => &[
                "Ressemble à des arnaques connues",
                "Looks like known scams",
                "Se parece a estafas conocidas",
            ],
            ModelLink => &[
                "Lien proche de liens de phishing connus",
                "Link close to known phishing links",
                "Enlace parecido a enlaces de phishing conocidos",
            ],
        }
    }
}

/// A signal and the text that triggered it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Signal {
    pub rule: Rule,
    pub evidence: String,
}

/// A link found in the message.
#[derive(Clone, Debug, PartialEq)]
pub struct Link {
    pub url: String,
    pub host: String,
    pub risky: bool,
    /// What the link model says, when it ran (never for an official domain).
    pub model: Option<f64>,
    pub official: bool,
}

/// What the trained models say about the text.
#[derive(Clone, Debug, PartialEq)]
pub struct Insight {
    /// The probability that it is a scam.
    pub probability: f64,
    /// The family it looks like (a key of [`models::category_label`]) and its probability.
    pub category: Option<(String, f64)>,
}

/// The result of an analysis.
#[derive(Clone, Debug, PartialEq)]
pub struct Report {
    pub score: u32,
    pub verdict: Verdict,
    /// 0 (low) to 2 (high).
    pub confidence: u8,
    pub signals: Vec<Signal>,
    pub links: Vec<Link>,
    pub model: Option<Insight>,
    /// The trained model raised the verdict by itself.
    pub decided_by_model: bool,
}

/// From these probabilities the scam model decides by itself, as in the app: at least
/// "suspicious", then "danger" (0.17 % and 0.06 % of false alarms on real messages kept
/// for the test).
pub const SUSPICIOUS_FROM: f64 = 0.9;
pub const DANGER_FROM: f64 = 0.98;

impl Report {
    pub fn confidence_label(&self) -> &'static T3 {
        match self.confidence {
            0 => &["Faible", "Low", "Baja"],
            1 => &["Moyen", "Medium", "Media"],
            _ => &["Élevé", "High", "Alta"],
        }
    }
}

const URGENCY: &[&str] = &[
    "24 heures",
    "24h",
    "immédiatement",
    "urgent",
    "sans délai",
    "dernier rappel",
    "avant ce soir",
    "expire",
    "maintenant",
    "within 24 hours",
    "24 hours",
    "immediately",
    "final notice",
    "right now",
    "act now",
    "today only",
    "tonight",
    "24 horas",
    "inmediatamente",
    "urgente",
    "último aviso",
    "caduca",
    "esta noche",
    "ahora mismo",
];
const THREAT: &[&str] = &[
    "suspendu",
    "bloqué",
    "fermé",
    "compromis",
    "renvoyé",
    "poursuites",
    "suspended",
    "locked",
    "closed",
    "compromised",
    "returned to sender",
    "legal action",
    "suspendida",
    "bloqueada",
    "cerrada",
    "comprometida",
    "devuelto",
];
const SENSITIVE: &[&str] = &[
    "mot de passe",
    "identifiant",
    "carte bancaire",
    "numéro de carte",
    "cryptogramme",
    "code sms",
    "code reçu",
    "iban",
    "rib",
    "password",
    "credit card",
    "card number",
    "security code",
    "cvv",
    "login details",
    "sms code",
    "contraseña",
    "tarjeta",
    "número de tarjeta",
    "código sms",
    "datos bancarios",
    "identidad",
];
const MONEY: &[&str] = &[
    "virement",
    "payer",
    "frais",
    "régler",
    "réglez",
    "remboursement",
    "wire transfer",
    "transfer",
    "pay ",
    "fee",
    "refund",
    "transferencia",
    "pagar",
    "tasa",
    "reembolso",
    "bitcoin",
    "crypto",
    "€",
    "$",
];
const SECRECY: &[&str] = &[
    "à personne",
    "confidentiel",
    "ne partagez pas",
    "discrétion",
    "don't tell",
    "do not tell",
    "confidential",
    "keep this between",
    "do not share",
    "a nadie",
    "confidencial",
    "no compartas",
];
const REWARD: &[&str] = &[
    "gagné",
    "cadeau",
    "gratuit",
    "félicitations",
    "won ",
    "you have won",
    "gift",
    "free",
    "congratulations",
    "prize",
    "ganado",
    "regalo",
    "gratis",
    "enhorabuena",
    "premio",
];
const AUTHORITY: &[&str] = &[
    "gouvernement",
    "police",
    "impôts",
    "officiel",
    "direction",
    "service sécurité",
    "government",
    "official",
    "tax office",
    "security team",
    "ceo",
    "gobierno",
    "policía",
    "hacienda",
    "oficial",
    "dirección",
];
const BRANDS: &[&str] = &[
    "paypal",
    "amazon",
    "netflix",
    "apple",
    "microsoft",
    "google",
    "facebook",
    "instagram",
    "whatsapp",
    "dhl",
    "ups",
    "fedex",
    "chronopost",
    "colissimo",
    "laposte",
    "correos",
    "ameli",
    "impots",
    "hacienda",
    "irs",
];
const SHORTENERS: &[&str] = &[
    "bit.ly",
    "tinyurl.com",
    "t.co",
    "goo.gl",
    "is.gd",
    "cutt.ly",
    "ow.ly",
    "rebrand.ly",
    "t.ly",
    "shorturl.at",
];
const FREE_MAIL: &[&str] = &[
    "gmail.", "outlook.", "hotmail.", "yahoo.", "proton.", "gmx.", "icloud.",
];
const ODD_TLDS: &[&str] = &[
    ".xyz", ".top", ".click", ".zip", ".mov", ".tk", ".gq", ".cf", ".work", ".rest", ".cam",
];
const LOGIN_WORDS: &[&str] = &[
    "login",
    "verify",
    "verification",
    "secure",
    "account",
    "update",
    "confirm",
    "signin",
    "connexion",
    "verificar",
    "cuenta",
];
const RISKY_EXT: &[&str] = &[
    ".exe", ".scr", ".js", ".vbs", ".bat", ".cmd", ".jar", ".iso", ".apk", ".msi", ".hta", ".lnk",
    ".docm", ".xlsm",
];
const MACRO: &[&str] = &[
    "activer le contenu",
    "activer les macros",
    "enable content",
    "enable macros",
    "habilitar contenido",
    "habilitar macros",
];
const QR: &[&str] = &["qr code", "code qr", "código qr", "qr-code"];

/// Whether `text` contains `word`, not as a part of a longer word: `irs` is not found
/// in `first`.
pub fn contains_word(text: &str, word: &str) -> bool {
    let alnum = |c: Option<char>| c.is_some_and(char::is_alphanumeric);
    let (first, last) = (word.chars().next(), word.chars().last());
    text.match_indices(word).any(|(at, _)| {
        let before = text[..at].chars().next_back();
        let after = text[at + word.len()..].chars().next();
        !(alnum(first) && alnum(before)) && !(alnum(last) && alnum(after))
    })
}

/// The first keyword of `list` found in `text` (already lowercased).
fn find(text: &str, list: &[&str]) -> Option<String> {
    list.iter()
        .find(|k| contains_word(text, k))
        .map(|k| (*k).to_owned())
}

/// Every URL of the text: `http://…`, `https://…` and `www.…`.
pub fn urls(text: &str) -> Vec<String> {
    let mut found: Vec<String> = Vec::new();
    for word in text.split(|c: char| c.is_whitespace() || matches!(c, '<' | '>' | '"' | '(' | ')'))
    {
        let start = ["https://", "http://", "www."]
            .iter()
            .filter_map(|p| word.find(p))
            .min();
        if let Some(start) = start {
            let url = word[start..].trim_end_matches(['.', ',', ';', ':', '!', '?', '\'']);
            if url.len() > 6 && !found.iter().any(|u| u == url) {
                found.push(url.to_owned());
            }
        }
    }
    found
}

/// The host of a URL, as written (case kept, to spot `paypaI`).
pub fn host(url: &str) -> &str {
    let rest = url
        .strip_prefix("https://")
        .or_else(|| url.strip_prefix("http://"))
        .unwrap_or(url);
    let end = rest.find(['/', '?', '#', ':']).unwrap_or(rest.len());
    let host = &rest[..end];
    host.rsplit('@').next().unwrap_or(host)
}

/// The domain of an address `Name <user@domain>` or `user@domain`.
fn email_domain(line: &str) -> Option<&str> {
    let at = line.rfind('@')?;
    let rest = &line[at + 1..];
    let end = rest
        .find(|c: char| c == '>' || c.is_whitespace())
        .unwrap_or(rest.len());
    Some(&rest[..end]).filter(|d| d.contains('.'))
}

/// The `From:` line of a pasted email (`De :`, `From:`, `De:`).
fn sender_line(text: &str) -> Option<&str> {
    text.lines().map(str::trim).find(|l| {
        let lower = l.to_lowercase();
        ["de :", "de:", "from:", "from :", "remitente:"]
            .iter()
            .any(|p| lower.starts_with(p))
    })
}

/// A domain that imitates a brand: characters that look alike (`I` for `l`, `0` for
/// `o`, `rn` for `m`), or letters from other alphabets.
fn imitates_brand(domain: &str) -> Option<&'static str> {
    if !domain.is_ascii() {
        return Some("unicode");
    }
    let has_lower = domain.chars().any(|c| c.is_ascii_lowercase());
    let lowered = domain.to_ascii_lowercase();
    let normalized: String = domain
        .chars()
        .map(|c| match c {
            'I' if has_lower => 'l',
            '0' => 'o',
            '1' => 'l',
            '3' => 'e',
            '5' => 's',
            c => c.to_ascii_lowercase(),
        })
        .collect::<String>()
        .replace("rn", "m");
    BRANDS
        .iter()
        .find(|b| normalized.contains(*b) && !lowered.contains(*b))
        .copied()
}

fn is_ip(host: &str) -> bool {
    let parts: Vec<&str> = host.split('.').collect();
    parts.len() == 4 && parts.iter().all(|p| p.parse::<u8>().is_ok())
}

/// Analyses a message with the rules alone.
pub fn analyze(text: &str) -> Report {
    analyze_with(text, None)
}

/// Analyses a message with the rules and, when they are loaded, the trained models: a
/// signal when they are very sure (the thresholds of the app), and the family of scam.
pub fn analyze_with(text: &str, trained: Option<&Models>) -> Report {
    let lower = text.to_lowercase();
    let mut signals: Vec<Signal> = Vec::new();
    fn push(signals: &mut Vec<Signal>, rule: Rule, evidence: String) {
        if !signals.iter().any(|s| s.rule == rule) {
            signals.push(Signal { rule, evidence });
        }
    }

    // Sender.
    let sender = sender_line(text);
    let sender_domain = sender.and_then(email_domain);
    if let Some(domain) = sender_domain {
        if imitates_brand(domain).is_some() {
            push(&mut signals, Rule::Lookalike, domain.to_owned());
        }
        let d = domain.to_lowercase();
        if FREE_MAIL.iter().any(|f| d.starts_with(f)) {
            let name = sender.unwrap_or("").to_lowercase();
            if find(&name, AUTHORITY).is_some() || BRANDS.iter().any(|b| contains_word(&name, b)) {
                push(&mut signals, Rule::FreeMailer, domain.to_owned());
            }
        }
    }

    // Links.
    let mut links = Vec::new();
    for url in urls(text) {
        let host = host(&url).to_owned();
        let h = host.to_lowercase();
        let mut risky = false;
        if imitates_brand(&host).is_some() {
            push(&mut signals, Rule::Lookalike, host.clone());
            risky = true;
        }
        if SHORTENERS
            .iter()
            .any(|s| h == *s || h.ends_with(&format!(".{s}")))
        {
            push(&mut signals, Rule::ShortLink, host.clone());
            risky = true;
        }
        if is_ip(&h) {
            push(&mut signals, Rule::IpLink, host.clone());
            risky = true;
        }
        if url.to_lowercase().starts_with("http://") {
            push(&mut signals, Rule::PlainHttp, url.clone());
            risky = true;
        }
        if ODD_TLDS.iter().any(|t| h.ends_with(t)) {
            push(&mut signals, Rule::OddTld, host.clone());
            risky = true;
        }
        if h.split('.').count() >= 4 {
            push(&mut signals, Rule::DeepSubdomains, host.clone());
            risky = true;
        }
        if let Some(word) = find(&h, LOGIN_WORDS) {
            push(&mut signals, Rule::LoginWords, word);
            risky = true;
        }
        // A brand named in the text, a link elsewhere: the registrable domain (the last
        // two labels) does not carry the brand.
        let registrable: String = {
            let labels: Vec<&str> = h.split('.').collect();
            labels[labels.len().saturating_sub(2)..].join(".")
        };
        if let Some(brand) = BRANDS.iter().find(|b| contains_word(&lower, b))
            && !registrable.contains(brand)
            && !is_ip(&h)
        {
            push(
                &mut signals,
                Rule::BrandMismatch,
                format!("{brand} → {host}"),
            );
            risky = true;
        }
        let official = models::is_official(&h);
        let mut model = None;
        if let Some(m) = trained
            && !official
            && !is_ip(&h)
        {
            let p = m.url.probabilities(&models::url_features(&url))[0];
            if p >= 0.95 {
                push(
                    &mut signals,
                    Rule::ModelLink,
                    format!("{host} ({:.0} %)", p * 100.0),
                );
                risky = true;
            }
            model = Some(p);
        }
        links.push(Link {
            url,
            host,
            risky,
            model,
            official,
        });
    }

    // Attachments.
    for word in lower.split(|c: char| c.is_whitespace() || matches!(c, ',' | ';' | ':' | '(' | ')'))
    {
        let word = word.trim_end_matches(['.', '!', '?']);
        if word.contains('.')
            && !word.contains('/')
            && !word.contains('@')
            && let Some(ext) = RISKY_EXT.iter().find(|e| word.ends_with(*e))
        {
            let stem = &word[..word.len() - ext.len()];
            if [".pdf", ".doc", ".docx", ".jpg", ".png", ".xlsx", ".txt"]
                .iter()
                .any(|e| stem.ends_with(e))
            {
                push(&mut signals, Rule::DoubleExtension, word.to_owned());
            } else {
                push(&mut signals, Rule::RiskyFile, word.to_owned());
            }
        }
    }
    if let Some(m) = find(&lower, MACRO) {
        push(&mut signals, Rule::Macro, m);
    }
    if let Some(q) = find(&lower, QR) {
        push(&mut signals, Rule::QrCode, q);
    }

    // Manipulation.
    for (rule, list) in [
        (Rule::Urgency, URGENCY),
        (Rule::Threat, THREAT),
        (Rule::SensitiveData, SENSITIVE),
        (Rule::Secrecy, SECRECY),
        (Rule::Reward, REWARD),
        (Rule::Authority, AUTHORITY),
    ] {
        if let Some(word) = find(&lower, list) {
            push(&mut signals, rule, word);
        }
    }
    // Money alone is ordinary: it counts with another sign of pressure.
    if let Some(word) = find(&lower, MONEY)
        && signals.iter().any(|s| s.rule.is_manipulation())
    {
        push(&mut signals, Rule::Money, word);
    }

    let words = lower.split_whitespace().count();
    let mut insight = None;
    let mut floor = 0;
    if let Some(m) = trained
        && words >= 5
    {
        let features = models::text_features(text);
        let p = m.scam.probabilities(&features)[0];
        let category = (p >= 0.5)
            .then(|| m.category.best(&features))
            .filter(|(_, cp)| *cp >= 0.4);
        // A message whose links all lead to official domains is no impersonation.
        let all_official = !links.is_empty() && links.iter().all(|l| l.official);
        if p >= SUSPICIOUS_FROM && !all_official {
            push(&mut signals, Rule::ModelScam, format!("{:.0} %", p * 100.0));
            floor = if p >= DANGER_FROM { 70 } else { 45 };
        }
        insight = Some(Insight {
            probability: p,
            category,
        });
    }

    let raw: u32 = signals.iter().map(|s| s.rule.weight()).sum();
    // Authority alone (a newsletter from a city hall) is no danger.
    let ruled = if signals.len() == 1 && signals[0].rule == Rule::Authority {
        4
    } else {
        raw.min(98)
    };
    // The model decides by itself when it is sure and the rules saw less.
    let score = ruled.max(floor);
    let confidence = match (words, signals.len()) {
        (0..=8, _) => 0,
        (_, 0..=1) => 1,
        (_, 2..=3) if score < 70 => 1,
        _ => 2,
    };
    Report {
        score,
        verdict: Verdict::of(score),
        confidence,
        signals,
        links,
        model: insight,
        decided_by_model: floor > ruled,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::data::SAMPLES;
    use crate::i18n::Lang;

    #[test]
    fn finds_urls_and_hosts() {
        let found = urls("Go to https://a.example/x?y=1, or www.b.example. And (http://1.2.3.4/z)");
        assert_eq!(
            found,
            [
                "https://a.example/x?y=1",
                "www.b.example",
                "http://1.2.3.4/z"
            ]
        );
        assert_eq!(host("https://user@a.example:8080/x"), "a.example");
        assert_eq!(host("www.b.example"), "www.b.example");
    }

    #[test]
    fn spots_lookalike_domains() {
        assert_eq!(
            imitates_brand("paypaI-account-check.example"),
            Some("paypal")
        );
        assert_eq!(imitates_brand("amaz0n-secure.example"), Some("amazon"));
        assert_eq!(imitates_brand("paypal.com"), None);
        assert_eq!(imitates_brand("bibliotheque-ville.example"), None);
        assert!(imitates_brand("аpple.example").is_some());
    }

    #[test]
    fn the_samples_get_the_expected_verdicts() {
        for lang in Lang::ALL {
            let verdicts: Vec<Verdict> = SAMPLES
                .iter()
                .map(|s| analyze(lang.t(&s.text)).verdict)
                .collect();
            assert_eq!(
                verdicts,
                [
                    Verdict::Danger,
                    Verdict::Suspicious,
                    Verdict::Danger,
                    Verdict::Safe
                ],
                "{lang:?}"
            );
        }
    }

    #[test]
    fn an_empty_text_is_safe_with_a_low_confidence() {
        let report = analyze("");
        assert_eq!(report.verdict, Verdict::Safe);
        assert_eq!(report.confidence, 0);
        assert!(report.signals.is_empty());
    }

    #[test]
    fn keywords_match_whole_words() {
        assert!(contains_word("visit the irs today", "irs"));
        assert!(!contains_word("the first step", "irs"));
        assert!(contains_word("rib_fournisseur.pdf", "rib"));
        assert!(!contains_word("décrire", "rib"));
        assert!(contains_word("1,99 €", "€"));
        let report = analyze("First, the groups meet at https://example.org/agenda");
        assert!(report.signals.is_empty(), "{:?}", report.signals);
    }

    #[test]
    fn the_models_sharpen_the_samples() {
        let trained = Models::from_public().expect("models");
        for lang in Lang::ALL {
            let reports: Vec<Report> = SAMPLES
                .iter()
                .map(|s| analyze_with(lang.t(&s.text), Some(&trained)))
                .collect();
            assert_eq!(reports[0].verdict, Verdict::Danger, "{lang:?}");
            assert_eq!(reports[3].verdict, Verdict::Safe, "{lang:?}");
            let parcel = reports[1].model.as_ref().expect("insight");
            assert_eq!(
                parcel.category.as_ref().map(|c| c.0.as_str()),
                Some("delivery"),
                "{lang:?}"
            );
            assert!(
                reports[3]
                    .model
                    .as_ref()
                    .is_some_and(|m| m.probability < 0.5),
                "{lang:?}"
            );
        }
    }

    #[test]
    fn the_model_decides_alone_when_it_is_sure() {
        let trained = Models::from_public().expect("models");
        // No rule fires on this text: only the model sees the romance scam.
        let text = "Hello dear, I am a widow engineer working on an oil rig. I saw your profile and your smile touched me. My son is in hospital, I need you to send money by transfer for the operation, I will pay you back when I arrive.";
        let alone = analyze(text);
        let with = analyze_with(text, Some(&trained));
        assert!(
            with.score > alone.score && with.decided_by_model,
            "{with:?}"
        );
        assert!(with.verdict == Verdict::Suspicious || with.verdict == Verdict::Danger);
        let calm = analyze_with(
            "Salut, on se retrouve samedi pour le déjeuner ? Dis-moi si midi te va, je réserve une table.",
            Some(&trained),
        );
        assert!(!calm.decided_by_model && calm.verdict == Verdict::Safe);
    }

    #[test]
    fn official_links_are_not_judged_by_the_link_model() {
        let trained = Models::from_public().expect("models");
        let r = analyze_with(
            "Suivez votre colis sur https://www.laposte.fr/outils/suivre-vos-envois",
            Some(&trained),
        );
        assert!(r.links[0].official && r.links[0].model.is_none());
    }

    #[test]
    fn double_extensions_are_caught() {
        let report = analyze("Voir la facture Facture_2026.pdf.exe");
        assert!(
            report
                .signals
                .iter()
                .any(|s| s.rule == Rule::DoubleExtension)
        );
    }
}
