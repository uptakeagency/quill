import SwiftUI

/// Lightweight markdown renderer for AI explanation text.
/// Supports headings, code blocks, bold/italic/code inline, bullet/numbered lists,
/// and clickable [[term]] links for tech dictionary drill-down.
struct MarkdownTextView: View {
    let text: String
    var onTermTap: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
        .textSelection(.enabled)
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "quill", url.host == "explain",
               let term = url.pathComponents.dropFirst().first?.removingPercentEncoding {
                onTermTap?(term)
                return .handled
            }
            // Only allow https links to open in browser (block file://, javascript:, etc.)
            if url.scheme == "https" {
                return .systemAction
            }
            return .discarded
        })
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

    /// Parse inline markdown (bold, italic, code) into AttributedString.
    /// Converts [[term]] markers into clickable quill://explain/ links.
    private func inlineMarkdown(_ text: String) -> AttributedString {
        let processed = convertTermLinks(text)
        return (try? AttributedString(
            markdown: processed,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(processed)
    }

    /// Replace [[term]] with [term](quill://explain/encoded) markdown links
    private func convertTermLinks(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "\\[\\[([^\\]]+)\\]\\]") else { return text }
        let nsText = text as NSString
        var result = text
        // Iterate in reverse to preserve range offsets
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).reversed() {
            let term = nsText.substring(with: match.range(at: 1))
            let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? term
            let replacement = "[\(term)](quill://explain/\(encoded))"
            result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
        }
        return result
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
