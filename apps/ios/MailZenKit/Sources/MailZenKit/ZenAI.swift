import Foundation

/// ZenAI: the assistant of MailZen. It answers from the results of the engine only: the
/// signals found, the sender, the links, the attachments. It treats the content of an
/// email as untrusted data (it never follows what an email says), never invents evidence,
/// and says what it cannot know.
public enum ZenAI {
    public enum Intent: String, CaseIterable, Sendable {
        case why, sender, link, file, reply, verify, clicked, password, report, money, summary
    }

    /// The suggested questions, in the order of the content.
    public static var suggestions: [(Intent, T3)] {
        let intents: [Intent] = [.why, .sender, .link, .file, .reply, .verify, .clicked, .password, .report, .money]
        return Array(zip(intents, Library.zenaiQuestions))
    }

    private static let keywords: [(Intent, [String])] = [
        (.password, ["mot de passe", "password", "contraseña", "identifiant"]),
        (.money, ["argent", "rembours", "virement", "money", "refund", "dinero", "recuperar", "payé", "paid", "pagado"]),
        (.clicked, ["cliqué", "clicked", "clic", "click", "ouvert le lien", "hice clic"]),
        (.file, ["fichier", "pièce jointe", "file", "attachment", "archivo", "adjunto", "pdf"]),
        (.link, ["lien", "link", "enlace", "url", "site"]),
        (.sender, ["expéditeur", "sender", "remitente", "qui", "who", "quién", "adresse", "address"]),
        (.reply, ["répondre", "reply", "responder", "réponse"]),
        (.verify, ["vérifier", "verify", "verificar", "entreprise", "company", "empresa", "officiel", "official"]),
        (.report, ["signaler", "report", "denunciar", "signalement"]),
        (.why, ["pourquoi", "why", "por qué", "dangereux", "suspect", "dangerous", "peligroso"]),
    ]

    /// The intent of a free question: the trained model when it is sure enough, the
    /// keywords otherwise.
    public static func intent(of question: String) -> Intent {
        if let models = Models.shared {
            let guess = models.intent(question)
            if guess.probability >= 0.45, let intent = Intent(rawValue: guess.label) {
                return intent
            }
        }
        let q = question.lowercased()
        return keywords.first { $0.1.contains { q.contains($0) } }?.0 ?? .summary
    }

    /// What the trained models say, in words.
    static func modelLines(_ report: Report) -> [String] {
        guard let m = report.model else { return [] }
        let pct = Int((m.probability * 100).rounded())
        if m.probability >= 0.5 {
            var lines = [tr("Mon modèle entraîné estime à \(pct) % que ce texte ressemble à des arnaques connues.",
                            "My trained model rates at \(pct)% the likelihood that this text looks like known scams.",
                            "Mi modelo entrenado estima en un \(pct) % que este texto se parece a estafas conocidas.")]
            if let c = m.category {
                let cp = Int((m.categoryProbability * 100).rounded())
                lines.append(tr("Il ressemble surtout à : \(c.label.fr) (confiance \(cp) %). ",
                                "It mostly looks like: \(c.label.en) (\(cp)% confidence). ",
                                "Se parece sobre todo a: \(c.label.es) (confianza \(cp) %). ") + c.advice.localized)
            }
            return lines
        }
        if m.probability <= 0.2 {
            return [tr("Mon modèle entraîné ne reconnaît pas de tournure d’arnaque (\(pct) %).",
                       "My trained model recognizes no scam wording (\(pct)%).",
                       "Mi modelo entrenado no reconoce redacción de estafa (\(pct) %).")]
        }
        return [tr("Mon modèle entraîné hésite (\(pct) %) : fiez-vous aux preuves ci-dessus.",
                   "My trained model is unsure (\(pct)%): rely on the evidence above.",
                   "Mi modelo entrenado duda (\(pct) %): fíate de las pruebas anteriores.")]
    }

    public static func answer(question: String, report: Report, message: EmailMessage?) -> [String] {
        answer(intent(of: question), report: report, message: message)
    }

