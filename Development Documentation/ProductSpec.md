# NextSeason — Product Specification

Phase 1 deliverable. Last updated: June 13, 2026.

## Purpose

NextSeason is an iOS app that helps TV fans answer one question: **when is the next season coming?**

Users can search for a show and see next-season status on demand. In a later release, logged-in users will save shows and receive notifications when next-season status changes.

Data source: [TVMaze API](https://www.tvmaze.com/api).

---

## Target user

**Primary persona:** A TV fan who has finished the latest aired season of a show and wants to know if and when the next season is coming — without manually checking news sites, social media, or streaming apps.

**Secondary traits** (inform UX, not v0.1 blockers):

- Cord-cutter / multi-platform viewer
- Follows several shows at once (relevant once watchlists and notifications exist)

---

## Problem being solved

**Core pain:** Next-season information is fragmented, inconsistent, and easy to miss.

**What users want:** A single place to answer *"Is there a next season, and when?"*

| Phase | What we solve |
|---|---|
| **v0.1** | On-demand lookup for any show |
| **Future** | Passive monitoring — tell me when something changes for shows I care about |

---

## MVP scope (v0.1 — guest search only)

### In scope

- Search TV shows by name (TVMaze)
- Show detail with **next-season status**, including when available:
  - Next season number (if known)
  - Premiere date (if known)
  - Status label when no date exists (e.g. "In Production", "TBA", "Ended", "No next season known")
- Clear empty and error states (no results, network failure, show ended)
- Works without login or account

### Out of scope for v0.1 (planned next)

- User accounts / Sign in with Apple
- Saved watchlist
- Push notifications
- Background polling

---

## Non-goals

These are intentionally excluded to prevent scope creep:

- **Not a streaming guide** — "where to watch" is not a primary feature
- **Not a full episode tracker** — no watch history or episode-level progress
- **Not a social app** — no comments, ratings, or friend feeds
- **Not multi-platform at launch** — iOS only
- **Not a TVMaze replacement** — we consume their data; we do not replicate their full catalog UX
- **Not real-time** — notifications (when built) are driven by periodic polling, not live webhooks

---

## Future core loop (context only — not v0.1)

After v0.1, the intended product path is:

1. User searches for a show
2. User views show detail
3. User saves show to a watchlist (requires account)
4. App polls TVMaze approximately every 12 hours for saved shows
5. App compares current next-season status to last known status
6. User receives a push notification when status has changed

**Status-change notification** means any meaningful delta in next-season fields, for example:

- No date → premiere date announced
- Premiere date updated
- Status changes (e.g. "In Development" → "In Production")
- Show transitions to "Ended" (no further seasons expected)

Exact field mapping and edge cases are deferred to Phase 2 research (`TVMazeResearch.md`).

---

## Open questions (Phase 2 research)

Do not answer these with implementation detail until TVMaze research is complete:

- What next-season fields does TVMaze actually expose per show?
- How reliable and timely are premiere dates vs. status strings?
- What App Store and `UNUserNotificationCenter` constraints apply to background polling?
- What is the minimum auth mechanism for saved shows (likely Sign in with Apple)?

---

## Success criteria for v0.1

Phase 1 is complete when:

- [ ] A guest can search for a show (e.g. "Severance") and understand next-season status on one screen
- [ ] It is obvious what v0.1 does **not** do
- [ ] The path to saved shows and change-based notifications is clear without prescribing implementation

---

## Related documents

- [ProjectKickoff.md](ProjectKickoff.md) — development workflow and AI philosophy
- [DevelopmentLog.md](DevelopmentLog.md) — session decisions and engineering judgment
- `TVMazeResearch.md` — Phase 2 (not started)
- `Architecture.md` — Phase 3 (not started)
