import AppKit
import ScreenCaptureKit
import Vision

/// Two-tier text capture at cursor position:
/// 1. Accessibility API (instant, pixel-perfect) — for standard text views
/// 2. ScreenCaptureKit + Vision OCR (fallback) — for images, PDFs, non-selectable text
final class ScreenTextCapture {
    static let shared = ScreenTextCapture()

    struct CapturedText {
        let word: String
        let sentence: String
        let allText: String
    }

    /// Main entry point: try AX first, then OCR
    func captureTextNearCursor() async -> CapturedText? {
        let mouseLocation = NSEvent.mouseLocation

        // Tier 1: Accessibility API — instant and accurate
        if let axResult = getTextViaAccessibility(at: mouseLocation) {
            Log.general.info("AX captured: '\(axResult.word)' in '\(axResult.sentence)'")
            return axResult
        }

        // Tier 2: Screen capture + OCR
        Log.general.info("AX failed, falling back to OCR")
        return await captureTextViaOCR(at: mouseLocation)
    }

    // MARK: - Tier 1: Accessibility API

    private func getTextViaAccessibility(at point: NSPoint) -> CapturedText? {
        let systemWide = AXUIElementCreateSystemWide()

        // Convert AppKit coords (bottom-left of primary) to CG coords (top-left of primary)
        guard let primaryScreen = NSScreen.screens.first else { return nil }
        let cgPoint = CGPoint(x: point.x, y: primaryScreen.frame.height - point.y)

        // Find element at position
        var elementRef: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(cgPoint.x), Float(cgPoint.y), &elementRef) == .success,
              let element = elementRef else {
            return nil
        }

        // Get character range at position using parameterized attribute
        var cgPointMutable = cgPoint
        guard let posValue = AXValueCreate(.cgPoint, &cgPointMutable) else { return nil }

