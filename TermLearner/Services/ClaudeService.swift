import Foundation
import UIKit

struct ExtractedTerm: Identifiable, Codable {
    let id: UUID
    var word: String
    var definition: String
    var notes: String

    init(word: String, definition: String, notes: String = "") {
        self.id = UUID()
        self.word = word
        self.definition = definition
        self.notes = notes
    }
}

struct ExtractionResult {
    let terms: [ExtractedTerm]
    let estimatedCount: Int
    let warning: String?
}

enum ClaudeServiceError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case networkError(String)
    case parsingError
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "No API key set. Please add your Claude API key in Settings."
        case .invalidImage: return "Could not process this image."
        case .networkError(let msg): return "Network error: \(msg)"
        case .parsingError: return "Could not parse terms from the image."
        case .rateLimited: return "Too many requests. Please wait a moment and try again."
        }
    }
}

final class ClaudeService {
    static let shared = ClaudeService()
    private init() {}

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: AppConstants.apiKeyDefaultsKey)
    }

    func extractTerms(from image: UIImage) async throws -> ExtractionResult {
        guard let key = apiKey, !key.isEmpty else { throw ClaudeServiceError.missingAPIKey }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClaudeServiceError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        let prompt = """
        Analyze this image and extract all vocabulary terms, definitions, or word-translation pairs you can see.

        IMPORTANT RULES:
        - Extract up to 70 terms from the image
        - If the image contains copyrighted content from a published book or commercial product, still extract the terms but set the "copyright_warning" field to true
        - Do NOT alter, embellish, or invent any terms — only extract what is visibly present
        - This data is used solely by the user for personal study; it is not used to train any AI model

        Respond ONLY with a valid JSON object in this exact format (no markdown, no extra text):
        {
          "terms": [
            { "word": "term here", "definition": "definition or translation here", "notes": "any helpful context" }
          ],
          "estimated_count": 5,
          "copyright_warning": false
        }
        """

        let requestBody: [String: Any] = [
            "model": AppConstants.claudeModel,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: AppConstants.claudeAPIEndpoint)!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 { throw ClaudeServiceError.rateLimited }
            if httpResponse.statusCode != 200 {
                throw ClaudeServiceError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }

        return try parseResponse(data: data)
    }

    private func parseResponse(data: Data) throws -> ExtractionResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String else {
            throw ClaudeServiceError.parsingError
        }

        // Strip any markdown fences that may appear despite instructions
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let termsArray = parsed["terms"] as? [[String: Any]] else {
            throw ClaudeServiceError.parsingError
        }

        let terms = termsArray.compactMap { dict -> ExtractedTerm? in
            guard let word = dict["word"] as? String,
                  let definition = dict["definition"] as? String,
                  !word.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            let notes = dict["notes"] as? String ?? ""
            return ExtractedTerm(word: word, definition: definition, notes: notes)
        }

        let estimatedCount = parsed["estimated_count"] as? Int ?? terms.count
        let hasCopyright = parsed["copyright_warning"] as? Bool ?? false
        let warning = hasCopyright
            ? "This image may contain copyrighted material. Terms are for personal study only and will not be used to train any AI."
            : nil

        return ExtractionResult(terms: terms, estimatedCount: estimatedCount, warning: warning)
    }
}
