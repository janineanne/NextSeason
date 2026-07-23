# Nextseason project access

## User

Are there any other tasks we need to do before starting on Phase 4 Slice 2?

## Assistant

Checking project docs and git state for Phase 4 Slice 1 completion and any blockers before Slice 2.

Based on the repo state and docs, **you’re ready to start Slice 2**. There aren’t any blocking pre-tasks left from Slice 1.

## Slice 1 is complete

`main` is clean and up to date with everything merged:

| Milestone | Status |
|-----------|--------|
| Step A — guest search | Merged |
| Step B — show detail + next-season status | Merged |
| Slice 1 loose ends (HTTP caching, `SearchViewModel` tests, doc updates) | Merged (`dfa2828`) |
| ChatGPT review items (date-only logic, extra tests, undated `nextepisode` fix) | Merged (`04d1681`) |

Slice 1’s open questions in `Architecture.md` §12 are resolved (HTML rendering, HTTP caching, persistence strategy). The only remaining §12 items are **Slice 2 decisions**, meant to be made while building Slice 2.

## Optional before you start (not blockers)

1. **Run the full test suite in Xcode locally** — ChatGPT’s Slice 1 review recommended this; I can’t run `xcodebuild` in this environment. Quick sanity check before a big new slice.

2. **Delete merged branches** — `Phase4-StepA`, `Phase4-StepB`, and `Phase-4-Review-Items` can be cleaned up if you’re done with them.

3. **Small doc refresh** — `ProductSpec.md` §9 still says “Phase 4 — Implementation: next. First vertical slice = guest search only.” Stale, but not blocking.

## One scope question to settle at Slice 2 kickoff

There’s a mild docs inconsistency:

- `ProductSpec.md` §4 lists **Sign in with Apple** under “planned for Slice 2.”
- **`DecisionLog.md` PD-001** says **no user accounts in MVP** — local watchlist only.

`Architecture.md` matches PD-001 (SwiftData + `WatchlistRepository`, no auth layer). So Slice 2 is really **Save & Notify** with a **local watchlist**, not login. Worth confirming that at kickoff and optionally updating ProductSpec so it doesn’t mention Sign in with Apple for Slice 2.

## What Slice 2 will decide (during implementation, not beforehand)

These are designed in the docs but intentionally not built yet:

- Watchlist persistence (`WatchlistRepository` + SwiftData)
- Save/remove from show detail
- Local notifications + permission flow
- Background polling (~12h) and change detection
- Debounced notifications (PD-008)
- Notification copy and exact “meaningful change” triggers
- Honest UI (“last updated” + TVMaze attribution)
- Offline/stale cache fallback (deferred from PD-010)

**Bottom line:** No required pre-work before Slice 2. Run tests locally if you want extra confidence, then we can kick off with a plan (same pattern as Slice 1: branch, plan, your approval, then code).

Want me to draft the Slice 2 implementation plan next?

## User

I have run the tests and they pass.  Please execute steps 2 and 3 in your list of optional tasks.

## Assistant

Deleting merged Phase 4 branches and updating `ProductSpec.md` §9 to reflect Slice 1 completion.

Both optional tasks are done.

## Step 2 — Branch cleanup

Deleted these merged branches locally and on `origin`:

- `Phase4-StepA`
- `Phase4-StepB`
- `Phase-4-Review-Items`

Only `main` remains locally; remote has `origin/main`.

## Step 3 — Doc refresh

Updated `ProductSpec.md` §9 to reflect current status:

- Phase 3 marked **done**
- Phase 4 marked **in progress**
- Slice 1 (Guest Search) marked **done**
- Slice 2 (Save & Notify) noted as **next**

The `ProductSpec.md` change is **uncommitted** on `main`. Say the word if you want me to commit it.

**What to verify:** In GitHub, confirm the three feature branches are gone from the remote branch list. No app code changed, so no rebuild needed for this step.

## User

I asked ChatGPT to confirm my memory that we decided to defer login for now.  This was the reply;  please implement the recommendations:

