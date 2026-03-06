# Dynamic OCR Language Detection

**Date:** 2026-03-06
**Status:** Approved

## Problem

`ScreenTextCapture.performOCR` hardcodes OCR recognition languages to `["en", "tr"]`. Users who set a different native language (e.g., German, Japanese) and encounter text in other languages on screen get poor OCR results because Vision can't recognize those languages.

## Key Insight

The user's **native language is what they already know** — when they select text to look up, it's almost certainly in a **foreign** language. OCR should recognize text in ANY language, not just the native one. The AI service layer already handles explaining/translating into the native language.

## Solution

Replace the hardcoded language list with Vision's `automaticallyDetectsLanguage = true` (available since macOS 13, app targets macOS 14+).

### Change

**File:** `Quill/Infrastructure/Accessibility/ScreenTextCapture.swift`
**Method:** `performOCR(on:)`
**Line:** 271

Before:
```swift
request.recognitionLanguages = ["en", "tr"]
```

After:
```swift
request.automaticallyDetectsLanguage = true
```

### Why This Works

1. Vision framework auto-detects the language of on-screen text (20+ languages supported)
2. No configuration needed — zero maintenance
3. The rest of the pipeline is already language-agnostic:
   - `NLLanguageRecognizer` in `QuillApp` detects native language text and auto-switches to Translate mode
   - AI services receive `nativeLanguage` parameter and respond in that language
   - OCR's only job is to accurately read whatever text is on screen

### What NOT to Change

- `AppState.nativeLanguage` / `targetLanguage` — unrelated to OCR
- `AIServiceProtocol` — already language-aware
- Settings UI — no new OCR language picker needed

## Alternatives Considered

| Approach | Verdict |
|----------|---------|
| Map all 19 app languages to BCP-47 codes | Over-engineered, list maintenance burden |
| Add OCR language picker in Settings | Unnecessary complexity, users shouldn't need to configure this |
| Read nativeLanguage from UserDefaults in OCR | Wrong — native language != text language on screen |
