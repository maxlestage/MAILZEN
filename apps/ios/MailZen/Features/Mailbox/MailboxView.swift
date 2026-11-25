import SwiftUI
import MailZenKit

/// Connect a mailbox over IMAP (with an app-specific password), then watch it.
struct MailboxView: View {
    @Environment(MailboxService.self) private var mailbox
    @State private var email = ""
    @State private var password = ""
    @State private var provider = MailProvider.all[0]
    @State private var host = ""
    @State private var connected = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let account = mailbox.account {
                    watching(account)
                } else {
                    form
                }
                promises
            }
            .padding()
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: mailbox.account)
        }
        .background(AppBackground())
        .navigationTitle(tr("Boîte mail", "Mailbox", "Buzón"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Connected

    private func watching(_ account: MailAccount) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                PulseIcon(systemName: "tray.full.fill", tint: Theme.safe)
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.email).font(.headline).foregroundStyle(Theme.text)
                    Text(account.host).font(.caption.monospaced()).foregroundStyle(Theme.muted)
                    Text(mailbox.statusLine).font(.caption).foregroundStyle(Theme.cyanLight)
                }
            }
            Toggle(isOn: Binding(get: { account.watching }, set: { mailbox.setWatching($0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("Veille automatique", "Automatic watch", "Vigilancia automática")).foregroundStyle(Theme.text)
                    Text(tr("Une notification si un email dangereux arrive.", "A notification if a dangerous email arrives.", "Una notificación si llega un correo peligroso."))
                        .font(.caption).foregroundStyle(Theme.muted)
                }
            }
            .tint(Theme.safe)
            .card()
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
            if !mailbox.checking, account.lastCheck != nil {
                Text(mailbox.lastFound == 0
                     ? tr("Aucun nouvel email.", "No new email.", "Ningún correo nuevo.")
                     : tr("\(mailbox.lastFound) email(s) analysé(s), voir l’historique.", "\(mailbox.lastFound) email(s) analyzed, see the history.", "\(mailbox.lastFound) correo(s) analizado(s), ver el historial."))
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
            if let error = mailbox.lastError {
                Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
            }
            Text(tr("iOS réveille MailZen de temps en temps (en général toutes les 15 minutes à quelques heures, selon votre usage) : l’alerte n’est pas instantanée. Ouvrir l’app vérifie tout de suite.",
                    "iOS wakes MailZen from time to time (usually every 15 minutes to a few hours, depending on your use): the alert is not instant. Opening the app checks right away.",
                    "iOS despierta MailZen de vez en cuando (normalmente cada 15 minutos a unas horas, según tu uso): la alerta no es instantánea. Abrir la app comprueba al momento."))
                .font(.caption).foregroundStyle(Theme.muted)
            Button(role: .destructive) { mailbox.disconnect() } label: {
                Label(tr("Déconnecter cette boîte", "Disconnect this mailbox", "Desconectar este buzón"), systemImage: "xmark.circle")
            }
            .buttonStyle(GhostButtonStyle(tint: Theme.danger))
        }
        .task { if account.watching { await mailbox.checkNow() } }
    }

    // MARK: Form

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(eyebrow: tr("Connexion", "Sign in", "Conexión"), title: tr("Connectez votre boîte mail", "Connect your mailbox", "Conecta tu buzón"))
            Text(tr("MailZen lit vos nouveaux emails en lecture seule, les analyse sur l’iPhone et vous prévient en cas de danger. Ils restent non lus dans votre messagerie.",
                    "MailZen reads your new emails read-only, analyzes them on the iPhone and warns you of any danger. They stay unread in your mail app.",
                    "MailZen lee tus correos nuevos en modo solo lectura, los analiza en el iPhone y te avisa si hay peligro. Siguen sin leer en tu correo."))
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
            field(tr("Mot de passe pour app", "App-specific password", "Contraseña para apps"), text: $password, secure: true)
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
                Label(error, systemImage: "exclamationmark.triangle").font(.footnote).foregroundStyle(Theme.suspicious)
            }
            Text(tr("Outlook et Hotmail demandent une connexion Microsoft dédiée, prévue dans une prochaine version.",
                    "Outlook and Hotmail require a dedicated Microsoft sign-in, planned for a future version.",
                    "Outlook y Hotmail requieren un inicio de sesión de Microsoft dedicado, previsto en una próxima versión."))
                .font(.caption).foregroundStyle(Theme.muted)
        }
    }

    private func field(_ title: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
            Group {
                if secure {
                    SecureField("", text: text).textContentType(.password)
                } else {
                    TextField("", text: text).textContentType(.emailAddress).keyboardType(.emailAddress)
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

    private var promises: some View {
        let items: [(String, String)] = [
            ("eye", tr("Lecture seule : vos emails restent non lus", "Read-only: your emails stay unread", "Solo lectura: tus correos siguen sin leer")),
            ("key.fill", tr("Un mot de passe pour app, jamais le vôtre", "An app password, never your own", "Una contraseña para apps, nunca la tuya")),
            ("lock.iphone", tr("Gardé dans le trousseau de cet iPhone", "Kept in this iPhone’s Keychain", "Guardada en el llavero de este iPhone")),
            ("cpu", tr("Analyse sur l’appareil, rien n’est envoyé", "Analyzed on the device, nothing sent", "Análisis en el dispositivo, nada se envía")),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.1) { item in
                Label(item.1, systemImage: item.0).font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .card(tint: Theme.safe.opacity(0.3))
    }
}
