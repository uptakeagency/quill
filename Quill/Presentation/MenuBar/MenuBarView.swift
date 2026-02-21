import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            statusSection
            Divider()
            modeSection
            Divider()
            actionSection
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "pencil.and.outline")
                Text("Quill")
                    .font(.headline)
                Spacer()
                statusBadge
            }

            if !appState.hasAccessibilityPermission {
                Button {
                    PermissionChecker.shared.openAccessibilitySettings()
                } label: {
                    Label("Grant Accessibility Permission", systemImage: "lock.open")
                }
            }

            if appState.aiBackend == .claudeAPI && !appState.hasAPIKey {
                Label("Claude API key not configured", systemImage: "key")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if appState.aiBackend == .gemini && !appState.hasGeminiKey {
                Label("Gemini API key not configured", systemImage: "key")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Label(appState.aiBackend.title, systemImage: appState.aiBackend == .claudeCLI ? "terminal" : appState.aiBackend == .gemini ? "bolt.fill" : "network")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        Group {
            if appState.isAnalyzing {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Analyzing...")
                        .font(.caption)
                }
            } else {
                Text("Ready")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var modeSection: some View {
        Picker("Default Mode", selection: $appState.selectedMode) {
            ForEach(AnalysisMode.allCases) { mode in
                Label(mode.title, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.inline)
    }

    private var actionSection: some View {
        VStack(spacing: 2) {
            Button {
                // Capture mouse location now, before the menu dismisses
                let mouse = NSEvent.mouseLocation
                let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })

                // Clear SwiftUI's saved window position so it doesn't restore
                UserDefaults.standard.removeObject(forKey: "Quill Settings-AppWindow-1")
                UserDefaults.standard.removeObject(forKey: "NSWindow Frame Quill Settings")

                openWindow(id: "settings")

                // Reposition after SwiftUI finishes laying out the window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApp.setActivationPolicy(.regular)

                    if let window = NSApp.windows.first(where: { $0.title == "Quill Settings" }),
                       let screen = targetScreen {
                        let x = screen.visibleFrame.midX - window.frame.width / 2
                        let y = screen.visibleFrame.midY - window.frame.height / 2
                        window.setFrameOrigin(NSPoint(x: x, y: y))
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    }

                    NSApp.activate(ignoringOtherApps: true)
                }
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .frame(width: 20)
                    Text("Settings...")
                    Spacer()
                    Text("⌘,")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)

            Divider()

            Button("Quit Quill") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 4)
    }
}
