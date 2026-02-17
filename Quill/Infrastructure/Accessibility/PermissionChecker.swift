import AppKit
import ApplicationServices

final class PermissionChecker {
    static let shared = PermissionChecker()

    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompt the system dialog asking for Accessibility permission
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Settings > Privacy > Accessibility directly
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
