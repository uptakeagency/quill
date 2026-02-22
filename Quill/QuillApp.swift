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

        Window("Quill Settings", id: "settings") {
            SettingsView(appState: appState)
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)

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
        // If panel is visible in techExplain mode, try drill-down instead of full reset
        if FloatingPanelController.shared.isVisible && appState.selectedMode == .techExplain {
            if let term = getDrillDownTerm(), !term.isEmpty {
                explainTerm(term)
                return
            }
        }

        appState.analysisTask?.cancel()
        appState.analysisTask = Task { @MainActor in
            // Remember the source app before reset clears it
            let sourceApp = NSWorkspace.shared.frontmostApplication
            appState.reset()
            appState.sourceApp = sourceApp
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

            FloatingPanelController.shared.show(
                appState: appState,
                onReanalyze: { [self] newMode in reanalyze(mode: newMode) },
                onExplainTerm: { [self] term, isLevelSwitch in explainTerm(term, isLevelSwitch: isLevelSwitch) }
            )

            await performAnalysis(text: finalText, mode: appState.selectedMode)
        }
    }

    private func reanalyze(mode: AnalysisMode) {
        let text = appState.originalText
        guard !text.isEmpty else { return }
        appState.analysisTask?.cancel()
        appState.analysisTask = Task { @MainActor in
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

    /// Get selected text for drill-down: try panel selection first, then AX from source app
    private func getDrillDownTerm() -> String? {
        // Try panel's own text selection (user selected text in the explanation)
        if let panelText = FloatingPanelController.shared.getSelectedText() {
            let trimmed = panelText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    private func explainTerm(_ term: String, isLevelSwitch: Bool = false) {
        Task { @MainActor in
            await performTechExplain(term: term, level: appState.selectedExplanationLevel, isLevelSwitch: isLevelSwitch)
        }
    }

    private func performTechExplain(term: String, level: ExplanationLevel, isLevelSwitch: Bool = false) async {
        // Check cache first
        if let cached = appState.techDictionary.cachedValue(for: term, level: level) {
            let explanation = TechExplanation(term: term, level: level, explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources)
            if isLevelSwitch {
                appState.techDictionary.replaceTop(explanation)
            } else {
                appState.techDictionary.push(explanation)
            }
            let result = AnalysisResult(mode: .techExplain, original: term, corrected: term, changes: [], explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources)
            appState.result = result
            appState.cachedResults[.techExplain] = result
            return
        }

        guard let service = appState.createAIService() else {
            appState.error = .noAPIKey
            return
        }

        appState.result = nil
        appState.error = nil
        appState.isAnalyzing = true
        defer { appState.isAnalyzing = false }
        do {
            let context = appState.sentenceContext.isEmpty ? nil : appState.sentenceContext
            let result = try await service.analyze(
                text: term, mode: .techExplain, tone: nil, sentenceContext: context,
                nativeLanguage: appState.nativeLanguage, targetLanguage: appState.targetLanguage,
                explanationLevel: level
            )
            guard !Task.isCancelled else { return }
            let explanationText = result.explanation ?? ""
            let explanation = TechExplanation(term: term, level: level, explanation: explanationText, tldr: result.tldr, resources: result.resources)
            if isLevelSwitch {
                appState.techDictionary.replaceTop(explanation)
            } else {
                appState.techDictionary.push(explanation)
            }
            appState.result = result
            appState.cachedResults[.techExplain] = result
        } catch let apiError as APIError {
            appState.error = .networkError(apiError.displayDescription)
        } catch {
            appState.error = .networkError(error.localizedDescription)
        }
    }

    private func performAnalysis(text: String, mode: AnalysisMode) async {
        guard !Task.isCancelled else { return }

        // For techExplain, use the dedicated drill-down flow
        if mode == .techExplain {
            await performTechExplain(term: text, level: appState.selectedExplanationLevel)
            return
        }

        guard let service = appState.createAIService() else {
            appState.error = .noAPIKey
            return
        }

        appState.result = nil
        appState.error = nil
        appState.isAnalyzing = true
        defer { appState.isAnalyzing = false }
        do {
            let tone: ToneStyle? = mode == .improve ? appState.selectedTone : nil
            let context = appState.sentenceContext.isEmpty ? nil : appState.sentenceContext
            let result = try await service.analyze(
                text: text, mode: mode, tone: tone, sentenceContext: context,
                nativeLanguage: appState.nativeLanguage, targetLanguage: appState.targetLanguage,
                explanationLevel: nil
            )
            guard !Task.isCancelled else { return }
            appState.result = result
            appState.cachedResults[mode] = result
        } catch let apiError as APIError {
            appState.error = .networkError(apiError.displayDescription)
        } catch {
            appState.error = .networkError(error.localizedDescription)
        }
    }
}
