import SwiftUI

/// Lightweight markdown renderer for AI explanation text.
/// Supports headings, code blocks, bold/italic/code inline, and bullet/numbered lists.
struct MarkdownTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .textSelection(.enabled)
    }

    // MARK: - Block Types

    private enum Block {
        case heading(String, Int)
        case codeBlock(String)
        case listItem(AttributedString)
        case numberedItem(Int, AttributedString)
        case paragraph(AttributedString)
    }

    // MARK: - Parser

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Code block (``` ... ```)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 } // skip closing ```
                blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                continue
            }

            // Heading (# ... #### )
            if let match = line.range(of: "^#{1,6}\\s+", options: .regularExpression) {
                let level = line[match].filter({ $0 == "#" }).count
                let headingText = String(line[match.upperBound...])
                blocks.append(.heading(headingText, level))
                i += 1
                continue
            }

            // Bullet list item (- or *)
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("- ") ||
               line.trimmingCharacters(in: .whitespaces).hasPrefix("* ") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let content = String(trimmed.dropFirst(2))
                blocks.append(.listItem(inlineMarkdown(content)))
                i += 1
                continue
            }

            // Numbered list item (1. 2. etc)
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if let dotIdx = trimmedLine.firstIndex(of: "."),
               dotIdx > trimmedLine.startIndex,
               let num = Int(trimmedLine[trimmedLine.startIndex..<dotIdx]),
               trimmedLine.index(after: dotIdx) < trimmedLine.endIndex,
               trimmedLine[trimmedLine.index(after: dotIdx)] == " " {
                let content = String(trimmedLine[trimmedLine.index(dotIdx, offsetBy: 2)...])
                blocks.append(.numberedItem(num, inlineMarkdown(content)))
                i += 1
                continue
            }

            // Empty line - skip
            if trimmedLine.isEmpty {
                i += 1
                continue
            }

            // Regular paragraph
            blocks.append(.paragraph(inlineMarkdown(line)))
            i += 1
        }

        return blocks
    }

    /// Parse inline markdown (bold, italic, code) into AttributedString
    private func inlineMarkdown(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    // MARK: - Renderer

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(let text, let level):
            Text(text)
                .font(level <= 2 ? .headline : .subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

        case .codeBlock(let code):
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .textSelection(.enabled)

        case .listItem(let attr):
            HStack(alignment: .top, spacing: 6) {
                Text("\u{2022}")
                    .foregroundStyle(.secondary)
                Text(attr)
            }
            .font(.callout)

        case .numberedItem(let num, let attr):
            HStack(alignment: .top, spacing: 6) {
                Text("\(num).")
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .trailing)
                Text(attr)
            }
            .font(.callout)

        case .paragraph(let attr):
            Text(attr)
                .font(.callout)
        }
    }
}
