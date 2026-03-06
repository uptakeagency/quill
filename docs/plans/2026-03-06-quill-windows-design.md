# Quill Windows — Design Document

**Date:** 2026-03-06
**Status:** Approved

## Overview

A Windows port of Quill — system-wide AI tech dictionary. Same concept as the macOS Swift app, rebuilt with Tauri v2 + Rust + React + TypeScript for Windows. Separate repo (`quill-windows`), separate codebase.

## Stack

| Layer | Technology |
|-------|-----------|
| App shell | Tauri v2 |
| Backend | Rust |
| Frontend | React + TypeScript + Tailwind CSS |
| AI clients | Gemini API, Claude API (no CLI) |
| Build | Cargo + Vite |

## Architecture

Hexagonal (Ports & Adapters), same as macOS version:

```
quill-windows/
├── src-tauri/src/
│   ├── main.rs
│   ├── hotkey.rs              # Global hotkey handler
│   ├── accessibility.rs       # Clipboard-based text capture + paste injection
│   ├── ocr.rs                 # Windows.Media.Ocr fallback
│   ├── clipboard.rs           # Clipboard save/restore/monitor
│   ├── panel.rs               # Win32 window style (WS_EX_NOACTIVATE)
│   ├── ai/
│   │   ├── mod.rs
│   │   ├── gemini.rs          # Gemini API client
│   │   ├── claude.rs          # Claude API client
│   │   ├── prompts.rs         # System/user prompts (ported from Swift)
│   │   └── parser.rs          # Multi-layer JSON parser
│   ├── models/
│   │   ├── mod.rs
│   │   ├── analysis.rs        # AnalysisResult, TextChange, Alternative
│   │   ├── mode.rs            # AnalysisMode
│   │   └── explanation.rs     # ExplanationLevel, TechDictionaryState
│   └── keyring.rs             # Windows Credential Manager
├── src/
│   ├── App.tsx
│   ├── components/
│   │   ├── FloatingPanel.tsx
│   │   ├── MarkdownView.tsx   # Markdown + [[term]] drill-down
│   │   ├── ModePicker.tsx
│   │   ├── LevelPicker.tsx
│   │   ├── Breadcrumb.tsx
│   │   ├── SuggestionView.tsx # Diff + explanation + resources + alts
│   │   ├── VocabularyCard.tsx
│   │   ├── Settings.tsx
│   │   └── Tray.tsx
│   ├── hooks/
│   │   ├── useAnalysis.ts
│   │   └── useDrillDown.ts
│   └── lib/
│       └── types.ts
├── package.json
├── tauri.conf.json
└── README.md
```

## Platform API Mappings

| Function | macOS (Swift) | Windows (Rust) | Crate/Plugin |
|----------|--------------|----------------|--------------|
| Text capture | AX API primary → clipboard fallback | Clipboard primary: Ctrl+C simulate → read | `windows` crate + `tauri-plugin-clipboard-manager` |
| Text replacement | AX setValue → clipboard fallback | clipboard write → hide → 50ms delay → Ctrl+V | `windows` crate `keybd_event` |
| OCR fallback | Vision + ScreenCaptureKit | Windows.Media.Ocr + Win32 screenshot | `uni-ocr` or `winocr` |
| Global hotkey | KeyboardShortcuts lib | Tauri built-in | `tauri-plugin-global-shortcut` |
| API key storage | Keychain | Windows Credential Manager | `keyring` |
| System tray | MenuBarExtra | Tauri built-in | Tauri v2 native |
| Floating panel | NSPanel + nonActivatingPanel | Tauri window + Win32 WS_EX_NOACTIVATE + WS_EX_TOOLWINDOW | `windows` crate + raw HWND |
| Focus management | NSPanel automatic | WM_MOUSEACTIVATE → MA_NOACTIVATE | `windows` crate window subclass |
| Panel positioning | NSEvent.mouseLocation + bounds | cursor_position() + physical pixel DPI | Tauri native + monitor API |
| Panel lifecycle | Create each time | Create once hidden, show/hide | Tauri window `visible: false` |
| Clipboard | NSPasteboard | Win32 clipboard API | `tauri-plugin-clipboard-manager` |
| Language detection | NLLanguageRecognizer | `whatlang` crate | `whatlang` |
| Settings storage | UserDefaults | JSON file | `tauri-plugin-store` |
| Cache | UserDefaults | %APPDATA%/quill-windows/cache.json | File-based JSON |

