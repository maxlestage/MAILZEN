import Foundation
import Testing
@testable import MailZenKit

@Suite struct PersonalModelTests {
    /// A scam the models do not recognize: no link, no known wording.
    let missed = "Bonjour, c'est le plombier de la résidence. Merci de déposer 80 euros en espèces sous le paillasson du voisin avant jeudi pour la réparation commune."
    /// The same scam, reworded.
    let similar = "Bonjour, ici le plombier de la résidence : déposez 60 euros en espèces sous le paillasson du voisin avant mardi pour la réparation commune, merci."
    /// A legitimate message that looks like a scam.
    let alarming = "URGENT : votre compte client sera suspendu sous 24 heures si la facture de 45 € n'est pas réglée. Merci de payer immédiatement par virement."
    let ordinary = "Salut, on se retrouve samedi pour le déjeuner ? Dis-moi si midi te va, je réserve une table pour quatre."

    @Test func nothingLearnedChangesNothing() throws {
        let models = try #require(Models.shared)
        let empty = PersonalModel()
        #expect(empty.adjustment(Featurizer.features(missed)) == 0)
        #expect(empty.verdict(of: missed) == nil)
        let report = Engine.analyze(text: missed, extra: [], learned: empty)
        #expect(report.model?.probability == models.scamProbability(missed))
    }

    @Test func aCorrectionTeachesTheMessageAndWhatResemblesIt() throws {
        let models = try #require(Models.shared)
        let before = Engine.analyze(text: similar, extra: [], learned: PersonalModel())
        let learned = PersonalModel.train([.init(text: missed, scam: true)], models: models)
        #expect(learned.examples == 1 && !learned.weights.isEmpty)
        // The very message: remembered.
        let same = Engine.analyze(text: missed, extra: [], learned: learned)
        #expect(same.userVerdict == true)
        #expect(same.signals.contains { $0.rule == .userReported })
        #expect(same.verdict == .danger)
        // A reworded one: the model now recognizes it.
        let after = Engine.analyze(text: similar, extra: [], learned: learned)
        #expect((after.model?.probability ?? 0) > (before.model?.probability ?? 1) + 0.3)
        #expect((after.model?.personal ?? 0) > 1)
        #expect(after.score > before.score)
    }

    @Test func aCorrectionDoesNotChangeUnrelatedMessages() throws {
        let models = try #require(Models.shared)
        let learned = PersonalModel.train([.init(text: missed, scam: true)], models: models)
        let p0 = models.scamProbability(ordinary)
        let report = Engine.analyze(text: ordinary, extra: [], learned: learned)
        #expect(abs((report.model?.probability ?? 1) - p0) < 0.1)
        #expect(report.verdict == .safe)
        // The reference messages keep their answers.
        var drift = 0.0
        for features in Anchors.features.prefix(150) {
            let z = models.scam.logits(features)[0]
            let a = 1 / (1 + exp(-z)), b = 1 / (1 + exp(-(z + learned.adjustment(features))))
            drift = max(drift, abs(a - b))
        }
        #expect(drift < 0.25, "largest drift on the reference messages: \(drift)")
    }

    @Test func aLegitimateCorrectionLowersTheVerdict() throws {
        let models = try #require(Models.shared)
        let before = Engine.analyze(text: alarming, extra: [], learned: PersonalModel())
        #expect(before.verdict != .safe)
        let learned = PersonalModel.train([.init(text: alarming, scam: false)], models: models)
        let after = Engine.analyze(text: alarming, extra: [], learned: learned)
        #expect(after.userVerdict == false)
        #expect(after.verdict == .safe)
        // What the rules found stays visible; only the model changed its mind.
        let rules = { (r: Report) in r.signals.filter { $0.rule.family != .model }.map(\.rule) }
        #expect(rules(after) == rules(before))
        #expect((after.model?.probability ?? 1) < (before.model?.probability ?? 0))
    }

    @Test func theLastWordOfTheUserWins() throws {
        let models = try #require(Models.shared)
        let learned = PersonalModel.train([.init(text: missed, scam: true), .init(text: missed, scam: false)], models: models)
        #expect(learned.verdict(of: missed) == false)
        #expect(learned.examples == 1)
    }

    @Test func itSurvivesSaving() throws {
        let models = try #require(Models.shared)
        let learned = PersonalModel.train([.init(text: missed, scam: true), .init(text: alarming, scam: false)], models: models)
        let copy = try JSONDecoder().decode(PersonalModel.self, from: JSONEncoder().encode(learned))
        #expect(copy == learned)
        let f = Featurizer.features(similar)
        #expect(copy.adjustment(f) == learned.adjustment(f))
    }

    @Test func theModelDecidesAloneOnlyWhenItIsSure() throws {
        try #require(Models.shared != nil)
        // No rule fires on this text (no link, no keyword): only the model can see it.
        let text = "Hello dear, I am a widow engineer working on an oil rig. I saw your profile and your smile touched me. My son is in hospital, I need you to send money by transfer for the operation, I will pay you back when I arrive."
        let report = Engine.analyze(text: text, extra: [], learned: PersonalModel())
        let p = try #require(report.model?.probability)
        if p >= Engine.dangerFrom {
            #expect(report.verdict == .danger && report.score >= 70)
        } else if p >= Engine.suspiciousFrom {
            #expect(report.verdict == .suspicious || report.verdict == .danger)
        }
        #expect(p >= Engine.suspiciousFrom, "the romance scam is recognized: \(p)")
        // A sure, ordinary message is never raised.
        let calm = Engine.analyze(text: ordinary, extra: [], learned: PersonalModel())
        #expect(!calm.decidedByModel && calm.verdict == .safe)
    }

    @Test func zenAIAnswersFreeQuestionsFromEveryFact() throws {
        let raw = "From: Service <support@colis-suivi-frais.top>\nSubject: Colis\n\nVotre colis est en attente. Réglez 1,99 € sous 24 heures : https://colis-suivi-frais.top/paiement"
        let message = EmailMessage(raw: raw)
        let report = Engine.analyze(message, personal: PersonalLists(), learned: PersonalModel())
        #expect(ZenAI.understand("Pourquoi ce mail est-il suspect ?").understood)
        #expect(!ZenAI.understand("xyzzy plugh 42").understood)
        let facts = ZenAI.facts(report: report, message: message)
        #expect(facts.count >= 4 && Set(facts).count == facts.count)
        #expect(facts.joined().contains("colis-suivi-frais.top"))
        #expect(ZenAI.fallback(report: report, message: message).count == facts.count + 1)
        // What was learned is said.
        let learned = PersonalModel.train([.init(text: message.analysisText, scam: true)])
        let again = Engine.analyze(message, personal: PersonalLists(), learned: learned)
        #expect(ZenAI.learnedLines(again).count >= 1)
    }
}
