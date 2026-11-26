// Generated from the website’s content (src/data.rs): the same texts in the app.
// swiftlint:disable all

import Foundation

public struct Sample: Sendable {
    public let label: T3
    public let text: T3
}

public struct Scenario: Sendable {
    public let icon: String
    public let title: T3
    public let steps: [T3]
}

public struct Category: Sendable {
    public let icon: String
    public let title: T3
    public let text: T3
}

public struct Module: Sendable {
    public let id: String
    public let icon: String
    public let name: String
    public let tag: T3
    public let text: T3
}

public enum Library {
    public static let samples: [Sample] = [
        Sample(
            label: T3("Faux PayPal", "Fake PayPal", "PayPal falso"),
            text: T3("De : Service Client PayPal <service@paypaI-account-check.example>\nObjet : Action requise : votre compte sera suspendu sous 24 heures\n\nBonjour,\nNous avons détecté une activité inhabituelle. Votre compte sera suspendu sous 24 heures si vous ne confirmez pas votre identité.\nConfirmez immédiatement votre mot de passe et votre carte bancaire ici :\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nService Sécurité", "From: PayPal Customer Service <service@paypaI-account-check.example>\nSubject: Action required: your account will be suspended within 24 hours\n\nHello,\nWe detected unusual activity. Your account will be suspended within 24 hours unless you confirm your identity.\nConfirm your password and credit card immediately here:\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nSecurity Team", "De: Atención al cliente PayPal <service@paypaI-account-check.example>\nAsunto: Acción requerida: su cuenta será suspendida en 24 horas\n\nHola:\nHemos detectado una actividad inusual. Su cuenta será suspendida en 24 horas si no confirma su identidad.\nConfirme inmediatamente su contraseña y su tarjeta aquí:\nhttp://paypal.secure-login.account-verification.example/confirm?id=88213\n\nEquipo de seguridad"),
        ),
        Sample(
            label: T3("Faux colis", "Fake parcel", "Paquete falso"),
            text: T3("De : Livraison Colis <notification@suivi-colis-express.example>\nObjet : Votre colis est en attente\n\nVotre colis n’a pas pu être livré. Des frais de réexpédition de 1,99 € sont à régler avant ce soir, sinon il sera renvoyé.\nRéglez ici : https://bit.ly/colis-2026\nVous pouvez aussi scanner le QR code joint.", "From: Parcel Delivery <notification@parcel-tracking-express.example>\nSubject: Your parcel is on hold\n\nYour parcel could not be delivered. A redelivery fee of $1.99 must be paid tonight, or it will be returned to sender.\nPay here: https://bit.ly/parcel-2026\nYou can also scan the attached QR code.", "De: Entrega de paquetes <notification@seguimiento-paquete-express.example>\nAsunto: Su paquete está retenido\n\nSu paquete no pudo entregarse. Debe pagar una tasa de reenvío de 1,99 € esta noche o será devuelto.\nPague aquí: https://bit.ly/paquete-2026\nTambién puede escanear el código QR adjunto."),
        ),
        Sample(
            label: T3("Fraude au président", "CEO fraud", "Fraude del CEO"),
            text: T3("De : Direction Générale <direction.generale@gmail.example>\nObjet : Urgent et confidentiel\n\nJe suis en réunion et injoignable. J’ai besoin que tu fasses un virement de 4 800 € à notre nouveau fournisseur, immédiatement.\nNe parle de cette opération à personne, c’est confidentiel.\nLe nouveau RIB est en pièce jointe : RIB_fournisseur.pdf.exe", "From: CEO Office <ceo.office@gmail.example>\nSubject: Urgent and confidential\n\nI am in a meeting and cannot be reached. I need you to make a wire transfer of $4,800 to our new supplier, immediately.\nDo not tell anyone about this, it is confidential.\nThe new bank details are attached: bank_details.pdf.exe", "De: Dirección General <direccion.general@gmail.example>\nAsunto: Urgente y confidencial\n\nEstoy en una reunión y no puedo hablar. Necesito que hagas una transferencia de 4.800 € a nuestro nuevo proveedor, inmediatamente.\nNo se lo cuentes a nadie, es confidencial.\nLos nuevos datos bancarios van adjuntos: datos_proveedor.pdf.exe"),
        ),
        Sample(
            label: T3("Newsletter", "Newsletter", "Boletín"),
            text: T3("De : Bibliothèque municipale <contact@bibliotheque-ville.example>\nObjet : Programme des ateliers de décembre\n\nBonjour,\nVoici le programme des ateliers du mois : lecture, numérique et jeux de société.\nLe détail est disponible sur notre site : https://bibliotheque-ville.example/ateliers\nBonne journée !", "From: City Library <contact@city-library.example>\nSubject: December workshop schedule\n\nHello,\nHere is this month’s workshop schedule: reading, digital skills and board games.\nDetails are on our website: https://city-library.example/workshops\nHave a nice day!", "De: Biblioteca municipal <contacto@biblioteca-ciudad.example>\nAsunto: Programa de talleres de diciembre\n\nHola:\nEste es el programa de talleres del mes: lectura, competencias digitales y juegos de mesa.\nLos detalles están en nuestra web: https://biblioteca-ciudad.example/talleres\n¡Buen día!"),
        ),
    ]