        var rangeValue: AnyObject?
        let rangeResult = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXRangeForPositionParameterizedAttribute as CFString,
            posValue,
            &rangeValue
        )

        guard rangeResult == .success, let axRange = rangeValue else { return nil }

        // Extract the CFRange
        var cfRange = CFRange(location: 0, length: 0)
        guard AXValueGetValue(axRange as! AXValue, .cfRange, &cfRange) else { return nil }

        // Get the full text value of the element
        var textValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &textValue)
        guard let fullText = textValue as? String else { return nil }

        // Sanity check: if text is too long or has no spaces, AX result is likely garbage
        // (e.g. terminal apps returning concatenated text) — fall through to OCR
        if fullText.count > 500 || (fullText.count > 30 && !fullText.contains(" ")) {
            Log.general.info("AX text looks malformed (\(fullText.count) chars), falling back to OCR")
            return nil
        }

        // Expand to word boundaries
        let nsRange = NSRange(location: cfRange.location, length: max(cfRange.length, 1))
        guard let swiftRange = Range(nsRange, in: fullText) else { return nil }
        let word = extractWord(from: fullText, at: swiftRange.lowerBound)
        let sentence = extractSentence(from: fullText, at: swiftRange.lowerBound)

        return CapturedText(word: word, sentence: sentence, allText: fullText)
    }

    private func extractWord(from text: String, at index: String.Index) -> String {
        var start = index
        var end = index

        while start > text.startIndex {
            let prev = text.index(before: start)
            if text[prev].isWhitespace || text[prev].isPunctuation { break }
            start = prev
        }

        while end < text.endIndex {
            if text[end].isWhitespace || text[end].isPunctuation { break }
            end = text.index(after: end)
        }

        return String(text[start..<end])
    }

    private func extractSentence(from text: String, at index: String.Index) -> String {
        let sentenceTerminators: CharacterSet = CharacterSet(charactersIn: ".!?;")
        let nsText = text as NSString
        let location = text.distance(from: text.startIndex, to: index)

        // Find start of sentence
        var start = location
        while start > 0 {
            let char = nsText.character(at: start - 1)
            if let scalar = Unicode.Scalar(char), sentenceTerminators.contains(scalar) { break }
            start -= 1
        }

        // Find end of sentence
        var end = location
        while end < nsText.length {
            let char = nsText.character(at: end)
            if let scalar = Unicode.Scalar(char), sentenceTerminators.contains(scalar) {
                end += 1
                break
            }
            end += 1
        }

        let range = NSRange(location: start, length: end - start)
        return nsText.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Tier 2: Screen Capture + Vision OCR

    private func captureTextViaOCR(at mouseLocation: NSPoint) async -> CapturedText? {
        guard let primaryScreen = NSScreen.screens.first else { return nil }

        let scale = primaryScreen.backingScaleFactor
        let captureWidth: CGFloat = 500
        let captureHeight: CGFloat = 250

        // CG coordinates: top-left origin (primary screen based)
        let cgMouseX = mouseLocation.x
        let cgMouseY = primaryScreen.frame.height - mouseLocation.y

        // Build rect centered on cursor
        var captureRect = CGRect(
            x: cgMouseX - captureWidth / 2,
            y: cgMouseY - captureHeight / 2,
            width: captureWidth,
            height: captureHeight
        )

        // Clamp to screen bounds — track how cursor position shifts
        let screenBounds = CGRect(x: 0, y: 0, width: primaryScreen.frame.width, height: primaryScreen.frame.height)

        if captureRect.minX < screenBounds.minX {
            captureRect.origin.x = screenBounds.minX
        }
        if captureRect.minY < screenBounds.minY {
            captureRect.origin.y = screenBounds.minY
        }
        if captureRect.maxX > screenBounds.maxX {
            captureRect.origin.x = screenBounds.maxX - captureWidth
        }
        if captureRect.maxY > screenBounds.maxY {
            captureRect.origin.y = screenBounds.maxY - captureHeight
        }

        // Cursor position relative to capture rect (normalized 0..1)
        let cursorInRectX = (cgMouseX - captureRect.origin.x) / captureWidth
        // Vision Y is bottom-left, CG is top-left → flip
        let cursorInRectY = 1.0 - ((cgMouseY - captureRect.origin.y) / captureHeight)

        // Capture using ScreenCaptureKit
        guard let cgImage = await captureScreen(rect: captureRect, scale: scale) else {
            Log.general.error("Screen capture failed")
            return nil
        }

        guard let result = await recognizeAndFindWord(in: cgImage, cursorNormX: cursorInRectX, cursorNormY: cursorInRectY) else {
            return nil
        }

        return result
    }

    private func captureScreen(rect: CGRect, scale: CGFloat) async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

            guard let display = content.displays.first(where: { display in
                let displayFrame = CGRect(
                    x: CGFloat(display.frame.origin.x),
                    y: CGFloat(display.frame.origin.y),
                    width: CGFloat(display.width),
                    height: CGFloat(display.height)
                )
                return displayFrame.intersects(rect)
            }) else {
                return nil
            }

            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.sourceRect = rect
            config.width = Int(rect.width * scale)
            config.height = Int(rect.height * scale)
            config.scalesToFit = false
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return image
        } catch {
            Log.general.error("ScreenCaptureKit error: \(error.localizedDescription)")
            return nil
        }
    }

    private func recognizeAndFindWord(in image: CGImage, cursorNormX: CGFloat, cursorNormY: CGFloat) async -> CapturedText? {
        let observations = await performOCR(on: image)
        guard !observations.isEmpty else { return nil }

        // Collect all text for context
        let allText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

        // Find word under cursor using per-word bounding boxes
        var closestWord: String?
        var closestSentence: String?
        var closestDistance: CGFloat = .greatestFiniteMagnitude

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let sentence = candidate.string
            let words = wordRanges(in: sentence)

            for (word, range) in words {
                guard let wordBox = try? candidate.boundingBox(for: range) else { continue }
                let box = wordBox.boundingBox

                // Check if cursor is inside word box
                if box.contains(CGPoint(x: cursorNormX, y: cursorNormY)) {
                    return CapturedText(word: word, sentence: sentence, allText: allText)
                }

                // Track closest word by distance
                let dist = hypot(box.midX - cursorNormX, box.midY - cursorNormY)
                if dist < closestDistance {
                    closestDistance = dist
                    closestWord = word
                    closestSentence = sentence
                }
            }
        }

        if let word = closestWord {
            return CapturedText(word: word, sentence: closestSentence ?? word, allText: allText)
        }

        return CapturedText(word: allText, sentence: allText, allText: allText)
    }

    private func performOCR(on image: CGImage) async -> [VNRecognizedTextObservation] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let results = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                Log.general.error("Vision OCR failed: \(error.localizedDescription)")
                continuation.resume(returning: [])
            }
        }
    }

    /// Split text into words with their String.Index ranges for boundingBox(for:)
    private func wordRanges(in text: String) -> [(String, Range<String.Index>)] {
        var results: [(String, Range<String.Index>)] = []
        var current = text.startIndex

        while current < text.endIndex {
            // Skip whitespace
            while current < text.endIndex && text[current].isWhitespace {
                current = text.index(after: current)
            }
            guard current < text.endIndex else { break }

            // Find end of word
            var wordEnd = current
            while wordEnd < text.endIndex && !text[wordEnd].isWhitespace {
                wordEnd = text.index(after: wordEnd)
            }

            let word = String(text[current..<wordEnd])
            results.append((word, current..<wordEnd))
            current = wordEnd
        }

        return results
    }
}
