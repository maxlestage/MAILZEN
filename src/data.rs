//! The content of the site, in three languages (`[fr, en, es]`).

use crate::i18n::T3;

pub const BRAND: &str = "MailZen";
pub const AUTHOR: &str = "Maxime Nathan Lestage";
pub const REPO: &str = "https://github.com/maxlestage/MAILZEN";
pub const CONTACT: &str = "contact@mailzen.app";

// ----- Interactive demo --------------------------------------------------------------------

pub struct Sample {
    pub label: T3,
    pub text: T3,
}

pub const SAMPLES: [Sample; 4] = [
    Sample {
        label: ["Faux PayPal", "Fake PayPal", "PayPal falso"],
        text: [
            "De : Service Client PayPal <service@paypaI-account-check.example>\nObjet : Action requise : votre compte sera suspendu sous 24 heures\n\nBonjour,\nNous avons détecté une activité inhabituelle. Votre compte sera suspendu sous 24 heures si vous ne confirmez pas votre identité.\nConfirmez immédiatement votre mot de passe et votre carte bancaire ici :\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nService Sécurité",
            "From: PayPal Customer Service <service@paypaI-account-check.example>\nSubject: Action required: your account will be suspended within 24 hours\n\nHello,\nWe detected unusual activity. Your account will be suspended within 24 hours unless you confirm your identity.\nConfirm your password and credit card immediately here:\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nSecurity Team",
            "De: Atención al cliente PayPal <service@paypaI-account-check.example>\nAsunto: Acción requerida: su cuenta será suspendida en 24 horas\n\nHola:\nHemos detectado una actividad inusual. Su cuenta será suspendida en 24 horas si no confirma su identidad.\nConfirme inmediatamente su contraseña y su tarjeta aquí:\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nEquipo de seguridad",
        ],
    },
    Sample {
        label: ["Faux colis", "Fake parcel", "Paquete falso"],
        text: [
            "De : Livraison Colis <notification@suivi-colis-express.example>\nObjet : Votre colis est en attente\n\nVotre colis n’a pas pu être livré. Des frais de réexpédition de 1,99 € sont à régler avant ce soir, sinon il sera renvoyé.\nRéglez ici : https://bit.ly/colis-2026\nVous pouvez aussi scanner le QR code joint.",
            "From: Parcel Delivery <notification@parcel-tracking-express.example>\nSubject: Your parcel is on hold\n\nYour parcel could not be delivered. A redelivery fee of $1.99 must be paid tonight, or it will be returned to sender.\nPay here: https://bit.ly/parcel-2026\nYou can also scan the attached QR code.",
            "De: Entrega de paquetes <notification@seguimiento-paquete-express.example>\nAsunto: Su paquete está retenido\n\nSu paquete no pudo entregarse. Debe pagar una tasa de reenvío de 1,99 € esta noche o será devuelto.\nPague aquí: https://bit.ly/paquete-2026\nTambién puede escanear el código QR adjunto.",
        ],
    },
    Sample {
        label: ["Fraude au président", "CEO fraud", "Fraude del CEO"],
        text: [
            "De : Direction Générale <direction.generale@gmail.example>\nObjet : Urgent et confidentiel\n\nJe suis en réunion et injoignable. J’ai besoin que tu fasses un virement de 4 800 € à notre nouveau fournisseur, immédiatement.\nNe parle de cette opération à personne, c’est confidentiel.\nLe nouveau RIB est en pièce jointe : RIB_fournisseur.pdf.exe",
            "From: CEO Office <ceo.office@gmail.example>\nSubject: Urgent and confidential\n\nI am in a meeting and cannot be reached. I need you to make a wire transfer of $4,800 to our new supplier, immediately.\nDo not tell anyone about this, it is confidential.\nThe new bank details are attached: bank_details.pdf.exe",
            "De: Dirección General <direccion.general@gmail.example>\nAsunto: Urgente y confidencial\n\nEstoy en una reunión y no puedo hablar. Necesito que hagas una transferencia de 4.800 € a nuestro nuevo proveedor, inmediatamente.\nNo se lo cuentes a nadie, es confidencial.\nLos nuevos datos bancarios van adjuntos: datos_proveedor.pdf.exe",
        ],
    },
    Sample {
        label: ["Newsletter", "Newsletter", "Boletín"],
        text: [
            "De : Bibliothèque municipale <contact@bibliotheque-ville.example>\nObjet : Programme des ateliers de décembre\n\nBonjour,\nVoici le programme des ateliers du mois : lecture, numérique et jeux de société.\nLe détail est disponible sur notre site : https://bibliotheque-ville.example/ateliers\nBonne journée !",
            "From: City Library <contact@city-library.example>\nSubject: December workshop schedule\n\nHello,\nHere is this month’s workshop schedule: reading, digital skills and board games.\nDetails are on our website: https://city-library.example/workshops\nHave a nice day!",
            "De: Biblioteca municipal <contacto@biblioteca-ciudad.example>\nAsunto: Programa de talleres de diciembre\n\nHola:\nEste es el programa de talleres del mes: lectura, competencias digitales y juegos de mesa.\nLos detalles están en nuestra web: https://biblioteca-ciudad.example/talleres\n¡Buen día!",
        ],
    },
];

// ----- Modules -----------------------------------------------------------------------------

pub struct Module {
    pub id: &'static str,
    pub icon: &'static str,
    pub name: &'static str,
    pub tag: T3,
    pub text: T3,
}

pub const MODULES: [Module; 7] = [
    Module {
        id: "scanner",
        icon: "mail",
        name: "Mail Scanner",
        tag: ["Le cœur", "The core", "El núcleo"],
        text: [
            "Analyse complète d’un email en quelques secondes, sans créer de compte : expéditeur, contenu, liens, pièces jointes.",
            "A complete analysis of an email in seconds, without an account: sender, content, links, attachments.",
            "Análisis completo de un correo en segundos, sin crear cuenta: remitente, contenido, enlaces y adjuntos.",
        ],
    },
    Module {
        id: "links",
        icon: "link",
        name: "Link Guard",
        tag: ["Liens", "Links", "Enlaces"],
        text: [
            "Chaque URL est décortiquée : domaine réel, redirections, raccourcisseurs, typosquatting, réputation.",
            "Every URL is taken apart: real domain, redirects, shorteners, typosquatting, reputation.",
            "Cada URL se descompone: dominio real, redirecciones, acortadores, typosquatting y reputación.",
        ],
    },
    Module {
        id: "files",
        icon: "file",
        name: "Attachment Guard",
        tag: ["Fichiers", "Files", "Archivos"],
        text: [
            "PDF, Office, archives, HTML, SVG : type réel, macros, scripts, doubles extensions et bombes ZIP.",
            "PDF, Office, archives, HTML, SVG: real type, macros, scripts, double extensions and ZIP bombs.",
            "PDF, Office, archivos comprimidos, HTML, SVG: tipo real, macros, scripts, dobles extensiones y bombas ZIP.",
        ],
    },
    Module {
        id: "screens",
        icon: "camera",
        name: "ScreenScan",
        tag: ["Captures", "Screenshots", "Capturas"],
        text: [
            "Une capture d’écran suffit : OCR, liens visibles, numéros, demandes de paiement et QR codes.",
            "A screenshot is enough: OCR, visible links, phone numbers, payment requests and QR codes.",
            "Basta una captura de pantalla: OCR, enlaces visibles, números, peticiones de pago y códigos QR.",
        ],
    },
    Module {
        id: "qr",
        icon: "qr",
        name: "QR Guard",
        tag: ["QR codes", "QR codes", "Códigos QR"],
        text: [
            "La destination s’affiche avant toute ouverture. Un QR code n’est jamais ouvert automatiquement.",
            "The destination is shown before anything opens. A QR code is never opened automatically.",
            "El destino se muestra antes de abrir nada. Un código QR nunca se abre automáticamente.",
        ],
    },
    Module {
        id: "zenai",
        icon: "spark",
        name: "ZenAI",
        tag: ["Assistant", "Assistant", "Asistente"],
        text: [
            "Un assistant relié aux résultats de l’analyse, qui explique, rassure et conseille sans culpabiliser.",
            "An assistant connected to the analysis results, which explains, reassures and advises without blame.",
            "Un asistente conectado a los resultados del análisis que explica, tranquiliza y aconseja sin culpabilizar.",
        ],
    },
    Module {
        id: "sos",
        icon: "lifebuoy",
        name: "SOS Cyber",
        tag: ["Assistance", "Assistance", "Asistencia"],
        text: [
            "Déjà cliqué ? MailZen ne vous abandonne pas : des étapes claires selon ce qui s’est passé.",
            "Already clicked? MailZen does not leave you alone: clear steps depending on what happened.",
            "¿Ya has hecho clic? MailZen no te deja solo: pasos claros según lo que haya pasado.",
        ],
    },
];

/// The ways to submit a message.
pub const IMPORTS: [T3; 10] = [
    ["Coller un email", "Paste an email", "Pegar un correo"],
    ["Fichier .eml", ".eml file", "Archivo .eml"],
    ["Fichier .msg", ".msg file", "Archivo .msg"],
    ["PDF d’un email", "PDF of an email", "PDF de un correo"],
    ["Capture d’écran", "Screenshot", "Captura de pantalla"],
    [
        "Partage depuis la messagerie",
        "Share from your mail app",
        "Compartir desde el correo",
    ],
    ["Partage de texte", "Share text", "Compartir texto"],
    ["Pièce jointe seule", "Attachment alone", "Adjunto suelto"],
    ["URL directe", "Direct URL", "URL directa"],
    ["QR code", "QR code", "Código QR"],
];