    public static let modules: [Module] = [
        Module(
            id: "scanner",
            icon: "mail",
            name: "Mail Scanner",
            tag: T3("Le cœur", "The core", "El núcleo"),
            text: T3("Analyse complète d’un email en quelques secondes, sans créer de compte : expéditeur, contenu, liens, pièces jointes.", "A complete analysis of an email in seconds, without an account: sender, content, links, attachments.", "Análisis completo de un correo en segundos, sin crear cuenta: remitente, contenido, enlaces y adjuntos."),
        ),
        Module(
            id: "links",
            icon: "link",
            name: "Link Guard",
            tag: T3("Liens", "Links", "Enlaces"),
            text: T3("Chaque URL est décortiquée : domaine réel, redirections, raccourcisseurs, typosquatting, réputation.", "Every URL is taken apart: real domain, redirects, shorteners, typosquatting, reputation.", "Cada URL se descompone: dominio real, redirecciones, acortadores, typosquatting y reputación."),
        ),
        Module(
            id: "files",
            icon: "file",
            name: "Attachment Guard",
            tag: T3("Fichiers", "Files", "Archivos"),
            text: T3("PDF, Office, archives, HTML, SVG : type réel, macros, scripts, doubles extensions et bombes ZIP.", "PDF, Office, archives, HTML, SVG: real type, macros, scripts, double extensions and ZIP bombs.", "PDF, Office, archivos comprimidos, HTML, SVG: tipo real, macros, scripts, dobles extensiones y bombas ZIP."),
        ),
        Module(
            id: "screens",
            icon: "camera",
            name: "ScreenScan",
            tag: T3("Captures", "Screenshots", "Capturas"),
            text: T3("Une capture d’écran suffit : OCR, liens visibles, numéros, demandes de paiement et QR codes.", "A screenshot is enough: OCR, visible links, phone numbers, payment requests and QR codes.", "Basta una captura de pantalla: OCR, enlaces visibles, números, peticiones de pago y códigos QR."),
        ),
        Module(
            id: "qr",
            icon: "qr",
            name: "QR Guard",
            tag: T3("QR codes", "QR codes", "Códigos QR"),
            text: T3("La destination s’affiche avant toute ouverture. Un QR code n’est jamais ouvert automatiquement.", "The destination is shown before anything opens. A QR code is never opened automatically.", "El destino se muestra antes de abrir nada. Un código QR nunca se abre automáticamente."),
        ),
        Module(
            id: "zenai",
            icon: "spark",
            name: "ZenAI",
            tag: T3("Assistant", "Assistant", "Asistente"),
            text: T3("Un assistant relié aux résultats de l’analyse, qui explique, rassure et conseille sans culpabiliser.", "An assistant connected to the analysis results, which explains, reassures and advises without blame.", "Un asistente conectado a los resultados del análisis que explica, tranquiliza y aconseja sin culpabilizar."),
        ),
        Module(
            id: "sos",
            icon: "lifebuoy",
            name: "SOS Cyber",
            tag: T3("Assistance", "Assistance", "Asistencia"),
            text: T3("Déjà cliqué ? MailZen ne vous abandonne pas : des étapes claires selon ce qui s’est passé.", "Already clicked? MailZen does not leave you alone: clear steps depending on what happened.", "¿Ya has hecho clic? MailZen no te deja solo: pasos claros según lo que haya pasado."),
        ),
    ]

