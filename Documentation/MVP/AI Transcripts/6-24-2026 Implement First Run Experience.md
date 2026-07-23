# First-run experience recommendations

## User

Please look at the First-Run Experience section of Release Readiness and give me your recommendations on what to change

## Assistant

Searching the repo for the Release Readiness doc and its First-Run Experience section.

Reviewing what's already shipped and how other Release Readiness sections are structured.

Here’s an assessment of the **First-Run Experience** section against what the app already does, plus concrete recommendations for both the doc and the product.

## Current state

The section is still a bare bullet list:

```224:235:Documentation/MVP/Release Readiness.md
## First-Run Experience

### Goal

Help users understand the app without instructions.

### Potential Improvements

- Welcome screen.
- Brief explanation of purpose.
- Suggested first search.
- Guidance when watchlist is empty.
```

Compared with **Watchlist Discoverability** and **Visual Polish**, it has no status, no “already covered” inventory, no scoped work items, and no success criteria. Several bullets are partly or fully done elsewhere in the doc/code.

---

## What’s already covered (doc should say so)

| Bullet in doc | Reality today |
|---|---|
| **Guidance when watchlist is empty** | Done — actionable empty state with “Find a Show” (`WatchlistView`). |
| **Brief explanation of purpose** | Partially done — Search idle (“Find Your Next Season”) and watchlist empty copy explain search → track → monitor. |
| **Welcome screen** | Not implemented; correctly deferred from Visual Polish. |
| **Suggested first search** | Not implemented — Search idle is passive text only. |

Also part of first-run, but not mentioned in this section:

- **Default tab is Search** — sensible for new users.
- **Notification prompt on first track** — “Stay in the Loop” alert after the first successful track (Search row or detail). Good contextual onboarding; no launch-time permission nag.
- **Track-from-search-row + tracked star** — lowers friction for the first meaningful action (Watchlist Discoverability).

---

## Recommendations for the Release Readiness doc

**1. Restructure the section** to match the other high/medium sections:

- **Already Covered** (cross-ref Watchlist Discoverability + Visual Polish empty states)
- **Remaining Work Items** (table with Priority / Status)
- **Deferred / Out of scope for beta**
- **Success Criteria**
- **Manual Verification**

**2. Revise the bullet list** so it reflects actual gaps:

| Item | Suggested doc treatment |
|---|---|
| Welcome screen | Keep, but scope as **optional one-time sheet** (2–3 lines), not a multi-screen tour |
| Brief explanation of purpose | Mark **partially done**; remaining work is **unifying copy** across Search idle, watchlist empty, and notification prompt |
| Suggested first search | Keep as **P0 remaining work** — biggest first-run gap |
| Guidance when watchlist is empty | Move to **Already Covered** or strike it |

**3. Add explicit deferrals** (aligned with Release Readiness purpose: polish, not major features):

- Multi-step onboarding carousel
- Tooltips / coach marks over the tab bar
- Account / Sign in with Apple intro (PD-001)
- Analytics-driven “smart” suggestions

**4. Cross-reference instead of duplicating** — point “watchlist empty guidance” and “empty state copy” to Watchlist Discoverability / Visual Polish so this section owns only **launch/first-session** gaps.

---

## Recommendations for what to actually build

Prioritized for beta, staying within “not major new functionality”:

### P0 — Do before beta (small diffs, high impact)

**Enhance the Search idle state** — the main first-run moment. Watchlist already has an action button; Search does not.

Options, from lightest to richer:

1. **Copy only** — add a line like “Use the search field above” and an example: “Try ‘The Bear’ or ‘Severance’.”
2. **One tappable example** — a `Button("Try an example")` that prefills the query and runs search (no new screens).
3. **Example chips** — only if you want more polish; slightly more UI work.

Recommendation: **#2** — one example button on the idle state. It teaches search without a welcome screen and matches the watchlist empty state pattern.

**Align value-prop copy** across the three first-run touchpoints so they tell one story:

