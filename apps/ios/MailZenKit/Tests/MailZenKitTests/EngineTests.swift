import Foundation
import Testing
@testable import MailZenKit

@Suite struct EngineTests {
    @Test func theRulesAloneGiveTheExpectedVerdicts() {
        for lang in AppLanguage.allCases {
            let verdicts = Library.samples.map { Engine.analyze(text: $0.text.text(lang), extra: [], models: false).verdict }
            #expect(verdicts == [.danger, .suspicious, .danger, .safe], "\(lang)")
        }
    }

    @Test func theModelsSharpenTheVerdicts() throws {
        try #require(Models.shared != nil)
        for lang in AppLanguage.allCases {
            let reports = Library.samples.map { Engine.analyze($0.text.text(lang)) }
            #expect(reports[0].verdict == .danger && reports[2].verdict == .danger, "\(lang)")
            #expect(reports[1].verdict == .suspicious || reports[1].verdict == .danger, "\(lang)")
            #expect(reports[3].verdict == .safe, "\(lang)")
            #expect(reports[1].model?.category == .delivery, "the parcel scam is recognized (\(lang))")
            #expect((reports[3].model?.probability ?? 1) < 0.5, "the newsletter is not a scam (\(lang))")
        }
    }

    @Test func findsURLsAndHosts() {
        let found = extractURLs("Go to https://a.example/x?y=1, or www.b.example. And (http://1.2.3.4/z)")
        #expect(found == ["https://a.example/x?y=1", "www.b.example", "http://1.2.3.4/z"])
        #expect(host(of: "https://user@a.example:8080/x") == "a.example")
        #expect(host(of: "www.b.example") == "www.b.example")
    }

    @Test func spotsLookalikeDomains() {
        #expect(imitatesBrand("paypaI-account-check.example") == "paypal")
        #expect(imitatesBrand("amaz0n-secure.example") == "amazon")
        #expect(imitatesBrand("paypal.com") == nil)
        #expect(imitatesBrand("bibliotheque-ville.example") == nil)
        #expect(imitatesBrand("аpple.example") != nil)
    }

    @Test func keywordsMatchWholeWords() {
        #expect(containsWord("visit the irs today", "irs"))
        #expect(!containsWord("the first step", "irs"))
        #expect(containsWord("rib_fournisseur.pdf", "rib"))
        #expect(!containsWord("décrire", "rib"))
        #expect(containsWord("1,99 €", "€"))
        #expect(Engine.analyze(text: "First, the groups meet at https://example.org/agenda", extra: [], models: false).signals.isEmpty)
    }

    @Test func anEmptyTextIsSafeWithALowConfidence() {
        let report = Engine.analyze("")
        #expect(report.verdict == .safe)
        #expect(report.confidence == 0)
    }

    @Test func doubleExtensionsAreCaught() {
        #expect(Engine.analyze("Voir Facture_2026.pdf.exe").signals.contains { $0.rule == .doubleExtension })
    }

    @Test func everyRuleHasItsTexts() {
        for rule in Rule.allCases {
            #expect(!rule.title.fr.isEmpty && !rule.explanation.es.isEmpty && rule.weight > 0)
        }
    }
}