    public static let scenarios: [Scenario] = [
        Scenario(
            icon: "cursor",
            title: T3("J’ai cliqué sur un lien", "I clicked a link", "Hice clic en un enlace"),
            steps: [
                T3("Fermez la page.", "Close the page.", "Cierra la página."),
                T3("Ne saisissez plus aucune donnée.", "Do not enter any more data.", "No introduzcas más datos."),
                T3("Identifiez ce qui a été communiqué ou téléchargé.", "Work out what was shared or downloaded.", "Identifica lo que se compartió o descargó."),
                T3("Vérifiez si un fichier a été ouvert.", "Check whether a file was opened.", "Comprueba si se abrió algún archivo."),
                T3("Adaptez les actions selon les circonstances, avec MailZen.", "Adapt the next steps to the situation, with MailZen.", "Adapta los pasos a la situación, con MailZen."),
            ],
        ),
        Scenario(
            icon: "download",
            title: T3("J’ai téléchargé un fichier", "I downloaded a file", "Descargué un archivo"),
            steps: [
                T3("N’ouvrez pas le fichier.", "Do not open the file.", "No abras el archivo."),
                T3("Analysez-le avec Attachment Guard.", "Analyze it with Attachment Guard.", "Analízalo con Attachment Guard."),
                T3("Supprimez-le s’il est suspect, puis videz la corbeille.", "Delete it if it is suspicious, then empty the trash.", "Bórralo si es sospechoso y vacía la papelera."),
                T3("Gardez une trace de l’email d’origine.", "Keep a record of the original email.", "Guarda una copia del correo original."),
            ],
        ),
        Scenario(
            icon: "file",
            title: T3("J’ai ouvert une pièce jointe", "I opened an attachment", "Abrí un adjunto"),
            steps: [
                T3("N’activez ni macros ni contenu.", "Do not enable macros or content.", "No habilites macros ni contenido."),
                T3("Déconnectez l’appareil du réseau si un comportement anormal apparaît.", "Disconnect the device from the network if it behaves strangely.", "Desconecta el dispositivo de la red si se comporta de forma extraña."),
                T3("Évaluez le risque selon le type de fichier et l’appareil.", "Assess the risk based on the file type and the device.", "Evalúa el riesgo según el tipo de archivo y el dispositivo."),
                T3("Faites-vous aider si un logiciel a pu s’installer.", "Get help if software may have been installed.", "Pide ayuda si se pudo instalar algún programa."),
            ],
        ),
        Scenario(
            icon: "key",
            title: T3("J’ai donné mon mot de passe", "I gave my password", "Di mi contraseña"),
            steps: [
                T3("Changez immédiatement le mot de passe depuis le service officiel.", "Change the password right away on the official service.", "Cambia la contraseña de inmediato en el servicio oficial."),
                T3("Changez-le partout où il est réutilisé.", "Change it everywhere it is reused.", "Cámbiala allí donde la reutilices."),
                T3("Révoquez les sessions ouvertes.", "Revoke open sessions.", "Cierra las sesiones abiertas."),
                T3("Activez l’authentification multifacteur.", "Turn on multi-factor authentication.", "Activa la autenticación multifactor."),
                T3("Vérifiez les méthodes de récupération.", "Check the recovery methods.", "Revisa los métodos de recuperación."),
                T3("Vérifiez les règles de transfert de la messagerie.", "Check the mail forwarding rules.", "Revisa las reglas de reenvío del correo."),
                T3("Contrôlez les appareils connectés.", "Check the connected devices.", "Revisa los dispositivos conectados."),
            ],
        ),
        Scenario(
            icon: "card",
            title: T3("J’ai donné mes coordonnées bancaires", "I gave my bank details", "Di mis datos bancarios"),
            steps: [
                T3("Contactez votre banque par un canal officiel.", "Contact your bank through an official channel.", "Contacta con tu banco por un canal oficial."),
                T3("Bloquez ou sécurisez les moyens de paiement concernés.", "Block or secure the payment methods involved.", "Bloquea o protege los medios de pago afectados."),
                T3("Vérifiez vos opérations.", "Check your transactions.", "Revisa tus operaciones."),
                T3("Conservez les preuves.", "Keep the evidence.", "Conserva las pruebas."),
                T3("Signalez la fraude.", "Report the fraud.", "Denuncia el fraude."),
            ],
        ),
        Scenario(
            icon: "coin",
            title: T3("J’ai envoyé de l’argent", "I sent money", "Envié dinero"),
            steps: [
                T3("Contactez la banque immédiatement.", "Contact your bank immediately.", "Contacta con el banco de inmediato."),
                T3("Demandez si un rappel de virement est possible.", "Ask whether the transfer can be recalled.", "Pregunta si se puede anular la transferencia."),
                T3("Conservez les preuves.", "Keep the evidence.", "Conserva las pruebas."),
                T3("Ne payez jamais de prétendus frais de récupération.", "Never pay so-called recovery fees.", "Nunca pagues supuestas tasas de recuperación."),
                T3("Signalez l’arnaque.", "Report the scam.", "Denuncia la estafa."),
            ],
        ),
        Scenario(
            icon: "message",
            title: T3("J’ai communiqué un code SMS", "I shared an SMS code", "Compartí un código SMS"),
            steps: [
                T3("Contactez le service concerné par son canal officiel.", "Contact the service through its official channel.", "Contacta con el servicio por su canal oficial."),
                T3("Changez le mot de passe du compte lié.", "Change the password of the linked account.", "Cambia la contraseña de la cuenta vinculada."),
                T3("Vérifiez les opérations et connexions récentes.", "Check recent transactions and sign-ins.", "Revisa operaciones e inicios de sesión recientes."),
                T3("Ne communiquez plus aucun code.", "Never share a code again.", "No compartas ningún código más."),
            ],
        ),
        Scenario(
            icon: "app",
            title: T3("J’ai installé une application", "I installed an app", "Instalé una aplicación"),
            steps: [
                T3("N’utilisez plus le logiciel suspect.", "Stop using the suspicious software.", "Deja de usar el programa sospechoso."),
                T3("Vérifiez les autorisations accordées.", "Check the permissions granted.", "Revisa los permisos concedidos."),
                T3("Évaluez les risques selon l’appareil.", "Assess the risks for the device.", "Evalúa los riesgos según el dispositivo."),
                T3("Suivez des étapes de sécurisation adaptées, pas génériques.", "Follow tailored securing steps, not generic ones.", "Sigue pasos de protección adaptados, no genéricos."),
            ],
        ),
        Scenario(
            icon: "qr",
            title: T3("J’ai scanné un QR code", "I scanned a QR code", "Escaneé un código QR"),
            steps: [
                T3("Fermez la page ouverte.", "Close the page that opened.", "Cierra la página abierta."),
                T3("Ne saisissez aucune donnée ni paiement.", "Enter no data and no payment.", "No introduzcas datos ni pagos."),
                T3("Vérifiez la destination avec QR Guard.", "Check the destination with QR Guard.", "Verifica el destino con QR Guard."),
                T3("Signalez le QR code s’il était sur une affiche.", "Report the QR code if it was on a poster.", "Denuncia el código QR si estaba en un cartel."),
            ],
        ),
        Scenario(
            icon: "reply",
            title: T3("J’ai répondu au mail", "I replied to the email", "Respondí al correo"),
            steps: [
                T3("N’envoyez plus aucune information.", "Send no more information.", "No envíes más información."),
                T3("Notez ce que vous avez communiqué.", "Write down what you shared.", "Anota lo que compartiste."),
                T3("Méfiez-vous des relances : elles vont arriver.", "Beware of follow-ups: they will come.", "Desconfía de los recordatorios: llegarán."),
                T3("Bloquez et signalez l’expéditeur.", "Block and report the sender.", "Bloquea y denuncia al remitente."),
            ],
        ),
        Scenario(
            icon: "help",
            title: T3("Je ne sais pas ce qui s’est passé", "I don’t know what happened", "No sé qué pasó"),
            steps: [
                T3("Respirez : vous n’êtes pas seul, et ce n’est pas votre faute.", "Breathe: you are not alone, and it is not your fault.", "Respira: no estás solo y no es culpa tuya."),
                T3("Répondez à quelques questions simples de ZenAI.", "Answer a few simple questions from ZenAI.", "Responde a unas preguntas sencillas de ZenAI."),
                T3("Recevez un plan d’action adapté.", "Get a tailored action plan.", "Recibe un plan de acción adaptado."),
                T3("Soyez orienté vers les ressources officielles.", "Be pointed to official resources.", "Recibe orientación hacia recursos oficiales."),
            ],
        ),
    ]

