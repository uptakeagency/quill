import SwiftUI

enum TextDiff {
    enum Segment {
        case unchanged(String)
        case removed(String)
        case added(String)
    }

    struct IndexedSegment: Identifiable {
        let id: Int
        let segment: Segment
    }

    /// Build diff segments from changes list
    static func buildSegments(original: String, changes: [TextChange]) -> [Segment] {
        guard !changes.isEmpty else {
            return [.unchanged(original)]
        }

        var segments: [Segment] = []
        var remaining = original

        for change in changes {
            guard let range = remaining.range(of: change.original) else {
                continue
            }

            // Text before the change
            let before = String(remaining[remaining.startIndex..<range.lowerBound])
            if !before.isEmpty {
                segments.append(.unchanged(before))
            }

            // The change itself
            segments.append(.removed(change.original))
            segments.append(.added(change.replacement))

            remaining = String(remaining[range.upperBound...])
        }

        // Remaining text after all changes
        if !remaining.isEmpty {
            segments.append(.unchanged(remaining))
        }

        return segments
    }
}