    /// The answer, in paragraphs, in the language of the device.
    public static func answer(_ intent: Intent, report: Report, message: EmailMessage?) -> [String] {
        let verdict = report.verdict.title.localized
        func bullets(_ signals: [Signal]) -> [String] {
            signals.prefix(5).map { "• \($0.rule.title.localized) — \($0.rule.explanation.localized)" }
        }
        switch intent {
        case .summary:
            return [
                tr("Verdict : \(verdict), \(report.score)/100, confiance \(report.confidenceLabel.fr.lowercased()).",
                   "Verdict: \(verdict), \(report.score)/100, \(report.confidenceLabel.en.lowercased()) confidence.",
                   "Veredicto: \(verdict), \(report.score)/100, confianza \(report.confidenceLabel.es.lowercased())."),
            ] + modelLines(report) + [
                report.verdict.advice.localized,
                tr("Posez-moi une question : pourquoi c’est suspect, qui est l’expéditeur, si le lien est dangereux…",
                   "Ask me a question: why it is suspicious, who the sender is, whether the link is dangerous…",
                   "Hazme una pregunta: por qué es sospechoso, quién es el remitente, si el enlace es peligroso…"),
            ]
        case .why:
            guard !report.signals.isEmpty else {
                return [tr("Je n’ai relevé aucun signal important dans ce message. Cela ne garantit pas qu’il soit sans danger : restez attentif à toute demande inhabituelle.",
                           "I found no significant signal in this message. That does not guarantee it is safe: stay alert to any unusual request.",
                           "No he encontrado ninguna señal importante en este mensaje. Eso no garantiza que sea seguro: atento a cualquier petición inusual.")]
                    + modelLines(report)
            }
            return [tr("Ce message présente \(report.signals.count) élément(s) préoccupant(s) :",
                       "This message shows \(report.signals.count) worrying element(s):",
                       "Este mensaje presenta \(report.signals.count) elemento(s) preocupante(s):")]
                + bullets(report.signals) + modelLines(report) + [report.verdict.advice.localized]
        case .sender:
            guard let address = message?.fromAddress, let domain = emailDomain(address) else {
                return [tr("Je ne vois pas d’adresse d’expéditeur dans ce message : je ne peux pas dire qui l’a envoyé. Ne vous fiez pas au nom affiché.",
                           "I see no sender address in this message: I cannot tell who sent it. Do not trust the display name.",
                           "No veo dirección de remitente en este mensaje: no puedo saber quién lo envió. No te fíes del nombre mostrado.")]
            }
            var lines = [tr("L’adresse réelle est \(address) (domaine \(domain)).", "The real address is \(address) (domain \(domain)).", "La dirección real es \(address) (dominio \(domain)).")]
            switch Brands.check(domain) {
            case .official(let brand):
                lines.append(tr("C’est un domaine officiel de \(brand.name). L’adresse d’expédition peut néanmoins être falsifiée : les vérifications SPF, DKIM et DMARC le confirment quand les en-têtes sont disponibles.",
                                "It is an official domain of \(brand.name). The sending address can still be forged: SPF, DKIM and DMARC checks confirm it when headers are available.",
                                "Es un dominio oficial de \(brand.name). La dirección puede falsificarse: SPF, DKIM y DMARC lo confirman cuando hay cabeceras."))
            case .imitation(let brand, let reason):
                lines.append(tr("Ce n’est pas un domaine de \(brand.name). ", "This is not a \(brand.name) domain. ", "No es un dominio de \(brand.name). ") + reason.localized)
            case .brand, .unknown:
                lines.append(tr("Je ne connais pas ce domaine : je ne peux ni confirmer ni infirmer l’identité de l’expéditeur.",
                                "I do not know this domain: I can neither confirm nor deny the sender’s identity.",
                                "No conozco este dominio: no puedo confirmar ni desmentir la identidad del remitente."))
            }
            lines += bullets(report.signals.filter { $0.rule.family == .sender || $0.rule == .authFailure || $0.rule == .brandMismatch })
            return lines
        case .link:
            guard !report.links.isEmpty else {
                return [tr("Je n’ai trouvé aucun lien dans ce message.", "I found no link in this message.", "No he encontrado ningún enlace en este mensaje.")]
            }
            var lines = report.links.prefix(5).map { link in
                (link.risky ? "⚠️ " : "✓ ") + link.host
            }
            let reasons = report.signals.filter { $0.rule.family == .link || $0.rule == .brandMismatch || $0.rule == .lookalike }
            if reasons.isEmpty {
                lines.append(tr("Je n’ai pas relevé de signal sur ces liens. Avant de saisir des données, vérifiez quand même l’adresse dans la barre du navigateur.",
                                "I found no signal on these links. Before entering any data, still check the address in the browser bar.",
                                "No he encontrado señales en estos enlaces. Antes de introducir datos, comprueba la dirección en la barra del navegador."))
            } else {
                lines += bullets(reasons)
                lines.append(tr("Ne l’ouvrez pas. Si vous devez accéder au service, tapez son adresse vous-même ou utilisez son application officielle.",
                                "Do not open it. If you need the service, type its address yourself or use its official app.",
                                "No lo abras. Si necesitas el servicio, escribe tú mismo su dirección o usa su app oficial."))
            }
            return lines
        case .file:
            guard let attachments = message?.attachments, !attachments.isEmpty else {
                return [tr("Ce message n’a pas de pièce jointe que je puisse analyser. Pour un fichier seul, utilisez le mode Fichier du scanner.",
                           "This message has no attachment I can analyze. For a file alone, use the File mode of the scanner.",
                           "Este mensaje no tiene adjuntos que pueda analizar. Para un archivo suelto, usa el modo Archivo del escáner.")]
            }
            var lines: [String] = []
            for attachment in attachments.prefix(4) {
                let analysis = attachment.analysis
                lines.append("📎 \(attachment.filename) — \(analysis.kind.label.localized), \(analysis.report.verdict.title.localized)")
                lines += bullets(analysis.report.signals)
            }
            lines.append(tr("Une analyse statique ne détecte pas tous les malwares : en cas de doute, n’ouvrez pas le fichier et demandez à l’expéditeur par un autre canal.",
                            "Static analysis does not catch every malware: when in doubt, do not open the file and ask the sender through another channel.",
                            "Un análisis estático no detecta todo el malware: ante la duda, no abras el archivo y pregunta al remitente por otro canal."))
            return lines
        case .reply:
            if report.verdict == .suspicious || report.verdict == .danger {
                return [tr("Je vous déconseille de répondre : une réponse confirme que votre adresse est active et ouvre la porte à d’autres tentatives.",
                           "I advise you not to reply: a reply confirms your address is active and invites more attempts.",
                           "Te aconsejo no responder: una respuesta confirma que tu dirección está activa y abre la puerta a más intentos."),
                        tr("Pour vérifier, contactez l’organisme par un canal officiel : Safe Reply prépare le message pour vous.",
                           "To check, contact the organization through an official channel: Safe Reply prepares the message for you.",
                           "Para verificar, contacta con el organismo por un canal oficial: Safe Reply prepara el mensaje.")]
            }
            return [tr("Rien n’interdit de répondre, mais ne communiquez ni mot de passe, ni code, ni coordonnées bancaires par email.",
                       "Nothing prevents a reply, but never share a password, a code or bank details by email.",
                       "Nada impide responder, pero nunca compartas contraseñas, códigos ni datos bancarios por correo.")]
        case .verify:
            let text = (message?.analysisText ?? "").lowercased()
            let named = Brands.all.filter { containsWord(text, $0.key) }
            var lines = named.prefix(3).map { brand in
                tr("Domaine(s) officiel(s) de \(brand.name) : ", "Official domain(s) of \(brand.name): ", "Dominio(s) oficial(es) de \(brand.name): ") + brand.domains.joined(separator: ", ")
            }
            lines.append(tr("Passez par l’application officielle, le site que vous tapez vous-même, ou le numéro inscrit sur votre carte ou votre contrat. N’utilisez jamais les coordonnées données dans le message.",
                            "Use the official app, a website you type yourself, or the number on your card or contract. Never use the contact details given in the message.",
                            "Usa la app oficial, una web que escribas tú mismo o el número de tu tarjeta o contrato. Nunca uses los datos de contacto del mensaje."))
            return lines
        case .clicked:
            return steps(Library.scenarios[0])
        case .password:
            return steps(Library.scenarios[3])
        case .money:
            return steps(Library.scenarios[5])
        case .report:
            return [
                tr("En France :", "In France:", "En Francia:"),
                "• Signal Spam — signal-spam.fr",
                tr("• SMS frauduleux : transférez-le au 33700", "• Scam SMS: forward it to 33700", "• SMS fraudulento: reenvíalo al 33700"),
                tr("• Assistance aux victimes : cybermalveillance.gouv.fr", "• Victim support: cybermalveillance.gouv.fr", "• Ayuda a víctimas: cybermalveillance.gouv.fr"),
                tr("Vous pouvez aussi utiliser « Signaler comme indésirable » dans votre messagerie, puis supprimer le message.",
                   "You can also use “Report as junk” in your mail app, then delete the message.",
                   "También puedes usar «Marcar como no deseado» en tu correo y luego borrar el mensaje."),
            ]
        }
    }

