# Quill

A lightweight, open-source AI writing assistant that works system-wide on macOS. Select text in any app, press a shortcut, and get instant grammar corrections, translations, and technical explanations.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## How It Works

1. **Select text** in any application
2. **Press** `⌃⌥Q` (Control + Option + Q)
3. **Review** the suggestion in the floating panel
4. **Apply** with one click — the corrected text replaces your selection

The floating panel appears near your cursor without stealing focus from your current app, so your workflow stays uninterrupted.

## Features

### Three Modes

| Mode | What it does |
|------|-------------|
| **Improve** | Fixes grammar, spelling, punctuation. Improves clarity and readability. Optional tone adjustment (formal, casual, professional, friendly). Suggests richer vocabulary alternatives. |
| **Translate** | Auto-detects language direction and translates between your native and target language. Provides translation notes and usage context. |
| **Tech Explain** | Explains technical terms, commands, and programming concepts with practical examples and related concepts. |

### Highlights

- **System-wide** — works in any macOS app (Safari, VS Code, Slack, Notes, etc.)
- **Multiple AI backends** — Gemini Flash (default, fast), Claude API, or Claude CLI
- **Non-intrusive** — floating panel doesn't steal focus; keeps your cursor in the source app
- **One-click apply** — corrected text is written back to the source app via Accessibility API
- **OCR fallback** — captures text near cursor when standard text selection isn't available
- **Auto language detection** — automatically switches to Translate mode when native language text is selected
- **Context-aware** — reads surrounding text for better, context-aware suggestions
- **Inline diff** — color-coded red/green diff view shows exactly what changed (Improve mode)
- **Vocabulary cards** — learn richer alternatives with definitions, examples, and CEFR levels

## Installation

### Requirements

- macOS 14 (Sonoma) or later
- An API key for [Google Gemini](https://aistudio.google.com/apikey) (free tier available) or [Anthropic Claude](https://console.anthropic.com/settings/keys)

### From Source

```bash
git clone https://github.com/uptakeagency/quill.git
cd quill

# Build and create .app bundle
./scripts/build-app.sh release

# Run
open dist/Quill.app
```

### First Launch

1. **Grant Accessibility permission** — Quill needs this to read and replace selected text. macOS will prompt you, or go to System Settings > Privacy & Security > Accessibility.
2. **Add your API key** — Open Settings from the menu bar icon and enter your Gemini or Claude API key.
3. **Try it** — Select some text, press `⌃⌥Q`, and see the magic.

### Stable Code Signing (Optional)

By default, macOS resets Accessibility permissions when the app binary changes (every rebuild). To avoid re-granting permissions during development:

```bash
./scripts/setup-cert.sh   # Creates a self-signed "Quill Development" certificate
./scripts/build-app.sh debug  # Uses the certificate automatically
```

## Architecture

Hexagonal (Ports & Adapters) architecture with clean separation of concerns:

```
Quill/
├── App/                  # AppState, lifecycle
├── Domain/
│   ├── Models/           # AnalysisMode, AnalysisResult, ToneStyle
│   └── Ports/            # AIServiceProtocol, TextCaptureProtocol
├── Infrastructure/
│   ├── Accessibility/    # AXUIElement text capture & replacement
│   ├── Claude/           # Claude API & CLI service, prompts, parser
│   ├── Gemini/           # Gemini API service
│   ├── Hotkey/           # Global shortcut registration
│   └── Keychain/         # Secure API key storage
├── Presentation/
│   ├── FloatingPanel/    # Main UI: panel, suggestions, diff view
│   ├── MenuBar/          # Menu bar icon and menu
│   ├── Settings/         # Configuration UI
│   └── Onboarding/       # First-launch wizard
└── Utilities/            # TextDiff, Logger
```

### Key Technical Decisions

- **Non-sandboxed** — Accessibility API requires it; distributed via DMG, not App Store
- **NSPanel with `.nonActivatingPanel`** — keeps focus in the source app so text replacement works
- **Protocol-based AI service** — easy to swap backends or add new ones (e.g., local LLMs)
- **JSON structured output** — all AI responses return structured JSON for reliable parsing and rich UI rendering

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | 1.9.4 | Global hotkey registration |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | 4.2.2+ | Secure API key storage |
| [SwiftAnthropic](https://github.com/jamesrochabrun/SwiftAnthropic) | 2.0.0+ | Claude API client |

## Configuration

All settings are accessible from the menu bar icon:

- **AI Backend** — Choose between Gemini Flash, Claude API, or Claude CLI
- **Model** — Select specific model (Gemini models are fetched dynamically)
- **Languages** — Set your native and target languages for translation
- **Shortcut** — Customize the global hotkey (default: `⌃⌥Q`)

## Building

```bash
# Development build
swift build

# Debug .app bundle
./scripts/build-app.sh debug

# Release .app bundle
./scripts/build-app.sh release

# Create DMG for distribution
./scripts/create-dmg.sh
```

No Xcode required — builds with Swift Package Manager. For Xcode project generation: `xcodegen generate`.

## License

MIT