## Data Flow

```
User selects text → Ctrl+Alt+Q (global hotkey)
    ↓
Rust: save current clipboard
    ↓
Simulate Ctrl+C → 50ms delay → read clipboard
    ↓
Clipboard empty? → OCR fallback (screen capture + Windows.Media.Ocr)
    ↓
Detect language (whatlang)
  ├─ Native language → mode: translate
  └─ Foreign language → mode: techExplain
    ↓
IPC event → Frontend "text-captured"
    ↓
Position panel near cursor (physical pixels, DPI-aware)
Show with WS_EX_NOACTIVATE (no focus steal)
    ↓
Check cache → hit: return cached → miss: call AI API
    ↓
Multi-layer JSON parse → IPC event "analysis-result"
    ↓
Frontend renders: Markdown + drill-down + breadcrumb
    ↓
[Apply] → hide panel → 50ms → clipboard write → Ctrl+V → restore clipboard
[ESC]   → hide panel → restore clipboard
```

## IPC Protocol

```
Rust → Frontend (Events):
  "text-captured"     { text, mode, context }
  "analysis-result"   { result: AnalysisResult }
  "analysis-error"    { error: string }
  "analyzing"         { status: bool }

Frontend → Rust (Commands):
  "analyze"           { text, mode, level, tone }
  "apply-text"        { corrected_text }
  "change-mode"       { mode }
  "drill-down"        { term }
  "get-settings"      {}
  "save-settings"     { settings }
  "clear-cache"       {}
```

## Windows Configuration

```json
{
  "windows": [
    {
      "label": "panel",
      "title": "",
      "width": 420,
      "height": 500,
      "decorations": false,
      "transparent": true,
      "alwaysOnTop": true,
      "focusable": false,
      "focus": false,
      "visible": false,
      "skipTaskbar": true
    },
    {
      "label": "settings",
      "title": "Quill Settings",
      "width": 500,
      "height": 450,
      "visible": false
    }
  ]
}
```

## Key Differences from macOS

- No Claude CLI backend (macOS/Linux only)
- Clipboard-based text capture is primary (not AX API)
- Win32 window style manipulation instead of NSPanel
- JSON file cache instead of UserDefaults
- Windows Credential Manager instead of Keychain
- React + Tailwind instead of SwiftUI
- No onboarding window (no Accessibility permission needed)
- Single coordinate system (top-left origin, simpler than macOS)

## What Stays the Same

- All AI prompts (same logic, different language)
- Multi-layer JSON parser strategy
- 6 explanation levels + drill-down + breadcrumb
- 3 modes (improve, translate, techExplain)
- Two-tier text capture (clipboard → OCR fallback)
- Theme system (compact/comfortable/spacious + color schemes)
- Cache strategy (API level + disk cache)
- [[term]] link pattern for drill-down

## Minimum Requirements

- Windows 10 version 1903+ (Windows.Media.Ocr + WebView2)
- WebView2 runtime (bundled or system-installed)
- API key for Gemini or Claude

## Research Sources

- Beetroot clipboard manager (Tauri v2 + React, production Windows app)
- Whispering voice-to-text (Svelte + Tauri, 97% code sharing)
- PastePaw clipboard manager (production Tauri on Windows)
- Raymond Chen: WS_EX_NOACTIVATE + WM_MOUSEACTIVATE handling
- Reddit r/tauri, r/rust, r/dotnet community experiences
- Tauri GitHub issues #7519, #11566, #14102, #14770