Yes, I believe DecisionLog.md is the correct source of truth and that we explicitly decided to defer login/account creation beyond the MVP.
The reasoning we discussed at the time was:
The core value proposition doesn't require accounts
Search for shows
Add shows to a watchlist
Notify when a new season is available
All of that can be accomplished with local storage.
Authentication adds a surprising amount of complexity
Sign in with Apple implementation
User account management
Cloud sync
Privacy policy considerations
Account deletion flows
Backend requirements if data isn't purely local
For a portfolio project, simpler is better
The goal is demonstrating good product judgment and AI-assisted development.
Shipping a polished MVP is more valuable than adding infrastructure that isn't required for the core feature.
Cloud sync is the feature that actually justifies accounts
If users want their watchlist on multiple devices, then Sign in with Apple becomes compelling.
That's a natural post-MVP enhancement.
So I would update the docs to something like:
ProductSpec.md
Remove "Sign in with Apple" from Slice 2.
Replace with:
"Future enhancement: Sign in with Apple and cloud-synced watchlists."
DecisionLog.md PD-001
Leave as-is.
Potentially strengthen the wording:
MVP will use a local watchlist stored on-device. User accounts, Sign in with Apple, and cloud synchronization are deferred until there is a demonstrated need for cross-device sync.
If you're treating the planning documents as an engineering project, the Decision Log should win when there is a conflict because it records an explicit architectural/product decision. The Product Spec should be updated to match it.
One additional thought: if you ever do add accounts later, I would not make that Slice 2. I'd put it much later—after you've proven the season-tracking workflow actually works and the app is useful. For this particular app, authentication feels like infrastructure rather than customer value.

## Assistant

Updating the docs to align ProductSpec with PD-001 on deferred login. Searching for all references to update.

Updating `ProductSpec.md` and strengthening PD-001 in `DecisionLog.md`. Fixing `AGENTS.md`, which still describes login as part of the app.

Documentation is aligned with PD-001. Here’s what changed:

## `ProductSpec.md`

**§4 (Slice 1 “not in scope” list)** — Removed “User accounts / Sign in with Apple.” Slice 2 scope is now only watchlist persistence and notifications/background polling.

**§6 (Slice 2)** — Added:
- Slice 2 uses on-device storage only; no accounts (points to PD-001).
- **Future enhancement (post-MVP):** Sign in with Apple and cloud-synced watchlists, when cross-device sync justifies the complexity.

(Your earlier §9 phase-status update from the optional cleanup is still in this file.)

## `DecisionLog.md` — PD-001

Strengthened the decision text per ChatGPT’s suggestion: local on-device watchlist for MVP; accounts, Sign in with Apple, and cloud sync deferred until cross-device sync is needed. Expanded rationale and clarified that accounts are **not** part of Slice 2.

## `AGENTS.md` (related fix)

Updated the app description so it no longer says users “create a login.” It now describes local watchlist + notifications and points to PD-001. This keeps agent guidance consistent with the decision log.

Kickoff transcripts were left unchanged (historical records).

**What to verify:** Skim `ProductSpec.md` §4, §6, and §9 plus PD-001 in `DecisionLog.md` — wording should match your intent.

Changes are uncommitted on `main`. Say the word if you want me to commit them.

## User

Execute the selected diff-tab create-branch-and-commit action.

Creating branch, staging the three doc files, and committing.

Done.

**Branch:** `cursor/defer-login-beyond-mvp` (checked out)

**Commit:** `a05b60a` — *Align docs with PD-001: local watchlist, no login in MVP.*

**Files committed (3):**
- `Documentation/ProductSpec.md`
- `Documentation/DecisionLog.md`
- `AGENTS.md`

Working tree is clean. Not pushed.

## User

main is now up to date.

Good — `main` includes the merge of `cursor/defer-login-beyond-mvp` (`0440311`), and your working tree is clean and synced with `origin/main`.

The login deferral docs are on `main`, so you're clear to start Slice 2 planning whenever you want.
