import Foundation
import UIKit
import Vision

/// Reads the text and the QR codes of a picture, on the device (Vision).
enum OCR {
    struct Result {
        var text: String
        var qrPayloads: [String]
    }

    static func read(_ image: UIImage) async -> Result {
        guard let cgImage = image.cgImage else { return Result(text: "", qrPayloads: []) }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let textRequest = VNRecognizeTextRequest()
                textRequest.recognitionLevel = .accurate
                textRequest.usesLanguageCorrection = true
                textRequest.recognitionLanguages = ["fr-FR", "en-US", "es-ES"]
                let barcodeRequest = VNDetectBarcodesRequest()
                barcodeRequest.symbologies = [.qr]
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
                try? handler.perform([textRequest, barcodeRequest])
                let lines = (textRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let payloads = (barcodeRequest.results ?? []).compactMap { $0.payloadStringValue }
                continuation.resume(returning: Result(text: lines.joined(separator: "\n"), qrPayloads: payloads))
            }
        }
    }
}