pub struct Step {
    pub icon: &'static str,
    pub title: T3,
    pub text: T3,
}

pub const STEPS: [Step; 5] = [
    Step {
        icon: "upload",
        title: [
            "Importer le message",
            "Import the message",
            "Importar el mensaje",
        ],
        text: [
            "Texte, email, capture ou fichier.",
            "Text, email, screenshot or file.",
            "Texto, correo, captura o archivo.",
        ],
    },
    Step {
        icon: "layers",
        title: [
            "Extraction des informations",
            "Information extraction",
            "Extracción de la información",
        ],
        text: [
            "Expéditeur, liens, contenu, fichiers et métadonnées.",
            "Sender, links, content, files and metadata.",
            "Remitente, enlaces, contenido, archivos y metadatos.",
        ],
    },
    Step {
        icon: "radar",
        title: [
            "Détection des menaces",
            "Threat detection",
            "Detección de amenazas",
        ],
        text: [
            "Analyse technique, réputation et signaux comportementaux.",
            "Technical analysis, reputation and behavioral signals.",
            "Análisis técnico, reputación y señales de comportamiento.",
        ],
    },
    Step {
        icon: "brain",
        title: [
            "Analyse contextuelle",
            "Contextual analysis",
            "Análisis contextual",
        ],
        text: [
            "Classification, compréhension et explication.",
            "Classification, understanding and explanation.",
            "Clasificación, comprensión y explicación.",
        ],
    },
    Step {
        icon: "report",
        title: [
            "Rapport de sécurité",
            "Security report",
            "Informe de seguridad",
        ],
        text: [
            "Verdict, risques, preuves et actions.",
            "Verdict, risks, evidence and actions.",
            "Veredicto, riesgos, pruebas y acciones.",
        ],
    },
];

/// What a detailed report contains.
pub const REPORT_ITEMS: [T3; 20] = [
    ["Verdict global", "Overall verdict", "Veredicto global"],
    ["Score de risque", "Risk score", "Puntuación de riesgo"],
    [
        "Niveau de confiance",
        "Confidence level",
        "Nivel de confianza",
    ],
    ["Résumé de l’email", "Email summary", "Resumen del correo"],
    [
        "Identité de l’expéditeur",
        "Sender identity",
        "Identidad del remitente",
    ],
    ["Adresse email", "Email address", "Dirección de correo"],
    ["Domaine", "Domain", "Dominio"],
    ["Objet", "Subject", "Asunto"],
    ["Contenu", "Content", "Contenido"],
    ["Liens", "Links", "Enlaces"],
    ["Pièces jointes", "Attachments", "Adjuntos"],
    ["Manipulation", "Manipulation", "Manipulación"],
    ["Usurpation", "Impersonation", "Suplantación"],
    ["Fraude financière", "Financial fraud", "Fraude financiero"],
    ["Données personnelles", "Personal data", "Datos personales"],
    [
        "Signaux techniques",
        "Technical signals",
        "Señales técnicas",
    ],
    ["Réputation", "Reputation", "Reputación"],
    [
        "Risques potentiels",
        "Potential risks",
        "Riesgos potenciales",
    ],
    ["Explications", "Explanations", "Explicaciones"],
    [
        "Recommandations immédiates",
        "Immediate recommendations",
        "Recomendaciones inmediatas",
    ],
];

/// The four verdicts, with their descriptions (the classes match `engine::Verdict`).
pub const VERDICTS: [(&str, T3, T3); 4] = [
    (
        "safe",
        [
            "Aucun risque notable détecté",
            "No notable risk detected",
            "Ningún riesgo notable",
        ],
        [
            "Les contrôles n’ont pas relevé de signal important. Cela ne garantit pas l’innocuité.",
            "The checks found no significant signal. This does not guarantee it is harmless.",
            "Los controles no detectaron señales importantes. Eso no garantiza que sea inofensivo.",
        ],
    ),
    (
        "caution",
        ["Vigilance", "Caution", "Precaución"],
        [
            "Quelques anomalies ou éléments à vérifier.",
            "A few anomalies or things to check.",
            "Algunas anomalías o elementos que verificar.",
        ],
    ),
    (
        "suspicious",
        ["Suspect", "Suspicious", "Sospechoso"],
        [
            "Plusieurs indicateurs inquiétants.",
            "Several worrying indicators.",
            "Varios indicadores preocupantes.",
        ],
    ),
    (
        "danger",
        ["Danger élevé", "High danger", "Peligro elevado"],
        [
            "Des éléments sérieux indiquent un risque de fraude ou d’attaque.",
            "Serious elements point to a risk of fraud or attack.",
            "Elementos serios indican un riesgo de fraude o ataque.",
        ],
    ),
];

// ----- Sender, links, files --------------------------------------------------------------

pub const SENDER_CHECKS: [T3; 14] = [
    ["Nom affiché", "Display name", "Nombre mostrado"],
    ["Adresse réelle", "Real address", "Dirección real"],
    ["Sous-domaines", "Subdomains", "Subdominios"],
    [
        "Adresse de réponse",
        "Reply-to address",
        "Dirección de respuesta",
    ],
    ["Nom ↔ domaine", "Name ↔ domain", "Nombre ↔ dominio"],
    [
        "Domaines ressemblants",
        "Lookalike domains",
        "Dominios parecidos",
    ],
    ["Unicode trompeur", "Deceptive Unicode", "Unicode engañoso"],
    ["Typosquatting", "Typosquatting", "Typosquatting"],
    ["Homographes", "Homographs", "Homógrafos"],
    ["Domaines récents", "Recent domains", "Dominios recientes"],
    ["SPF", "SPF", "SPF"],
    ["DKIM", "DKIM", "DKIM"],
    ["DMARC", "DMARC", "DMARC"],
    [
        "Indices de spoofing",
        "Spoofing hints",
        "Indicios de spoofing",
    ],
];

pub const BRAND_KINDS: [T3; 12] = [
    ["Banque", "Bank", "Banco"],
    ["Assurance", "Insurance", "Seguros"],
    ["Administration", "Government", "Administración"],
    ["Énergie", "Energy", "Energía"],
    ["Opérateur", "Carrier", "Operador"],
    ["Livraison", "Delivery", "Mensajería"],
    ["Commerce", "Retail", "Comercio"],
    ["Paiement", "Payments", "Pagos"],
    ["Réseau social", "Social network", "Red social"],
    ["Cloud", "Cloud", "Nube"],
    ["Entreprise", "Company", "Empresa"],
    ["Employeur", "Employer", "Empleador"],
];

pub const LINK_CHECKS: [T3; 16] = [
    [
        "Extraction automatique",
        "Automatic extraction",
        "Extracción automática",
    ],
    [
        "Domaine et sous-domaine",
        "Domain and subdomain",
        "Dominio y subdominio",
    ],
    ["URL réelle", "Real URL", "URL real"],
    ["Typosquatting", "Typosquatting", "Typosquatting"],
    ["Unicode trompeur", "Deceptive Unicode", "Unicode engañoso"],
    ["Liens raccourcis", "Short links", "Enlaces acortados"],
    ["Redirections", "Redirects", "Redirecciones"],
    ["Paramètres", "Parameters", "Parámetros"],
    [
        "Caractères encodés",
        "Encoded characters",
        "Caracteres codificados",
    ],
    ["Réputation", "Reputation", "Reputación"],
    ["Phishing connu", "Known phishing", "Phishing conocido"],
    ["Malwares", "Malware", "Malware"],
    ["Certificats TLS", "TLS certificates", "Certificados TLS"],
    [
        "Formulaires de collecte",
        "Data-harvesting forms",
        "Formularios de captura",
    ],
    ["URL vers une IP", "URL to an IP", "URL a una IP"],
    [
        "URL anormalement longues",
        "Abnormally long URLs",
        "URL anormalmente largas",
    ],
];

pub const SANDBOX: [T3; 11] = [
    [
        "Navigation sandbox",
        "Sandboxed browsing",
        "Navegación aislada",
    ],
    [
        "Isolation réseau",
        "Network isolation",
        "Aislamiento de red",
    ],
    [
        "Redirections limitées",
        "Limited redirects",
        "Redirecciones limitadas",
    ],
    [
        "Téléchargements limités",
        "Limited downloads",
        "Descargas limitadas",
    ],
    [
        "Scripts restreints",
        "Restricted scripts",
        "Scripts restringidos",
    ],
    [
        "Anti-exploits",
        "Exploit protection",
        "Protección anti-exploits",
    ],
    ["Anti-SSRF", "SSRF protection", "Protección SSRF"],
    ["Pas d’URL internes", "No internal URLs", "Sin URL internas"],
    ["Timeouts", "Timeouts", "Tiempos límite"],
    ["Taille limitée", "Size limits", "Tamaño limitado"],
    ["Anti-boucles", "Loop protection", "Anti-bucles"],
];

