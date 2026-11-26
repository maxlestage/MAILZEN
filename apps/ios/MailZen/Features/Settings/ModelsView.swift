import SwiftUI
import MailZenKit

/// Settings › On-device intelligence: what the trained models are, what they measured,
/// a playground to try them, the user's lists of senders and their corrections.
struct ModelsView: View {
    private var store: PersonalStore { PersonalStore.shared }
    private let manifest = Models.shared?.manifest
    @State private var confirmErase = false

    private func pct(_ value: Double, digits: Int = 1) -> String {
        value.formatted(.percent.precision(.fractionLength(digits)))
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(get: { store.useModels }, set: { store.setUseModels($0) })) {
                    Label(tr("Utiliser les modèles entraînés", "Use the trained models", "Usar los modelos entrenados"), systemImage: "cpu")
                }
                .tint(Theme.cyan)
                Toggle(isOn: Binding(get: { store.autonomous }, set: { store.setAutonomous($0) })) {
                    Label(tr("Laisser le modèle décider seul", "Let the model decide by itself", "Dejar que el modelo decida solo"), systemImage: "bolt.shield")
                }
                .tint(Theme.cyan)
                .disabled(!store.useModels)
            } footer: {
                Text(tr("Les modèles tournent sur l’iPhone, sans connexion : rien de ce que vous analysez n’en sort. Autonome, le modèle classe lui-même un message « Suspect » dès 90 % de certitude et « Danger élevé » dès 98 %, même si aucune règle ne s’est déclenchée. Sinon, il ajoute seulement un signal aux règles.",
                        "The models run on the iPhone, offline: nothing you analyze leaves it. Autonomous, the model itself rates a message “Suspicious” from 90% certainty and “High danger” from 98%, even when no rule fired. Otherwise it only adds a signal to the rules.",
                        "Los modelos funcionan en el iPhone, sin conexión: nada de lo que analizas sale de él. Autónomo, el modelo califica él mismo un mensaje como «Sospechoso» desde el 90 % de certeza y «Peligro elevado» desde el 98 %, aunque ninguna regla se active. Si no, solo añade una señal a las reglas."))
            }

            Section {
                HStack {
                    Label(tr("Corrections apprises", "Corrections learned", "Correcciones aprendidas"), systemImage: "graduationcap")
                    Spacer()
                    if store.learning {
                        ProgressView()
                    } else {
                        Text("\(store.learned.examples)").foregroundStyle(Theme.muted)
                    }
                }
                LabeledContent(tr("Poids ajustés pour vous", "Weights adjusted for you", "Pesos ajustados para ti"), value: store.learned.weights.count.formatted())
            } header: {
                Text(tr("Apprentissage sur l’appareil", "On-device learning", "Aprendizaje en el dispositivo"))
            } footer: {
                Text(tr("À chaque correction (« MailZen s’est trompé ? » en bas d’un rapport), le modèle se réentraîne tout seul sur l’iPhone, en une fraction de seconde : il retient le message et reconnaît ensuite ceux qui lui ressemblent. Aucun ordinateur, aucun serveur.",
                        "At each correction (“Did MailZen get it wrong?” at the bottom of a report), the model retrains by itself on the iPhone, in a fraction of a second: it remembers the message and then recognizes those that resemble it. No computer, no server.",
                        "Con cada corrección («¿MailZen se ha equivocado?» al final de un informe), el modelo se reentrena solo en el iPhone, en una fracción de segundo: recuerda el mensaje y luego reconoce los que se le parecen. Sin ordenador ni servidor."))
            }

            if let m = manifest {
                Section(tr("Les modèles", "The models", "Los modelos") + " · " + m.version) {
                    modelRow("text.magnifyingglass", tr("Arnaques et phishing", "Scams and phishing", "Estafas y phishing"),
                             tr("\(pct(m.scam.accuracy)) d’exactitude sur des messages jamais vus. Au seuil retenu : \(pct(m.scam.falsePositives09)) de fausses alertes, \(pct(m.scam.recall09, digits: 0)) des arnaques reconnues. \(m.scam.messages.formatted()) messages d’entraînement.",
                                "\(pct(m.scam.accuracy)) accuracy on unseen messages. At the chosen threshold: \(pct(m.scam.falsePositives09)) false alarms, \(pct(m.scam.recall09, digits: 0)) of scams recognized. \(m.scam.messages.formatted()) training messages.",
                                "\(pct(m.scam.accuracy)) de exactitud en mensajes nunca vistos. En el umbral elegido: \(pct(m.scam.falsePositives09)) de falsas alarmas, \(pct(m.scam.recall09, digits: 0)) de estafas reconocidas. \(m.scam.messages.formatted()) mensajes de entrenamiento."))
                    modelRow("link", tr("Liens", "Links", "Enlaces"),
                             tr("Entraîné sur \(m.url.links.formatted()) adresses. Sur des domaines jamais vus, au seuil retenu : \(pct(m.url.falsePositives095)) de fausses alertes, \(pct(m.url.recall095, digits: 0)) des liens de phishing reconnus. Jamais appliqué aux domaines officiels vérifiés.",
                                "Trained on \(m.url.links.formatted()) addresses. On unseen domains, at the chosen threshold: \(pct(m.url.falsePositives095)) false alarms, \(pct(m.url.recall095, digits: 0)) of phishing links recognized. Never applied to verified official domains.",
                                "Entrenado con \(m.url.links.formatted()) direcciones. En dominios nunca vistos, en el umbral elegido: \(pct(m.url.falsePositives095)) de falsas alarmas, \(pct(m.url.recall095, digits: 0)) de enlaces de phishing reconocidos. Nunca se aplica a dominios oficiales verificados."))
                    modelRow("square.grid.3x3", tr("Familles d’arnaques", "Families of scams", "Familias de estafas"),
                             tr("\(m.category.families) familles, \(pct(m.category.accuracy, digits: 0)) de bonnes réponses sur des messages d’un type jamais vu. Affichée seulement quand le modèle est assez sûr.",
                                "\(m.category.families) families, \(pct(m.category.accuracy, digits: 0)) right on messages of an unseen kind. Shown only when the model is sure enough.",
                                "\(m.category.families) familias, \(pct(m.category.accuracy, digits: 0)) de aciertos en mensajes de un tipo nunca visto. Solo se muestra cuando el modelo está bastante seguro."))
                    modelRow("bubble.left.and.text.bubble.right", tr("Questions à ZenAI", "Questions to ZenAI", "Preguntas a ZenAI"),
                             tr("\(m.intent.intents) sujets reconnus, le bon dans \(pct(m.intent.accuracy, digits: 0)) des cas sur des formulations jamais vues. Pour toute autre question, ZenAI répond à partir de tous les faits de l’analyse.",
                                "\(m.intent.intents) topics recognized, the right one \(pct(m.intent.accuracy, digits: 0)) of the time on unseen phrasings. For any other question, ZenAI answers from every fact of the analysis.",
                                "\(m.intent.intents) temas reconocidos, el correcto en el \(pct(m.intent.accuracy, digits: 0)) de los casos con formulaciones nunca vistas. Para cualquier otra pregunta, ZenAI responde a partir de todos los hechos del análisis."))
                    modelRow("sparkles", "Apple Intelligence",
                             OnDeviceModel.isAvailable
                             ? tr("Disponible : ZenAI reformule ses réponses à partir des seuls faits de l’analyse, jamais du contenu de l’email.",
                                  "Available: ZenAI rephrases its answers from the facts of the analysis only, never from the content of the email.",
                                  "Disponible: ZenAI reformula sus respuestas solo a partir de los hechos del análisis, nunca del contenido del correo.")
                             : tr("Indisponible sur cet iPhone (iOS 26 et un appareil compatible requis) : ZenAI répond avec ses propres phrases.",
                                  "Unavailable on this iPhone (iOS 26 and a compatible device required): ZenAI answers with its own sentences.",
                                  "No disponible en este iPhone (requiere iOS 26 y un dispositivo compatible): ZenAI responde con sus propias frases."))
                }
            }

            Section {
                NavigationLink { ModelPlaygroundView() } label: {
                    Label(tr("Essayer les modèles", "Try the models", "Probar los modelos"), systemImage: "testtube.2")
                }
            }

            Section(tr("Expéditeurs de confiance", "Trusted senders", "Remitentes de confianza")) {
                if store.lists.trusted.isEmpty {
                    Text(tr("Aucun pour l’instant : indiquez-en un depuis un rapport.", "None yet: add one from a report.", "Ninguno por ahora: añade uno desde un informe."))
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                ForEach(store.lists.trusted.sorted(), id: \.self) { key in
                    Label(key, systemImage: "person.crop.circle.badge.checkmark").foregroundStyle(Theme.text)
                        .swipeActions { Button(tr("Retirer", "Remove", "Quitar"), role: .destructive) { store.remove(key) } }
                }
            }
            Section(tr("Expéditeurs bloqués", "Blocked senders", "Remitentes bloqueados")) {
                if store.lists.blocked.isEmpty {
                    Text(tr("Aucun pour l’instant.", "None yet.", "Ninguno por ahora."))
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                ForEach(store.lists.blocked.sorted(), id: \.self) { key in
                    Label(key, systemImage: "person.crop.circle.badge.xmark").foregroundStyle(Theme.text)
                        .swipeActions { Button(tr("Débloquer", "Unblock", "Desbloquear"), role: .destructive) { store.remove(key) } }
                }
            }

            Section {
                LabeledContent(tr("Corrections enregistrées", "Saved corrections", "Correcciones guardadas"), value: "\(store.corrections.count)")
                if !store.corrections.isEmpty {
                    NavigationLink { CorrectionsView() } label: {
                        Label(tr("Voir les corrections", "See the corrections", "Ver las correcciones"), systemImage: "list.bullet")
                    }
                    if let file = store.exportFile() {
                        ShareLink(item: file) {
                            Label(tr("Exporter pour réentraîner", "Export to retrain", "Exportar para reentrenar"), systemImage: "square.and.arrow.up")
                        }
                    }
                    Button(role: .destructive) { confirmErase = true } label: {
                        Label(tr("Effacer les corrections", "Erase the corrections", "Borrar las correcciones"), systemImage: "trash")
                    }
                }
            } header: {
                Text(tr("Vos corrections", "Your corrections", "Tus correcciones"))
            } footer: {
                Text(tr("Les corrections restent sur l’iPhone et le modèle les apprend tout seul. L’export est facultatif : il sert à améliorer le modèle de base pour tout le monde (ml/train.py --feedback). Il contient le texte des messages : ne le partagez qu’avec une personne de confiance.",
                        "Corrections stay on the iPhone and the model learns them by itself. Exporting is optional: it improves the base model for everyone (ml/train.py --feedback). It contains the text of the messages: share it only with someone you trust.",
                        "Las correcciones se quedan en el iPhone y el modelo las aprende solo. Exportar es opcional: sirve para mejorar el modelo base para todos (ml/train.py --feedback). Contiene el texto de los mensajes: compártelo solo con alguien de confianza."))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Intelligence sur l’appareil", "On-device intelligence", "Inteligencia en el dispositivo"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(tr("Effacer toutes les corrections ?", "Erase all the corrections?", "¿Borrar todas las correcciones?"), isPresented: $confirmErase, titleVisibility: .visible) {
            Button(tr("Effacer", "Erase", "Borrar"), role: .destructive) { store.eraseCorrections() }
        }
    }

    private func modelRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.cyanLight).frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                Text(detail).font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 2)
    }
}

