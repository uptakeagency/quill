import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                Text("Welcome to Quill")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("AI-powered writing assistant for macOS")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                OnboardingStep(
                    number: 1,
                    title: "Accessibility Permission",
                    description: "Required to read and replace selected text in other apps.",
                    isComplete: appState.hasAccessibilityPermission
                ) {
                    PermissionChecker.shared.requestPermission()
                }

                OnboardingStep(
                    number: 2,
                    title: "API Key",
                    description: "Add your Gemini or Claude API key in Settings.",
                    isComplete: appState.hasAPIKey || appState.hasGeminiKey
                ) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }

                OnboardingStep(
                    number: 3,
                    title: "Try It Out",
                    description: "Select text anywhere, press ⌃⌥Q, and see the magic!",
                    isComplete: false
                ) {}
            }

            Spacer()

            Button("Get Started") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!appState.hasAccessibilityPermission)
        }
        .padding(32)
        .frame(width: 450, height: 500)
    }
}

struct OnboardingStep: View {
    let number: Int
    let title: String
    let description: String
    let isComplete: Bool
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.blue)
                    .frame(width: 28, height: 28)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !isComplete && number <= 2 {
                    Button(number == 1 ? "Grant Permission" : "Open Console") {
                        action()
                    }
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }
        }
    }
}