pub const FORMATS: [(&str, T3); 16] = [
    (
        "PDF",
        [
            "Métadonnées, liens, structures",
            "Metadata, links, structures",
            "Metadatos, enlaces, estructuras",
        ],
    ),
    (
        "DOCX",
        [
            "Liens, contenu intégré",
            "Links, embedded content",
            "Enlaces, contenido incrustado",
        ],
    ),
    (
        "XLSX",
        [
            "Formules, liens externes",
            "Formulas, external links",
            "Fórmulas, enlaces externos",
        ],
    ),
    (
        "PPTX",
        [
            "Liens et contenu intégré",
            "Links and embedded content",
            "Enlaces y contenido incrustado",
        ],
    ),
    (
        "DOC",
        [
            "Structures dangereuses",
            "Dangerous structures",
            "Estructuras peligrosas",
        ],
    ),
    (
        "XLS",
        [
            "Structures, macros, liens",
            "Structures, macros, links",
            "Estructuras, macros, enlaces",
        ],
    ),
    (
        "PPT",
        [
            "Structures, contenu intégré",
            "Structures, embedded content",
            "Estructuras, contenido incrustado",
        ],
    ),
    (
        "ZIP",
        [
            "Contenu des archives",
            "Archive contents",
            "Contenido de archivos",
        ],
    ),
    (
        "RAR",
        [
            "Contenu, si pris en charge",
            "Contents, if supported",
            "Contenido, si es compatible",
        ],
    ),
    (
        "7Z",
        [
            "Contenu, si pris en charge",
            "Contents, if supported",
            "Contenido, si es compatible",
        ],
    ),
    (
        "HTML",
        [
            "Scripts, formulaires, redirections",
            "Scripts, forms, redirects",
            "Scripts, formularios, redirecciones",
        ],
    ),
    (
        "TXT",
        ["Analyse textuelle", "Text analysis", "Análisis de texto"],
    ),
    (
        "EML",
        [
            "Parsing de messages",
            "Message parsing",
            "Análisis de mensajes",
        ],
    ),
    (
        "CSV",
        [
            "Formules malveillantes",
            "Malicious formulas",
            "Fórmulas maliciosas",
        ],
    ),
    (
        "SVG",
        [
            "Scripts, références externes",
            "Scripts, external references",
            "Scripts, referencias externas",
        ],
    ),
    (
        "IMG",
        [
            "OCR, QR codes, contenu trompeur",
            "OCR, QR codes, deceptive content",
            "OCR, QR, contenido engañoso",
        ],
    ),
];

pub const FILE_CHECKS: [T3; 18] = [
    ["Extension", "Extension", "Extensión"],
    ["Type réel", "Real type", "Tipo real"],
    ["Signature binaire", "Binary signature", "Firma binaria"],
    ["Métadonnées", "Metadata", "Metadatos"],
    ["Fichiers imbriqués", "Nested files", "Archivos anidados"],
    [
        "Contenu intégré",
        "Embedded content",
        "Contenido incrustado",
    ],
    ["Liens", "Links", "Enlaces"],
    ["Macros", "Macros", "Macros"],
    ["Scripts", "Scripts", "Scripts"],
    [
        "Structures anormales",
        "Abnormal structures",
        "Estructuras anómalas",
    ],
    [
        "Indicateurs de malware",
        "Malware indicators",
        "Indicadores de malware",
    ],
    ["Réputation", "Reputation", "Reputación"],
    ["Hash SHA-256", "SHA-256 hash", "Hash SHA-256"],
    ["Fichiers cachés", "Hidden files", "Archivos ocultos"],
    [
        "Doubles extensions",
        "Double extensions",
        "Dobles extensiones",
    ],
    ["Limites de taille", "Size limits", "Límites de tamaño"],
    [
        "Limites de décompression",
        "Decompression limits",
        "Límites de descompresión",
    ],
    ["Anti-bombes ZIP", "ZIP bomb protection", "Anti-bombas ZIP"],
];

pub const SCREEN_TYPES: [T3; 12] = [
    ["Gmail", "Gmail", "Gmail"],
    ["Apple Mail", "Apple Mail", "Apple Mail"],
    ["Outlook", "Outlook", "Outlook"],
    ["SMS", "SMS", "SMS"],
    ["WhatsApp", "WhatsApp", "WhatsApp"],
    ["Messages", "Messages", "Mensajes"],
    ["Notifications", "Notifications", "Notificaciones"],
    ["Pages web", "Web pages", "Páginas web"],
    ["Factures", "Invoices", "Facturas"],
    [
        "Faux avis de paiement",
        "Fake payment notices",
        "Avisos de pago falsos",
    ],
    ["QR codes", "QR codes", "Códigos QR"],
    ["Faux documents", "Fake documents", "Documentos falsos"],
];

pub const QR_PLACES: [T3; 7] = [
    ["Emails", "Emails", "Correos"],
    ["Documents", "Documents", "Documentos"],
    ["Factures", "Invoices", "Facturas"],
    ["Captures", "Screenshots", "Capturas"],
    ["Affiches", "Posters", "Carteles"],
    ["Colis", "Parcels", "Paquetes"],
    ["Pages web", "Web pages", "Páginas web"],
];

// ----- ZenAI -------------------------------------------------------------------------------

pub const ZENAI_CAN: [T3; 15] = [
    [
        "Expliquer un email",
        "Explain an email",
        "Explicar un correo",
    ],
    [
        "Expliquer un score",
        "Explain a score",
        "Explicar una puntuación",
    ],
    ["Expliquer une URL", "Explain a URL", "Explicar una URL"],
    [
        "Expliquer une pièce jointe",
        "Explain an attachment",
        "Explicar un adjunto",
    ],
    [
        "Répondre à une question",
        "Answer a question",
        "Responder a una pregunta",
    ],
    [
        "Simplifier un message",
        "Simplify a message",
        "Simplificar un mensaje",
    ],
    [
        "Repérer la manipulation",
        "Spot manipulation",
        "Detectar la manipulación",
    ],
    ["Donner des conseils", "Give advice", "Dar consejos"],
    [
        "Guider après un clic",
        "Guide after a click",
        "Guiar tras un clic",
    ],
    [
        "Guider après un vol de données",
        "Guide after a data theft",
        "Guiar tras un robo de datos",
    ],
    [
        "Guider après une fraude bancaire",
        "Guide after bank fraud",
        "Guiar tras un fraude bancario",
    ],
    ["Aider à signaler", "Help to report", "Ayudar a denunciar"],
    [
        "Trouver les incohérences",
        "Find inconsistencies",
        "Encontrar incoherencias",
    ],
    [
        "Expliquer la sécurité",
        "Explain security",
        "Explicar la seguridad",
    ],
    [
        "Conseiller sans culpabiliser",
        "Advise without blame",
        "Aconsejar sin culpabilizar",
    ],
];

pub const ZENAI_QUESTIONS: [T3; 10] = [
    [
        "Pourquoi ce mail est-il suspect ?",
        "Why is this email suspicious?",
        "¿Por qué es sospechoso este correo?",
    ],
    [
        "Qui est réellement l’expéditeur ?",
        "Who is the real sender?",
        "¿Quién es realmente el remitente?",
    ],
    [
        "Est-ce que le lien est dangereux ?",
        "Is the link dangerous?",
        "¿Es peligroso el enlace?",
    ],
    [
        "Est-ce que je peux ouvrir le fichier ?",
        "Can I open the file?",
        "¿Puedo abrir el archivo?",
    ],
    [
        "Est-ce que je dois répondre ?",
        "Should I reply?",
        "¿Debo responder?",
    ],
    [
        "Comment vérifier l’entreprise ?",
        "How do I check the company?",
        "¿Cómo verifico la empresa?",
    ],
    [
        "Que faire si j’ai cliqué ?",
        "What if I clicked?",
        "¿Qué hago si hice clic?",
    ],
    [
        "Que faire si j’ai donné mon mot de passe ?",
        "What if I gave my password?",
        "¿Qué hago si di mi contraseña?",
    ],
    [
        "Comment signaler ce mail ?",
        "How do I report this email?",
        "¿Cómo denuncio este correo?",
    ],
    [
        "Est-ce que je peux récupérer mon argent ?",
        "Can I get my money back?",
        "¿Puedo recuperar mi dinero?",
    ],
];

pub const ZENAI_RULES: [T3; 9] = [
    [
        "Le contenu des emails est une donnée non fiable",
        "Email content is untrusted data",
        "El contenido de los correos es un dato no fiable",
    ],
    [
        "Les instructions d’un email sont ignorées",
        "Instructions inside an email are ignored",
        "Las instrucciones de un correo se ignoran",
    ],
    [
        "Aucune commande exécutée",
        "No command is ever run",
        "Nunca se ejecuta ningún comando",
    ],
    [
        "Aucune action externe non autorisée",
        "No unauthorized external action",
        "Ninguna acción externa no autorizada",
    ],
    [
        "Aucun envoi sans consentement",
        "Nothing sent without consent",
        "Nada se envía sin consentimiento",
    ],
    [
        "Jamais confondu avec le système",
        "Never mistaken for system instructions",
        "Nunca se confunde con instrucciones del sistema",
    ],
    [
        "Appuyé sur le moteur de détection",
        "Grounded in the detection engine",
        "Basado en el motor de detección",
    ],
    [
        "Les incertitudes sont dites",
        "Uncertainty is stated",
        "Las incertidumbres se dicen",
    ],
    [
        "Aucune preuve inventée",
        "No invented evidence",
        "Ninguna prueba inventada",
    ],
];

