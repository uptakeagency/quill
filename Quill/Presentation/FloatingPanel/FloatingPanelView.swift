import SwiftUI

struct FloatingPanelView: View {
    @Bindable var appState: AppState
    var onDismiss: () -> Void
    var onReanalyze: ((AnalysisMode) -> Void)?
    var onExplainTerm: ((String, _ isLevelSwitch: Bool) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Üstte minimal close button
            header

            // TL;DR sol-border ile content'ten ÖNCE — kelimenin hemen altında okunsun
            if appState.selectedMode == .techExplain,
               let tldr = appState.techDictionary.currentExplanation?.tldr ?? appState.result?.tldr,
               !tldr.isEmpty {
                persistentTldr(tldr)
            }

            // techExplain mode'da breadcrumb (drill-down geçmişi)
            if appState.selectedMode == .techExplain, appState.techDictionary.canGoBack {
                breadcrumbBar
            }

            // Tone selector improve mode'da content'in üstünde
            if appState.selectedMode == .improve {
                toneSelector
            }

            // Level selector techExplain mode'da content'in üstünde
            if appState.selectedMode == .techExplain {
                levelSelector
            }

            // İçerik
            contentArea

            // İçerik üretildiyse Copy/Apply satırı
            if copyText != nil {
                Divider().opacity(0.3)
                actionBar
            }

            // Apple Look Up panel'i diline yakın bottom tab bar
            Divider().opacity(0.3)
            ModePickerView(selectedMode: $appState.selectedMode)
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
                    let explanation = TechExplanation(term: current.term, level: newLevel, explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources, alternatives: cached.alternatives)
                    // Replace top of stack with new level
                    appState.techDictionary.explanationStack[appState.techDictionary.explanationStack.count - 1] = explanation
                    let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: cached.explanation, tldr: cached.tldr, resources: cached.resources, alternatives: cached.alternatives)
                    appState.result = result
                    appState.cachedResults[.techExplain] = result
                } else {
                    onExplainTerm?(current.term, true)
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

    // Sade header — Look Up panel'inde brand görünmez, sadece kapama kontrolü
    private var header: some View {
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, appState.appearance.contentPadding)
        .padding(.top, 8)
        .padding(.bottom, 2)
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
                    let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: current.explanation, tldr: current.tldr, resources: current.resources, alternatives: current.alternatives)
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
                                let result = AnalysisResult(mode: .techExplain, original: current.term, corrected: current.term, changes: [], explanation: current.explanation, tldr: current.tldr, resources: current.resources, alternatives: current.alternatives)
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

    // Apple Dictionary'nin highlight bloku diline yakın: sol renkli border + sade text
    private func persistentTldr(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(appState.appearance.tldrAccent)
                .frame(width: 2)
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, appState.appearance.contentPadding)
        .padding(.vertical, 4)
    }

    // Tech mode: terim büyük h1 başlık olarak — Apple Dictionary diline yakın
    private func currentTermSection(_ term: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(term)
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("tech term")
                .font(.system(size: 12).italic())
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }

    // Diğer modlar: orijinal metni native dictionary entry başlığı gibi göster
    private var originalTextSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(appState.originalText)
                .font(.system(size: 22, weight: .semibold, design: .default))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            if !appState.sentenceContext.isEmpty && appState.sentenceContext != appState.originalText {
                DisclosureGroup {
                    Text(appState.sentenceContext.count > 300
                         ? String(appState.sentenceContext.prefix(300)) + "..."
                         : appState.sentenceContext)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Context")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.bottom, 2)
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
                onExplainTerm?(term, false)
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

    // Native dictionary alt action satırı: kompakt, içerik varsa görünür
    @ViewBuilder
    private var actionBar: some View {
        if let text = copyText {
            HStack(spacing: 10) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                if appState.result?.mode != .techExplain {
                    Button {
                        Task {
                            if let corrected = appState.result?.corrected {
                                let sourceApp = appState.sourceApp
                                onDismiss()
                                try? await Task.sleep(for: .milliseconds(100))
                                _ = await AccessibilityManager.shared.replaceSelectedText(with: corrected, in: sourceApp)
                            }
                        }
                    } label: {
                        Label("Apply", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, appState.appearance.contentPadding)
            .padding(.vertical, 6)
        }
    }
}
