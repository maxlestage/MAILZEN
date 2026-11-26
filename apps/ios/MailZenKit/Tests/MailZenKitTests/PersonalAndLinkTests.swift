import Foundation
import Testing
@testable import MailZenKit

@Suite struct PersonalAndLinkTests {
    let raw = """
    From: "Service client" <support@colis-suivi-frais.top>
    Subject: Votre colis
    Content-Type: text/plain; charset=utf-8

    Votre colis est en attente. Réglez 1,99 € sous 24 heures : https://colis-suivi-frais.top/paiement
    """

    @Test func keysAreDomainsOrFreeMailboxes() {
        #expect(PersonalLists.key(of: "Anne <anne@news.example.co.uk>") == "example.co.uk")
        #expect(PersonalLists.key(of: "Paul <Paul.Martin@gmail.com>") == "paul.martin@gmail.com")
        #expect(PersonalLists.key(of: "pas d'adresse") == nil)
    }

    @Test func aBlockedSenderIsFlagged() {
        let message = EmailMessage(raw: "From: Bob <bob@shop.example>\nSubject: Hi\n\nHello, see you tomorrow.")
        #expect(Engine.analyze(message, personal: PersonalLists()).verdict == .safe)
        let report = Engine.analyze(message, personal: PersonalLists(blocked: ["shop.example"]))
        #expect(report.signals.contains { $0.rule == .blockedSender })
        #expect(report.verdict != .safe)
    }

    @Test func aTrustedSenderLowersTheScoreButKeepsTheSignals() {
        let message = EmailMessage(raw: "From: Compta <compta@fournisseur.example>\nSubject: Facture\n\nMerci de régler la facture de 1 200 € par virement avant ce soir, c'est urgent.")
        let plain = Engine.analyze(message, personal: PersonalLists())
        let trusted = Engine.analyze(message, personal: PersonalLists(trusted: ["fournisseur.example"]))
        #expect(trusted.trustedSender)
        #expect(trusted.score <= 19 && trusted.score <= plain.score)
        #expect(trusted.signals.count == plain.signals.count)
    }

    @Test func aTrustedSenderDoesNotHideAnImpersonation() {
        let message = EmailMessage(raw: "From: PayPal <service@paypaI.example>\nSubject: Compte\n\nVotre compte est suspendu.")
        let report = Engine.analyze(message, personal: PersonalLists(trusted: ["paypai.example", "paypaI.example"]))
        #expect(!report.trustedSender)
    }

    @Test func theLinkModelFlagsPhishingLinksButNotOfficialOnes() throws {
        let models = try #require(Models.shared)
        #expect(models.linkProbability("https://paypa1-secure-login.xyz/verify/account.php") > 0.95)
        #expect(models.linkProbability("https://www.amazon.fr/gp/your-account/order-history") < 0.5)
        let report = Engine.analyze(EmailMessage(raw: raw), personal: PersonalLists())
        let link = try #require(report.links.first)
        #expect(link.modelProbability != nil && link.risky)
        let official = Engine.analyze("Suivez votre colis sur https://www.laposte.fr/outils/suivre-vos-envois")
        #expect(official.links.first?.modelProbability == nil)
        #expect(!official.signals.contains { $0.rule == .modelLink })
    }

    @Test func zenAIKnowsTheKindOfScamAndHowToBlock() {
        #expect(ZenAI.intent(of: "Quel type d'arnaque est-ce ?") == .kind)
        #expect(ZenAI.intent(of: "How do I block this sender?") == .block)
        let message = EmailMessage(raw: raw)
        let report = Engine.analyze(message, personal: PersonalLists())
        let kind = ZenAI.answer(.kind, report: report, message: message).joined(separator: " ")
        #expect(!kind.isEmpty)
        #expect(!ZenAI.answer(.block, report: report, message: message).isEmpty)
        #expect(ZenAI.suggestions.count == Library.zenaiQuestions.count)
    }
}
