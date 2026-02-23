import Foundation

enum ExplanationLevel: String, CaseIterable, Identifiable, Codable {
    case eli5
    case eli15
    case professional
    case samples
    case resources
    case alternatives

    var id: String { rawValue }

    var title: String {
        switch self {
        case .eli5: "ELI5"
        case .eli15: "ELI15"
        case .professional: "Pro"
        case .samples: "Samples"
        case .resources: "Resources"
        case .alternatives: "Alts"
        }
    }

    var icon: String {
        switch self {
        case .eli5: "figure.child"
        case .eli15: "graduationcap"
        case .professional: "briefcase"
        case .samples: "curlybraces"
        case .resources: "book"
        case .alternatives: "arrow.triangle.branch"
        }
    }

    var promptInstruction: String {
        switch self {
        case .eli5:
            "Explain like I'm 5 years old. Use very simple words, fun analogies, and everyday examples. Avoid jargon completely."
        case .eli15:
            "Explain for a 15-year-old learning to code. Use clear language with some technical terms, relatable examples, and brief code snippets when helpful."
        case .professional:
            "Explain for an experienced developer. Be precise, use proper terminology, discuss trade-offs, edge cases, and mention relevant design patterns or alternatives."
        case .samples:
            "Provide 2-3 practical code examples showing how this term/concept is used in real code. Each example should be a short, runnable snippet with a one-line comment explaining what it does. Focus on common use cases from simple to advanced."
        case .resources:
            "Be very concise. In 3-5 bullet points, list: what to learn first, one common pitfall, and 2-3 related concepts. Keep each bullet to one sentence. Do NOT write long paragraphs."
        case .alternatives:
            "Focus ONLY on alternatives and competitors for this term. List 3-5 alternatives, each with a one-line description, 1-2 pros, and 1-2 cons. Write the description, pros, and cons in the user's native language."
        }
    }

    /// Default set of visible levels
    static let defaultVisible: Set<ExplanationLevel> = [.eli15, .professional, .samples]
}