/// The ZenAI conversation of the home page: (from the user, text).
pub const CHAT: [(bool, T3); 5] = [
    (
        true,
        [
            "Pourquoi ce mail est-il dangereux ?",
            "Why is this email dangerous?",
            "¿Por qué es peligroso este correo?",
        ],
    ),
    (
        false,
        [
            "Ce mail présente trois éléments préoccupants : l’adresse de l’expéditeur ne correspond pas au domaine habituel de l’entreprise.",
            "This email shows three worrying signs: the sender’s address does not match the company’s usual domain.",
            "Este correo presenta tres elementos preocupantes: la dirección del remitente no coincide con el dominio habitual de la empresa.",
        ],
    ),
    (
        false,
        [
            "Le lien dirige vers un domaine différent de celui annoncé, et le message vous pousse à agir vite en menaçant de bloquer votre compte.",
            "The link goes to a different domain than the one announced, and the message rushes you by threatening to block your account.",
            "El enlace lleva a un dominio distinto del anunciado y el mensaje te apura amenazando con bloquear tu cuenta.",
        ],
    ),
    (
        false,
        [
            "Je vous conseille de ne pas cliquer. Pour vérifier votre compte, ouvrez directement l’application officielle.",
            "I advise you not to click. To check your account, open the official app directly.",
            "Te aconsejo no hacer clic. Para comprobar tu cuenta, abre directamente la aplicación oficial.",
        ],
    ),
    (
        true,
        [
            "Et si j’ai déjà cliqué ?",
            "And if I already clicked?",
            "¿Y si ya hice clic?",
        ],
    ),
];

// ----- Manipulation and scams ------------------------------------------------------------

pub const TECHNIQUES: [(&str, T3, T3); 12] = [
    (
        "clock",
        ["Urgence", "Urgency", "Urgencia"],
        [
            "« Vous avez 24 heures »",
            "“You have 24 hours”",
            "«Tiene 24 horas»",
        ],
    ),
    (
        "alert",
        ["Peur", "Fear", "Miedo"],
        [
            "« Votre compte est compromis »",
            "“Your account is compromised”",
            "«Su cuenta está comprometida»",
        ],
    ),
    (
        "crown",
        ["Autorité", "Authority", "Autoridad"],
        [
            "« Message officiel du gouvernement »",
            "“Official government message”",
            "«Mensaje oficial del gobierno»",
        ],
    ),
    (
        "bolt",
        ["Pression", "Pressure", "Presión"],
        [
            "« Vous devez agir maintenant »",
            "“You must act now”",
            "«Debe actuar ahora»",
        ],
    ),
    (
        "lock",
        ["Secret", "Secrecy", "Secreto"],
        [
            "« N’en parlez à personne »",
            "“Tell no one about this”",
            "«No se lo cuente a nadie»",
        ],
    ),
    (
        "gift",
        ["Récompense", "Reward", "Recompensa"],
        [
            "« Vous avez gagné 5 000 € »",
            "“You have won $5,000”",
            "«Ha ganado 5.000 €»",
        ],
    ),
    (
        "eye",
        ["Curiosité", "Curiosity", "Curiosidad"],
        [
            "« Consultez votre dossier »",
            "“See your file”",
            "«Consulte su expediente»",
        ],
    ),
    (
        "ban",
        ["Menace", "Threat", "Amenaza"],
        [
            "« Votre compte sera fermé »",
            "“Your account will be closed”",
            "«Su cuenta será cerrada»",
        ],
    ),
    (
        "coin",
        [
            "Manipulation financière",
            "Financial manipulation",
            "Manipulación financiera",
        ],
        [
            "« Envoyez le virement »",
            "“Send the transfer”",
            "«Envíe la transferencia»",
        ],
    ),
    (
        "heart",
        [
            "Manipulation affective",
            "Emotional manipulation",
            "Manipulación afectiva",
        ],
        [
            "Une relation de confiance exploitée",
            "A trusted relationship exploited",
            "Una relación de confianza explotada",
        ],
    ),
    (
        "mask",
        ["Impersonation", "Impersonation", "Suplantación"],
        [
            "Un proche ou un supérieur imité",
            "A relative or a boss imitated",
            "Un familiar o un jefe imitado",
        ],
    ),
    (
        "maze",
        ["Confusion", "Confusion", "Confusión"],
        [
            "Des consignes ambiguës",
            "Ambiguous instructions",
            "Instrucciones ambiguas",
        ],
    ),
];

pub struct Category {
    pub icon: &'static str,
    pub title: T3,
    pub text: T3,
}

pub const CATEGORIES: [Category; 6] = [
    Category {
        icon: "bank",
        title: ["Banques", "Banks", "Bancos"],
        text: [
            "Faux remboursements, faux paiements, fausses alertes.",
            "Fake refunds, fake payments, fake alerts.",
            "Reembolsos, pagos y alertas falsos.",
        ],
    },
    Category {
        icon: "parcel",
        title: ["Livraisons", "Deliveries", "Envíos"],
        text: [
            "Faux colis, douanes, frais et relivraisons.",
            "Fake parcels, customs, fees and redeliveries.",
            "Paquetes falsos, aduanas, tasas y reenvíos.",
        ],
    },
    Category {
        icon: "gov",
        title: ["Administrations", "Government", "Administraciones"],
        text: [
            "Faux impôts, organismes et documents administratifs.",
            "Fake taxes, agencies and official documents.",
            "Impuestos, organismos y documentos falsos.",
        ],
    },
    Category {
        icon: "briefcase",
        title: ["Entreprises", "Companies", "Empresas"],
        text: [
            "Fraude au président, au fournisseur et à l’employeur.",
            "CEO, supplier and employer fraud.",
            "Fraude del CEO, del proveedor y del empleador.",
        ],
    },
    Category {
        icon: "chart",
        title: ["Finances", "Finance", "Finanzas"],
        text: [
            "Virements, investissements, crypto et gains fictifs.",
            "Transfers, investments, crypto and fake gains.",
            "Transferencias, inversiones, cripto y ganancias falsas.",
        ],
    },
    Category {
        icon: "heart",
        title: ["Sentimentales", "Romance", "Sentimentales"],
        text: [
            "Manipulation affective et demandes d’argent.",
            "Emotional manipulation and requests for money.",
            "Manipulación afectiva y peticiones de dinero.",
        ],
    },
];

pub const SCAMS: [T3; 39] = [
    ["Phishing", "Phishing", "Phishing"],
    ["Spear phishing", "Spear phishing", "Spear phishing"],
    ["Whaling", "Whaling", "Whaling"],
    ["Fraude au président", "CEO fraud", "Fraude del CEO"],
    ["Faux support", "Fake support", "Soporte falso"],
    ["Faux remboursements", "Fake refunds", "Reembolsos falsos"],
    ["Faux colis", "Fake parcels", "Paquetes falsos"],
    ["Faux impôts", "Fake taxes", "Impuestos falsos"],
    [
        "Faux documents administratifs",
        "Fake official documents",
        "Documentos oficiales falsos",
    ],
    [
        "Faux recrutements",
        "Fake job offers",
        "Ofertas de empleo falsas",
    ],
    [
        "Fraude aux fournisseurs",
        "Supplier fraud",
        "Fraude de proveedores",
    ],
    ["Faux RIB", "Fake bank details", "Datos bancarios falsos"],
    [
        "Fraude au virement",
        "Wire fraud",
        "Fraude de transferencia",
    ],
    ["Arnaques crypto", "Crypto scams", "Estafas cripto"],
    [
        "Faux investissements",
        "Fake investments",
        "Inversiones falsas",
    ],
    ["Faux cadeaux", "Fake gifts", "Regalos falsos"],
    ["Faux concours", "Fake contests", "Concursos falsos"],
    [
        "Faux abonnements",
        "Fake subscriptions",
        "Suscripciones falsas",
    ],
    [
        "Arnaques sentimentales",
        "Romance scams",
        "Estafas románticas",
    ],
    ["Chantage", "Blackmail", "Chantaje"],
    ["Sextorsion", "Sextortion", "Sextorsión"],
    ["Faux antivirus", "Fake antivirus", "Antivirus falsos"],
    [
        "Faux support technique",
        "Tech support scams",
        "Soporte técnico falso",
    ],
    [
        "Fraude aux QR codes",
        "QR code fraud",
        "Fraude con códigos QR",
    ],
    [
        "Faux avis de paiement",
        "Fake payment notices",
        "Avisos de pago falsos",
    ],
    [
        "Faux récupérateurs de fonds",
        "Fake fund recovery",
        "Falsa recuperación de fondos",
    ],
    [
        "Faux messages de sécurité",
        "Fake security messages",
        "Mensajes de seguridad falsos",
    ],
    [
        "Faux comptes sociaux",
        "Fake social accounts",
        "Cuentas sociales falsas",
    ],
    ["Faux cloud", "Fake cloud", "Nube falsa"],
    ["Faux hébergements", "Fake rentals", "Alojamientos falsos"],
    ["Faux billets", "Fake tickets", "Entradas falsas"],
    [
        "Faux marketplaces",
        "Fake marketplaces",
        "Marketplaces falsos",
    ],
    ["Fraude à la vente", "Sales fraud", "Fraude en la venta"],
    ["Fraude à l’achat", "Purchase fraud", "Fraude en la compra"],
    ["Faux documents", "Fake documents", "Documentos falsos"],
    ["Malwares", "Malware", "Malware"],
    ["Ransomware", "Ransomware", "Ransomware"],
    [
        "Collecte de données",
        "Data harvesting",
        "Recolección de datos",
    ],
    [
        "Arnaques à l’identité",
        "Identity scams",
        "Estafas de identidad",
    ],
];

// ----- SOS Cyber ---------------------------------------------------------------------------

pub struct Scenario {
    pub icon: &'static str,
    pub title: T3,
    pub steps: &'static [T3],
}

