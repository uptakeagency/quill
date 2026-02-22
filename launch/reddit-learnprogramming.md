# Reddit r/learnprogramming

## Title

I built a free tool for the "AI wrote this code but I don't understand half the terms" problem

## Body

If you're learning to code with AI, you've probably experienced this:

You ask ChatGPT or Copilot to help you build something. It gives you code that uses WebSockets, Docker containers, nginx reverse proxies, JWT tokens, middleware... and you nod along pretending you understand. You paste it in, it works, but you learned nothing.

Googling each term breaks your flow. Asking the AI to explain opens a whole new conversation. You just want a quick, clear answer right where you are.

So I built **Quill** — a free, open source macOS app that works like this:

1. Select any term in any app (your IDE, terminal, browser, anywhere)
2. Press `Ctrl+Option+Q`
3. A floating panel appears with an instant explanation

[IMAGE: assets/ELI5.png]

**The part I think is most useful for learners: explanation levels.**

You can pick from 5 levels:

| Level | What you get |
|-------|-------------|
| **ELI5** | Dead simple. Analogies, no jargon. "A WebSocket is like a phone call instead of sending letters back and forth." |
| **ELI15** | Clear but starts using real terms. Good for when you're getting comfortable. |
| **Pro** | Trade-offs, patterns, edge cases. For when you actually want depth. |
| **Samples** | 2-3 practical code examples you can use. |
| **Resources** | A learning path — what to study next, official docs, common pitfalls. |

You can switch between these with one click. So when ELI5 makes sense and you want more depth, just tap Pro.

**The other thing that helps: drill-down.**

The explanation highlights related terms. Click one, and you get its explanation. There's a breadcrumb trail so you can navigate back. It's like falling down a Wikipedia rabbit hole, but for programming concepts.

```
You look up "WebSocket"
  → explanation mentions "HTTP" and "TCP"
    → you click "TCP"
      → that mentions "packet" and "handshake"
        → breadcrumb: WebSocket > TCP (click to go back)
```

**It's free and open source (MIT license).** You need a Google Gemini API key (the free tier is enough) or a Claude API key.

- Download: https://github.com/uptakeagency/quill/releases/latest
- GitHub: https://github.com/uptakeagency/quill

macOS only for now. It uses the Accessibility API to read your text selection, which is a macOS-specific feature.

If you're a learner dealing with AI-generated code full of terms you don't know, I hope this helps. Happy to answer any questions.
