import SwiftUI
import MailZenKit

/// The mailboxes: every account, a unified inbox, the folders of each account, and every
/// message, page by page.
struct MailboxView: View {
    @Environment(MailboxService.self) private var mailbox
    @State private var adding = false
    @State private var removing: MailAccount?

    static let inbox = IMAPFolder(name: "INBOX", delimiter: "/", flags: [])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if mailbox.accounts.isEmpty {
                    AddMailboxForm {}
                } else {
                    accounts
                }
                MailboxPromises()
            }
            .padding()
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: mailbox.accounts)
        }
        .background(AppBackground())
        .navigationTitle(tr("Boîtes mail", "Mailboxes", "Buzones"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !mailbox.accounts.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button { adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel(tr("Ajouter une boîte", "Add a mailbox", "Añadir un buzón"))
                }
            }
        }
        .sheet(isPresented: $adding) {
            NavigationStack {
                ScrollView { AddMailboxForm { adding = false }.padding() }
                    .background(AppBackground())
                    .navigationTitle(tr("Ajouter une boîte", "Add a mailbox", "Añadir un buzón"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(tr("Annuler", "Cancel", "Cancelar")) { adding = false }
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .confirmationDialog(tr("Déconnecter cette boîte ?", "Disconnect this mailbox?", "¿Desconectar este buzón?"),
                            isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
                            titleVisibility: .visible, presenting: removing) { account in
            Button(tr("Déconnecter \(account.email)", "Disconnect \(account.email)", "Desconectar \(account.email)"), role: .destructive) {
                mailbox.disconnect(account)
            }
        }
        .task { await mailbox.checkNow() }
    }

    private var accounts: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                MailListView(title: tr("Toutes les boîtes de réception", "All inboxes", "Todas las bandejas de entrada"),
                             sources: mailbox.accounts.map { MailSource(account: $0, folder: Self.inbox) })
            } label: {
                HStack(spacing: 14) {
                    PulseIcon(systemName: "tray.2.fill", tint: Theme.cyan)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("Toutes les boîtes de réception", "All inboxes", "Todas las bandejas de entrada"))
                            .font(.headline).foregroundStyle(Theme.text)
                        Text(tr("\(mailbox.accounts.count) boîte(s) · tous les emails, chacun analysé", "\(mailbox.accounts.count) mailbox(es) · every email, each analyzed", "\(mailbox.accounts.count) buzón(es) · todos los correos, cada uno analizado"))
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                }
                .card(tint: Theme.cyan.opacity(0.4))
            }
            .buttonStyle(.plain)

            ForEach(mailbox.accounts) { account in
                accountCard(account)
            }

            Button {
                Task { await mailbox.checkNow() }
            } label: {
                if mailbox.checking {
                    ProgressView().tint(.black)
                } else {
                    Label(tr("Vérifier maintenant", "Check now", "Comprobar ahora"), systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(mailbox.checking)
            if let error = mailbox.lastError {
                Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
            }
            Button { adding = true } label: {
                Label(tr("Ajouter une boîte mail", "Add a mailbox", "Añadir un buzón"), systemImage: "plus.circle")
            }
            .buttonStyle(GhostButtonStyle(tint: Theme.cyanLight))
            Text(tr("Les listes se chargent par pages de 30 emails, au fil du défilement, et se mettent à jour toutes les minutes tant qu’elles sont ouvertes. En arrière-plan, iOS réveille MailZen de temps en temps (de 15 minutes à quelques heures) pour vérifier les boîtes veillées.",
                    "Lists load 30 emails at a time as you scroll, and update every minute while they are open. In the background, iOS wakes MailZen from time to time (15 minutes to a few hours) to check the watched mailboxes.",
                    "Las listas se cargan de 30 en 30 correos al desplazarte y se actualizan cada minuto mientras están abiertas. En segundo plano, iOS despierta MailZen de vez en cuando (de 15 minutos a unas horas) para comprobar los buzones vigilados."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func accountCard(_ account: MailAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                AccountFoldersView(account: account)
            } label: {
                HStack(spacing: 12) {
                    IconBox(systemName: "tray.full.fill", tint: Theme.safe, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(account.email).font(.headline).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.8)
                        Text(account.host).font(.caption.monospaced()).foregroundStyle(Theme.muted)
                        Text(mailbox.status(of: account)).font(.caption).foregroundStyle(Theme.cyanLight)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: "folder").foregroundStyle(Theme.cyanLight)
                        Text(tr("Dossiers", "Folders", "Carpetas")).font(.caption2).foregroundStyle(Theme.muted)
                    }
                }
            }
            .buttonStyle(.plain)
            Toggle(isOn: Binding(get: { account.watching }, set: { mailbox.setWatching(account, $0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("Veille automatique", "Automatic watch", "Vigilancia automática")).font(.subheadline).foregroundStyle(Theme.text)
                    Text(tr("Une notification si un email dangereux arrive.", "A notification if a dangerous email arrives.", "Una notificación si llega un correo peligroso."))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
            }
            .tint(Theme.safe)
            Button(role: .destructive) { removing = account } label: {
                Label(tr("Déconnecter", "Disconnect", "Desconectar"), systemImage: "xmark.circle").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Theme.danger)
        }
        .card()
    }
}

/// Connect a mailbox over IMAP, with an app-specific password.
struct AddMailboxForm: View {
    @Environment(MailboxService.self) private var mailbox
    @State private var email = ""
    @State private var password = ""
    @State private var provider = MailProvider.all[0]
    @State private var host = ""
    @State private var reveal = false
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(eyebrow: tr("Connexion", "Sign in", "Conexión"), title: tr("Connectez votre boîte mail", "Connect your mailbox", "Conecta tu buzón"))
            Text(tr("MailZen affiche tous vos emails et tous vos dossiers en lecture seule, analyse chacun sur l’iPhone et vous prévient en cas de danger. Ils restent non lus dans votre messagerie. Ajoutez autant de boîtes que vous voulez.",
                    "MailZen shows all your emails and all your folders read-only, analyzes each one on the iPhone and warns you of any danger. They stay unread in your mail app. Add as many mailboxes as you like.",
                    "MailZen muestra todos tus correos y carpetas en modo solo lectura, analiza cada uno en el iPhone y te avisa si hay peligro. Siguen sin leer en tu correo. Añade tantos buzones como quieras."))
                .font(.subheadline).foregroundStyle(Theme.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MailProvider.all) { p in
                        Button { withAnimation { provider = p } } label: {
                            Chip(text: p.name, tint: provider == p ? Theme.cyan : Theme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            field(tr("Adresse email", "Email address", "Correo electrónico"), text: $email, secure: false)
                .onChange(of: email) { _, value in
                    let guess = MailProvider.guess(for: value)
                    if guess.id != "other" { provider = guess }
                }
            if provider.id == "other" {
                field(tr("Serveur IMAP (ex. imap.example.com)", "IMAP server (e.g. imap.example.com)", "Servidor IMAP (p. ej. imap.example.com)"), text: $host, secure: false)
            }
            field(tr("Mot de passe pour app (pas celui du compte)", "App-specific password (not the account one)", "Contraseña para apps (no la de la cuenta)"), text: $password, secure: !reveal, password: true)
                .overlay(alignment: .bottomTrailing) {
                    Button { reveal.toggle() } label: {
                        Image(systemName: reveal ? "eye.slash" : "eye").foregroundStyle(Theme.muted).padding(14)
                    }
                    .accessibilityLabel(reveal ? tr("Masquer", "Hide", "Ocultar") : tr("Afficher", "Show", "Mostrar"))
                }
            if provider.id != "other", password.contains(where: \.isWhitespace) {
                Label(tr("Les espaces du mot de passe seront retirés : ils ne servent qu’à le lire.", "The spaces of the password will be removed: they are only there to read it.", "Los espacios de la contraseña se quitarán: solo sirven para leerla."),
                      systemImage: "checkmark.circle").font(.caption).foregroundStyle(Theme.safe)
            }
            VStack(alignment: .leading, spacing: 6) {
                Label(provider.note.localized, systemImage: "key.fill").font(.footnote).foregroundStyle(Theme.muted)
                if let help = provider.passwordHelp {
                    Link(destination: help) {
                        Label(tr("Créer un mot de passe pour app", "Create an app password", "Crear una contraseña para apps"), systemImage: "arrow.up.right.square")
                            .font(.footnote.weight(.semibold))
                    }
                }
            }
            .card(padding: 12)
            Button {
                let server = provider.id == "other" ? host.trimmingCharacters(in: .whitespaces) : provider.host
                Task {
                    if await mailbox.connect(email: email.trimmingCharacters(in: .whitespaces), password: password, host: server) {
                        password = ""
                        email = ""
                        onDone()
                    }
                }
            } label: {
                if mailbox.checking {
                    ProgressView().tint(.black)
                } else {
                    Label(tr("Connecter", "Connect", "Conectar"), systemImage: "link")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(mailbox.checking || !email.contains("@") || password.isEmpty || (provider.id == "other" && host.isEmpty))
            if let error = mailbox.lastError {
                VStack(alignment: .leading, spacing: 8) {
                    Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
                    if let help = provider.passwordHelp {
                        Link(destination: help) {
                            Label(tr("Créer un nouveau mot de passe pour app", "Create a new app password", "Crear una nueva contraseña para apps"), systemImage: "arrow.up.right.square")
                                .font(.footnote.weight(.semibold))
                        }
                    }
                }
                .card(tint: Theme.suspicious.opacity(0.4), padding: 12)
            }
            Text(tr("Outlook et Hotmail demandent une connexion Microsoft dédiée, prévue dans une prochaine version.",
                    "Outlook and Hotmail require a dedicated Microsoft sign-in, planned for a future version.",
                    "Outlook y Hotmail requieren un inicio de sesión de Microsoft dedicado, previsto en una próxima versión."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func field(_ title: String, text: Binding<String>, secure: Bool, password: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
            Group {
                if secure {
                    // No password AutoFill: iOS would offer the account password (Google,
                    // Apple…), which the server refuses; an app password is needed.
                    SecureField("", text: text).textContentType(nil)
                } else {
                    TextField("", text: text)
                        .textContentType(password ? nil : .emailAddress)
                        .keyboardType(password ? .asciiCapable : .emailAddress)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(Theme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
            .foregroundStyle(Theme.text)
        }
    }
}

struct MailboxPromises: View {
    var body: some View {
        let items: [(String, String)] = [
            ("eye", tr("Lecture seule : vos emails restent non lus", "Read-only: your emails stay unread", "Solo lectura: tus correos siguen sin leer")),
            ("key.fill", tr("Un mot de passe pour app, jamais le vôtre", "An app password, never your own", "Una contraseña para apps, nunca la tuya")),
            ("lock.iphone", tr("Gardé dans le trousseau de cet iPhone", "Kept in this iPhone’s Keychain", "Guardada en el llavero de este iPhone")),
            ("cpu", tr("Analyse sur l’appareil, rien n’est envoyé", "Analyzed on the device, nothing sent", "Análisis en el dispositivo, nada se envía")),
        ]
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.1) { item in
                Label(item.1, systemImage: item.0).font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .card(tint: Theme.safe.opacity(0.3))
    }
}
