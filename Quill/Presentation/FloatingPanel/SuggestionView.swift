import SwiftUI

struct SuggestionView: View {
    let result: AnalysisResult
    var appearance: PanelAppearance = PanelAppearance()
    var onUseWord: ((VocabularyCard) -> Void)?
    var onTermTap: ((String) -> Void)?

    /// Modes where inline diff (red strikethrough → green) makes sense
    private var usesDiff: Bool {
        result.mode == .improve
    }

    var body: some View {
        VStack(alignment: .leading, spacing: appearance.sectionSpacing) {
            // Result section — diff for corrections, plain text for others
            if usesDiff {
                diffSection
            } else if result.mode != .techExplain {
                plainResultSection
            }

            // Changes detail — only for diff modes
            if usesDiff && !result.changes.isEmpty {
                changesSection
            }

            // TL;DR — shown in FloatingPanelView header for techExplain, inline for others
            if result.mode != .techExplain, let tldr = result.tldr, !tldr.isEmpty {
                tldrSection(tldr)
            }

            // Explanation (for explain/translate/techExplain modes)
            if let explanation = result.explanation, !explanation.isEmpty {
                explanationSection(explanation)
            }

            // Resource links (techExplain mode)
            if let resources = result.resources, !resources.isEmpty {
                resourcesSection(resources)
            }

            // Alternatives (dedicated tab)
            if let alternatives = result.alternatives, !alternatives.isEmpty {
                alternativesSection(alternatives)
            }

            // Vocabulary cards
            if let cards = result.vocabularyCards, !cards.isEmpty {
                VocabularyCardView(cards: cards, onUseWord: onUseWord)
            }
        }
        .textSelection(.enabled)
    }

    private var resultLabel: String {
        switch result.mode {
        case .translate: "Translation"
        default: "Corrected"
        }
    }

    /// Plain text result (translate, tone, vocabulary) — no diff highlighting
    private var plainResultSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(resultLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(result.corrected)
                .font(.body)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    /// Inline diff view (proofread, rewrite, explain)
    private var diffSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Corrected")
                .font(.caption)
                .foregroundStyle(.secondary)

            let segments = TextDiff.buildSegments(original: result.original, changes: result.changes)

            WrappingHStack(segments: segments, appearance: appearance)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Changes (\(result.changes.count))")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(result.changes) { change in
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(change.original)
                                .strikethrough()
                                .foregroundStyle(appearance.removedColor)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(change.replacement)
                                .foregroundStyle(appearance.addedColor)
                        }
                        .font(appearance.contentFont)

                        Text(change.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private func tldrSection(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(appearance.tldrAccent)
            Text(text)
                .font(appearance.contentFont)
                .foregroundStyle(.primary)
        }
        .padding(appearance.sectionPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appearance.tldrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func resourcesSection(_ resources: [ResourceLink]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Resources")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(resources) { link in
                    if let url = URL(string: link.url), url.scheme == "https" {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(link.title)
                                    .font(appearance.contentFont)
                                    .lineLimit(1)
                                Spacer()
                                Text(url.host ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(appearance.linkColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(appearance.sectionPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(appearance.resourcesBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func alternativesSection(_ alternatives: [Alternative]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alternatives")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(alternatives) { alt in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            if let onTermTap {
                                Button {
                                    onTermTap(alt.name)
                                } label: {
                                    Text(alt.name)
                                        .font(appearance.contentFont.bold())
                                        .foregroundStyle(appearance.linkColor)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(alt.name)
                                    .font(appearance.contentFont.bold())
                            }
                            Text("— \(alt.description)")
                                .font(appearance.contentFont)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        HStack(spacing: 12) {
                            Label(alt.pros, systemImage: "plus.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Label(alt.cons, systemImage: "minus.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(appearance.sectionPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(appearance.resourcesBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func explanationSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Explanation")
                .font(.caption)
                .foregroundStyle(.secondary)
            MarkdownTextView(text: text, appearance: appearance, onTermTap: onTermTap)
                .padding(appearance.sectionPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(appearance.explanationBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

/// Simple text flow layout for diff segments
struct WrappingHStack: View {
    let segments: [TextDiff.Segment]
    var appearance: PanelAppearance = PanelAppearance()

    var body: some View {
        // Use a simple Text concatenation for inline diff display
        segments.reduce(Text("")) { result, segment in
            switch segment {
            case .unchanged(let text):
                result + Text(text)
            case .removed(let text):
                result + Text(text)
                    .strikethrough()
                    .foregroundColor(appearance.removedColor)
            case .added(let text):
                result + Text(text)
                    .foregroundColor(appearance.addedColor)
                    .fontWeight(.medium)
            }
        }
    }
}