    private static func steps(_ scenario: Scenario) -> [String] {
        [scenario.title.localized + " :"]
            + scenario.steps.enumerated().map { "\($0.offset + 1). \($0.element.localized)" }
            + [tr("Vous n’êtes pas seul : SOS Cyber vous guide pas à pas.", "You are not alone: SOS Cyber guides you step by step.", "No estás solo: SOS Cyber te guía paso a paso.")]
    }
}

/// Safe Reply: messages ready to send, that never answer the suspicious email itself.
public enum SafeReply {
    public struct Template: Sendable, Hashable {
        public let title: T3
        public let text: String
    }

    public static func templates(report: Report, message: EmailMessage?) -> [Template] {
        let subject = message?.subject ?? tr("(sans objet)", "(no subject)", "(sin asunto)")
        let from = message?.fromAddress ?? tr("(expéditeur inconnu)", "(unknown sender)", "(remitente desconocido)")
        let verdict = report.verdict.title.localized
        var list = [
            Template(
                title: T3("Vérifier auprès du service officiel", "Check with the official service", "Verificar con el servicio oficial"),
                text: tr("Bonjour,\n\nJ’ai reçu un message se présentant comme venant de vous (objet : « \(subject) », expéditeur : \(from)). Pouvez-vous me confirmer s’il est authentique ? Je n’ai cliqué sur aucun lien et je n’ai communiqué aucune information.\n\nMerci.",
                         "Hello,\n\nI received a message claiming to come from you (subject: “\(subject)”, sender: \(from)). Can you confirm whether it is genuine? I have not clicked any link nor shared any information.\n\nThank you.",
                         "Hola:\n\nHe recibido un mensaje que dice venir de ustedes (asunto: «\(subject)», remitente: \(from)). ¿Pueden confirmarme si es auténtico? No he hecho clic en ningún enlace ni he compartido información.\n\nGracias.")),
            Template(
                title: T3("Prévenir un proche", "Warn a relative", "Avisar a un familiar"),
                text: tr("Attention : j’ai reçu un email suspect (« \(subject) », de \(from)). MailZen l’a classé « \(verdict) » (\(report.score)/100). Si tu reçois le même, ne clique sur rien et ne réponds pas.",
                         "Heads up: I received a suspicious email (“\(subject)”, from \(from)). MailZen rated it “\(verdict)” (\(report.score)/100). If you get the same one, do not click anything and do not reply.",
                         "Atención: he recibido un correo sospechoso («\(subject)», de \(from)). MailZen lo ha calificado «\(verdict)» (\(report.score)/100). Si te llega el mismo, no hagas clic ni respondas.")),
        ]
        if report.verdict == .safe || report.verdict == .caution {
            list.append(Template(
                title: T3("Réponse neutre", "Neutral reply", "Respuesta neutra"),
                text: tr("Bonjour,\n\nMerci pour votre message. Je vais vérifier ces informations directement auprès de vos services, par vos canaux officiels.\n\nCordialement.",
                         "Hello,\n\nThank you for your message. I will check this information directly with your services, through your official channels.\n\nBest regards.",
                         "Hola:\n\nGracias por su mensaje. Verificaré esta información directamente con sus servicios, por sus canales oficiales.\n\nSaludos.")))
        }
        return list
    }
}
