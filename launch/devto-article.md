# Dev.to Article

---
title: I built a system-wide tech dictionary because AI made me feel dumb
published: false
tags: opensource, swift, macos, ai
cover_image: [IMAGE: assets/Pro.png]
---

## The moment that started it all

A few months ago, I asked Claude to help me set up a deployment pipeline. It gave me a perfectly working config with nginx reverse proxy, Docker multi-stage builds, health check endpoints, and graceful shutdown handlers.

It worked on the first try.

And I understood maybe 40% of it.

I could *use* it. I could copy-paste it. I could even modify it slightly. But if someone asked me what a reverse proxy actually does, or why the Docker build had multiple FROM statements, I'd have to fake my way through.

This is the new normal for a lot of us. AI writes code that works, but it uses vocabulary we haven't fully internalized. And the gap between "it works" and "I understand why" keeps growing.

## The flow problem

The obvious answer is "just look it up." But here's what that actually looks like:

1. You're in VS Code, reading AI-generated code
2. You hit a term you don't fully get
3. You open a browser, Google it
4. You get a Stack Overflow answer written for someone with a different context
5. You read three paragraphs, open two more tabs
6. You forgot what you were doing
7. Repeat

Or you ask the AI to explain, which opens a new chat thread, loses context, and turns a 5-second question into a 2-minute conversation.

What I wanted was: select the term, press a key, get an answer, keep going.

## So I built it

[IMAGE: assets/demo.gif]

**Quill** is a macOS menu bar app. It does one thing:

1. Select any term in any app
2. Press `Ctrl+Option+Q`
3. A floating panel appears near your cursor with an explanation
4. The panel doesn't steal focus — your source app stays active

That's the core. But a few features make it actually useful for learning, not just quick lookups.

## Explanation levels

Not everyone needs the same depth. Quill has 5 levels you can switch between with one click:

[IMAGE: assets/ELI5.png]

- **ELI5** — Simple words, analogies. "A WebSocket is like a phone call instead of sending letters."
- **ELI15** — Real terms, clear language. Good for intermediate learners.
- **Pro** — Trade-offs, patterns, when to use what, edge cases.
- **Samples** — 2-3 practical code snippets.
- **Resources** — What to study next, official docs, common pitfalls.

The key insight: you often start at ELI5, then want to go deeper once it clicks. Having all levels one click away makes that natural.

## Drill-down: the rabbit hole feature

This is the part I use the most. The AI marks related terms in the explanation with double brackets, and Quill turns them into clickable links.

[IMAGE: assets/resources.png]

Click "TCP" inside a WebSocket explanation, and you get TCP's explanation. Click "packet" inside that, go deeper. A breadcrumb trail keeps track of where you are:

```
WebSocket > TCP > packet
```

Click any breadcrumb to jump back. It's like a personal Wikipedia for tech concepts, except every article is written at the level you chose.

You can also just select any text in the explanation and press the hotkey again — no brackets needed. See a term you want to explore? Select it, same shortcut, deeper you go.

## The architecture (for the curious)

I went with Hexagonal Architecture (Ports & Adapters) in Swift:

```
Domain/       — Models + Ports (AIServiceProtocol)
Infrastructure/  — AI backends, Accessibility API, Keychain
Presentation/    — FloatingPanel, Settings, MenuBar
```

[IMAGE: assets/settings.png]

A few technical decisions that might be interesting:

**Non-activating NSPanel.** The floating panel uses `NSPanel` with `.nonActivatingPanel`. This is the critical trick — if the window activated (took focus), the source app would lose focus and the Accessibility API couldn't replace text. Most macOS floating window tutorials miss this.

**Accessibility API, no sandbox.** The app reads selected text via `AXUIElement`. This requires the Accessibility entitlement, which means the app can't be sandboxed, which means no App Store. Worth the trade-off for system-wide functionality.

**Protocol-based AI backends.** `AIServiceProtocol` defines the port. Gemini, Claude API, and Claude CLI are adapters. Adding a new backend (Ollama, local LLM, etc.) means implementing one protocol. The domain never knows which backend is active.

**Multi-layer JSON parsing.** AI responses aren't always valid JSON. The parser chain: Codable -> sanitize common issues -> JSONSerialization -> regex extraction -> raw text fallback. A brace-matching depth tracker handles truncated responses better than naive `lastIndex(of: "}")`.

**Prompt via stdin.** The Claude CLI adapter passes the prompt through stdin to avoid it showing up in `ps` output. Small thing, but important for security.

The whole thing is ~3,000 lines of Swift with 3 dependencies. No Xcode project needed — `swift build` works.

## It's free and open source

Quill is MIT licensed. It uses Google Gemini's free tier by default, so you can start using it without paying anything. Claude is also supported if you prefer.

- **Download:** [Quill-1.0.0.dmg](https://github.com/uptakeagency/quill/releases/latest)
- **Source:** [github.com/uptakeagency/quill](https://github.com/uptakeagency/quill)

### Ways to contribute

- **New AI backends** — Ollama, local LLMs, other providers (just implement `AIServiceProtocol`)
- **UI/UX** — floating panel design, markdown rendering, accessibility improvements
- **Localization** — the explanations adapt to your system language, but the UI is English-only
- **Testing** — hexagonal architecture makes unit testing clean, but coverage is still thin

## The bigger point

We're in this weird era where AI makes us more productive but potentially less knowledgeable. The code works, but we don't always understand why.

I don't think the answer is to stop using AI. The answer is to build better bridges between "it works" and "I get it." Quill is my attempt at one small bridge.

If you've ever nodded along to AI-generated code without understanding half the terms in it — give it a try. And if you have ideas for making it better, PRs are open.

---

*Quill is already getting feedback on [Hacker News](https://news.ycombinator.com/item?id=47106795). Would love to hear your thoughts too.*
