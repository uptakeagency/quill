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
    var selectedMode: AnalysisMode = .improve
    var selectedTone: ToneStyle?
    var aiBackend: AIBackend = .gemini
    var nativeLanguage: String = "English"
    var targetLanguage: String = "English"
    var geminiModel: String = "gemini-2.5-flash"
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
    }

    var hasGeminiKey: Bool {
        KeychainManager.shared.getGeminiKey() != nil
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
