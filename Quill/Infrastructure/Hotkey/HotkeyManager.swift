import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let triggerQuill = Self("triggerQuill", default: .init(.q, modifiers: [.control, .option]))
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onTrigger: (() -> Void)?

    func register() {
        KeyboardShortcuts.onKeyUp(for: .triggerQuill) { [weak self] in
            Log.hotkey.info("Quill triggered via hotkey")
            self?.onTrigger?()
        }
    }

    func unregister() {
        KeyboardShortcuts.disable(.triggerQuill)
    }
}