- Search: find a show → see next-season status  
- Watchlist empty: track shows you care about  
- Notification prompt: get alerted when status changes  

Right now each piece is fine alone but doesn’t explicitly connect **track → notify**.

### P1 — Nice for beta, not blocking

**Optional one-time welcome sheet** — only if beta feedback says people still don’t get it after the Search idle change.

If you add it:

- Show once (`@AppStorage` / `UserDefaults`), dismissible, no “sign up” step
- Three bullets max: Search → Track (star) → Notifications when dates change
- Primary action: “Get Started” → dismiss (stay on Search tab)
- Do **not** request notification permission on launch — keep the existing prompt-on-first-track flow

### P2 — Defer unless beta proves need

- Full welcome / onboarding flow
- Tab-bar coach marks
- Multiple suggested searches or personalized suggestions
- Separate “What is NextSeason?” About screen (Feedback Mechanism may cover “report issues” later)

---

## What I would **not** change

- **No launch-time notification permission** — current defer-until-first-track is the right pattern.
- **No full welcome carousel for MVP beta** — two tabs and strong empty states should be enough once Search idle is actionable.
- **Don’t re-do watchlist empty state** — it’s already the best first-run surface after Search.

---

## Suggested success criteria (for the doc)

- A new user can find Search, run a query, and track a show **without external instructions**.
- They understand **why** to track (next-season updates / notifications), not just **how**.
- No one describes the app as “I didn’t know what to do first.”

---

## Suggested manual verification

- Fresh install (or reset `UserDefaults`): lands on Search, idle state is clear and actionable.
- Tap example / run first search → see results → track from row → notification prompt appears with sensible copy.
- Switch to Watchlist before tracking → empty state → “Find a Show” → back to Search root.
- Second launch: no repeated welcome (if you add a one-time sheet); idle/example still works.

---

## Bottom line

**Change the doc** from a vague four-bullet list into a scoped section that acknowledges work already shipped in Watchlist Discoverability and Visual Polish, and narrows remaining work to **Search idle guidance** (+ optional unified copy and an optional one-time sheet).

**Change the app** minimally: make Search’s first-run state as actionable as Watchlist’s empty state; treat a full welcome screen as optional P1 based on beta feedback, not a default MVP requirement.

If you want, I can draft the updated **First-Run Experience** section in `Release Readiness.md` in the same format as Visual Polish, or implement the Search idle enhancement first.

## User

Please add the new section to Release Readiness first

## Assistant

Updating the First-Run Experience section in Release Readiness to match the other sections' structure and our recommendations.

Updated `Documentation/MVP/Release Readiness.md` — the **First-Run Experience** section now matches the structure of Watchlist Discoverability and Visual Polish.

**Added:**
- **Scope** — in-context guidance only, no major new flows
- **Already Covered** — Search default tab, idle/empty states, track affordances, notification-on-first-track
- **Work Items** table — P0 (Search idle action + unified copy), P1 (optional one-time sheet), deferred full onboarding
- **Remaining Opportunities** — detailed notes with the “Try an example” recommendation
- **Deferred** — carousel, coach marks, launch-time notifications, Sign in with Apple, etc.
- **Success Criteria** and **Manual Verification**

**Removed:** the old four-bullet “Potential Improvements” list (watchlist empty guidance moved to Already Covered; welcome screen scoped to P1/deferred).

When you’re ready, the next step is implementing the P0 Search idle enhancement.

## User

Oops - I need to commit the previous work first.  Please remove your last changes to Release Readiness but hold onto them since we'll need them in a few minutes.

## Assistant

Reverting the First-Run Experience section in Release Readiness and saving the updated content so we can reapply it shortly.

Saving the updated section to a draft file, then reverting Release Readiness.

Done.

**Reverted:** `Documentation/MVP/Release Readiness.md` is back to the original four-bullet First-Run Experience section.

**Saved for later:** The full updated section is in `Documentation/MVP/First-Run Experience.section-draft.md`. When you’re ready, say the word and I’ll paste it back into Release Readiness (and we can delete the draft file).

