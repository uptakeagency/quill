import Foundation

enum ClaudeResponseParser {

    private struct AIResponse: Codable {
        let corrected: String
        let changes: [TextChange]
        let vocabulary: [VocabularyCard]?
        let explanation: String?
    }

    static func parse(response: String, mode: AnalysisMode, originalText: String) -> AnalysisResult {
        let cleaned = extractJSON(from: response)

        guard let data = cleaned.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(AIResponse.self, from: data) else {
            return fallbackResult(cleaned, mode: mode, originalText: originalText)
        }

        return AnalysisResult(
            mode: mode,
            original: originalText,
            corrected: parsed.corrected,
            changes: parsed.changes,
            explanation: parsed.explanation,
            vocabularyCards: mode == .improve ? parsed.vocabulary : nil
        )
    }

    // MARK: - Helpers

    /// Extract JSON from a response that may contain markdown fences or extra text
    private static func extractJSON(from text: String) -> String {
        // Try to find JSON between code fences
        if let range = text.range(of: "```json\n"),
           let endRange = text.range(of: "\n```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
        }

        // Try to find JSON between { and }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }

        return text
    }

    /// Fallback when JSON parsing fails - treat response as plain corrected text
    private static func fallbackResult(_ text: String, mode: AnalysisMode, originalText: String) -> AnalysisResult {
        Log.ai.warning("JSON parse failed, using raw text fallback")
        return AnalysisResult(
            mode: mode,
            original: originalText,
            corrected: text.trimmingCharacters(in: .whitespacesAndNewlines),
            changes: [],
            explanation: nil,
            vocabularyCards: nil
        )
    }
}
