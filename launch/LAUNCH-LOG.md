# Quill Launch Log

Launch started: 2026-02-22

## Phase 1: Assets & README (Completed)

- [x] Demo GIF recorded and added to `assets/demo.gif`
- [x] Screenshots captured (ELI5, Pro, Settings, Resources, etc.)
- [x] README updated with hero GIF, inline screenshots, feature sections
- [x] GitHub release page updated

## Phase 2: Platform Launches

### Hacker News
- **Status**: LIVE
- **URL**: https://news.ycombinator.com/item?id=47106795
- **Format**: Show HN
- **Result**: Posted, low traction (1 upvote, 0 comments at time of launch)
- **Notes**: May repost after README improvements if HN rules allow

### Reddit r/macapps
- **Status**: REMOVED BY MODERATORS
- **Content file**: `launch/reddit-macapps.md`
- **Format**: Text post with demo GIF
- **Result**: Post removed — likely self-promotion rules violation
- **Lesson**: r/macapps has strict self-promotion limits, need established account history

### Reddit r/programming
- **Status**: REMOVED BY MODERATORS
- **Content file**: `launch/reddit-programming.md`
- **Format**: Text post, technical focus (Hexagonal Architecture, Swift, Accessibility API)
- **Result**: Post removed — likely Rule 2 (no self-promotion/project showcase)
- **Lesson**: r/programming is very strict about project posts, prefer blog post links

### Reddit r/learnprogramming
- **Status**: PERMANENT BAN
- **Content file**: `launch/reddit-learnprogramming.md`
- **Format**: Text post, education focus (ELI5 levels, learning path)
- **Result**: Post removed, account permanently banned from subreddit
- **Ban reasons**: Rule 2 (self-promotion), Rule 6 (no showcasing), Rule 13 (AI-generated content)
- **Lesson**: ALWAYS read subreddit rules before posting. This sub has zero tolerance and no appeal process. AI-generated content is explicitly banned in some communities.

### Reddit r/SideProject
- **Status**: POSTED SUCCESSFULLY
- **Format**: Text post
- **Title**: "I built a free tool for the 'AI wrote this code but I don't understand half the terms' problem"
- **Result**: Successfully submitted, no removal
- **Notes**: Project-friendly subreddit, less strict moderation

### Reddit r/coolgithubprojects
- **Status**: POSTED SUCCESSFULLY
- **Post ID**: t3_1rbcwzw
- **Format**: Link post (subreddit only allows link/image posts)
- **URL**: https://github.com/uptakeagency/quill
- **Title**: "Quill — System-wide AI tech dictionary for macOS. Select any term, press a shortcut, get an instant explanation. Swift, Hexagonal Architecture, MIT licensed."
- **Result**: Successfully submitted, no removal
- **Notes**: Good fit for open source project showcase

### Dev.to
- **Status**: PUBLISHED
- **URL**: https://dev.to/cengiz_selcuk/i-built-a-system-wide-tech-dictionary-because-ai-made-me-feel-dumb-e31
- **Content file**: `launch/devto-article.md`
- **Title**: "I built a system-wide tech dictionary because AI made me feel dumb"
- **Tags**: opensource, swift, ai, showdev
- **Notes**:
  - "macos" tag doesn't exist on Dev.to, used "showdev" instead (more visibility)
  - No cover image added (optional)
  - Images from article (`[IMAGE:]` references) were removed — Dev.to requires uploaded images
  - Account created fresh on launch day

### Twitter/X
- **Status**: NOT STARTED
- **Content file**: `launch/twitter-thread.md`
- **Planned format**: 5-6 tweet thread with demo GIF

### Product Hunt
- **Status**: NOT STARTED
- **Content file**: `launch/producthunt-draft.md`
- **Planned**: Later phase, after initial feedback

### Reddit r/opensource
- **Status**: NOT STARTED
- **Content file**: `launch/reddit-opensource.md`
- **Planned**: Second wave

## Summary

| Platform | Status | Result |
|----------|--------|--------|
| Hacker News | Live | Low traction |
| r/macapps | Removed | Moderation (self-promo) |
| r/programming | Removed | Moderation (self-promo) |
| r/learnprogramming | Skipped | Risk too high |
| r/SideProject | Posted | Success |
| r/coolgithubprojects | Posted | Success |
| Dev.to | Published | Success |
| Twitter/X | Pending | Not started |
| Product Hunt | Pending | Not started |
| r/opensource | Pending | Not started |

## Key Learnings

1. **Reddit moderation is strict** — r/macapps and r/programming both removed posts instantly. Project-specific subreddits (r/SideProject, r/coolgithubprojects) are much more welcoming.
2. **Dev.to tag limitations** — Not all tags exist. "macos" is not a registered tag. Always check tag availability before planning.
3. **Link vs Text posts** — Some subreddits (r/coolgithubprojects) only allow link posts. Adapt format to platform.
4. **Account age matters** — Fresh accounts face more scrutiny on Reddit. Building karma before posting helps.
5. **"showdev" on Dev.to** — One of the most effective tags for project showcases, highly recommended.

## Next Steps

- [ ] Twitter/X thread
- [ ] r/opensource post
- [ ] Product Hunt launch (needs gallery images, tagline, maker comment)
- [ ] Monitor posted content for engagement, respond to comments
- [ ] Consider reposting on HN at better timing (Tue-Thu, 9-11am EST)
