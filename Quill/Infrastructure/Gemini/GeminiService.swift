import Foundation

/// Gemini API client using direct REST calls — no SDK needed
final class GeminiService: AIServiceProtocol {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    func analyze(text: String, mode: AnalysisMode, tone: ToneStyle?, sentenceContext: String? = nil, nativeLanguage: String? = nil, targetLanguage: String? = nil, explanationLevel: ExplanationLevel? = nil) async throws -> AnalysisResult {
        let systemPrompt = ClaudePrompts.systemPrompt(for: mode, explanationLevel: explanationLevel)
        let userPrompt = ClaudePrompts.userPrompt(for: mode, text: text, tone: tone, sentenceContext: sentenceContext, nativeLanguage: nativeLanguage, targetLanguage: targetLanguage)
        Log.ai.info("Sending \(mode.rawValue) request to Gemini (\(self.model))")

        let response = try await callGemini(
            model: self.model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )

        return ClaudeResponseParser.parse(response: response, mode: mode, originalText: text)
    }

    // MARK: - Private

    private func callGemini(model: String, systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else {
            throw QuillError.networkError("Invalid Gemini API URL")
        }

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["parts": [["text": userPrompt]]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 2048
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuillError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw QuillError.networkError("Gemini API \(httpResponse.statusCode): \(errorBody)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw QuillError.parseError("Failed to parse Gemini response")
        }

        return text
    }

    /// Fetches available text generation models from the Gemini API
    static func fetchAvailableModels(apiKey: String) async throws -> [String] {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            Log.ai.warning("Gemini model fetch failed: HTTP \(httpResponse.statusCode)")
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            return []
        }

        return models.compactMap { model -> String? in
            guard let name = model["name"] as? String,
                  let methods = model["supportedGenerationMethods"] as? [String],
                  methods.contains("generateContent") else { return nil }
            let id = name.replacingOccurrences(of: "models/", with: "")
            // Filter to text-relevant gemini models only
            guard id.hasPrefix("gemini-"),
                  !id.contains("image"),
                  !id.contains("tts"),
                  !id.contains("computer-use"),
                  !id.contains("robotics"),
                  !id.contains("exp-") else { return nil }
            return id
        }.sorted().reversed()  // newest first
    }
}