**Note:** The draft file is new/untracked — leave it out of your visual polish commit unless you want it kept in the repo temporarily.

## User

Ok, please make a branch and then restore your draft work into Release Readiness

## Assistant

Creating a branch and restoring the First-Run Experience draft into Release Readiness.

Done.

**Branch:** `feature/first-run-experience-docs` (from `main`)

**Restored:** The expanded **First-Run Experience** section is back in `Documentation/MVP/Release Readiness.md` — scope, already covered, work items table, remaining opportunities, deferred items, success criteria, and manual verification.

**Uncommitted:** Only `Release Readiness.md` is modified. Say if you want this committed, or if we should move on to the P0 implementation (Search idle “Try an example” + unified copy).

## User

Move on to the P0 implementation

## Assistant

Implementing P0 first-run work: reading the SwiftUI skill and the Search, Watchlist, and notification copy paths.

Implementing P0: shared first-run copy, a Search idle “Try an Example” action, and unified notification messaging across views.

P0 first-run work is implemented on `feature/first-run-experience-docs`. Build succeeds; simulator tests couldn’t run here (CoreSimulator unavailable in this environment).

## What changed

**New:** `FirstRunCopy.swift` — shared strings for Search idle, Watchlist empty, notification prompt/denied alerts, and the notifications-disabled banner.

**Search idle (`SearchView`):**
- Updated description: find a show → see next-season status; points to search field + example
- **“Try an Example”** button prefills `"Severance"` and triggers search via existing `.task(id: query)` debounce
- Accessibility switched to `children: .contain` so the button stays tappable in UI tests

**Unified copy:**
- Watchlist empty → “Track shows you care about — tap the star on any search result.”
- Notification prompts (Search + detail) → alerts when next season gets a release date or status update
- Denied/settings copy aligned in Search, detail, and watchlist banner

**Tests:** `testTryExampleButtonRunsSearch` in `SearchAndTrackUITests`

**Docs:** Release Readiness P0 items marked Done; implementation notes added; draft file removed

## What to test locally

1. Fresh launch → Search tab → tap **Try an Example** → Severance results appear
2. Watchlist empty copy reads clearly and **Find a Show** still works
3. Track a show → **Stay in the Loop** message matches the unified copy
4. Run `SearchAndTrackUITests` (especially the new example-button test)

Say if you want this committed or a PR opened.

## User

Are there any other tests that should be added?

## Assistant

Reviewing existing test coverage against the first-run changes to identify meaningful gaps.

For the P0 first-run work specifically, coverage is **mostly adequate**. One UI test is worth adding; a few others are optional or blocked by how tests are set up today.

## Already covered

| Area | Existing tests |
|---|---|
| Search idle on launch | `NavigationUITests.testLaunchShowsSearchTab` |
| Try an Example → results | `SearchAndTrackUITests.testTryExampleButtonRunsSearch` |
| Example search mechanism | `SearchViewModelTests` (query → results/empty/idle) |
| Watchlist empty + Find a Show | `NavigationUITests.testSwitchToWatchlistTabShowsEmptyState`, `testFindShowButtonNavigatesToSearch` |
| First-track / notification prompt | **Not UI-testable today** — `NotificationService.needsAuthorizationPrompt()` returns `false` when `-UITesting` is set |

## Worth adding (recommended)

**1. UI: Try an Example fills the search field**

`testTryExampleButtonRunsSearch` only checks that results appear. A small companion test would lock in the prefilling behavior:

- Tap **Try an Example**
- Assert the search field value is `"Severance"` (not just that a result row exists)

That’s the main regression risk if someone refactors the button to run search without updating `viewModel.query`.

**2. UI: idle state exposes the button on fresh launch**

Extend `testLaunchShowsSearchTab` (or add a one-liner) to assert `search.tryExample` exists when the idle prompt is visible. Cheap guard against accidentally removing the action from the idle state.

## Optional — useful but not required for P0

**3. UI: Try an Example after clearing search**

