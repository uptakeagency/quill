# Quill - macOS System-Wide AI Writing Assistant

## Build & Run

```bash
# Development build
swift build

# Create .app bundle (debug)
./scripts/build-app.sh debug

# Create .app bundle (release)
./scripts/build-app.sh release

# Run the app
open dist/Quill.app

# Create DMG for distribution
./scripts/create-dmg.sh
```

## Architecture

Hexagonal architecture with clean separation:
- **Domain**: Models + Ports (protocols) - no dependencies
- **Infrastructure**: Claude API, Accessibility, Keychain, Hotkey implementations
- **Presentation**: SwiftUI views (MenuBar, FloatingPanel, Settings, Onboarding)

## Key Decisions

- **Non-sandboxed**: Accessibility API requires it, distribution via DMG not App Store
- **KeyboardShortcuts v1.9.4**: Pinned because v2.x uses `#Preview` which requires Xcode
- **SwiftAnthropic v2.x**: Factory pattern with `betaHeaders: nil`, Content.text has `(String, Citations?)` tuple
- **NSPanel with `.nonActivatingPanel`**: Keeps focus in source app so AX text replacement works

## Testing

No Xcode required for building. Uses SPM (`swift build`).
For Xcode, regenerate project: `xcodegen generate`

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| KeyboardShortcuts | 1.9.4 (exact) | Global hotkey registration |
| KeychainAccess | 4.2.2+ | API key storage |
| SwiftAnthropic | 2.0.0+ | Claude API client |
