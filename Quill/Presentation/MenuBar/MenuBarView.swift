import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState

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
            SettingsLink {
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
