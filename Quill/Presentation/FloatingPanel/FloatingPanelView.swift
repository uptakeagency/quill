import SwiftUI

struct FloatingPanelView: View {
    @Bindable var appState: AppState
    var onDismiss: () -> Void
    var onReanalyze: ((AnalysisMode) -> Void)?
    var onExplainTerm: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ModePickerView(selectedMode: $appState.selectedMode)
            if appState.selectedMode == .improve {
                toneSelector
            }
            if appState.selectedMode == .techExplain {
                levelSelector
                if appState.techDictionary.canGoBack {
                    breadcrumbBar
                }
            }
            Divider()
            contentArea
            Divider()
            actionBar
        }
        .frame(width: appState.appearance.panelWidth, height: appState.appearance.panelHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: appState.appearance.cornerRadius))
        .onChange(of: appState.selectedMode) { _, newMode in
            guard !appState.originalText.isEmpty else { return }
            // Use cached result if available, otherwise re-analyze
            if let cached = appState.cachedResults[newMode] {
                appState.result = cached
                appState.error = nil
            } else if !appState.isAnalyzing {
                onReanalyze?(newMode)
            }
        }
        .onChange(of: appState.selectedTone) { _, _ in
            guard appState.selectedMode == .improve, !appState.originalText.isEmpty, !appState.isAnalyzing else { return }
            // Tone changed — invalidate improve cache and re-analyze
            appState.cachedResults.removeValue(forKey: .improve)
            onReanalyze?(.improve)
        }
        .onChange(of: appState.selectedExplanationLevel) { _, newLevel in
            guard appState.selectedMode == .techExplain, !appState.isAnalyzing else { return }
            // Check cache for current term at new level
            if let current = appState.techDictionary.currentExplanation {
                if let cached = appState.techDictionary.cachedValue(for: current.term, level: newLevel) {
                    let explanation = TechExplanation(term: current.term, level: newLevel, explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources)
                    // Replace top of stack with new level
                    appState.techDictionary.explanationStack[appState.techDictionary.explanationStack.count - 1] = explanation
                    let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources)
                    appState.result = result
                    appState.cachedResults[.techExplain] = result
                } else {
                    onExplainTerm?(current.term)
                }
            }
        }
        .onChange(of: appState.isAnalyzing) { wasAnalyzing, isNow in
            // When analysis finishes, check if mode changed during analysis
            // Do NOT retry on error — prevents infinite loop
            if wasAnalyzing && !isNow,
               appState.cachedResults[appState.selectedMode] == nil,
               appState.error == nil,
               !appState.originalText.isEmpty {
                onReanalyze?(appState.selectedMode)
            }
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "pencil.and.outline")
                .foregroundStyle(.blue)
            Text("Quill")
                .font(.headline)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, appState.appearance.contentPadding)
        .padding(.vertical, 10)
    }

    private var toneSelector: some View {
        HStack(spacing: 4) {
            Text("Tone:")
                .font(.caption)
                .foregroundStyle(.secondary)

            tonePill("None", isSelected: appState.selectedTone == nil) { appState.selectedTone = nil }
            ForEach(ToneStyle.allCases) { tone in
                tonePill(tone.title, isSelected: appState.selectedTone == tone) { appState.selectedTone = tone }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func tonePill(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let a = appState.appearance
        return Button(action: action) {
            Text(label)
                .font(.system(size: a.pillFontSize, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? a.pillSelectedBackground : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? a.pillSelectedBorder : a.pillUnselectedBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }

    private var visibleLevels: [ExplanationLevel] {
        ExplanationLevel.allCases.filter { appState.visibleExplanationLevels.contains($0) }
    }

    private var levelSelector: some View {
        HStack(spacing: 4) {
            ForEach(visibleLevels) { level in
                tonePill(level.title, isSelected: appState.selectedExplanationLevel == level) {
                    appState.selectedExplanationLevel = level
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var breadcrumbBar: some View {
        HStack(spacing: 4) {
            Button {
                appState.techDictionary.pop()
                if let current = appState.techDictionary.currentExplanation {
                    let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: current.explanation, tldr: current.tldr, resources: current.resources)
                    appState.result = result
                    appState.cachedResults[.techExplain] = result
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    let crumbs = appState.techDictionary.breadcrumbs
                    ForEach(Array(crumbs.enumerated()), id: \.offset) { index, term in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                        }
                        Button {
                            appState.techDictionary.popTo(index: index)
                            if let current = appState.techDictionary.currentExplanation {
                                let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: current.explanation, tldr: current.tldr, resources: current.resources)
                                appState.result = result
                                appState.cachedResults[.techExplain] = result
                            }
                        } label: {
                            Text(term)
                                .font(.system(size: 10))
                                .foregroundStyle(index == crumbs.count - 1 ? .primary : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private var contentArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // In techExplain mode with drill-down, show current term instead of original text
                if appState.selectedMode == .techExplain, let current = appState.techDictionary.currentExplanation {
                    currentTermSection(current.term)
                } else if !appState.originalText.isEmpty {
                    originalTextSection
                }

                if appState.isAnalyzing {
                    loadingSection
                } else if let result = appState.result {
                    resultSection(result)
                } else if let error = appState.error {
                    errorSection(error)
                } else if appState.originalText.isEmpty {
                    emptySection
                }
            }
            .padding(appState.appearance.contentPadding)
        }
        .frame(maxHeight: .infinity)
    }

    private func currentTermSection(_ term: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Term")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(term)
                .font(.body)
                .fontWeight(.medium)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var originalTextSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Original")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(appState.originalText)
                .font(.body)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            if !appState.sentenceContext.isEmpty && appState.sentenceContext != appState.originalText {
                DisclosureGroup("Context") {
                    Text(appState.sentenceContext.count > 300
                         ? String(appState.sentenceContext.prefix(300)) + "..."
                         : appState.sentenceContext)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var loadingSection: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Analyzing...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func resultSection(_ result: AnalysisResult) -> some View {
        SuggestionView(
            result: result,
            appearance: appState.appearance,
            onUseWord: { card in
                guard var current = appState.result else { return }
                // Update corrected text for Apply/Copy
                current.corrected = current.corrected.replacingOccurrences(
                    of: card.original, with: card.suggestion
                )
                // Add to changes so it appears in the diff view
                current.changes.append(TextChange(
                    original: card.original,
                    replacement: card.suggestion,
                    reason: "\(card.level) vocabulary upgrade"
                ))
                // Remove used card
                current.vocabularyCards?.removeAll { $0.original == card.original }
                appState.result = current
                appState.cachedResults[current.mode] = current
            },
            onTermTap: appState.selectedMode == .techExplain ? { term in
                onExplainTerm?(term)
            } : nil
        )
    }

    private func errorSection(_ error: QuillError) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(error.localizedDescription)
                    .font(.subheadline)
            }

            if case .accessibilityDenied = error {
                Button {
                    PermissionChecker.shared.openAccessibilitySettings()
                } label: {
                    Label("Open Accessibility Settings", systemImage: "lock.open")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var emptySection: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.cursor")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Select text in any app and press the shortcut")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    /// Text to copy — explanation for Tech, corrected for others
    private var copyText: String? {
        guard let result = appState.result else { return nil }
        switch result.mode {
        case .techExplain:
            return result.explanation ?? result.corrected
        default:
            return result.corrected
        }
    }

    private var actionBar: some View {
        HStack {
            if let text = copyText {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }

                Spacer()

                // Apply only for modes that produce replacement text
                if appState.result?.mode != .techExplain {
                    Button("Apply") {
                        Task {
                            if let corrected = appState.result?.corrected {
                                onDismiss()
                                _ = await AccessibilityManager.shared.replaceSelectedText(with: corrected, in: appState.sourceApp)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, appState.appearance.contentPadding)
        .padding(.vertical, 10)
    }
}