/// The saved corrections, newest first.
struct CorrectionsView: View {
    private var store: PersonalStore { PersonalStore.shared }

    var body: some View {
        List {
            ForEach(store.corrections.sorted { $0.date > $1.date }) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: c.label == 1 ? "xmark.shield.fill" : "checkmark.shield.fill")
                            .foregroundStyle(c.label == 1 ? Theme.danger : Theme.safe)
                        Text(c.label == 1 ? tr("Arnaque", "Scam", "Estafa") : tr("Légitime", "Legitimate", "Legítimo"))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                        if let raw = c.category, let category = ScamCategory(rawValue: raw) {
                            Text("· " + category.label.localized).font(.caption).foregroundStyle(Theme.muted).lineLimit(1)
                        }
                        Spacer()
                        Text(c.date, style: .date).font(.caption2).foregroundStyle(Theme.muted)
                    }
                    Text(c.text).font(.footnote).foregroundStyle(Theme.muted).lineLimit(3)
                    Text(tr("MailZen avait dit : ", "MailZen had said: ", "MailZen había dicho: ") + (Verdict(rawValue: c.verdict)?.title.localized ?? c.verdict) + " (\(c.score)/100)")
                        .font(.caption2).foregroundStyle(Theme.muted)
                }
            }
            .onDelete { store.deleteCorrections(at: $0) }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Corrections", "Corrections", "Correcciones"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Type anything and see what each model says, live.