pub const SCENARIOS: [Scenario; 11] = [
    Scenario {
        icon: "cursor",
        title: [
            "J’ai cliqué sur un lien",
            "I clicked a link",
            "Hice clic en un enlace",
        ],
        steps: &[
            ["Fermez la page.", "Close the page.", "Cierra la página."],
            [
                "Ne saisissez plus aucune donnée.",
                "Do not enter any more data.",
                "No introduzcas más datos.",
            ],
            [
                "Identifiez ce qui a été communiqué ou téléchargé.",
                "Work out what was shared or downloaded.",
                "Identifica lo que se compartió o descargó.",
            ],
            [
                "Vérifiez si un fichier a été ouvert.",
                "Check whether a file was opened.",
                "Comprueba si se abrió algún archivo.",
            ],
            [
                "Adaptez les actions selon les circonstances, avec MailZen.",
                "Adapt the next steps to the situation, with MailZen.",
                "Adapta los pasos a la situación, con MailZen.",
            ],
        ],
    },
    Scenario {
        icon: "download",
        title: [
            "J’ai téléchargé un fichier",
            "I downloaded a file",
            "Descargué un archivo",
        ],
        steps: &[
            [
                "N’ouvrez pas le fichier.",
                "Do not open the file.",
                "No abras el archivo.",
            ],
            [
                "Analysez-le avec Attachment Guard.",
                "Analyze it with Attachment Guard.",
                "Analízalo con Attachment Guard.",
            ],
            [
                "Supprimez-le s’il est suspect, puis videz la corbeille.",
                "Delete it if it is suspicious, then empty the trash.",
                "Bórralo si es sospechoso y vacía la papelera.",
            ],
            [
                "Gardez une trace de l’email d’origine.",
                "Keep a record of the original email.",
                "Guarda una copia del correo original.",
            ],
        ],
    },
    Scenario {
        icon: "file",
        title: [
            "J’ai ouvert une pièce jointe",
            "I opened an attachment",
            "Abrí un adjunto",
        ],
        steps: &[
            [
                "N’activez ni macros ni contenu.",
                "Do not enable macros or content.",
                "No habilites macros ni contenido.",
            ],
            [
                "Déconnectez l’appareil du réseau si un comportement anormal apparaît.",
                "Disconnect the device from the network if it behaves strangely.",
                "Desconecta el dispositivo de la red si se comporta de forma extraña.",
            ],
            [
                "Évaluez le risque selon le type de fichier et l’appareil.",
                "Assess the risk based on the file type and the device.",
                "Evalúa el riesgo según el tipo de archivo y el dispositivo.",
            ],
            [
                "Faites-vous aider si un logiciel a pu s’installer.",
                "Get help if software may have been installed.",
                "Pide ayuda si se pudo instalar algún programa.",
            ],
        ],
    },
    Scenario {
        icon: "key",
        title: [
            "J’ai donné mon mot de passe",
            "I gave my password",
            "Di mi contraseña",
        ],
        steps: &[
            [
                "Changez immédiatement le mot de passe depuis le service officiel.",
                "Change the password right away on the official service.",
                "Cambia la contraseña de inmediato en el servicio oficial.",
            ],
            [
                "Changez-le partout où il est réutilisé.",
                "Change it everywhere it is reused.",
                "Cámbiala allí donde la reutilices.",
            ],
            [
                "Révoquez les sessions ouvertes.",
                "Revoke open sessions.",
                "Cierra las sesiones abiertas.",
            ],
            [
                "Activez l’authentification multifacteur.",
                "Turn on multi-factor authentication.",
                "Activa la autenticación multifactor.",
            ],
            [
                "Vérifiez les méthodes de récupération.",
                "Check the recovery methods.",
                "Revisa los métodos de recuperación.",
            ],
            [
                "Vérifiez les règles de transfert de la messagerie.",
                "Check the mail forwarding rules.",
                "Revisa las reglas de reenvío del correo.",
            ],
            [
                "Contrôlez les appareils connectés.",
                "Check the connected devices.",
                "Revisa los dispositivos conectados.",
            ],
        ],
    },
    Scenario {
        icon: "card",
        title: [
            "J’ai donné mes coordonnées bancaires",
            "I gave my bank details",
            "Di mis datos bancarios",
        ],
        steps: &[
            [
                "Contactez votre banque par un canal officiel.",
                "Contact your bank through an official channel.",
                "Contacta con tu banco por un canal oficial.",
            ],
            [
                "Bloquez ou sécurisez les moyens de paiement concernés.",
                "Block or secure the payment methods involved.",
                "Bloquea o protege los medios de pago afectados.",
            ],
            [
                "Vérifiez vos opérations.",
                "Check your transactions.",
                "Revisa tus operaciones.",
            ],
            [
                "Conservez les preuves.",
                "Keep the evidence.",
                "Conserva las pruebas.",
            ],
            [
                "Signalez la fraude.",
                "Report the fraud.",
                "Denuncia el fraude.",
            ],
        ],
    },
    Scenario {
        icon: "coin",
        title: ["J’ai envoyé de l’argent", "I sent money", "Envié dinero"],
        steps: &[
            [
                "Contactez la banque immédiatement.",
                "Contact your bank immediately.",
                "Contacta con el banco de inmediato.",
            ],
            [
                "Demandez si un rappel de virement est possible.",
                "Ask whether the transfer can be recalled.",
                "Pregunta si se puede anular la transferencia.",
            ],
            [
                "Conservez les preuves.",
                "Keep the evidence.",
                "Conserva las pruebas.",
            ],
            [
                "Ne payez jamais de prétendus frais de récupération.",
                "Never pay so-called recovery fees.",
                "Nunca pagues supuestas tasas de recuperación.",
            ],
            [
                "Signalez l’arnaque.",
                "Report the scam.",
                "Denuncia la estafa.",
            ],
        ],
    },
    Scenario {
        icon: "message",
        title: [
            "J’ai communiqué un code SMS",
            "I shared an SMS code",
            "Compartí un código SMS",
        ],
        steps: &[
            [
                "Contactez le service concerné par son canal officiel.",
                "Contact the service through its official channel.",
                "Contacta con el servicio por su canal oficial.",
            ],
            [
                "Changez le mot de passe du compte lié.",
                "Change the password of the linked account.",
                "Cambia la contraseña de la cuenta vinculada.",
            ],
            [
                "Vérifiez les opérations et connexions récentes.",
                "Check recent transactions and sign-ins.",
                "Revisa operaciones e inicios de sesión recientes.",
            ],
            [
                "Ne communiquez plus aucun code.",
                "Never share a code again.",
                "No compartas ningún código más.",
            ],
        ],
    },
    Scenario {
        icon: "app",
        title: [
            "J’ai installé une application",
            "I installed an app",
            "Instalé una aplicación",
        ],
        steps: &[
            [
                "N’utilisez plus le logiciel suspect.",
                "Stop using the suspicious software.",
                "Deja de usar el programa sospechoso.",
            ],
            [
                "Vérifiez les autorisations accordées.",
                "Check the permissions granted.",
                "Revisa los permisos concedidos.",
            ],
            [
                "Évaluez les risques selon l’appareil.",
                "Assess the risks for the device.",
                "Evalúa los riesgos según el dispositivo.",
            ],
            [
                "Suivez des étapes de sécurisation adaptées, pas génériques.",
                "Follow tailored securing steps, not generic ones.",
                "Sigue pasos de protección adaptados, no genéricos.",
            ],
        ],
    },
    Scenario {
        icon: "qr",
        title: [
            "J’ai scanné un QR code",
            "I scanned a QR code",
            "Escaneé un código QR",
        ],
        steps: &[
            [
                "Fermez la page ouverte.",
                "Close the page that opened.",
                "Cierra la página abierta.",
            ],
            [
                "Ne saisissez aucune donnée ni paiement.",
                "Enter no data and no payment.",
                "No introduzcas datos ni pagos.",
            ],
            [
                "Vérifiez la destination avec QR Guard.",
                "Check the destination with QR Guard.",
                "Verifica el destino con QR Guard.",
            ],
            [
                "Signalez le QR code s’il était sur une affiche.",
                "Report the QR code if it was on a poster.",
                "Denuncia el código QR si estaba en un cartel.",
            ],
        ],
    },
    Scenario {
        icon: "reply",
        title: [
            "J’ai répondu au mail",
            "I replied to the email",
            "Respondí al correo",
        ],
        steps: &[
            [
                "N’envoyez plus aucune information.",
                "Send no more information.",
                "No envíes más información.",
            ],
            [
                "Notez ce que vous avez communiqué.",
                "Write down what you shared.",
                "Anota lo que compartiste.",
            ],
            [
                "Méfiez-vous des relances : elles vont arriver.",
                "Beware of follow-ups: they will come.",
                "Desconfía de los recordatorios: llegarán.",
            ],
            [
                "Bloquez et signalez l’expéditeur.",
                "Block and report the sender.",
                "Bloquea y denuncia al remitente.",
            ],
        ],
    },
    Scenario {
        icon: "help",
        title: [
            "Je ne sais pas ce qui s’est passé",
            "I don’t know what happened",
            "No sé qué pasó",
        ],
        steps: &[
            [
                "Respirez : vous n’êtes pas seul, et ce n’est pas votre faute.",
                "Breathe: you are not alone, and it is not your fault.",
                "Respira: no estás solo y no es culpa tuya.",
            ],
            [
                "Répondez à quelques questions simples de ZenAI.",
                "Answer a few simple questions from ZenAI.",
                "Responde a unas preguntas sencillas de ZenAI.",
            ],
            [
                "Recevez un plan d’action adapté.",
                "Get a tailored action plan.",
                "Recibe un plan de acción adaptado.",
            ],
            [
                "Soyez orienté vers les ressources officielles.",
                "Be pointed to official resources.",
                "Recibe orientación hacia recursos oficiales.",
            ],
        ],
    },
];

