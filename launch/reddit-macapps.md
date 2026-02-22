# Reddit r/macapps

## Title

Quill — a system-wide tech dictionary for macOS. Select any term, press a shortcut, get an instant AI explanation. Free, open source.

## Body

Hey r/macapps,

I'm the developer of Quill, a free and open-source macOS app I built to solve a problem I kept running into: AI tools write code with terms I half-understand, and Googling them breaks my flow.

**What it does:**

Select any term in any app (VS Code, Terminal, Safari, anything) and press `Ctrl+Option+Q`. A floating panel appears near your cursor with an instant explanation. No context switching, no new tabs.

[IMAGE: assets/demo.gif]

**What makes it different from just Googling:**

- **System-wide** — works in every app, not just the browser
- **Stays in context** — the floating panel doesn't steal focus from your current app
- **5 explanation levels** — from ELI5 (simple analogies) to Pro (trade-offs, edge cases, patterns)
- **Drill-down** — related terms are highlighted as clickable links. Click one, go deeper. Breadcrumbs let you navigate back. It's like a Wikipedia rabbit hole for tech
- **TL;DR + Resources** — every explanation starts with a one-liner and ends with links to docs/tutorials

**Also included:**

- Grammar/spelling fix mode with inline diff
- Translation mode (auto-detect language)
- Vocabulary cards with CEFR levels

**How it works under the hood:**

The app reads your selection via the macOS Accessibility API and sends it to either Google Gemini (free tier available) or Claude. The explanation appears in a non-activating NSPanel so your source app keeps focus.

**Installation:**

Download the DMG from GitHub, drag to Applications, grant Accessibility permission, add your API key (Gemini free tier works great), done.

- Download: https://github.com/uptakeagency/quill/releases/latest
- GitHub: https://github.com/uptakeagency/quill
- License: MIT

[IMAGE: assets/settings2.png]

Happy to answer any questions. Feedback and feature requests welcome!
