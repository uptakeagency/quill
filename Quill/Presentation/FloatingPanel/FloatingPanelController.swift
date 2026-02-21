import AppKit
import SwiftUI

/// Custom NSPanel that doesn't steal focus from the source app
final class QuillPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Hide standard window buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
}

@Observable
final class FloatingPanelController {
    static let shared = FloatingPanelController()

    private var panel: QuillPanel?
    private var escMonitor: Any?
    var isVisible = false

    func show(appState: AppState, onReanalyze: ((AnalysisMode) -> Void)? = nil, onExplainTerm: ((String) -> Void)? = nil) {
        let panelWidth: CGFloat = 420
        let panelHeight: CGFloat = 380

        let contentRect = positionNearCursor(width: panelWidth, height: panelHeight)

        if panel == nil {
            panel = QuillPanel(contentRect: contentRect)
        }

        let hostingView = NSHostingView(
            rootView: FloatingPanelView(
                appState: appState,
                onDismiss: { [weak self] in self?.hide() },
                onReanalyze: onReanalyze,
                onExplainTerm: onExplainTerm
            )
        )

        panel?.contentView = hostingView
        panel?.setContentSize(NSSize(width: panelWidth, height: panelHeight))
        panel?.setFrameOrigin(contentRect.origin)
        panel?.orderFrontRegardless()

        isVisible = true

        // ESC key monitoring — remove previous monitor before adding new one
        if let monitor = escMonitor { NSEvent.removeMonitor(monitor) }
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.hide()
                return nil
            }
            return event
        }
    }

    /// Find selected text within the panel's view hierarchy (SwiftUI text selection uses NSTextView)
    func getSelectedText() -> String? {
        guard let contentView = panel?.contentView else { return nil }
        return findSelectedText(in: contentView)
    }

    private func findSelectedText(in view: NSView) -> String? {
        if let textView = view as? NSTextView {
            let range = textView.selectedRange()
            if range.length > 0 {
                return (textView.string as NSString).substring(with: range)
            }
        }
        for subview in view.subviews {
            if let found = findSelectedText(in: subview) {
                return found
            }
        }
        return nil
    }

    func hide() {
        if let monitor = escMonitor { NSEvent.removeMonitor(monitor); escMonitor = nil }
        panel?.orderOut(nil)
        isVisible = false
    }

    private func positionNearCursor(width: CGFloat, height: CGFloat) -> NSRect {
        let mouseLocation = NSEvent.mouseLocation

        // Find the screen containing the cursor
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
                ?? NSScreen.main ?? NSScreen.screens.first else {
            return NSRect(x: 100, y: 100, width: width, height: height)
        }
        let screenFrame = screen.visibleFrame

        // Position panel near cursor, with offset
        var x = mouseLocation.x + 20
        var y = mouseLocation.y - height - 20

        // Keep panel within screen bounds
        if x + width > screenFrame.maxX {
            x = mouseLocation.x - width - 20
        }
        if y < screenFrame.minY {
            y = mouseLocation.y + 20
        }
        if x < screenFrame.minX {
            x = screenFrame.minX + 10
        }

        return NSRect(x: x, y: y, width: width, height: height)
    }
}
