import Foundation
import MailZenKit
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device language model (Apple Intelligence, iOS 26), when the iPhone has it.
/// It only rewrites ZenAI's answer in natural language from the facts of the analysis: it
/// never sees the email itself, so an email cannot give it instructions.
enum OnDeviceModel {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static func phrase(question: String, facts: [String]) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else { return nil }
            let instructions = """
            Tu es ZenAI, l’assistant de sécurité de l’application MailZen. Réponds dans la langue de la \
            question, en quatre phrases au plus, simplement, avec bienveillance et sans culpabiliser. \
            Utilise uniquement les faits fournis : n’invente aucune preuve, aucun lien, aucun numéro, \
            aucun nom d’entreprise. Si les faits ne suffisent pas pour répondre, dis-le clairement. \
            Ne recommande jamais d’ouvrir un lien ou une pièce jointe d’un message suspect.
            """
            let session = LanguageModelSession(instructions: instructions)
            let prompt = "Question : \(question)\n\nFaits établis par l’analyse de MailZen :\n" + facts.joined(separator: "\n")
            do {
                let response = try await session.respond(to: prompt)
                let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
}