    public static let categories: [Category] = [
        Category(
            icon: "bank",
            title: T3("Banques", "Banks", "Bancos"),
            text: T3("Faux remboursements, faux paiements, fausses alertes.", "Fake refunds, fake payments, fake alerts.", "Reembolsos, pagos y alertas falsos."),
        ),
        Category(
            icon: "parcel",
            title: T3("Livraisons", "Deliveries", "Envíos"),
            text: T3("Faux colis, douanes, frais et relivraisons.", "Fake parcels, customs, fees and redeliveries.", "Paquetes falsos, aduanas, tasas y reenvíos."),
        ),
        Category(
            icon: "gov",
            title: T3("Administrations", "Government", "Administraciones"),
            text: T3("Faux impôts, organismes et documents administratifs.", "Fake taxes, agencies and official documents.", "Impuestos, organismos y documentos falsos."),
        ),
        Category(
            icon: "briefcase",
            title: T3("Entreprises", "Companies", "Empresas"),
            text: T3("Fraude au président, au fournisseur et à l’employeur.", "CEO, supplier and employer fraud.", "Fraude del CEO, del proveedor y del empleador."),
        ),
        Category(
            icon: "chart",
            title: T3("Finances", "Finance", "Finanzas"),
            text: T3("Virements, investissements, crypto et gains fictifs.", "Transfers, investments, crypto and fake gains.", "Transferencias, inversiones, cripto y ganancias falsas."),
        ),
        Category(
            icon: "heart",
            title: T3("Sentimentales", "Romance", "Sentimentales"),
            text: T3("Manipulation affective et demandes d’argent.", "Emotional manipulation and requests for money.", "Manipulación afectiva y peticiones de dinero."),
        ),
    ]

