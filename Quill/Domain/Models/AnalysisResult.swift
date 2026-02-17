import Foundation

struct AnalysisResult: Equatable {
    let mode: AnalysisMode
    let original: String
    let corrected: String
    let changes: [TextChange]
    let explanation: String?
    let vocabularyCards: [VocabularyCard]?

    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        lhs.mode == rhs.mode && lhs.original == rhs.original && lhs.corrected == rhs.corrected
    }
}

struct TextChange: Codable, Identifiable {
    var id = UUID()
    let original: String
    let replacement: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case original, replacement, reason
    }
}

struct VocabularyCard: Codable, Identifiable {
    var id = UUID()
    let original: String
    let suggestion: String
    let definition: String
    let example: String
    let level: String // e.g. "B2", "C1"

    enum CodingKeys: String, CodingKey {
        case original, suggestion, definition, example, level
    }
}