struct ModelPlaygroundView: View {
    @State private var text = ""
    @State private var question = ""

    private var models: Models? { Models.shared }

    var body: some View {
        List {
            Section(tr("Un message", "A message", "Un mensaje")) {
                TextField(tr("Collez un SMS, un email ou un lien…", "Paste a text, an email or a link…", "Pega un SMS, un correo o un enlace…"), text: $text, axis: .vertical)
                    .lineLimit(3...10)
                if let models, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let p = models.scamProbability(text)
                    meter(tr("Ressemblance avec des arnaques", "Resemblance to scams", "Parecido con estafas"), p, danger: p >= 0.9)
                    let c = models.category(text)
                    if p >= 0.5, let category = ScamCategory(rawValue: c.label) {
                        LabeledContent(tr("Famille la plus proche", "Closest family", "Familia más cercana"),
                                       value: "\(category.label.localized) · \(Int((c.probability * 100).rounded())) %")
                            .font(.footnote)
                    }
                    ForEach(extractURLs(text), id: \.self) { url in
                        let h = host(of: url)
                        if Brands.official(h) != nil {
                            LabeledContent(h, value: tr("officiel vérifié", "verified official", "oficial verificado")).font(.footnote)
                        } else {
                            let lp = models.linkProbability(url)
                            meter(h, lp, danger: lp >= 0.95)
                        }
                    }
                }
            }
            Section(tr("Une question à ZenAI", "A question to ZenAI", "Una pregunta a ZenAI")) {
                TextField(tr("Ex. : je peux cliquer ?", "E.g. can I click?", "Ej.: ¿puedo hacer clic?"), text: $question)
                if !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let intent = ZenAI.intent(of: question)
                    let guess = models?.intent(question)
                    LabeledContent(tr("Sujet compris", "Topic understood", "Tema entendido"), value: intent.rawValue)
                    if let guess {
                        LabeledContent(tr("Confiance du modèle", "Model confidence", "Confianza del modelo"), value: "\(Int((guess.probability * 100).rounded())) %")
                    }
                }
            }
            .font(.footnote)
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle(tr("Essayer les modèles", "Try the models", "Probar los modelos"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func meter(_ title: String, _ p: Double, danger: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.footnote).foregroundStyle(Theme.text).lineLimit(1)
                Spacer()
                Text("\(Int((p * 100).rounded())) %").font(.footnote.monospacedDigit().weight(.semibold))
                    .foregroundStyle(danger ? Theme.danger : (p >= 0.5 ? Theme.caution : Theme.safe))
            }
            ProgressView(value: p).tint(danger ? Theme.danger : (p >= 0.5 ? Theme.caution : Theme.safe))
        }
        .animation(.snappy, value: p)
    }
}