    public static let techniques: [(icon: String, name: T3, example: T3)] = [
        (
            "clock",
            T3("Urgence", "Urgency", "Urgencia"),
            T3("« Vous avez 24 heures »", "“You have 24 hours”", "«Tiene 24 horas»"),
        ),
        (
            "alert",
            T3("Peur", "Fear", "Miedo"),
            T3("« Votre compte est compromis »", "“Your account is compromised”", "«Su cuenta está comprometida»"),
        ),
        (
            "crown",
            T3("Autorité", "Authority", "Autoridad"),
            T3("« Message officiel du gouvernement »", "“Official government message”", "«Mensaje oficial del gobierno»"),
        ),
        (
            "bolt",
            T3("Pression", "Pressure", "Presión"),
            T3("« Vous devez agir maintenant »", "“You must act now”", "«Debe actuar ahora»"),
        ),
        (
            "lock",
            T3("Secret", "Secrecy", "Secreto"),
            T3("« N’en parlez à personne »", "“Tell no one about this”", "«No se lo cuente a nadie»"),
        ),
        (
            "gift",
            T3("Récompense", "Reward", "Recompensa"),
            T3("« Vous avez gagné 5 000 € »", "“You have won $5,000”", "«Ha ganado 5.000 €»"),
        ),
        (
            "eye",
            T3("Curiosité", "Curiosity", "Curiosidad"),
            T3("« Consultez votre dossier »", "“See your file”", "«Consulte su expediente»"),
        ),
        (
            "ban",
            T3("Menace", "Threat", "Amenaza"),
            T3("« Votre compte sera fermé »", "“Your account will be closed”", "«Su cuenta será cerrada»"),
        ),
        (
            "coin",
            T3("Manipulation financière", "Financial manipulation", "Manipulación financiera"),
            T3("« Envoyez le virement »", "“Send the transfer”", "«Envíe la transferencia»"),
        ),
        (
            "heart",
            T3("Manipulation affective", "Emotional manipulation", "Manipulación afectiva"),
            T3("Une relation de confiance exploitée", "A trusted relationship exploited", "Una relación de confianza explotada"),
        ),
        (
            "mask",
            T3("Impersonation", "Impersonation", "Suplantación"),
            T3("Un proche ou un supérieur imité", "A relative or a boss imitated", "Un familiar o un jefe imitado"),
        ),
        (
            "maze",
            T3("Confusion", "Confusion", "Confusión"),
            T3("Des consignes ambiguës", "Ambiguous instructions", "Instrucciones ambiguas"),
        ),
    ]

