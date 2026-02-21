import SwiftUI

struct SuggestionView: View {
    let result: AnalysisResult
    var onUseWord: ((VocabularyCard) -> Void)?
    var onTermTap: ((String) -> Void)?

    /// Modes where inline diff (red strikethrough → green) makes sense
    private var usesDiff: Bool {
        result.mode == .improve
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            // TL;DR (techExplain mode)
            if let tldr = result.tldr, !tldr.isEmpty {
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

            WrappingHStack(segments: segments)
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
                                .foregroundStyle(.red)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(change.replacement)
                                .foregroundStyle(.green)
                        }
                        .font(.callout)

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
                .foregroundStyle(.orange)
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func resourcesSection(_ resources: [ResourceLink]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Resources")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(resources) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(link.title)
                                    .font(.callout)
                                    .lineLimit(1)
                                Spacer()
                                Text(url.host ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func explanationSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Explanation")
                .font(.caption)
                .foregroundStyle(.secondary)
            MarkdownTextView(text: text, onTermTap: onTermTap)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

/// Simple text flow layout for diff segments
struct WrappingHStack: View {
    let segments: [TextDiff.Segment]

    var body: some View {
        // Use a simple Text concatenation for inline diff display
        segments.reduce(Text("")) { result, segment in
            switch segment {
            case .unchanged(let text):
                result + Text(text)
            case .removed(let text):
                result + Text(text)
                    .strikethrough()
                    .foregroundColor(.red)
            case .added(let text):
                result + Text(text)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
    }
}
