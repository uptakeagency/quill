import Foundation

struct TechExplanation: Equatable {
    let term: String
    let level: ExplanationLevel
    var explanation: String
    var tldr: String?
    var resources: [ResourceLink]?
}

struct TechCacheKey: Hashable, Codable {
    let term: String
    let level: ExplanationLevel
}

struct TechCacheValue: Equatable, Codable {
    let explanation: String
    let tldr: String?
    let resources: [ResourceLink]?
}

@Observable
final class TechDictionaryState {
    var explanationStack: [TechExplanation] = []
    private(set) var cache: [TechCacheKey: TechCacheValue] = [:]

    private static let cacheKey = "techDictionaryCache"

    init() {
        loadCache()
    }

    var currentExplanation: TechExplanation? {
        explanationStack.last
    }

    var canGoBack: Bool {
        explanationStack.count > 1
    }

    var breadcrumbs: [String] {
        explanationStack.map(\.term)
    }

    func push(_ explanation: TechExplanation) {
        explanationStack.append(explanation)
        let key = TechCacheKey(term: explanation.term, level: explanation.level)
        let value = TechCacheValue(explanation: explanation.explanation, tldr: explanation.tldr, resources: explanation.resources)
        cache[key] = value
        saveCache()
    }

    /// Replace top of stack (used when switching levels for the same term)
    func replaceTop(_ explanation: TechExplanation) {
        guard !explanationStack.isEmpty else {
            push(explanation)
            return
        }
        explanationStack[explanationStack.count - 1] = explanation
        let key = TechCacheKey(term: explanation.term, level: explanation.level)
        let value = TechCacheValue(explanation: explanation.explanation, tldr: explanation.tldr, resources: explanation.resources)
        cache[key] = value
        saveCache()
    }

    func pop() {
        guard canGoBack else { return }
        explanationStack.removeLast()
    }

    func popTo(index: Int) {
        guard index >= 0, index < explanationStack.count else { return }
        explanationStack = Array(explanationStack.prefix(index + 1))
    }

    func cachedValue(for term: String, level: ExplanationLevel) -> TechCacheValue? {
        cache[TechCacheKey(term: term, level: level)]
    }

    /// Reset navigation stack only — disk cache persists across sessions
    func reset() {
        explanationStack.removeAll()
    }

    /// Clear all cached explanations from memory and disk
    func clearCache() {
        cache.removeAll()
        explanationStack.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
    }

    // MARK: - Persistence

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let decoded = try? JSONDecoder().decode([TechCacheKey: TechCacheValue].self, from: data) else { return }
        cache = decoded
    }
}
