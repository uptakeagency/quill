import Foundation
import AppKit

/// macOS'un global Look Up gesture'larını (Ctrl+⌘+D klavye, Force Touch trackpad)
/// passive olarak dinler. Event'leri tüketmez — system Look Up panel'i normal davranışını korur,
/// Quill paralel olarak aynı anda tetiklenir.
///
/// Accessibility permission gerekli (Quill zaten alıyor).
final class LookupGestureMonitor {
    static let shared = LookupGestureMonitor()

    var onLookupTriggered: (() -> Void)?

    private var keyboardEventTap: CFMachPort?
    private var pressureMonitor: Any?

    // Force click throttle — pressure event'leri rapid fire gelir, 1s'de bir tetiklenelim
    fileprivate static var lastForceClickAt: Date?

    func start() {
        startKeyboardTap()
        startPressureMonitor()
    }

    func stop() {
        if let tap = keyboardEventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            keyboardEventTap = nil
        }
        if let monitor = pressureMonitor {
            NSEvent.removeMonitor(monitor)
            pressureMonitor = nil
        }
    }

    // MARK: Ctrl+⌘+D klavye yakalama

    private func startKeyboardTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, _ in
            guard type == .keyDown else { return Unmanaged.passUnretained(event) }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let flags = event.flags
            // 'D' macOS keycode = 2; Ctrl+⌘+D = system Look Up shortcut
            if keyCode == 2,
               flags.contains(.maskCommand),
               flags.contains(.maskControl),
               !flags.contains(.maskShift),
               !flags.contains(.maskAlternate) {
                DispatchQueue.main.async {
                    LookupGestureMonitor.shared.onLookupTriggered?()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else {
            Log.hotkey.error("LookupGestureMonitor: CGEvent.tapCreate başarısız (Accessibility izni eksik?)")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        keyboardEventTap = tap
        Log.hotkey.info("LookupGestureMonitor: keyboard tap aktif (Ctrl+⌘+D)")
    }

    // MARK: Force Touch yakalama

    private func startPressureMonitor() {
        // Force Touch trackpad'inin "Look Up" pressure stage'i 2.
        // NOT: macOS Sequoia+ bu event'leri background app'e iletmiyor — yine de dene.
        pressureMonitor = NSEvent.addGlobalMonitorForEvents(matching: .pressure) { event in
            if event.stage == 2 {
                Log.hotkey.info("LookupGestureMonitor: NSEvent .pressure stage 2")
                Self.triggerThrottled()
            }
        }
        if pressureMonitor != nil {
            Log.hotkey.info("LookupGestureMonitor: NSEvent pressure monitor aktif")
        }
    }

    /// Force Click pressure stream rapid fire gelir — 1s throttle ile tek tetikleme.
    fileprivate static func triggerThrottled() {
        let now = Date()
        if let last = lastForceClickAt, now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastForceClickAt = now
        LookupGestureMonitor.shared.onLookupTriggered?()
    }
}
