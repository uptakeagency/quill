# Quill Windows Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Windows version of Quill (system-wide AI tech dictionary) using Tauri v2 + Rust + React + TypeScript as a separate repo.

**Architecture:** Hexagonal (Ports & Adapters). Rust backend handles system integration (clipboard, hotkey, OCR, AI APIs, Win32). React frontend renders the floating panel, settings, and system tray menu. Communication via Tauri IPC (commands + events).

**Tech Stack:** Tauri v2, Rust, React 19, TypeScript, Tailwind CSS, Vite, `windows` crate, `keyring`, `whatlang`, `reqwest`, `serde`

**Design Doc:** `docs/plans/2026-03-06-quill-windows-design.md`

---

## Phase 1: Project Scaffold & Domain Models

### Task 1: Create Tauri project and repo

**Files:**
- Create: `D:\Projects\quill-windows\` (entire project scaffold)

**Step 1: Scaffold Tauri + React + TypeScript project**

```bash
cd /d/Projects
bun create tauri-app quill-windows --template react-ts
cd quill-windows
```

Select: React, TypeScript, bun as package manager.

**Step 2: Install frontend dependencies**

```bash
cd /d/Projects/quill-windows
bun install
bun add tailwindcss @tailwindcss/vite react-markdown
```

**Step 3: Configure Tailwind**

Add Tailwind Vite plugin to `vite.config.ts`:
```ts
import tailwindcss from "@tailwindcss/vite";
// add to plugins array: tailwindcss()
```

Add to `src/index.css`:
```css
@import "tailwindcss";
```

**Step 4: Add Rust dependencies to `src-tauri/Cargo.toml`**

```toml
[dependencies]
tauri = { version = "2", features = ["tray-icon"] }
tauri-plugin-global-shortcut = "2"
tauri-plugin-clipboard-manager = "2"
tauri-plugin-store = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
reqwest = { version = "0.12", features = ["json"] }
tokio = { version = "1", features = ["full"] }
keyring = "3"
whatlang = "0.16"
windows = { version = "0.58", features = [
    "Win32_UI_WindowsAndMessaging",
    "Win32_UI_Input_KeyboardAndMouse",
    "Win32_System_DataExchange",
    "Win32_Foundation",
    "Win32_Graphics_Gdi",
    "Media_Ocr",
    "Graphics_Imaging",
    "Storage_Streams",
] }
log = "0.4"
env_logger = "0.11"
```

**Step 5: Configure Tauri windows in `src-tauri/tauri.conf.json`**

Add to `app.windows`:
```json
[
  {
    "label": "panel",
    "title": "",
    "width": 420,
    "height": 500,
    "decorations": false,
    "transparent": true,
    "alwaysOnTop": true,
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
```

Add capabilities for plugins in `src-tauri/capabilities/default.json`:
```json
{
  "permissions": [
    "core:default",
    "global-shortcut:allow-register",
    "global-shortcut:allow-unregister",
    "clipboard-manager:allow-read-text",
    "clipboard-manager:allow-write-text",
    "store:allow-get",
    "store:allow-set",
    "store:allow-delete",
    "store:allow-keys"
  ]
}
```

**Step 6: Initialize git repo**

```bash
cd /d/Projects/quill-windows
git init
git add -A
git commit -m "Initial Tauri v2 + React + TypeScript scaffold"
```

**Step 7: Verify it builds**

```bash
cd /d/Projects/quill-windows
timeout 120 bun run tauri build 2>&1 | tail -5
```

Expected: Build succeeds (or at least compiles Rust side).

---

### Task 2: Domain models (Rust)

**Files:**
- Create: `src-tauri/src/models/mod.rs`
- Create: `src-tauri/src/models/mode.rs`
- Create: `src-tauri/src/models/analysis.rs`
- Create: `src-tauri/src/models/explanation.rs`

**Step 1: Write tests for AnalysisMode**

Create `src-tauri/src/models/mode.rs`:
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum AnalysisMode {
    Improve,
    Translate,
    TechExplain,
}

impl Default for AnalysisMode {
    fn default() -> Self {
        Self::TechExplain
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_mode_is_tech_explain() {
        assert_eq!(AnalysisMode::default(), AnalysisMode::TechExplain);
    }

    #[test]
    fn serializes_to_camel_case() {
        let json = serde_json::to_string(&AnalysisMode::TechExplain).unwrap();
        assert_eq!(json, "\"techExplain\"");
    }
}
```

**Step 2: Write ExplanationLevel**

Create `src-tauri/src/models/explanation.rs`:
```rust
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ExplanationLevel {
    Eli5,
    Eli15,
    Professional,
    Samples,
    Resources,
    Alternatives,
}

impl ExplanationLevel {
    pub fn title(&self) -> &str {
        match self {
            Self::Eli5 => "ELI5",
            Self::Eli15 => "ELI15",
            Self::Professional => "Pro",
            Self::Samples => "Samples",
            Self::Resources => "Resources",
            Self::Alternatives => "Alts",
        }
    }

    pub fn icon(&self) -> &str {
        match self {
            Self::Eli5 => "🧒",
            Self::Eli15 => "🎓",
            Self::Professional => "💼",
            Self::Samples => "💻",
            Self::Resources => "📚",
            Self::Alternatives => "🔄",
        }
    }
}

impl Default for ExplanationLevel {
    fn default() -> Self {
        Self::Eli15
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TechExplanation {
    pub term: String,
    pub level: ExplanationLevel,
    pub explanation: String,
    pub tldr: Option<String>,
    pub resources: Option<Vec<ResourceLink>>,
    pub alternatives: Option<Vec<Alternative>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceLink {
    pub title: String,
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Alternative {
    pub name: String,
    pub description: String,
    pub pros: Vec<String>,
    pub cons: Vec<String>,
}

/// Stack-based drill-down state
#[derive(Debug, Default)]
pub struct TechDictionaryState {
    pub stack: Vec<TechExplanation>,
    cache: Mutex<HashMap<String, TechExplanation>>,
}

impl TechDictionaryState {
    pub fn push(&mut self, explanation: TechExplanation) {
        let key = format!("{}:{:?}", explanation.term, explanation.level);
        self.cache.lock().unwrap().insert(key, explanation.clone());
        self.stack.push(explanation);
    }

    pub fn pop(&mut self) -> Option<TechExplanation> {
        if self.stack.len() > 1 {
            self.stack.pop()
        } else {
            None
        }
    }

    pub fn replace_top(&mut self, explanation: TechExplanation) {
        let key = format!("{}:{:?}", explanation.term, explanation.level);
        self.cache.lock().unwrap().insert(key, explanation.clone());
        if let Some(top) = self.stack.last_mut() {
            *top = explanation;
        } else {
            self.stack.push(explanation);
        }
    }

    pub fn cached(&self, term: &str, level: ExplanationLevel) -> Option<TechExplanation> {
        let key = format!("{term}:{level:?}");
        self.cache.lock().unwrap().get(&key).cloned()
    }

    pub fn current(&self) -> Option<&TechExplanation> {
        self.stack.last()
    }

    pub fn breadcrumbs(&self) -> Vec<String> {
        self.stack.iter().map(|e| e.term.clone()).collect()
    }

    pub fn reset(&mut self) {
        self.stack.clear();
    }

    pub fn cache_count(&self) -> usize {
        self.cache.lock().unwrap().len()
    }

    pub fn clear_cache(&self) {
        self.cache.lock().unwrap().clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn drill_down_push_pop() {
        let mut state = TechDictionaryState::default();
        state.push(TechExplanation {
            term: "WebSocket".into(),
            level: ExplanationLevel::Eli15,
            explanation: "A protocol...".into(),
            tldr: None, resources: None, alternatives: None,
        });
        state.push(TechExplanation {
            term: "HTTP".into(),
            level: ExplanationLevel::Eli15,
            explanation: "HyperText...".into(),
            tldr: None, resources: None, alternatives: None,
        });
        assert_eq!(state.breadcrumbs(), vec!["WebSocket", "HTTP"]);
        state.pop();
        assert_eq!(state.breadcrumbs(), vec!["WebSocket"]);
    }

    #[test]
    fn cannot_pop_last_item() {
        let mut state = TechDictionaryState::default();
        state.push(TechExplanation {
            term: "Rust".into(),
            level: ExplanationLevel::Eli5,
            explanation: "...".into(),
            tldr: None, resources: None, alternatives: None,
        });
        assert!(state.pop().is_none());
        assert_eq!(state.stack.len(), 1);
    }

    #[test]
    fn cache_hit() {
        let mut state = TechDictionaryState::default();
        state.push(TechExplanation {
            term: "Docker".into(),
            level: ExplanationLevel::Professional,
            explanation: "Containers...".into(),
            tldr: Some("Containers.".into()),
            resources: None, alternatives: None,
        });
        let cached = state.cached("Docker", ExplanationLevel::Professional);
        assert!(cached.is_some());
        assert_eq!(cached.unwrap().tldr, Some("Containers.".into()));
    }

    #[test]
    fn replace_top_for_level_switch() {
        let mut state = TechDictionaryState::default();
        state.push(TechExplanation {
            term: "Rust".into(),
            level: ExplanationLevel::Eli5,
            explanation: "Simple...".into(),
            tldr: None, resources: None, alternatives: None,
        });
        state.replace_top(TechExplanation {
            term: "Rust".into(),
            level: ExplanationLevel::Professional,
            explanation: "Advanced...".into(),
            tldr: None, resources: None, alternatives: None,
        });
        assert_eq!(state.stack.len(), 1);
        assert_eq!(state.current().unwrap().level, ExplanationLevel::Professional);
    }
}
```

**Step 3: Write AnalysisResult**

Create `src-tauri/src/models/analysis.rs`:
```rust
use serde::{Deserialize, Serialize};
use super::explanation::{ResourceLink, Alternative};
use super::mode::AnalysisMode;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AnalysisResult {
    pub mode: AnalysisMode,
    pub original: String,
    pub corrected: String,
    #[serde(default)]
    pub changes: Vec<TextChange>,
    pub explanation: Option<String>,
    pub tldr: Option<String>,
    pub resources: Option<Vec<ResourceLink>>,
    pub alternatives: Option<Vec<Alternative>>,
    #[serde(default)]
    pub vocabulary: Vec<VocabularyCard>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextChange {
    pub original: String,
    pub corrected: String,
    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VocabularyCard {
    pub word: String,
    pub suggestion: String,
    pub level: String,
    pub definition: String,
    pub example: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum ToneStyle {
    Formal,
    Casual,
    Professional,
    Friendly,
}
```

**Step 4: Write mod.rs**

Create `src-tauri/src/models/mod.rs`:
```rust
pub mod mode;
pub mod analysis;
pub mod explanation;

pub use mode::AnalysisMode;
pub use analysis::{AnalysisResult, TextChange, VocabularyCard, ToneStyle};
pub use explanation::{ExplanationLevel, TechExplanation, TechDictionaryState, ResourceLink, Alternative};
```

**Step 5: Run tests**

```bash
cd /d/Projects/quill-windows/src-tauri
cargo test models -- --nocapture
```

Expected: All tests pass.

**Step 6: Commit**

```bash
git add src-tauri/src/models/
git commit -m "Add domain models: AnalysisMode, ExplanationLevel, AnalysisResult, TechDictionaryState"
```

---

## Phase 2: AI Backend (Rust)

### Task 3: AI prompts

**Files:**
- Create: `src-tauri/src/ai/mod.rs`
- Create: `src-tauri/src/ai/prompts.rs`

Port all prompts from macOS `Quill/Infrastructure/Claude/ClaudePrompts.swift`. Reference that file for exact prompt text. The prompts module is pure functions (no I/O), so it's fully testable.

Key functions:
```rust
pub fn system_prompt(mode: AnalysisMode, level: Option<ExplanationLevel>, native_language: &str) -> String
pub fn user_prompt(mode: AnalysisMode, text: &str, tone: Option<ToneStyle>, context: Option<&str>, native_language: &str, target_language: &str) -> String
```

Tests: verify prompt contains expected keywords for each mode/level combination.

**Commit:** `"Add AI prompt templates (ported from macOS Swift)"`

---

### Task 4: Multi-layer JSON response parser

**Files:**
- Create: `src-tauri/src/ai/parser.rs`

Port the parsing strategy from `Quill/Infrastructure/Claude/ClaudeResponseParser.swift`:
1. Direct `serde_json::from_str` (Codable equivalent)
2. JSON sanitization (escape literal \n/\t) → retry
3. `serde_json::Value` lenient parsing (JSONSerialization equivalent)
4. Regex fallback (extract `"explanation"` field)
5. Raw text fallback

Key functions:
```rust
pub fn parse_response(raw: &str, mode: AnalysisMode) -> Result<AnalysisResult, String>
fn extract_json(text: &str) -> Option<&str>
fn find_matching_brace(text: &str, start: usize) -> Option<usize>
fn sanitize_json(text: &str) -> String
```

Tests: test each parsing layer with intentionally malformed JSON inputs.

**Commit:** `"Add multi-layer JSON response parser"`

---

### Task 5: Gemini API client

**Files:**
- Create: `src-tauri/src/ai/gemini.rs`

Port from `Quill/Infrastructure/Gemini/GeminiService.swift`. Use `reqwest` for HTTP.

```rust
pub async fn analyze(api_key: &str, model: &str, text: &str, mode: AnalysisMode,
    tone: Option<ToneStyle>, context: Option<&str>, native_language: &str,
    target_language: &str, level: Option<ExplanationLevel>) -> Result<AnalysisResult, String>
```

POST to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

Tests: test request body construction (mock the HTTP call).

**Commit:** `"Add Gemini API client"`

---

### Task 6: Claude API client

**Files:**
- Create: `src-tauri/src/ai/claude.rs`

Direct HTTP with `reqwest` (no SDK). POST to `https://api.anthropic.com/v1/messages`.

Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `Content-Type: application/json`.

Tests: test request body construction.

**Commit:** `"Add Claude API client"`

---

## Phase 3: System Integration (Rust)

### Task 7: Credential management (keyring)

**Files:**
- Create: `src-tauri/src/keyring_manager.rs`

```rust
const SERVICE: &str = "com.c3nx.quill-windows";

pub fn get_api_key(key_type: &str) -> Option<String>
pub fn save_api_key(key_type: &str, value: &str) -> Result<(), String>
pub fn delete_api_key(key_type: &str) -> Result<(), String>
```

Key types: `"gemini-api-key"`, `"claude-api-key"`.

Register as Tauri commands:
```rust
#[tauri::command]
pub fn get_gemini_key() -> Option<String> { ... }
#[tauri::command]
pub fn save_gemini_key(key: String) -> Result<(), String> { ... }
// etc.
```

**Commit:** `"Add Windows Credential Manager integration via keyring"`

---

### Task 8: Clipboard text capture

**Files:**
- Create: `src-tauri/src/clipboard.rs`

The core text capture flow:
```rust
pub async fn capture_selected_text(app: &AppHandle) -> Result<String, String> {
    // 1. Save current clipboard
    // 2. Simulate Ctrl+C via SendInput
    // 3. Sleep 50ms
    // 4. Read clipboard
    // 5. Restore original clipboard
    // 6. Return captured text (or empty if clipboard unchanged)
}

pub async fn paste_text(app: &AppHandle, text: &str) -> Result<(), String> {
    // 1. Write text to clipboard
    // 2. Sleep 50ms
    // 3. Simulate Ctrl+V via SendInput
}
```

Uses `windows` crate for `SendInput` with `KEYBDINPUT` for Ctrl+C/V simulation.

**Commit:** `"Add clipboard-based text capture and paste injection"`

---

### Task 9: OCR fallback

**Files:**
- Create: `src-tauri/src/ocr.rs`

Triggered when clipboard capture returns empty:
```rust
pub async fn capture_text_near_cursor() -> Result<Option<CapturedText>, String> {
    // 1. Get cursor position (GetCursorPos)
    // 2. Capture 500x250px region around cursor (BitBlt screen capture)
    // 3. Run Windows.Media.Ocr on captured image
    // 4. Find word closest to cursor position
    // 5. Return CapturedText { word, sentence, all_text }
}
```

Use `uni-ocr` or `winocr` crate. Alternatively, direct WinRT via `windows` crate.

**Commit:** `"Add Windows OCR fallback for non-selectable text"`

---

### Task 10: Panel window management (Win32)

**Files:**
- Create: `src-tauri/src/panel.rs`

```rust
pub fn setup_panel_window(app: &AppHandle) -> Result<(), String> {
    let panel = app.get_webview_window("panel").unwrap();
    let hwnd = panel.hwnd().unwrap();

    // Set WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW
    unsafe {
        let ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
        SetWindowLongPtrW(hwnd, GWL_EXSTYLE,
            ex_style | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW);
    }
}

pub fn show_panel_near_cursor(app: &AppHandle) -> Result<(), String> {
    let panel = app.get_webview_window("panel").unwrap();
    // Get cursor pos, calculate position, DPI-aware, clamp to monitor bounds
    // Show with SWP_NOACTIVATE
}

pub fn hide_panel(app: &AppHandle) {
    let panel = app.get_webview_window("panel").unwrap();
    panel.hide().unwrap();
}
```

**Commit:** `"Add Win32 non-activating panel window management"`

---

### Task 11: Global hotkey + main flow

**Files:**
- Modify: `src-tauri/src/main.rs`
- Create: `src-tauri/src/app_state.rs`

Wire everything together:
```rust
fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .setup(|app| {
            setup_panel_window(app.handle());
            register_hotkey(app.handle());
            setup_tray(app.handle());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            analyze, apply_text, get_settings, save_settings,
            get_gemini_key, save_gemini_key, get_claude_key, save_claude_key,
            clear_cache,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Quill");
}
```

Hotkey handler flow:
1. Capture text (clipboard → OCR fallback)
2. Detect language (whatlang)
3. Emit "text-captured" event to frontend
4. Show panel near cursor
5. Call AI API
6. Emit "analysis-result" event

**Commit:** `"Wire up main flow: hotkey → capture → analyze → panel"`

---

## Phase 4: Frontend (React + TypeScript)

### Task 12: TypeScript types and shared hooks

**Files:**
- Create: `src/lib/types.ts`
- Create: `src/hooks/useAnalysis.ts`
- Create: `src/hooks/useDrillDown.ts`

Define TS types matching Rust models. Create hooks for:
- `useAnalysis`: Listen to Tauri events, manage loading/result/error state
- `useDrillDown`: Stack-based navigation, breadcrumbs, cache

**Commit:** `"Add TypeScript types and analysis/drill-down hooks"`

---

### Task 13: FloatingPanel and core components

**Files:**
- Create: `src/components/FloatingPanel.tsx`
- Create: `src/components/ModePicker.tsx`
- Create: `src/components/LevelPicker.tsx`
- Create: `src/components/Breadcrumb.tsx`
- Create: `src/components/MarkdownView.tsx`
- Create: `src/components/SuggestionView.tsx`
- Create: `src/components/VocabularyCard.tsx`

Port the SwiftUI layout to React + Tailwind. Key considerations:
- `MarkdownView`: Use `react-markdown` + custom renderer for `[[term]]` → click handler
- `SuggestionView`: Inline diff (strikethrough removed, bold added)
- `FloatingPanel`: Transparent background, rounded corners, shadow via Tailwind

**Commit:** `"Add floating panel UI components"`

---

### Task 14: Settings window

**Files:**
- Create: `src/components/Settings.tsx`
- Modify: `src/App.tsx` (route panel vs settings based on window label)

Three tabs: General, Shortcuts, Appearance.
Uses `tauri-plugin-store` for persistence.
Uses Tauri commands for keyring access.

**Commit:** `"Add settings window with AI backend, language, and appearance config"`

---

### Task 15: System tray

**Files:**
- Modify: `src-tauri/src/main.rs` (tray setup)

Tray menu items:
- Status (Quill - Ready / Analyzing)
- Mode picker (Improve / Translate / Tech Dictionary)
- Settings (open settings window)
- Quit

**Commit:** `"Add system tray with mode picker and settings access"`

---

## Phase 5: Polish & Release

### Task 16: App icon and metadata

**Files:**
- Create: `src-tauri/icons/` (generate from Quill icon)
- Modify: `src-tauri/tauri.conf.json` (app metadata, bundle ID)

Bundle ID: `com.c3nx.quill-windows`
App name: Quill
Version: 1.0.0

**Commit:** `"Add app icon and Windows metadata"`

---

### Task 17: README and build scripts

**Files:**
- Create: `README.md`

Document: installation, build from source, usage, architecture.

**Commit:** `"Add README with installation and usage docs"`

---

### Task 18: Integration test and first release build

**Step 1: Run full test suite**

```bash
cd /d/Projects/quill-windows/src-tauri
cargo test --all
```

**Step 2: Build release**

```bash
cd /d/Projects/quill-windows
timeout 300 bun run tauri build
```

**Step 3: Test the built app**

Manual test checklist:
- [ ] App starts in system tray
- [ ] Ctrl+Alt+Q captures selected text
- [ ] Panel appears near cursor without stealing focus
- [ ] Tech Dictionary mode: ELI5/ELI15/Pro/Samples/Resources/Alts tabs work
- [ ] Drill-down: [[term]] links work, breadcrumb navigation
- [ ] Improve mode: diff view, Apply button pastes corrected text
- [ ] Translate mode: auto-detects language
- [ ] OCR fallback: hover over image text, press hotkey
- [ ] Settings: API key save/load, language selection, theme switching
- [ ] ESC closes panel
- [ ] Clicking outside panel closes it

**Step 4: Commit and tag**

```bash
git tag v1.0.0
git push origin main --tags
```

---

## Task Dependency Graph

```
Task 1 (scaffold)
  ├── Task 2 (models)
  │     ├── Task 3 (prompts)
  │     │     ├── Task 4 (parser)
  │     │     ├── Task 5 (gemini)
  │     │     └── Task 6 (claude)
  │     └── Task 12 (TS types)
  │           └── Task 13 (panel UI)
  │                 └── Task 14 (settings UI)
  ├── Task 7 (keyring)
  ├── Task 8 (clipboard)
  │     └── Task 9 (OCR)
  ├── Task 10 (panel win32)
  └── Task 15 (tray)
        └── Task 11 (main flow — wires everything)
              └── Task 16-18 (polish & release)
```

**Parallelizable groups:**
- Tasks 3-6 (AI backend) can run in parallel with Tasks 7-10 (system integration)
- Task 12-14 (frontend) can start once Task 2 is done (types are defined)
- Task 11 is the integration point — needs all prior tasks

**Estimated total: 18 tasks**