// ----- Ecosystem ---------------------------------------------------------------------------

pub struct Feature {
    pub icon: &'static str,
    pub name: &'static str,
    pub text: T3,
    pub points: [T3; 4],
}

pub const ECOSYSTEM: [Feature; 4] = [
    Feature {
        icon: "reply",
        name: "Safe Reply",
        text: [
            "Répondre sans prendre de risque. Par défaut, MailZen ne répond jamais automatiquement à un email suspect.",
            "Reply without taking risks. By default, MailZen never replies automatically to a suspicious email.",
            "Responder sin riesgos. Por defecto, MailZen nunca responde automáticamente a un correo sospechoso.",
        ],
        points: [
            [
                "Pourquoi ne pas répondre",
                "Why not to reply",
                "Por qué no responder",
            ],
            [
                "Vérification par un canal officiel",
                "Check through an official channel",
                "Verificación por un canal oficial",
            ],
            [
                "Réponse neutre si approprié",
                "A neutral reply when suitable",
                "Respuesta neutra si procede",
            ],
            [
                "Prévenir un collègue ou un proche",
                "Warn a colleague or a relative",
                "Avisar a un colega o familiar",
            ],
        ],
    },
    Feature {
        icon: "badge",
        name: "Brand Check",
        text: [
            "Vérifier une entreprise ou un organisme. Les domaines officiels sont vérifiés, sourcés, jamais inventés.",
            "Check a company or an organization. Official domains are verified and sourced, never invented.",
            "Verificar una empresa u organismo. Los dominios oficiales se verifican y documentan, nunca se inventan.",
        ],
        points: [
            [
                "Domaine officiel vérifié",
                "Verified official domain",
                "Dominio oficial verificado",
            ],
            [
                "Domaines ressemblants",
                "Lookalike domains",
                "Dominios parecidos",
            ],
            ["Signalements", "Reports", "Denuncias"],
            [
                "Comment la contacter",
                "How to contact it",
                "Cómo contactarla",
            ],
        ],
    },
    Feature {
        icon: "family",
        name: "FamilyZen",
        text: [
            "Protéger ses proches, en toute transparence : aucun accès secret, aucune surveillance cachée, aucun partage automatique.",
            "Protect your loved ones, transparently: no secret access, no hidden monitoring, no automatic sharing.",
            "Proteger a los tuyos con transparencia: sin acceso secreto, sin vigilancia oculta, sin compartir automáticamente.",
        ],
        points: [
            [
                "Inviter un proche",
                "Invite a relative",
                "Invitar a un familiar",
            ],
            [
                "Partager une analyse",
                "Share an analysis",
                "Compartir un análisis",
            ],
            ["Alerte volontaire", "Voluntary alert", "Alerta voluntaria"],
            [
                "Permissions maîtrisées",
                "Controlled permissions",
                "Permisos controlados",
            ],
        ],
    },
    Feature {
        icon: "book",
        name: "ZenLearn",
        text: [
            "Apprendre à reconnaître les arnaques : cours courts, mini-jeux, quiz quotidien, badges et niveaux.",
            "Learn to recognize scams: short lessons, mini-games, a daily quiz, badges and levels.",
            "Aprender a reconocer estafas: lecciones cortas, minijuegos, quiz diario, insignias y niveles.",
        ],
        points: [
            [
                "Email réel ou faux ?",
                "Real or fake email?",
                "¿Correo real o falso?",
            ],
            [
                "Trouver les 5 erreurs",
                "Spot the 5 mistakes",
                "Encuentra los 5 errores",
            ],
            [
                "Niveau débutant à avancé",
                "Beginner to advanced",
                "De principiante a avanzado",
            ],
            [
                "Récompenses non financières",
                "Non-financial rewards",
                "Recompensas no económicas",
            ],
        ],
    },
];

/// The demo dashboard (fictional data).
pub const RADAR: [(T3, u64, &str); 4] = [
    (
        ["Emails analysés", "Emails analyzed", "Correos analizados"],
        128,
        "mail",
    ),
    (
        [
            "Emails suspects",
            "Suspicious emails",
            "Correos sospechosos",
        ],
        12,
        "alert",
    ),
    (
        ["Liens à risque", "Risky links", "Enlaces de riesgo"],
        7,
        "link",
    ),
    (
        [
            "Fichiers suspects",
            "Suspicious files",
            "Archivos sospechosos",
        ],
        3,
        "file",
    ),
];

pub const LEARN_TOPICS: [T3; 13] = [
    [
        "Comprendre le phishing",
        "Understand phishing",
        "Entender el phishing",
    ],
    [
        "Reconnaître un faux email",
        "Spot a fake email",
        "Reconocer un correo falso",
    ],
    [
        "Reconnaître un faux SMS",
        "Spot a fake SMS",
        "Reconocer un SMS falso",
    ],
    ["Vérifier un lien", "Check a link", "Verificar un enlace"],
    [
        "Vérifier un expéditeur",
        "Check a sender",
        "Verificar un remitente",
    ],
    [
        "Comprendre les domaines",
        "Understand domains",
        "Entender los dominios",
    ],
    ["Les mots de passe", "Passwords", "Las contraseñas"],
    [
        "L’authentification multifacteur",
        "Multi-factor authentication",
        "La autenticación multifactor",
    ],
    [
        "Les faux documents",
        "Fake documents",
        "Los documentos falsos",
    ],
    [
        "Les fraudes bancaires",
        "Bank fraud",
        "Los fraudes bancarios",
    ],
    [
        "Les QR codes dangereux",
        "Dangerous QR codes",
        "Los códigos QR peligrosos",
    ],
    [
        "Les arnaques aux crypto",
        "Crypto scams",
        "Las estafas cripto",
    ],
    [
        "Les techniques de manipulation",
        "Manipulation techniques",
        "Las técnicas de manipulación",
    ],
];

/// "Real or fake link?": (link, is it the real one, explanation).
pub const QUIZ: [(&str, bool, T3); 6] = [
    (
        "https://www.paypal.com/signin",
        true,
        [
            "Le domaine enregistré est bien paypal.com, en HTTPS.",
            "The registered domain is indeed paypal.com, over HTTPS.",
            "El dominio registrado es efectivamente paypal.com, con HTTPS.",
        ],
    ),
    (
        "https://paypal.com.account-check.example/login",
        false,
        [
            "Le vrai domaine est account-check.example : « paypal.com » n’est qu’un sous-domaine.",
            "The real domain is account-check.example: “paypal.com” is only a subdomain.",
            "El dominio real es account-check.example: «paypal.com» solo es un subdominio.",
        ],
    ),
    (
        "https://amaz0n-orders.example/track",
        false,
        [
            "Un zéro remplace le « o » : c’est du typosquatting.",
            "A zero replaces the “o”: that is typosquatting.",
            "Un cero sustituye a la «o»: es typosquatting.",
        ],
    ),
    (
        "http://192.168.12.4/bank/verify",
        false,
        [
            "Une banque n’envoie jamais vers une adresse IP, en HTTP non chiffré.",
            "A bank never sends you to an IP address over unencrypted HTTP.",
            "Un banco nunca te envía a una dirección IP por HTTP sin cifrar.",
        ],
    ),
    (
        "https://www.service-public.fr/particuliers",
        true,
        [
            "Le domaine officiel de l’administration française, sans détour.",
            "The official domain of the French administration, straight up.",
            "El dominio oficial de la administración francesa, sin rodeos.",
        ],
    ),
    (
        "https://bit.ly/3xYz-colis",
        false,
        [
            "Un lien raccourci cache sa destination : vérifiez-la avant d’ouvrir.",
            "A short link hides its destination: check it before opening.",
            "Un enlace acortado oculta su destino: compruébalo antes de abrir.",
        ],
    ),
];

// ----- Privacy -----------------------------------------------------------------------------

pub const PRIVACY: [T3; 15] = [
    [
        "Analyse locale prioritaire",
        "Local analysis first",
        "Análisis local prioritario",
    ],
    [
        "Pas de compte obligatoire",
        "No account required",
        "Sin cuenta obligatoria",
    ],
    [
        "Pas de stockage cloud par défaut",
        "No cloud storage by default",
        "Sin almacenamiento en la nube por defecto",
    ],
    [
        "Consentement explicite",
        "Explicit consent",
        "Consentimiento explícito",
    ],
    [
        "Minimisation des données",
        "Data minimization",
        "Minimización de datos",
    ],
    ["Chiffrement local", "Local encryption", "Cifrado local"],
    [
        "Protection des clés",
        "Key protection",
        "Protección de claves",
    ],
    [
        "Suppression des données",
        "Data deletion",
        "Eliminación de datos",
    ],
    ["Historique local", "Local history", "Historial local"],
    [
        "Contrôle des permissions",
        "Permission control",
        "Control de permisos",
    ],
    [
        "Sources externes transparentes",
        "Transparent external sources",
        "Fuentes externas transparentes",
    ],
    [
        "Aucune publicité ciblée",
        "No targeted ads",
        "Sin publicidad dirigida",
    ],
    [
        "Aucune revente de données",
        "No data resale",
        "Sin reventa de datos",
    ],
    [
        "Données personnelles protégées",
        "Personal data protected",
        "Datos personales protegidos",
    ],
    [
        "Politique lisible",
        "A readable policy",
        "Una política legible",
    ],
];

