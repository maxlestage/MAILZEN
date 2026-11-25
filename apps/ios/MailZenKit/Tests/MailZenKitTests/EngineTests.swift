import Foundation
import Testing
@testable import MailZenKit

@Suite struct EngineTests {
    @Test func theSamplesGetTheExpectedVerdicts() {
        for lang in AppLanguage.allCases {
            let verdicts = Library.samples.map { Engine.analyze($0.text.text(lang)).verdict }
            #expect(verdicts == [.danger, .suspicious, .danger, .safe], "\(lang)")
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
        #expect(Engine.analyze("First, the groups meet at https://example.org/agenda").signals.isEmpty)
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