    public static let scams: [T3] = [
        T3("Phishing", "Phishing", "Phishing"),
        T3("Spear phishing", "Spear phishing", "Spear phishing"),
        T3("Whaling", "Whaling", "Whaling"),
        T3("Fraude au président", "CEO fraud", "Fraude del CEO"),
        T3("Faux support", "Fake support", "Soporte falso"),
        T3("Faux remboursements", "Fake refunds", "Reembolsos falsos"),
        T3("Faux colis", "Fake parcels", "Paquetes falsos"),
        T3("Faux impôts", "Fake taxes", "Impuestos falsos"),
        T3("Faux documents administratifs", "Fake official documents", "Documentos oficiales falsos"),
        T3("Faux recrutements", "Fake job offers", "Ofertas de empleo falsas"),
        T3("Fraude aux fournisseurs", "Supplier fraud", "Fraude de proveedores"),
        T3("Faux RIB", "Fake bank details", "Datos bancarios falsos"),
        T3("Fraude au virement", "Wire fraud", "Fraude de transferencia"),
        T3("Arnaques crypto", "Crypto scams", "Estafas cripto"),
        T3("Faux investissements", "Fake investments", "Inversiones falsas"),
        T3("Faux cadeaux", "Fake gifts", "Regalos falsos"),
        T3("Faux concours", "Fake contests", "Concursos falsos"),
        T3("Faux abonnements", "Fake subscriptions", "Suscripciones falsas"),
        T3("Arnaques sentimentales", "Romance scams", "Estafas románticas"),
        T3("Chantage", "Blackmail", "Chantaje"),
        T3("Sextorsion", "Sextortion", "Sextorsión"),
        T3("Faux antivirus", "Fake antivirus", "Antivirus falsos"),
        T3("Faux support technique", "Tech support scams", "Soporte técnico falso"),
        T3("Fraude aux QR codes", "QR code fraud", "Fraude con códigos QR"),
        T3("Faux avis de paiement", "Fake payment notices", "Avisos de pago falsos"),
        T3("Faux récupérateurs de fonds", "Fake fund recovery", "Falsa recuperación de fondos"),
        T3("Faux messages de sécurité", "Fake security messages", "Mensajes de seguridad falsos"),
        T3("Faux comptes sociaux", "Fake social accounts", "Cuentas sociales falsas"),
        T3("Faux cloud", "Fake cloud", "Nube falsa"),
        T3("Faux hébergements", "Fake rentals", "Alojamientos falsos"),
        T3("Faux billets", "Fake tickets", "Entradas falsas"),
        T3("Faux marketplaces", "Fake marketplaces", "Marketplaces falsos"),
        T3("Fraude à la vente", "Sales fraud", "Fraude en la venta"),
        T3("Fraude à l’achat", "Purchase fraud", "Fraude en la compra"),
        T3("Faux documents", "Fake documents", "Documentos falsos"),
        T3("Malwares", "Malware", "Malware"),
        T3("Ransomware", "Ransomware", "Ransomware"),
        T3("Collecte de données", "Data harvesting", "Recolección de datos"),
        T3("Arnaques à l’identité", "Identity scams", "Estafas de identidad"),
    ]

    public static let learnTopics: [T3] = [
        T3("Comprendre le phishing", "Understand phishing", "Entender el phishing"),
        T3("Reconnaître un faux email", "Spot a fake email", "Reconocer un correo falso"),
        T3("Reconnaître un faux SMS", "Spot a fake SMS", "Reconocer un SMS falso"),
        T3("Vérifier un lien", "Check a link", "Verificar un enlace"),
        T3("Vérifier un expéditeur", "Check a sender", "Verificar un remitente"),
        T3("Comprendre les domaines", "Understand domains", "Entender los dominios"),
        T3("Les mots de passe", "Passwords", "Las contraseñas"),
        T3("L’authentification multifacteur", "Multi-factor authentication", "La autenticación multifactor"),
        T3("Les faux documents", "Fake documents", "Los documentos falsos"),
        T3("Les fraudes bancaires", "Bank fraud", "Los fraudes bancarios"),
        T3("Les QR codes dangereux", "Dangerous QR codes", "Los códigos QR peligrosos"),
        T3("Les arnaques aux crypto", "Crypto scams", "Las estafas cripto"),
        T3("Les techniques de manipulation", "Manipulation techniques", "Las técnicas de manipulación"),
    ]

