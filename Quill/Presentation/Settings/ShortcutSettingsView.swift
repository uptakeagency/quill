import SwiftUI
import KeyboardShortcuts

struct ShortcutSettingsView: View {
    var body: some View {
        Form {
            Section("Global Shortcut") {
                HStack {
                    Text("Trigger Quill")
                    Spacer()
                    KeyboardShortcuts.Recorder("", name: .triggerQuill)
                }
                Text("Select text in any app, then press this shortcut to analyze it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
    }
}
