import AppKit
import ApplicationServices

final class AccessibilityManager: TextCaptureProtocol {
    static let shared = AccessibilityManager()

    // MARK: - TextCaptureProtocol

    func checkPermission() -> Bool {
        PermissionChecker.shared.isTrusted
    }

    func requestPermission() {
        PermissionChecker.shared.requestPermission()
    }

    struct SelectionResult {
        let selectedText: String
        let surroundingText: String?  // full element text for context
    }

    func getSelectedText() async -> String? {
        return (await getSelectionWithContext())?.selectedText
    }

    /// Get selected text plus surrounding context from the same UI element
    func getSelectionWithContext() async -> SelectionResult? {
        if let result = getSelectedTextWithContextViaAX() {
            return result
        }
        Log.accessibility.info("AX failed, falling back to clipboard")
        if let text = await getSelectedTextViaClipboard() {
            return SelectionResult(selectedText: text, surroundingText: nil)
        }
        return nil
    }

    func replaceSelectedText(with text: String) async -> Bool {
        if replaceSelectedTextViaAX(text) {
            return true
        }
        Log.accessibility.info("AX replace failed, falling back to clipboard")
        return await replaceSelectedTextViaClipboard(text)
    }

    // MARK: - AX API

    private func getSelectedTextWithContextViaAX() -> SelectionResult? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success, let element = focusedElement else {
            Log.accessibility.warning("Could not get focused element: \(focusResult.rawValue)")
            return nil
        }

        // AX API guarantees AXUIElement type when focusResult == .success
        let axElement = element as! AXUIElement

        // Get selected text
        var selectedText: AnyObject?
        let textResult = AXUIElementCopyAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard textResult == .success, let text = selectedText as? String, !text.isEmpty else {
            Log.accessibility.debug("No selected text via AX")
            return nil
        }

        // Get full element text for context
        var fullTextValue: AnyObject?
        AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &fullTextValue)
        let fullText = fullTextValue as? String

        // If full text is too large, try to get a smaller context around selection
        var context: String? = nil
        if let full = fullText {
            if full.count <= 2000 {
                context = full
            } else if let selectedRange = getSelectedRange(element: axElement) {
                // Get ~500 chars around the selection (use NSString length for UTF-16 safety)
                let nsString = full as NSString
                let fullLength = nsString.length
                let start = max(0, selectedRange.location - 250)
                let end = min(fullLength, selectedRange.location + selectedRange.length + 250)
                context = nsString.substring(with: NSRange(location: start, length: end - start))
            }
        }

        return SelectionResult(selectedText: text, surroundingText: context)
    }

    private func getSelectedRange(element: AXUIElement) -> NSRange? {
        var rangeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeValue
        )
        guard result == .success, let axValue = rangeValue else { return nil }

        var cfRange = CFRange(location: 0, length: 0)
        guard AXValueGetValue(axValue as! AXValue, .cfRange, &cfRange) else { return nil }
        return NSRange(location: cfRange.location, length: cfRange.length)
    }

    private func replaceSelectedTextViaAX(_ text: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success, let element = focusedElement else {
            return false
        }

        let setResult = AXUIElementSetAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }

    // MARK: - Clipboard Fallback

    @MainActor
    private func getSelectedTextViaClipboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        // Simulate Cmd+C
        simulateKeyPress(key: .c, modifiers: .maskCommand)

        // Small delay for clipboard to update
        try? await Task.sleep(for: .milliseconds(100))

        let selectedText = pasteboard.string(forType: .string)

        // Restore previous clipboard contents
        pasteboard.clearContents()
        if let previous = previousContents {
            pasteboard.setString(previous, forType: .string)
        }

        // Only return if clipboard changed (meaning text was copied)
        if selectedText != previousContents {
            return selectedText
        }
        return nil
    }

    @MainActor
    private func replaceSelectedTextViaClipboard(_ text: String) async -> Bool {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        // Put replacement text on clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulateKeyPress(key: .v, modifiers: .maskCommand)

        // Small delay for paste to complete
        try? await Task.sleep(for: .milliseconds(100))

        // Restore previous clipboard contents
        pasteboard.clearContents()
        if let previous = previousContents {
            pasteboard.setString(previous, forType: .string)
        }

        return true
    }

    // MARK: - Key Simulation

    private func simulateKeyPress(key: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        keyDown?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyUp?.flags = modifiers
        keyUp?.post(tap: .cghidEventTap)
    }
}

// CGKeyCode constants
private extension CGKeyCode {
    static let c: CGKeyCode = 0x08
    static let v: CGKeyCode = 0x09
}
