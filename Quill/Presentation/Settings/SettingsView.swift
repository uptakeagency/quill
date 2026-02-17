import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @Bindable var appState: AppState
    @State private var apiKeyInput = ""
    @State private var geminiKeyInput = ""

    var body: some View {
        Form {
            Section("AI Backend") {
                Picker("Backend", selection: $appState.aiBackend) {
                    ForEach(AIBackend.allCases) { backend in
                        Text(backend.title).tag(backend)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(appState.aiBackend.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appState.aiBackend == .gemini {
                Section("Gemini API Key") {
                    SecureField("API Key", text: $geminiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Save API Key") {
                        KeychainManager.shared.saveGeminiKey(geminiKeyInput)
                        geminiKeyInput = ""
                    }
                    .disabled(geminiKeyInput.isEmpty)

                    if appState.hasGeminiKey {
                        Label("Gemini key configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Button("Remove API Key", role: .destructive) {
                            KeychainManager.shared.deleteGeminiKey()
                        }
                        .foregroundStyle(.red)
                    }
                }

                Section("Gemini Model") {
                    Picker("Model", selection: $appState.geminiModel) {
                        ForEach(appState.availableGeminiModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }

                    HStack {
                        Button {
                            fetchLatestModels()
                        } label: {
                            Label("Check for Latest Models", systemImage: "arrow.clockwise")
                        }
                        .disabled(appState.isFetchingModels || !appState.hasGeminiKey)

                        if appState.isFetchingModels {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }

            if appState.aiBackend == .claudeAPI {
                Section("Claude API Key") {
                    SecureField("API Key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Save API Key") {
                        KeychainManager.shared.saveAPIKey(apiKeyInput)
                        appState.hasAPIKey = true
                        apiKeyInput = ""
                    }
                    .disabled(apiKeyInput.isEmpty)

                    if appState.hasAPIKey {
                        Label("API key configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Button("Remove API Key", role: .destructive) {
                            KeychainManager.shared.deleteAPIKey()
                            appState.hasAPIKey = false
                        }
                        .foregroundStyle(.red)
                    }
                }
            }

            Section("Translation Languages") {
                Picker("Native Language", selection: $appState.nativeLanguage) {
                    ForEach(Self.languages, id: \.self) { Text($0) }
                }

                Picker("Target Language", selection: $appState.targetLanguage) {
                    ForEach(Self.languages, id: \.self) { Text($0) }
                }

                Text("Used by Translate mode to determine source and target languages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Accessibility") {
                if appState.hasAccessibilityPermission {
                    Label("Permission granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Permission required", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Button("Open System Settings") {
                        PermissionChecker.shared.openAccessibilitySettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
    }

    private static let languages = [
        "Arabic", "Chinese", "Dutch", "English", "French", "German",
        "Greek", "Hindi", "Italian", "Japanese", "Korean", "Persian",
        "Polish", "Portuguese", "Russian", "Spanish", "Swedish", "Turkish", "Ukrainian"
    ]

    private func fetchLatestModels() {
        guard let key = KeychainManager.shared.getGeminiKey() else { return }
        appState.isFetchingModels = true
        Task {
            do {
                let models = try await GeminiService.fetchAvailableModels(apiKey: key)
                await MainActor.run {
                    if !models.isEmpty {
                        appState.availableGeminiModels = models
                        // Keep current selection if still available
                        if !models.contains(appState.geminiModel) {
                            appState.geminiModel = models.first ?? "gemini-2.5-flash"
                        }
                    }
                    appState.isFetchingModels = false
                }
            } catch {
                await MainActor.run { appState.isFetchingModels = false }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section("Panel") {
                Text("Panel appearance settings will be available in a future update.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
    }
}