pub const MODES: [(&str, &str, T3, T3); 3] = [
    (
        "local",
        "phone",
        ["Local", "Local", "Local"],
        [
            "Analyse sur l’appareil, pour les fonctions compatibles.",
            "Analysis on the device, for compatible features.",
            "Análisis en el dispositivo, para las funciones compatibles.",
        ],
    ),
    (
        "cloud",
        "cloud",
        ["Cloud", "Cloud", "Nube"],
        [
            "Analyse complémentaire via des services externes, après information et consentement.",
            "Additional analysis through external services, after information and consent.",
            "Análisis complementario mediante servicios externos, tras información y consentimiento.",
        ],
    ),
    (
        "hybrid",
        "layers",
        ["Hybride", "Hybrid", "Híbrido"],
        [
            "Analyse locale et vérifications externes facultatives pour renforcer les résultats.",
            "Local analysis plus optional external checks to strengthen the results.",
            "Análisis local y verificaciones externas opcionales para reforzar los resultados.",
        ],
    ),
];

// ----- Product -----------------------------------------------------------------------------

pub const MORE_MODULES: [(&str, T3); 18] = [
    (
        "Phone Scam",
        [
            "Arnaques par appel",
            "Phone call scams",
            "Estafas telefónicas",
        ],
    ),
    (
        "SMS Guard",
        ["Analyse des SMS", "SMS analysis", "Análisis de SMS"],
    ),
    (
        "Web Guard",
        [
            "Analyse de sites web",
            "Website analysis",
            "Análisis de sitios web",
        ],
    ),
    (
        "QR Guard",
        [
            "Analyse de QR codes",
            "QR code analysis",
            "Análisis de códigos QR",
        ],
    ),
    (
        "Document Guard",
        [
            "Analyse de documents",
            "Document analysis",
            "Análisis de documentos",
        ],
    ),
    (
        "Payment Guard",
        [
            "Paiements suspects",
            "Suspicious payments",
            "Pagos sospechosos",
        ],
    ),
    (
        "Brand Check",
        [
            "Identités de marques",
            "Brand identities",
            "Identidades de marca",
        ],
    ),
    (
        "Identity Guard",
        [
            "Indices d’usurpation",
            "Impersonation hints",
            "Indicios de suplantación",
        ],
    ),
    (
        "ZenLearn",
        ["Éducation cyber", "Cyber education", "Educación cíber"],
    ),
    (
        "FamilyZen",
        [
            "Protection des proches",
            "Family protection",
            "Protección familiar",
        ],
    ),
    (
        "SOS Cyber",
        [
            "Assistance après incident",
            "Post-incident help",
            "Ayuda tras un incidente",
        ],
    ),
    (
        "History",
        ["Historique sécurisé", "Secure history", "Historial seguro"],
    ),
    (
        "ZenAI",
        [
            "Assistant intelligent",
            "Smart assistant",
            "Asistente inteligente",
        ],
    ),
    (
        "Trust Score",
        [
            "Indicateurs de risque",
            "Risk indicators",
            "Indicadores de riesgo",
        ],
    ),
    (
        "Threat Alert",
        ["Alertes de menaces", "Threat alerts", "Alertas de amenazas"],
    ),
    (
        "Search",
        [
            "Recherche d’analyses",
            "Search analyses",
            "Búsqueda de análisis",
        ],
    ),
    (
        "Cyber Library",
        [
            "Bibliothèque éducative",
            "Learning library",
            "Biblioteca educativa",
        ],
    ),
    (
        "Privacy Control",
        ["Gestion des données", "Data management", "Gestión de datos"],
    ),
];

/// The engines of MailZen Core.
pub const CORE: [(&str, T3); 6] = [
    (
        "Email Parser",
        [
            "Parsing, headers, MIME",
            "Parsing, headers, MIME",
            "Parsing, cabeceras, MIME",
        ],
    ),
    (
        "URL Engine",
        [
            "Domaines, liens, redirections",
            "Domains, links, redirects",
            "Dominios, enlaces, redirecciones",
        ],
    ),
    (
        "File Engine",
        [
            "Documents, archives",
            "Documents, archives",
            "Documentos, archivos",
        ],
    ),
    (
        "Risk Engine",
        [
            "Score et décision",
            "Score and decision",
            "Puntuación y decisión",
        ],
    ),
    (
        "Threat Intel",
        [
            "Sources de réputation",
            "Reputation sources",
            "Fuentes de reputación",
        ],
    ),
    (
        "AI Engine",
        [
            "Classification et explication",
            "Classification and explanation",
            "Clasificación y explicación",
        ],
    ),
];

/// What iOS and Android allow: (feature, iOS, Android), with `1` yes, `0` no, `2` via an
/// authorized integration.
pub const PLATFORMS: [(T3, u8, u8); 10] = [
    (
        ["Coller un email", "Paste an email", "Pegar un correo"],
        1,
        1,
    ),
    (
        [
            "Importer un fichier",
            "Import a file",
            "Importar un archivo",
        ],
        1,
        1,
    ),
    (
        [
            "Partage vers MailZen",
            "Share to MailZen",
            "Compartir con MailZen",
        ],
        1,
        1,
    ),
    (
        [
            "Scanner une capture",
            "Scan a screenshot",
            "Escanear una captura",
        ],
        1,
        1,
    ),
    (["OCR", "OCR", "OCR"], 1, 1),
    (
        [
            "Scanner un QR code",
            "Scan a QR code",
            "Escanear un código QR",
        ],
        1,
        1,
    ),
    (["Analyse locale", "Local analysis", "Análisis local"], 1, 1),
    (
        [
            "Connexion à une boîte email",
            "Connect a mailbox",
            "Conectar un buzón",
        ],
        2,
        2,
    ),
    (
        [
            "Accès universel aux emails des autres apps",
            "Universal access to other apps’ emails",
            "Acceso universal a los correos de otras apps",
        ],
        0,
        0,
    ),
    (
        [
            "Surveillance universelle des emails",
            "Universal email monitoring",
            "Vigilancia universal del correo",
        ],
        0,
        0,
    ),
];

pub struct Phase {
    pub name: T3,
    pub title: &'static str,
    pub items: &'static [T3],
}

pub const ROADMAP: [Phase; 9] = [
    Phase {
        name: ["Fondations", "Foundations", "Cimientos"],
        title: "MailZen Core",
        items: &[
            [
                "Architecture Rust",
                "Rust architecture",
                "Arquitectura Rust",
            ],
            ["Parsing des emails", "Email parsing", "Parsing de correos"],
            ["Moteur de règles", "Rules engine", "Motor de reglas"],
            ["Score de risque", "Risk score", "Puntuación de riesgo"],
        ],
    },
    Phase {
        name: [
            "Scanner opérationnel",
            "Working scanner",
            "Escáner operativo",
        ],
        title: "Mail Scanner",
        items: &[
            [
                "Import texte et EML",
                "Text and EML import",
                "Importar texto y EML",
            ],
            [
                "Apps iOS et Android",
                "iOS and Android apps",
                "Apps iOS y Android",
            ],
            ["Rapport détaillé", "Detailed report", "Informe detallado"],
            ["Historique local", "Local history", "Historial local"],
        ],
    },
    Phase {
        name: ["Analyse des liens", "Link analysis", "Análisis de enlaces"],
        title: "Link Guard",
        items: &[
            ["URL Engine", "URL Engine", "URL Engine"],
            ["Redirections", "Redirects", "Redirecciones"],
            ["Typosquatting", "Typosquatting", "Typosquatting"],
            ["Réputation", "Reputation", "Reputación"],
        ],
    },
    Phase {
        name: [
            "Analyse des expéditeurs",
            "Sender analysis",
            "Análisis de remitentes",
        ],
        title: "Sender Intelligence",
        items: &[
            ["SPF, DKIM, DMARC", "SPF, DKIM, DMARC", "SPF, DKIM, DMARC"],
            ["Spoofing", "Spoofing", "Spoofing"],
            ["Usurpation", "Impersonation", "Suplantación"],
            [
                "Domaines ressemblants",
                "Lookalike domains",
                "Dominios parecidos",
            ],
        ],
    },
    Phase {
        name: ["Documents", "Documents", "Documentos"],
        title: "Attachment Guard",
        items: &[
            ["PDF et Office", "PDF and Office", "PDF y Office"],
            ["HTML et ZIP", "HTML and ZIP", "HTML y ZIP"],
            ["Hashes", "Hashes", "Hashes"],
            ["Sandbox sécurisée", "Secure sandbox", "Sandbox seguro"],
        ],
    },
    Phase {
        name: ["Images et QR codes", "Images and QR codes", "Imágenes y QR"],
        title: "ScreenScan & QR Guard",
        items: &[
            ["OCR", "OCR", "OCR"],
            ["Captures", "Screenshots", "Capturas"],
            [
                "Extraction de liens",
                "Link extraction",
                "Extracción de enlaces",
            ],
            ["Analyse de QR", "QR analysis", "Análisis de QR"],
        ],
    },
    Phase {
        name: [
            "Intelligence contextuelle",
            "Contextual intelligence",
            "Inteligencia contextual",
        ],
        title: "ZenAI",
        items: &[
            ["Classification", "Classification", "Clasificación"],
            ["Explication", "Explanation", "Explicación"],
            ["Assistant", "Assistant", "Asistente"],
            ["Guide incident", "Incident guide", "Guía de incidentes"],
        ],
    },
    Phase {
        name: ["Assistance", "Assistance", "Asistencia"],
        title: "SOS Cyber",
        items: &[
            [
                "Clic et mot de passe",
                "Click and password",
                "Clic y contraseña",
            ],
            ["Paiement", "Payment", "Pago"],
            ["Fichier et application", "File and app", "Archivo y app"],
            ["Signalement", "Reporting", "Denuncia"],
        ],
    },
    Phase {
        name: ["Écosystème", "Ecosystem", "Ecosistema"],
        title: "MailZen+",
        items: &[
            [
                "FamilyZen et ZenLearn",
                "FamilyZen and ZenLearn",
                "FamilyZen y ZenLearn",
            ],
            [
                "Brand Check, Web et SMS Guard",
                "Brand Check, Web and SMS Guard",
                "Brand Check, Web y SMS Guard",
            ],
            [
                "Intégrations email",
                "Email integrations",
                "Integraciones de correo",
            ],
            ["Abonnement Pro", "Pro subscription", "Suscripción Pro"],
        ],
    },
];