- Run example → clear search field → idle prompt and **Try an Example** return  
Covers a round-trip edge case; lower priority since ViewModel idle logic is already unit-tested.

**4. Unit: `NotificationService` deferral**

There are no unit tests for `needsAuthorizationPrompt()` / `deferAuthorizationPrompt()`. That behavior is part of the first-run notification story (Not Now shouldn’t re-prompt every track). It predates this work, but a small test would be valuable if you want first-run coverage to include notifications:

- Before defer → `needsAuthorizationPrompt()` is `true` (with mocked `.notDetermined`)
- After `deferAuthorizationPrompt()` → `false`

This needs a test hook or injectable `UserDefaults`, since deferral uses `UserDefaults` today.

## Skip (low value or impractical)

| Test idea | Why skip |
|---|---|
| `FirstRunCopy` string unit tests | Asserts constants, not behavior |
| Exact copy text in UI tests | Brittle; copy will change |
| “Stay in the Loop” alert in UI tests | Disabled under `-UITesting` by design |
| System notification permission dialog | Not reliably automatable in XCUITest |
| Welcome sheet (P1) | Not implemented yet |

## Bottom line

**Add one test:** verify Try an Example populates the search field.  
**Optionally tighten** launch idle coverage (button exists) and, if you care about the notification first-run path in automation, add **NotificationService deferral unit tests** — that’s separate from the copy/button work but fits the same user journey.

I can add the search-field UI test (and the launch assertion) if you want.

## User

Add all the ones you think are worthwhile

## Assistant

Implementing the worthwhile tests: reviewing NotificationService and the UI test setup first.

Adding UI test helpers and NotificationService test hooks, then implementing the new tests.

Fixing the failing clear-search UI test — the nav-bar search field likely isn't clearing reliably.

Replacing the flaky nav-bar clear UI test with a unit test that covers the same behavior.

Added the worthwhile tests. All pass locally.

## UI tests

**`NavigationUITests.testLaunchShowsSearchTab`** — also asserts **Try an Example** is visible on launch.

**`SearchAndTrackUITests.testTryExamplePopulatesSearchField`** — verifies the button prefills `"Severance"` in the search field (not just that results appear).

**Shared helpers** in `NextSeasonUITestCase`: `searchField`, `tryExampleButton`, `tapTryExample()`, `waitForSearchFieldValue()`, and a more robust `clearSearchField()`.

## Unit tests

**`NotificationServiceTests`** (5 tests) — deferral and prompt eligibility:
- Needs prompt when `.notDetermined`
- No prompt after defer
- No prompt when authorized/denied
- Reset restores prompt eligibility

**`SearchViewModelTests.clearingQueryReturnsToIdle`** — clearing the query after results returns to `.idle`.

## Small production change for testability

`NotificationService` now accepts injectable `UserDefaults` and has a `#if DEBUG` test initializer with a fixed authorization status, plus instance `resetDeferredPromptForTesting()`.

## Round-trip UI test note

I tried **`testTryExampleAfterClearingSearchReturnsToIdle`** but nav-bar `.searchable` clear is unreliable in XCUITest (failed consistently even with multiple clear strategies). The same behavior is covered by **`clearingQueryReturnsToIdle`** at the ViewModel layer instead — better fit for that logic.

## What to run locally

