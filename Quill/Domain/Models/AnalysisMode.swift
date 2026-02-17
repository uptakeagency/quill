import Foundation

enum AnalysisMode: String, CaseIterable, Identifiable {
    case improve
    case translate
    case techExplain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .improve: "Improve"
        case .translate: "Translate"
        case .techExplain: "Tech"
        }
    }

    var icon: String {
        switch self {
        case .improve: "wand.and.stars"
        case .translate: "globe"
        case .techExplain: "chevron.left.forwardslash.chevron.right"
        }
    }

    var description: String {
        switch self {
        case .improve: "Fix grammar, improve clarity, vocabulary"
        case .translate: "Translate between languages"
        case .techExplain: "Explain technical/programming terms"
        }
    }

    var usesHaiku: Bool {
        switch self {
        case .translate, .techExplain: true
        case .improve: false
        }
    }
}
