import SwiftUI
import SwiftAnthropic
import NaturalLanguage

@main
struct QuillApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Image(systemName: appState.isAnalyzing ? "pencil.and.outline.badge.clock" : "pencil.and.outline")
        }

        Settings {
            SettingsView(appState: appState)
        }

        Window("Welcome to Quill", id: "onboarding") {
            OnboardingView(appState: appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        setupHotkey()
        checkPermissions()
        startPermissionPolling()
    }

    private func setupHotkey() {
        HotkeyManager.shared.onTrigger = { [self] in
            handleHotkeyTrigger()
        }
        HotkeyManager.shared.register()
    }

    private func checkPermissions() {
        appState.hasAccessibilityPermission = PermissionChecker.shared.isTrusted
        appState.hasAPIKey = KeychainManager.shared.getAPIKey() != nil
    }

    /// Poll accessibility permission every 2 seconds until granted
    private func startPermissionPolling() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            let granted = PermissionChecker.shared.isTrusted
            if granted != appState.hasAccessibilityPermission {
                appState.hasAccessibilityPermission = granted
                Log.general.info("Accessibility permission changed: \(granted)")
            }
            if granted { timer.invalidate() }
        }
    }

    private func handleHotkeyTrigger() {
        appState.analysisTask?.cancel()
        appState.analysisTask = Task { @MainActor in
            appState.reset()
            // Refresh permission state
            appState.hasAccessibilityPermission = PermissionChecker.shared.isTrusted

            guard appState.hasAccessibilityPermission else {
                appState.error = .accessibilityDenied
                FloatingPanelController.shared.show(appState: appState)
                return
            }

            // Try AX selection with context first, then fall back to OCR
            var finalText: String?

            if let selection = await AccessibilityManager.shared.getSelectionWithContext() {
                finalText = selection.selectedText
                if let surrounding = selection.surroundingText, surrounding != selection.selectedText {
                    appState.sentenceContext = surrounding
                }
            }

            // Fallback: OCR screen capture for non-selectable text
            if finalText == nil || finalText!.isEmpty {
                Log.general.info("No AX selection, trying OCR screen capture")
                if let captured = await ScreenTextCapture.shared.captureTextNearCursor() {
                    finalText = captured.word
                    appState.sentenceContext = captured.sentence
                }
            }

            guard let finalText, !finalText.isEmpty else {
                appState.error = .noTextSelected
                FloatingPanelController.shared.show(appState: appState)
                return
            }

            appState.originalText = finalText

            // Auto-select Translate for native language text
            if detectsNativeLanguage(finalText) {
                appState.selectedMode = .translate
            }

            FloatingPanelController.shared.show(appState: appState) { [self] newMode in
                reanalyze(mode: newMode)
            }

            await performAnalysis(text: finalText, mode: appState.selectedMode)
        }
    }

    private func reanalyze(mode: AnalysisMode) {
        let text = appState.originalText
        guard !text.isEmpty else { return }
        Task { @MainActor in
            await performAnalysis(text: text, mode: mode)
        }
    }

    /// Detect if text is in the user's native language using NLLanguageRecognizer
    private func detectsNativeLanguage(_ text: String) -> Bool {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage else { return false }

        // Map appState.nativeLanguage to NLLanguage
        let nativeMap: [String: NLLanguage] = [
            "Turkish": .turkish, "Arabic": .arabic, "Chinese": .simplifiedChinese,
            "Dutch": .dutch, "French": .french, "German": .german, "Greek": .greek,
            "Hindi": .hindi, "Italian": .italian, "Japanese": .japanese, "Korean": .korean,
            "Persian": .persian, "Polish": .polish, "Portuguese": .portuguese,
            "Russian": .russian, "Spanish": .spanish, "Swedish": .swedish, "Ukrainian": .ukrainian
        ]

        guard let nativeLang = nativeMap[appState.nativeLanguage] else { return false }
        return detected == nativeLang
    }

    private func performAnalysis(text: String, mode: AnalysisMode) async {
        guard !Task.isCancelled else { return }
        guard let service = appState.createAIService() else {
            appState.error = .noAPIKey
            return
        }

        appState.result = nil
        appState.error = nil
        appState.isAnalyzing = true
        do {
            let tone: ToneStyle? = mode == .improve ? appState.selectedTone : nil
            let context = appState.sentenceContext.isEmpty ? nil : appState.sentenceContext
            let result = try await service.analyze(
                text: text, mode: mode, tone: tone, sentenceContext: context,
                nativeLanguage: appState.nativeLanguage, targetLanguage: appState.targetLanguage
            )
            guard !Task.isCancelled else { return }
            appState.result = result
            appState.cachedResults[mode] = result
        } catch let apiError as APIError {
            appState.error = .networkError(apiError.displayDescription)
        } catch {
            appState.error = .networkError(error.localizedDescription)
        }
        appState.isAnalyzing = false
    }
}
