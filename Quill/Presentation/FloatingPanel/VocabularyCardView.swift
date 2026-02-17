import SwiftUI

struct VocabularyCardView: View {
    let cards: [VocabularyCard]
    var onUseWord: ((VocabularyCard) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vocabulary Suggestions")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(cards) { card in
                VocabularyCardItem(card: card, onUse: onUseWord)
            }
        }
    }
}

struct VocabularyCardItem: View {
    let card: VocabularyCard
    var onUse: ((VocabularyCard) -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: word swap
            HStack {
                Text(card.original)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(card.suggestion)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Spacer()
                if onUse != nil {
                    Button("Use") { onUse?(card) }
                        .font(.system(size: 10))
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }
                levelBadge(card.level)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Expandable detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.definition)
                        .font(.caption)

                    HStack(spacing: 4) {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(card.example)
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func levelBadge(_ level: String) -> some View {
        Text(level)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(levelColor(level).opacity(0.2))
            .foregroundStyle(levelColor(level))
            .clipShape(Capsule())
    }

    private func levelColor(_ level: String) -> Color {
        switch level.uppercased() {
        case "B1": .green
        case "B2": .blue
        case "C1": .purple
        case "C2": .red
        default: .gray
        }
    }
}
