# Reddit r/opensource

## Title

Quill — open source, system-wide AI tech dictionary for macOS. ~3K LOC, MIT licensed, contributions welcome.

## Body

Hey r/opensource,

I'm releasing Quill as an MIT-licensed open source project and would love to get more eyes on it.

**What it is:** A macOS menu bar app that gives you instant AI explanations for any selected term, system-wide. Select a term in any app, press `Ctrl+Option+Q`, get an explanation in a floating panel near your cursor.

[IMAGE: assets/demo.gif]

**Why open source:**

- The app reads your text selections via Accessibility API — you should be able to audit exactly what it does
- AI-powered tools should be transparent about what gets sent to which API
- I want this to get better through community feedback, not just my own use cases

**Project stats:**

- ~3,000 lines of Swift
- 3 dependencies (KeyboardShortcuts, KeychainAccess, SwiftAnthropic)
- Hexagonal Architecture (Ports & Adapters) — clean separation between domain, infrastructure, and presentation
- No Xcode project needed — builds with `swift build`
- macOS 14+ (Sonoma)

**Contribution areas I'd especially welcome:**

- **New AI backends** — the architecture uses a protocol (`AIServiceProtocol`), so adding Ollama, local LLMs, or other providers is straightforward
- **UI/UX improvements** — the floating panel, markdown rendering, accessibility
- **Localization** — the app explains terms in the user's system language, but the UI itself is English-only
- **Testing** — the hexagonal architecture makes unit testing natural, but coverage is minimal right now
- **Documentation** — architecture docs, contribution guide

**Quick start for contributors:**

```bash
git clone https://github.com/uptakeagency/quill.git
cd quill
swift build
./scripts/build-app.sh debug
open dist/Quill.app
```

GitHub: https://github.com/uptakeagency/quill
License: MIT
Download: https://github.com/uptakeagency/quill/releases/latest

The app requires a Gemini or Claude API key (Gemini has a generous free tier). It's non-sandboxed because the Accessibility API requires it, so distribution is via DMG, not the App Store.

Feedback, issues, and PRs all welcome!
