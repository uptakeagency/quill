# Product Hunt Draft

## Tagline (max 60 characters)

Learn what AI writes for you. System-wide tech dictionary.

## Description (max 250 characters)

Select any term in any macOS app, press a shortcut, get an instant AI explanation at your level. ELI5 to Pro, drill-down navigation, TL;DR + resources. Works with Gemini (free) or Claude. Open source, MIT licensed.

## Topics

- Developer Tools
- Open Source
- Artificial Intelligence
- Mac
- Productivity

## Maker Comment Draft

Hey Product Hunt!

I built Quill because I kept running into the same problem: AI tools generate code full of terms I half-understand, and looking them up breaks my flow.

Quill is dead simple — select a term in any app, press Ctrl+Option+Q, and a floating panel appears with an explanation. It doesn't steal focus from your current app, so you stay in context.

What I'm most proud of:

**Explanation levels** — You can switch between ELI5 (simple analogies), ELI15, Pro (trade-offs, patterns), code samples, and a learning path with resources. One click to change depth.

**Drill-down** — Related terms are highlighted. Click one, go deeper. Breadcrumbs let you navigate back. It turns every lookup into a learning path.

**System-wide** — Not a browser extension. Not a chat window. It works in VS Code, Terminal, Safari, Figma, anything. Wherever you can select text.

The app is free and open source (MIT). It uses Google Gemini's free tier by default, so you don't need to pay anything. Claude is also supported if you prefer it.

Built in Swift with Hexagonal Architecture, ~3K lines of code. Contributions welcome.

Download: https://github.com/uptakeagency/quill/releases/latest
Source: https://github.com/uptakeagency/quill

Would love your feedback!

## Gallery Images (5)

### Image 1 — Hero (Demo GIF)
[IMAGE: assets/demo.gif]
**Description:** Animated demo showing the full Quill workflow: select a term, press the hotkey, floating panel appears with explanation.

### Image 2 — ELI5 Level
[IMAGE: assets/ELI5.png]
**Description:** WebSocket explained at ELI5 level — simple analogies, no jargon. Shows the floating panel with level pills, TL;DR, and breadcrumb navigation.

### Image 3 — Pro Level
[IMAGE: assets/Pro.png]
**Description:** Same term at Pro level — trade-offs, patterns, linked terms like "client" and "server." Shows how one click changes the depth.

### Image 4 — Resources & Learning Path
[IMAGE: assets/resources.png]
**Description:** Resources tab showing learning path, official docs, and breadcrumb navigation trail for drill-down exploration.

### Image 5 — Settings
[IMAGE: assets/settings2.png]
**Description:** Settings screen showing AI backend selection (Gemini Flash, Claude API, Claude CLI), API key configuration, and the "Gemini key configured" status.
