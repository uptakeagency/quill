import SwiftUI

enum AIBackend: String, CaseIterable, Identifiable {
    case gemini = "gemini"
    case claudeAPI = "api"
    case claudeCLI = "cli"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gemini: "Gemini Flash (Fast)"
        case .claudeCLI: "Claude CLI (Local)"
        case .claudeAPI: "Claude API (Key)"
        }
    }

    var description: String {
        switch self {
        case .gemini: "Google Gemini 2.0 Flash - fast and free tier available"
        case .claudeCLI: "Uses installed claude command - no API key needed"
        case .claudeAPI: "Direct API calls - requires API key, supports streaming"
        }
    }
}

@Observable
final class AppState {
    var selectedMode: AnalysisMode = .techExplain
    var selectedTone: ToneStyle?
    var selectedExplanationLevel: ExplanationLevel = .eli15
    var techDictionary = TechDictionaryState()
    var visibleExplanationLevels: Set<ExplanationLevel> = ExplanationLevel.defaultVisible {
        didSet { saveVisibleLevels() }
    }
    var aiBackend: AIBackend = .gemini {
        didSet { UserDefaults.standard.set(aiBackend.rawValue, forKey: "aiBackend") }
    }
    var nativeLanguage: String = "English" {
        didSet { UserDefaults.standard.set(nativeLanguage, forKey: "nativeLanguage") }
    }
    var targetLanguage: String = "English" {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage") }
    }
    var geminiModel: String = "gemini-2.5-flash" {
        didSet { UserDefaults.standard.set(geminiModel, forKey: "geminiModel") }
    }
    var panelTheme: PanelTheme = .comfortable {
        didSet { UserDefaults.standard.set(panelTheme.rawValue, forKey: "panelTheme") }
    }
    var panelColorScheme: PanelColorScheme = .standard {
        didSet { UserDefaults.standard.set(panelColorScheme.rawValue, forKey: "panelColorScheme") }
    }

    var appearance: PanelAppearance {
        PanelAppearance(theme: panelTheme, colorScheme: panelColorScheme)
    }
    var availableGeminiModels: [String] = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.5-pro",
        "gemini-3-flash-preview",
        "gemini-3-pro-preview",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite"
    ]
    var isFetchingModels = false
    var isAnalyzing = false
    var originalText = ""
    var sentenceContext = ""  // surrounding sentence when captured via OCR
    var result: AnalysisResult?
    var error: QuillError?
    var hasAccessibilityPermission = false
    var hasAPIKey = false
    var cachedResults: [AnalysisMode: AnalysisResult] = [:]
    var analysisTask: Task<Void, Never>?
    var sourceApp: NSRunningApplication?

    func reset() {
        isAnalyzing = false
        originalText = ""
        sentenceContext = ""
        result = nil
        error = nil
        cachedResults.removeAll()
        sourceApp = nil
        techDictionary.reset()
    }

    var hasGeminiKey: Bool {
        KeychainManager.shared.getGeminiKey() != nil
    }

    init() {
        loadVisibleLevels()
        loadPreferences()
    }

    func createAIService() -> AIServiceProtocol? {
        switch aiBackend {
        case .gemini:
            guard let key = KeychainManager.shared.getGeminiKey() else { return nil }
            return GeminiService(apiKey: key, model: geminiModel)
        case .claudeCLI:
            return ClaudeCLIService()
        case .claudeAPI:
            guard let apiKey = KeychainManager.shared.getAPIKey() else { return nil }
            return ClaudeService(apiKey: apiKey)
        }
    }

    // MARK: - Persistence

    private static let visibleLevelsKey = "visibleExplanationLevels"

    private func saveVisibleLevels() {
        let rawValues = visibleExplanationLevels.map(\.rawValue)
        UserDefaults.standard.set(rawValues, forKey: AppState.visibleLevelsKey)
    }

    private func loadPreferences() {
        if let backend = UserDefaults.standard.string(forKey: "aiBackend"),
           let parsed = AIBackend(rawValue: backend) {
            aiBackend = parsed
        }
        if let lang = UserDefaults.standard.string(forKey: "nativeLanguage") {
            nativeLanguage = lang
        }
        if let lang = UserDefaults.standard.string(forKey: "targetLanguage") {
            targetLanguage = lang
        }
        if let model = UserDefaults.standard.string(forKey: "geminiModel") {
            geminiModel = model
        }
        if let theme = UserDefaults.standard.string(forKey: "panelTheme"),
           let parsed = PanelTheme(rawValue: theme) {
            panelTheme = parsed
        }
        if let scheme = UserDefaults.standard.string(forKey: "panelColorScheme"),
           let parsed = PanelColorScheme(rawValue: scheme) {
            panelColorScheme = parsed
        }
    }

    private func loadVisibleLevels() {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: AppState.visibleLevelsKey) else { return }
        let levels = rawValues.compactMap { ExplanationLevel(rawValue: $0) }
        if !levels.isEmpty {
            visibleExplanationLevels = Set(levels)
            // Ensure selected level is still visible
            if !visibleExplanationLevels.contains(selectedExplanationLevel),
               let first = ExplanationLevel.allCases.first(where: { visibleExplanationLevels.contains($0) }) {
                selectedExplanationLevel = first
            }
        }
    }
}

enum QuillError: LocalizedError {
    case noTextSelected
    case noAPIKey
    case accessibilityDenied
    case networkError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .noTextSelected:
            "No text selected. Select some text and try again."
        case .noAPIKey:
            "API key not configured. Switch to Claude CLI or add your API key in Settings."
        case .accessibilityDenied:
            "Accessibility permission required. Open System Settings to grant access."
        case .networkError(let message):
            "Error: \(message)"
        case .parseError(let message):
            "Failed to parse response: \(message)"
        }
    }
}
