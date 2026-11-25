import Foundation
import Testing
@testable import MailZenKit

@Suite struct EmailMessageTests {
    static let phishing = """
    Return-Path: <bounce@mailer.example>
    Authentication-Results: mx.example.org; spf=fail smtp.mailfrom=paypal.com; dkim=none
    From: =?UTF-8?B?U2VydmljZSBQYXlQYWwg8J+UkA==?= <service@paypal-secure.example>
    Reply-To: <collect@other-domain.example>
    Subject: =?ISO-8859-1?Q?Action_requise_=E0_faire?=
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="outer"

    --outer
    Content-Type: multipart/alternative; boundary="inner"

    --inner
    Content-Type: text/plain; charset=utf-8
    Content-Transfer-Encoding: quoted-printable

    Votre compte sera suspendu sous 24 heures. Confirmez votre mot de passe=
     ici.
    --inner
    Content-Type: text/html; charset=utf-8
    Content-Transfer-Encoding: base64

    PHA+Q29uZmlybWV6IDxhIGhyZWY9Imh0dHA6Ly8xOTIuMTY4LjAuOS9sb2dpbiI+aWNpPC9hPjwvcD4=
    --inner--
    --outer
    Content-Type: application/octet-stream; name="facture.pdf.exe"
    Content-Disposition: attachment; filename="facture.pdf.exe"
    Content-Transfer-Encoding: base64

    TVqQAAMAAAAEAAAA
    --outer--
    """

    @Test func parsesHeadersPartsAndAttachments() {
        let m = EmailMessage(raw: Self.phishing)
        #expect(m.from == "Service PayPal 🔐 <service@paypal-secure.example>")
        #expect(m.fromAddress == "service@paypal-secure.example")
        #expect(m.subject == "Action requise à faire")
        #expect(m.failedAuthentication == "spf=fail")
        #expect(m.bodyText.contains("mot de passe ici."))
        #expect(m.links == ["http://192.168.0.9/login"])
        #expect(m.attachments.map(\.filename) == ["facture.pdf.exe"])
        #expect(m.attachments.first?.size == 12)
    }

    @Test func theEngineReadsTheWholeEmail() {
        let report = Engine.analyze(EmailMessage(raw: Self.phishing))
        let rules = Set(report.signals.map(\.rule))
        for rule in [Rule.authFailure, .replyToMismatch, .ipLink, .doubleExtension, .urgency, .threat, .sensitiveData] {
            #expect(rules.contains(rule), "\(rule)")
        }
        #expect(report.verdict == .danger)
    }

    @Test func pastedTextIsNotAnEmail() {
        let m = EmailMessage(raw: "Bonjour : voici le lien https://example.org\nÀ bientôt")
        #expect(m.bodyText.contains("https://example.org"))
        #expect(m.bodyText.contains("À bientôt"))
    }

    @Test func labelsOfMailAppsAreHeaders() {
        let m = EmailMessage(raw: "De : Banque <info@banque.example>\nObjet : Alerte\n\nCliquez ici.")
        #expect(m.fromAddress == "info@banque.example")
        #expect(m.subject == "Alerte")
        #expect(m.bodyText == "Cliquez ici.")
    }

    @Test func htmlOnlyMessagesGiveTheirText() {
        let raw = "From: a@b.example\nContent-Type: text/html\n\n<html><body><p>Hello&nbsp;<b>you</b></p><script>x()</script></body></html>"
        #expect(EmailMessage(raw: raw).bodyText == "Hello you")
    }
}
