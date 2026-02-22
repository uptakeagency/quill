import Foundation

enum ClaudeResponseParser {

    private struct AIResponse: Codable {
        let corrected: String
        let changes: [TextChange]
        let vocabulary: [VocabularyCard]?
        let explanation: String?
        let tldr: String?
        let resources: [ResourceLink]?
    }

    static func parse(response: String, mode: AnalysisMode, originalText: String) -> AnalysisResult {
        let cleaned = extractJSON(from: response)

        var result: AnalysisResult?

        // Try Codable first
        result = decodeCodable(cleaned, mode: mode, originalText: originalText)

        // Try sanitizing (escape literal newlines inside JSON strings)
        if result == nil {
            let sanitized = sanitizeJSON(cleaned)
            if sanitized != cleaned {
                result = decodeCodable(sanitized, mode: mode, originalText: originalText)
                if result != nil { Log.ai.info("Parsed response after JSON sanitization") }
            }

            // Try lenient JSONSerialization
            if result == nil {
                result = decodeSerialization(sanitized, mode: mode, originalText: originalText)
                if result != nil { Log.ai.info("Parsed response via JSONSerialization fallback") }
            }
        }

        // Last resort: regex extract the explanation field directly
        if result == nil, let explanation = extractExplanationField(from: cleaned) {
            Log.ai.info("Extracted explanation via regex fallback")
            result = AnalysisResult(
                mode: mode, original: originalText,
                corrected: originalText, changes: [],
                explanation: explanation, tldr: nil, resources: nil, vocabularyCards: nil
            )
        }

        var final = result ?? fallbackResult(cleaned, mode: mode, originalText: originalText)

        // Normalize double-escaped newlines/tabs in explanation text
        if let explanation = final.explanation {
            final.explanation = normalizeEscapes(explanation)
        }
        if let tldr = final.tldr {
            final.tldr = normalizeEscapes(tldr)
        }

        return final
    }

    /// Convert literal \n and \t sequences to real characters
    private static func normalizeEscapes(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
    }

    // MARK: - Decoders

    private static func decodeCodable(_ json: String, mode: AnalysisMode, originalText: String) -> AnalysisResult? {
        guard let data = json.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(AIResponse.self, from: data) else { return nil }
        return AnalysisResult(
            mode: mode, original: originalText,
            corrected: parsed.corrected, changes: parsed.changes,
            explanation: parsed.explanation, tldr: parsed.tldr,
            resources: parsed.resources,
            vocabularyCards: mode == .improve ? parsed.vocabulary : nil
        )
    }

    private static func decodeSerialization(_ json: String, mode: AnalysisMode, originalText: String) -> AnalysisResult? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let corrected = obj["corrected"] as? String ?? originalText
        let explanation = obj["explanation"] as? String
        let tldr = obj["tldr"] as? String
        var changes: [TextChange] = []
        if let arr = obj["changes"] as? [[String: String]] {
            changes = arr.compactMap { d in
                guard let o = d["original"], let r = d["replacement"], let reason = d["reason"] else { return nil }
                return TextChange(original: o, replacement: r, reason: reason)
            }
        }
        var resources: [ResourceLink]?
        if let arr = obj["resources"] as? [[String: String]] {
            resources = arr.compactMap { d in
                guard let title = d["title"], let url = d["url"] else { return nil }
                return ResourceLink(title: title, url: url)
            }
        }
        return AnalysisResult(
            mode: mode, original: originalText,
            corrected: corrected, changes: changes,
            explanation: explanation, tldr: tldr, resources: resources, vocabularyCards: nil
        )
    }

    // MARK: - JSON Helpers

    /// Extract JSON from response that may contain markdown fences or extra text
    private static func extractJSON(from text: String) -> String {
        // Try to find JSON between code fences
        let fencePattern = "```(?:json|JSON)?\\s*\\n?"
        if let startRange = text.range(of: fencePattern, options: .regularExpression),
           let endRange = text.range(of: "\\n?\\s*```", options: .regularExpression, range: startRange.upperBound..<text.endIndex) {
            return String(text[startRange.upperBound..<endRange.lowerBound])
        }

        // Try to find JSON by matching braces from the first {
        if let start = text.firstIndex(of: "{"),
           let end = findMatchingBrace(in: text, from: start) {
            return String(text[start...end])
        }

        return text
    }

    /// Find the matching closing brace for an opening { at the given index,
    /// respecting nesting and string literals.
    private static func findMatchingBrace(in text: String, from start: String.Index) -> String.Index? {
        var depth = 0
        var inString = false
        var escaped = false
        var lastClose: String.Index?

        for idx in text[start...].indices {
            let ch = text[idx]
            if escaped { escaped = false; continue }
            if ch == "\\" && inString { escaped = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            guard !inString else { continue }
            if ch == "{" { depth += 1 }
            if ch == "}" {
                depth -= 1
                if depth == 0 { return idx }
                lastClose = idx
            }
        }
        // Fallback: return the last } found if braces didn't balance
        return lastClose
    }

    /// Escape literal newlines/tabs inside JSON string values
    private static func sanitizeJSON(_ json: String) -> String {
        var result = ""
        var inString = false
        var escaped = false
        for char in json {
            if escaped {
                result.append(char)
                escaped = false
                continue
            }
            if char == "\\" && inString {
                result.append(char)
                escaped = true
                continue
            }
            if char == "\"" {
                inString.toggle()
                result.append(char)
                continue
            }
            if inString {
                switch char {
                case "\n": result.append("\\n")
                case "\r": result.append("\\r")
                case "\t": result.append("\\t")
                default: result.append(char)
                }
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// Regex extract the "explanation" value directly from JSON-like text
    private static func extractExplanationField(from text: String) -> String? {
        // Match "explanation": "..." (handles escaped quotes)
        guard let range = text.range(of: "\"explanation\"\\s*:\\s*\"", options: .regularExpression) else { return nil }
        let start = range.upperBound
        var end = start
        var escaped = false
        for idx in text[start...].indices {
            let ch = text[idx]
            if escaped { escaped = false; end = text.index(after: idx); continue }
            if ch == "\\" { escaped = true; end = text.index(after: idx); continue }
            if ch == "\"" { end = idx; break }
            end = text.index(after: idx)
        }
        guard end > start else { return nil }
        let raw = String(text[start..<end])
        // Unescape JSON escapes
        return raw
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")
            .replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    /// Final fallback when all parsing fails
    private static func fallbackResult(_ text: String, mode: AnalysisMode, originalText: String) -> AnalysisResult {
        Log.ai.warning("JSON parse failed completely, using raw text fallback")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isExplanationMode = mode == .techExplain || mode == .translate
        return AnalysisResult(
            mode: mode, original: originalText,
            corrected: isExplanationMode ? originalText : trimmed,
            changes: [],
            explanation: isExplanationMode ? trimmed : nil, tldr: nil,
            resources: nil, vocabularyCards: nil
        )
    }
}