    public static let quiz: [(url: String, real: Bool, why: T3)] = [
        (
            "https://www.paypal.com/signin",
            true,
            T3("Le domaine enregistré est bien paypal.com, en HTTPS.", "The registered domain is indeed paypal.com, over HTTPS.", "El dominio registrado es efectivamente paypal.com, con HTTPS."),
        ),
        (
            "https://paypal.com.account-check.example/login",
            false,
            T3("Le vrai domaine est account-check.example : « paypal.com » n’est qu’un sous-domaine.", "The real domain is account-check.example: “paypal.com” is only a subdomain.", "El dominio real es account-check.example: «paypal.com» solo es un subdominio."),
        ),
        (
            "https://amaz0n-orders.example/track",
            false,
            T3("Un zéro remplace le « o » : c’est du typosquatting.", "A zero replaces the “o”: that is typosquatting.", "Un cero sustituye a la «o»: es typosquatting."),
        ),
        (
            "http://192.168.12.4/bank/verify",
            false,
            T3("Une banque n’envoie jamais vers une adresse IP, en HTTP non chiffré.", "A bank never sends you to an IP address over unencrypted HTTP.", "Un banco nunca te envía a una dirección IP por HTTP sin cifrar."),
        ),
        (
            "https://www.service-public.fr/particuliers",
            true,
            T3("Le domaine officiel de l’administration française, sans détour.", "The official domain of the French administration, straight up.", "El dominio oficial de la administración francesa, sin rodeos."),
        ),
        (
            "https://bit.ly/3xYz-colis",
            false,
            T3("Un lien raccourci cache sa destination : vérifiez-la avant d’ouvrir.", "A short link hides its destination: check it before opening.", "Un enlace acortado oculta su destino: compruébalo antes de abrir."),
        ),
    ]

    public static let zenaiQuestions: [T3] = [
        T3("Pourquoi ce mail est-il suspect ?", "Why is this email suspicious?", "¿Por qué es sospechoso este correo?"),
        T3("Quel type d’arnaque est-ce ?", "What kind of scam is it?", "¿Qué tipo de estafa es?"),
        T3("Qui est réellement l’expéditeur ?", "Who is the real sender?", "¿Quién es realmente el remitente?"),
        T3("Est-ce que le lien est dangereux ?", "Is the link dangerous?", "¿Es peligroso el enlace?"),
        T3("Est-ce que je peux ouvrir le fichier ?", "Can I open the file?", "¿Puedo abrir el archivo?"),
        T3("Est-ce que je dois répondre ?", "Should I reply?", "¿Debo responder?"),
        T3("Comment vérifier l’entreprise ?", "How do I check the company?", "¿Cómo verifico la empresa?"),
        T3("Que faire si j’ai cliqué ?", "What if I clicked?", "¿Qué hago si hice clic?"),
        T3("Que faire si j’ai donné mon mot de passe ?", "What if I gave my password?", "¿Qué hago si di mi contraseña?"),
        T3("Comment signaler ce mail ?", "How do I report this email?", "¿Cómo denuncio este correo?"),
        T3("Est-ce que je peux récupérer mon argent ?", "Can I get my money back?", "¿Puedo recuperar mi dinero?"),
        T3("Comment bloquer cet expéditeur ?", "How do I block this sender?", "¿Cómo bloqueo a este remitente?"),
    ]

    public static let privacy: [T3] = [
        T3("Analyse locale prioritaire", "Local analysis first", "Análisis local prioritario"),
        T3("Pas de compte obligatoire", "No account required", "Sin cuenta obligatoria"),
        T3("Pas de stockage cloud par défaut", "No cloud storage by default", "Sin almacenamiento en la nube por defecto"),
        T3("Consentement explicite", "Explicit consent", "Consentimiento explícito"),
        T3("Minimisation des données", "Data minimization", "Minimización de datos"),
        T3("Chiffrement local", "Local encryption", "Cifrado local"),
        T3("Protection des clés", "Key protection", "Protección de claves"),
        T3("Suppression des données", "Data deletion", "Eliminación de datos"),
        T3("Historique local", "Local history", "Historial local"),
        T3("Contrôle des permissions", "Permission control", "Control de permisos"),
        T3("Sources externes transparentes", "Transparent external sources", "Fuentes externas transparentes"),
        T3("Aucune publicité ciblée", "No targeted ads", "Sin publicidad dirigida"),
        T3("Aucune revente de données", "No data resale", "Sin reventa de datos"),
        T3("Données personnelles protégées", "Personal data protected", "Datos personales protegidos"),
        T3("Politique lisible", "A readable policy", "Una política legible"),
    ]

}