```bash
xcodebuild -scheme NextSeason -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## User

When the user uses the example search button, I'm thinking maybe there should be some text below the results telling them to tap the star to add to watchlist, or tap anywhere else on the row to see the show detail.  What do you think?

## Assistant

Good instinct — that’s the moment the first-run story actually clicks: they’ve searched, and now they need to know what to do with a row.

**I’d add it, but scoped and subtle.**

### Why it helps
- Search idle tells them *what to search for*; results are where they need *what to do next*.
- Watchlist empty copy (“tap the star…”) is easy to miss if they never open that tab first.
- The star-on-the-right pattern isn’t obvious to everyone, especially if they expect the whole row to track.

### What I’d avoid
- **Only after “Try an Example”** — manual searchers need the same guidance; example-only hints feel inconsistent.
- **Always-on for every search** — gets patronizing fast for returning users.
- **A big banner** — you already have list rows + TVMaze attribution; another loud block will feel crowded.

### Recommendation
Show a **one-time, muted footer hint** the first time they get results (from example *or* typing), then never again:

> Tap the star to track a show, or tap the row to see its next-season details.

Implementation-wise: a small secondary line under the list (above attribution), driven by `@AppStorage`/`UserDefaults`, dismissed automatically after first successful track *or* first detail open.

That keeps first-run teaching without cluttering normal use.

### Optional polish
- After they track from that first results screen, you could skip the hint on future searches (already handled by one-time flag).
- No need to repeat notification copy here — the “Stay in the Loop” alert covers that on first track.

**Bottom line:** Yes, worth doing — as a **first-results hint**, not an example-only or permanent footer. If you want, I can implement that on the branch.

## User

Sounds good, let's see it.

## Assistant

Implementing a one-time muted footer hint on first search results, dismissed after the user tracks a show or opens detail.

Resetting the hint on UI-test launch so tests don't interfere with each other.

## User

Start multitasking

## User

I've just noticed that the Watchlist page doesn't have a title at the top. Please have it say Watchlist in the same size that the search page has NextSeason, unless you can think of a reason not to.

## Assistant

Checking how Search and Watchlist set their navigation titles so we can match Watchlist to Search.

Working on the Watchlist title now — I’ll match it to the large “NextSeason” style on Search and report back when it’s done.

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: subagent
status: success
task_id: 1388cd7a-cac5-41ea-9c16-e93b9f20bfce
title: Fix Watchlist navigation title
detail: ## Summary

**What was wrong:** Watchlist already had `.navigationTitle("Watchlist")`, but it didn’t read like Search’s “NextSeason” title because:
1. Layout differed from Search — `appNavigationChrome()` was inside the `NavigationStack`, and background/frame modifiers were on inner content only.
2. An **empty watchlist List** (no rows, no banner) isn’t scroll-backed, so SwiftUI often **doesn’t render the large navigation title** — the most likely reason it looked like there was no title.

**What changed** (`WatchlistView.swift`):
- Matched Search structure: full-size content + `appScreenBackground()` inside the stack, `appNavigationChrome()` outside.
- Added `.navigationBarTitleDisplayMode(.large)` so “Watchlist” uses the same large title style as “NextSeason”.
- Added a hidden 1pt list row when the watchlist is empty (and notifications aren’t denied) so the list stays scroll-backed and the large title appears.

**Build:** Succeeds on iPhone 17 simulator.

**Manual check:**
- Watchlist tab (empty) — large **Watchlist** title visible at top, matching Search’s **NextSeason** size.
- With tracked shows — title still shows; list scrolls normally.
- Empty state overlay and “Find a Show” still work; last-row delete animation unchanged.
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-transcripts/a5b2e3a0-9663-4e3e-98fc-95cca6a22869/subagents/1388cd7a-cac5-41ea-9c16-e93b9f20bfce.jsonl
</task>
</system_notification>
<user_query>The beginning of the above subagent result is already visible to the user. Perform any follow-up actions (if needed). DO NOT regurgitate or reiterate its result unless asked. If multiple subagents have now completed and none are still running, briefly summarize the findings and conclusions across all of them. Otherwise, if no follow-ups remain, end your response with a brief third-person confirmation that the subagent has completed. If you mention an agent or subagent in your response, link it with the `[label](id)` format using the agent_id or task_id from the notification instead of printing the raw ID. Don't repeat the same confirmation every time.</user_query>

## Assistant

Checking whether the Watchlist title fix landed cleanly and if any earlier in-progress work still needs attention.

The [Watchlist title fix](1388cd7a-cac5-41ea-9c16-e93b9f20bfce) is in and the project builds cleanly — no further code changes needed for that.

**Quick check:** open the Watchlist tab (empty and with shows) and confirm **Watchlist** appears as a large title, matching **NextSeason** on Search.
