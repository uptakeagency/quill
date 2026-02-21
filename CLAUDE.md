# Quill - macOS System-Wide AI Tech Dictionary

"Learn what AI writes for you." Select any term, press a shortcut, get an instant explanation at your level.

## Build & Run

```bash
swift build                    # Development build
./scripts/build-app.sh debug   # Debug .app bundle
./scripts/build-app.sh release # Release .app bundle
open dist/Quill.app            # Run the app
./scripts/create-dmg.sh        # DMG for distribution
```

No Xcode required. For Xcode project: `xcodegen generate`

## Architecture

Hexagonal (Ports & Adapters) with clean separation:
- **Domain**: Models (ExplanationLevel, TechDictionaryState, AnalysisResult) + Ports (AIServiceProtocol)
- **Infrastructure**: Claude API/CLI, Gemini API, Accessibility (AXUIElement + Vision OCR), Keychain
- **Presentation**: FloatingPanel (drill-down, markdown, diff), Settings, MenuBar, Onboarding

## Key Decisions

- **Non-sandboxed**: Accessibility API requires it, distribution via DMG not App Store
- **KeyboardShortcuts v1.9.4**: Pinned because v2.x uses `#Preview` which requires Xcode
- **SwiftAnthropic v2.x**: Factory pattern with `betaHeaders: nil`, Content.text has `(String, Citations?)` tuple
- **NSPanel with `.nonActivatingPanel`**: Keeps focus in source app so AX text replacement works
- **Window(id:) for Settings**: Replaced `Settings {}` scene for multi-screen positioning control
- **Default mode is techExplain**: App starts in Tech Dictionary mode, user can switch
- **Prompt via stdin for CLI**: ClaudeCLIService passes prompt through stdin to avoid `ps` exposure
- **Two-layer caching**: Claude API `cache_control: ephemeral` + local UserDefaults disk cache
- **Multi-layer JSON parser**: Codable → sanitizeJSON → JSONSerialization → regex → raw fallback
- **Brace-matching JSON extraction**: Depth-tracking parser instead of `lastIndex(of: "}")`
- **Vision OCR with error handling**: `do/catch` in `performOCR` to prevent continuation hangs
- **`defer` for isAnalyzing**: Guarantees reset on all code paths including cancellation

## Key Patterns

- **TechDictionaryState**: Stack-based drill-down with breadcrumbs, Codable cache persisted to UserDefaults
- **ExplanationLevel**: 5 levels (ELI5, ELI15, Pro, Samples, Resources) with configurable visibility
- **`[[term]]` links**: AI marks related terms, converted to `quill://explain/` URLs via NSRegularExpression with percent-encoding
- **Panel text selection + hotkey**: NSTextView hierarchy traversal for drill-down without brackets
- **Settings multi-screen**: `openWindow(id:)` + clear saved state + reposition to mouse screen + activation policy toggle

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| KeyboardShortcuts | 1.9.4 (exact) | Global hotkey registration |
| KeychainAccess | 4.2.2+ | API key storage |
| SwiftAnthropic | 2.0.0+ | Claude API client |