pub struct Plan {
    pub name: &'static str,
    pub tag: T3,
    /// Monthly and yearly prices, or `None` (on quote).
    pub price: Option<(T3, T3)>,
    pub featured: bool,
    pub points: &'static [T3],
}

pub const PLANS: [Plan; 4] = [
    Plan {
        name: "Free",
        tag: ["Essentiel", "Essential", "Esencial"],
        price: Some((["0 €", "€0", "0 €"], ["0 €", "€0", "0 €"])),
        featured: false,
        points: &[
            ["Scanner de mails", "Email scanner", "Escáner de correos"],
            [
                "Analyse de liens de base",
                "Basic link analysis",
                "Análisis básico de enlaces",
            ],
            [
                "Score de risque et explication",
                "Risk score and explanation",
                "Puntuación y explicación",
            ],
            [
                "Analyse de captures",
                "Screenshot analysis",
                "Análisis de capturas",
            ],
            ["Scanner QR", "QR scanner", "Escáner QR"],
            ["Historique limité", "Limited history", "Historial limitado"],
        ],
    },
    Plan {
        name: "Pro",
        tag: [
            "Protection avancée",
            "Advanced protection",
            "Protección avanzada",
        ],
        price: Some((
            ["4,99 €/mois", "€4.99/month", "4,99 €/mes"],
            ["39,99 €/an", "€39.99/year", "39,99 €/año"],
        )),
        featured: true,
        points: &[
            [
                "Analyses approfondies",
                "In-depth analyses",
                "Análisis en profundidad",
            ],
            [
                "Fichiers avancés",
                "Advanced file analysis",
                "Archivos avanzados",
            ],
            [
                "Réputation étendue",
                "Extended reputation",
                "Reputación ampliada",
            ],
            ["ZenAI", "ZenAI", "ZenAI"],
            [
                "Historique et rapports",
                "History and reports",
                "Historial e informes",
            ],
            [
                "SOS Cyber avancé",
                "Advanced SOS Cyber",
                "SOS Cyber avanzado",
            ],
        ],
    },
    Plan {
        name: "Family",
        tag: [
            "Protection des proches",
            "Family protection",
            "Protección familiar",
        ],
        price: Some((
            ["8,99 €/mois", "€8.99/month", "8,99 €/mes"],
            ["8,99 €/mois", "€8.99/month", "8,99 €/mes"],
        )),
        featured: false,
        points: &[
            ["Espaces partagés", "Shared spaces", "Espacios compartidos"],
            [
                "Partage d’analyses",
                "Analysis sharing",
                "Compartir análisis",
            ],
            ["Accompagnement", "Support", "Acompañamiento"],
            [
                "Ressources éducatives",
                "Learning resources",
                "Recursos educativos",
            ],
            [
                "Gestion des invitations",
                "Invitation management",
                "Gestión de invitaciones",
            ],
        ],
    },
    Plan {
        name: "Business",
        tag: ["Professionnels", "Professionals", "Profesionales"],
        price: None,
        featured: false,
        points: &[
            ["Analyse avancée", "Advanced analysis", "Análisis avanzado"],
            [
                "Plusieurs utilisateurs",
                "Multiple users",
                "Varios usuarios",
            ],
            ["Reporting", "Reporting", "Informes"],
            ["Sensibilisation", "Awareness training", "Concienciación"],
            [
                "Protection contre la fraude",
                "Fraud protection",
                "Protección contra el fraude",
            ],
        ],
    },
];

pub const FAQ: [(T3, T3); 8] = [
    (
        [
            "MailZen lit-il mes emails ?",
            "Does MailZen read my emails?",
            "¿MailZen lee mis correos?",
        ],
        [
            "Non. MailZen n’analyse que ce que vous lui soumettez : un email collé, partagé, une capture ou un fichier. Aucune surveillance universelle de votre boîte, ce que ni iOS ni Android ne permettent d’ailleurs.",
            "No. MailZen only analyzes what you submit: a pasted or shared email, a screenshot or a file. There is no universal monitoring of your mailbox, which neither iOS nor Android allows anyway.",
            "No. MailZen solo analiza lo que tú le envías: un correo pegado o compartido, una captura o un archivo. No hay vigilancia universal de tu buzón, algo que ni iOS ni Android permiten.",
        ],
    ),
    (
        [
            "Faut-il créer un compte ?",
            "Do I need an account?",
            "¿Hace falta crear una cuenta?",
        ],
        [
            "Non, le scanner de base fonctionne sans compte. Un compte n’est utile que pour les fonctions partagées comme FamilyZen.",
            "No, the basic scanner works without an account. An account is only useful for shared features such as FamilyZen.",
            "No, el escáner básico funciona sin cuenta. Una cuenta solo sirve para funciones compartidas como FamilyZen.",
        ],
    ),
    (
        [
            "Mes données partent-elles dans le cloud ?",
            "Does my data go to the cloud?",
            "¿Mis datos van a la nube?",
        ],
        [
            "Par défaut, non : l’analyse locale est prioritaire. Les vérifications cloud sont facultatives, expliquées, et soumises à votre consentement explicite.",
            "Not by default: local analysis comes first. Cloud checks are optional, explained, and subject to your explicit consent.",
            "Por defecto, no: el análisis local es prioritario. Las verificaciones en la nube son opcionales, se explican y requieren tu consentimiento explícito.",
        ],
    ),
    (
        [
            "Un score faible garantit-il qu’un email est sûr ?",
            "Does a low score guarantee an email is safe?",
            "¿Una puntuación baja garantiza que un correo es seguro?",
        ],
        [
            "Non. « Aucun risque notable détecté » signifie que les contrôles n’ont rien relevé d’important, pas qu’un message est inoffensif. MailZen distingue toujours le score de danger du niveau de confiance.",
            "No. “No notable risk detected” means the checks found nothing significant, not that the message is harmless. MailZen always separates the danger score from the confidence level.",
            "No. «Ningún riesgo notable detectado» significa que los controles no encontraron nada importante, no que el mensaje sea inofensivo. MailZen siempre separa la puntuación de peligro del nivel de confianza.",
        ],
    ),
    (
        [
            "L’IA décide-t-elle seule ?",
            "Does the AI decide alone?",
            "¿La IA decide sola?",
        ],
        [
            "Non. Le verdict vient d’un moteur de décision indépendant, en Rust : règles déterministes, réputation et signaux techniques. ZenAI explique ces résultats sans jamais inventer de preuve.",
            "No. The verdict comes from an independent decision engine written in Rust: deterministic rules, reputation and technical signals. ZenAI explains those results and never invents evidence.",
            "No. El veredicto procede de un motor de decisión independiente escrito en Rust: reglas deterministas, reputación y señales técnicas. ZenAI explica esos resultados sin inventar nunca pruebas.",
        ],
    ),
    (
        [
            "Quand sortent les applications ?",
            "When are the apps coming?",
            "¿Cuándo salen las aplicaciones?",
        ],
        [
            "MailZen se construit par étapes : le moteur Rust, le scanner, Link Guard et le rapport d’abord, puis les apps iOS (Swift, SwiftUI) et Android (Kotlin, Compose).",
            "MailZen is built in stages: the Rust engine, the scanner, Link Guard and the report first, then the iOS (Swift, SwiftUI) and Android (Kotlin, Compose) apps.",
            "MailZen se construye por etapas: primero el motor Rust, el escáner, Link Guard y el informe, después las apps de iOS (Swift, SwiftUI) y Android (Kotlin, Compose).",
        ],
    ),
    (
        [
            "J’ai été victime : que faire ?",
            "I have been scammed: what now?",
            "He sido víctima: ¿qué hago?",
        ],
        [
            "Ouvrez SOS Cyber ci-dessus et choisissez ce qui s’est passé. En France, Cybermalveillance.gouv.fr accompagne les victimes ; contactez aussi votre banque par un canal officiel.",
            "Open SOS Cyber above and choose what happened. In France, Cybermalveillance.gouv.fr helps victims; also contact your bank through an official channel.",
            "Abre SOS Cyber más arriba y elige lo que pasó. En Francia, Cybermalveillance.gouv.fr ayuda a las víctimas; contacta también con tu banco por un canal oficial.",
        ],
    ),
    (
        [
            "Les prix sont-ils définitifs ?",
            "Are the prices final?",
            "¿Los precios son definitivos?",
        ],
        [
            "Non, ils sont indicatifs. Les coûts des services d’analyse et des API seront mesurés avant de fixer les limites des abonnements.",
            "No, they are indicative. The costs of analysis services and APIs will be measured before setting the subscription limits.",
            "No, son orientativos. Los costes de los servicios de análisis y de las API se medirán antes de fijar los límites de las suscripciones.",
        ],
    ),
];
