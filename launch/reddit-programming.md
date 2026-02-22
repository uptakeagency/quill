# Reddit r/programming

## Title

Quill: a system-wide AI tech dictionary for macOS — built with Hexagonal Architecture in Swift, using Accessibility API and non-activating NSPanel tricks

## Body

I built a macOS app that gives you instant AI-powered explanations for any term, system-wide. Select a term in any app, press `Ctrl+Option+Q`, get an explanation in a floating panel. Open source, MIT licensed.

I'm sharing it here because the technical decisions might be interesting to discuss.

**The architecture problem:**

I wanted to swap AI backends easily (Gemini, Claude API, Claude CLI) without touching the rest of the code. Went with Hexagonal Architecture (Ports & Adapters):

```
Domain/
  Models/    — ExplanationLevel, TechDictionaryState, AnalysisResult
  Ports/     — AIServiceProtocol
Infrastructure/
  Claude/    — Claude API + CLI adapter
  Gemini/    — Gemini API adapter (default)
  Accessibility/  — AXUIElement text capture
  Keychain/  — Secure key storage
Presentation/
  FloatingPanel/  — NSPanel, markdown, drill-down
```

`AIServiceProtocol` is the port. Each AI backend is an adapter. Adding a new one means implementing one protocol. The domain doesn't know or care which backend is active.

**The interesting macOS challenges:**

1. **Non-activating panel**: The floating panel uses `NSPanel` with `.nonActivatingPanel` style mask. This is critical — if the panel activated (took focus), the source app would lose focus and Accessibility-based text replacement would break. Most "floating window" tutorials get this wrong.

2. **Accessibility API without sandbox**: The app reads selected text via `AXUIElement`. This requires the Accessibility permission and means the app can't be sandboxed, which means no App Store. Distribution is via DMG.

3. **Drill-down with `[[brackets]]`**: The AI marks related terms in double brackets. These get converted to `quill://explain/` URLs via `NSRegularExpression` with percent-encoding. Clicking one pushes to a navigation stack with breadcrumbs. You can also select any text in the explanation and press the hotkey again — no brackets needed.

4. **Multi-layer JSON parsing**: AI responses aren't always valid JSON. The parser tries Codable first, then sanitizes common issues, then falls back to JSONSerialization, then regex extraction, then raw text. Brace-matching depth tracking instead of naive `lastIndex(of: "}")`.

5. **Prompt via stdin**: The Claude CLI adapter passes the prompt through stdin instead of command-line arguments to avoid exposure in `ps` output.

6. **Two-layer caching**: Claude API's `cache_control: ephemeral` for prompt caching on the server side, plus local UserDefaults disk cache so repeated lookups are instant.

**The whole thing is ~3K lines of Swift**, no Xcode project needed (`swift build` works), and uses only 3 dependencies: KeyboardShortcuts (pinned to 1.9.4 because v2.x needs Xcode-only `#Preview`), KeychainAccess, and SwiftAnthropic.

[IMAGE: assets/Pro.png]

GitHub: https://github.com/uptakeagency/quill

Would love to hear thoughts on the architecture choices, especially if you've dealt with Accessibility API or non-activating panels in macOS apps.
