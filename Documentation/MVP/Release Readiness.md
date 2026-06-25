# NextSeason - Release Readiness

## Completed Improvements

The following improvements have already been implemented during MVP development and are retained here as a record of release readiness progress.

- Accessibility review completed with VoiceOver, Dynamic Type, and touch target improvements.
- Notification handling refined, including permission flow and behavior from terminated app state.
- Watchlist discovery improvements, including clearer watchlist status and quick add/remove from search results.
- Search behavior reviewed and updated to reflect current TVMaze capabilities and limitations.
- General UX polish and documentation updates completed throughout the MVP review process.

---


## Purpose

This document tracks the work required before NextSeason is shared publicly, linked from a resume, or distributed to beta testers.

The goal is not to add major new functionality. The goal is to ensure the application feels professional, understandable, and reliable.

---

# Release Criteria

Before sharing the application with external users:

- Core functionality is complete.
- No known critical defects exist.
- Basic usability issues have been addressed.
- Application behavior is predictable.
- The app reflects professional software engineering practices.

---

# High Priority

## Search Quality Improvements

### Goal

Users should be able to find the show they are looking for even when search terms are imperfect.

### Potential Improvements

- Ignore punctuation differences.
- Ignore common articles ("The", "A").
- Improve result ranking.
- Handle common abbreviations.
- Handle partial title searches.
- Improve matching of alternate show names.

### TVMaze Coverage Summary

The `/search/shows` endpoint is backed by Elasticsearch with a fuzzy algorithm
(fuzziness 2) and ranks results by relevance (fuzzy closeness + popularity weight
+ exact-match boost), including matches against alternate (AKA) names. Most of the
improvements above are therefore already handled server-side, so the remaining
app-side work is narrow:

- Already handled by TVMaze: punctuation differences, partial title searches,
 alternate (AKA) name matching, and relevance/popularity ranking.
- Mostly covered indirectly (low value): ignoring common articles — partial
 matching already returns e.g. "The Office" for "office".
- Real app-side opportunities: common abbreviation / acronym aliasing (e.g.
 "GoT", "SVU"), which TVMaze does not expand, and app-purpose result ordering
 (de-emphasize ended shows, surface shows with a known/upcoming next season).
 
### Search Fallback UX

TVMaze's public search API returns a maximum of 10 results with no pagination,
even though the website exposes additional pages.

If a user cannot find the desired show, provide a helpful empty/failure state
instead of implying that no matching show exists.

Potential copy:

> Can't find your show?
>
> Try a more specific title instead of a single word — add a subtitle or the
> year (for example, "Title: Subtitle" or "Title 2019").

This is a low-cost usability improvement that addresses the API limitation
without adding significant complexity.

Validate during beta whether search is actually a pain point before investing
further.

Status: Implemented. The no-results state in `SearchView` now shows guidance
("Can't Find Your Show?") encouraging a more specific query instead of the
generic "no results" message.

### Success Criteria

Most users can successfully find and track a show without needing multiple search attempts.

---

## Watchlist Discoverability

### Goal

New users should immediately understand how to track a show.

### Questions

- Is the Track button obvious?
- Is it clear when a show is already tracked?
- Is it obvious how to remove a show?
- Is it obvious what the app does?

### Implemented Improvements

**Watchlist tab**

- Actionable empty state with a prominent "Find a Show" button that switches to the Search tab at root (clears stale search navigation via `showSearchRoot()`).
- Edit button in the toolbar when the watchlist has shows; exposes delete controls (swipe-to-delete still works).
- Empty-state overlay pattern keeps the list mounted when empty to avoid a UICollectionView crash on last delete.
- Edit mode resets when the last show is deleted (no stuck edit mode).

**Search tab**

- Tracked badge — filled yellow star on search rows for already-tracked shows.
- Inline track button — star button on each search row to track/untrack without opening detail.
- Notification prompts when tracking from a search row (same behavior as show detail).

**Show detail**

- Immediate tracked state at navigation time so the Track button shows the correct state on the first frame.
- `refreshTrackedState` on reappear reconciles if the watchlist changed elsewhere.

### Bug Fixes

- Deleting the last watchlist show no longer crashes.
- "Find a Show" no longer lands on a stale detail page from a prior search session.
- Detail Track button no longer shows stale "Tracking" after removal elsewhere.

Status: Implemented. UI and unit tests cover track-from-search-row, Find a Show navigation, edit-delete-last-show exiting edit mode, and `showSearchRoot()` on `AppNavigationCoordinator`.

### Remaining Opportunities

- Improved onboarding copy.
- Welcome screen / first-run guidance (see First-Run Experience).

### Success Criteria

Users can find, track, and remove shows without confusion. Tracked state is visible and consistent across Search, detail, and Watchlist.

---

## Visual Polish

### Goal

The application should feel intentional and complete.

### Scope

Polish only — no new features. Prefer asset-catalog colors, typography, and layout
adjustments over a custom design system or third-party dependencies.

### Work Items

| Item | Priority | Status |
|------|----------|--------|
| App icon (1024×1024) | P0 | Done — review artwork before portfolio release |
| Accent + semantic colors (`AccentColor`, `TrackedStar`, `Warning`) | P0 | Done |
| Lavender-gray surfaces (`AppBackground`, `AppSurface`) | P0 | Done |
| Text hierarchy (`AppMutedText`, `appPrimaryText` / `appSecondaryText`) | P0 | Done |
| Next Season card on show detail (surface + status icon) | P0 | Done |
| Inset list row surfaces (`appListRowSurface`) | P1 | Done |
| Tracked star + stale warning use semantic colors | P1 | Done |
| Notifications-disabled banner card treatment | P1 | Done |
| Search loading skeleton rows | P1 | Done |
| Search keyboard dismiss (retain query text) | P1 | Done |
| Watchlist row removal animation | P1 | Done |
| Consistent spacing scale (`AppSpacing`) | P2 | Done |
| Dark-mode surface + muted-text refinements | P2 | Done |
| Watchlist row subtitle line limit | P2 | Done |
| Empty / no-results states use primary + muted text | P2 | Done |

### Deferred (out of scope for this pass)

- Full welcome / onboarding screen (see First-Run Experience).
- Custom tab bar or navigation chrome.
- Accent-colored navigation titles (large titles remain system primary).
- Motion-heavy transitions or third-party design libraries.
- High-contrast variants for `AppMutedText` (verify during Accessibility Review).

### Implementation Notes

- **Surfaces:** `AppBackground` and `AppSurface` replace stark system white/black on
  screens, lists, cards, and the TVMaze attribution strip. `appScreenBackground()`,
  `appNavigationChrome()`, `appPlainListStyle()`, `appSurfaceCard()`, and
  `appInsetSurfaceCard()` centralize layout chrome in `AppScreenBackground.swift`.
- **Colors:** `AccentColor` (dusky purple light / lavender light dark) drives tint,
  primary text, and prominent buttons. `TrackedStar` and `Warning` replace raw
  `.yellow` / `.orange`. `AppMutedText` is used for secondary metadata lines.
- **Text hierarchy:** `appPrimaryText()` applies accent to titles, show names, status
  lines, and section headers. `appSecondaryText()` applies muted color to genres,
  timestamps, descriptions, attribution, and supporting copy. Tab bar and controls use
  `.tint(Color.accentColor)`.
- **Next Season:** Body-sized headline with a status icon on an inset `AppSurface`
  card (not a large hero). Icon tint uses `NextSeasonStatus.emphasisColor` (accent for
  scheduled/airing, muted for less certain states).
- **Lists:** Search and watchlist rows use inset rounded `AppSurface` cards instead of
  full-width system row backgrounds. Watchlist removal animates via `withAnimation` and
  avoids a full reload on local commits.
- **Search:** Skeleton poster/text placeholders while loading. Live search is
  debounced; returning from detail does not flash skeletons when results are cached.
  Keyboard dismisses on results, scroll, and after search completes while keeping the
  query visible in the navigation search field.
- **Empty states:** Search idle uses `ContentUnavailableView` (“Find Your Next Season”)
  with a “Try an Example” action. No-results state guides toward a more specific query
  (“Can't Find Your Show?”). Watchlist empty state has “Find a Show.” All use primary
  title + muted description; first-run copy lives in `FirstRunCopy.swift`.

### Success Criteria

Users describe the app as "finished" rather than "a prototype."

### Manual Verification

- Light Mode and Dark Mode: surfaces, primary/muted text hierarchy, tracked star,
  warning text, and accent buttons.
- App icon renders correctly on home screen and in Settings.
- Search: keyboard dismisses without clearing query; skeleton does not flash on back
  navigation; no-results copy is helpful.
- Watchlist: last-row delete animates smoothly; empty overlay does not crash.
- Largest Dynamic Type: list rows, Next Season card, and skeleton rows do not clip
  awkwardly (full pass planned under Accessibility Review).

---

# Medium Priority

## First-Run Experience

### Goal

Help users understand the app without external instructions — what it does, what to
do first, and why tracking matters.

### Scope

Lightweight in-context guidance only. Prefer copy and small affordances on existing
screens over new flows, coach marks, or multi-step onboarding. Aligns with Release
Readiness purpose: polish and clarity, not major new functionality.

### Already Covered

Cross-referenced from **Watchlist Discoverability** and **Visual Polish**:

- **Default tab:** Search opens first (`AppNavigationCoordinator.selectedTab`).
- **Search idle state:** `ContentUnavailableView` (“Find Your Next Season”) with
  supporting copy and a “Try an Example” button that prefills “Severance”.
- **Watchlist empty state:** Actionable “Find a Show” button switches to Search at
  root; copy explains track → monitor next season.
- **Track affordances:** Inline star on search rows, tracked badge, detail Track
  button with correct first-frame state.
- **Notification onboarding:** In-app “Stay in the Loop” prompt on first successful
  track (not at launch); deferred/denied paths with Settings link and watchlist
  banner.

### Work Items

| Item | Priority | Status |
|------|----------|--------|
| Search idle: actionable first step (example query or “Try an example” button) | P0 | Done — “Try an Example” prefills “Severance” |
| Unify value-prop copy across Search idle, watchlist empty, notification prompt | P0 | Done — `FirstRunCopy` |
| Optional one-time welcome sheet (2–3 bullets, dismissible, `@AppStorage`) | P1 | Not started |
| Full welcome / multi-screen onboarding | — | Deferred |

### Implementation Notes

- **`FirstRunCopy`:** Centralizes first-run strings for Search idle, Watchlist empty,
  notification prompt/denied alerts, and the notifications-disabled banner.
- **Search idle:** “Try an Example” sets `SearchViewModel.query` to “Severance”;
  existing `.task(id: query)` debounce runs the search.
- **Notification copy:** Unified around release date + status updates (not launch-time
  permission).

### Remaining Opportunities

**Search idle (P0)** — The largest first-run gap. Watchlist empty state already has
a prominent action; Search idle is passive text only. Options, lightest first:

1. Copy only — point to the search field and show an example title
   (“Try ‘The Bear’ or ‘Severance’”).
2. One tappable example — prefills the query and runs search (no new screen).
3. Example chips — only if beta feedback warrants extra polish.

Recommendation: **#2** — teaches search without a launch welcome screen and matches
the watchlist empty-state pattern.

**Unified copy (P0)** — Tell one story across first-run touchpoints:

- Search: find a show → see next-season status
- Watchlist empty: track shows you care about
- Notification prompt: get alerted when status or release date changes

**Optional welcome sheet (P1)** — Add only if beta users still don’t understand the
app after Search idle improvements. If implemented:

- Show once, dismissible, no account step
- Three bullets max: Search → Track (star) → Notifications on updates
- Primary action: “Get Started” → dismiss (remain on Search)
- Do **not** request notification permission at launch

### Deferred (out of scope for beta)

- Multi-step onboarding carousel or tab-bar coach marks
- Multiple suggested searches or personalized recommendations
- Launch-time notification permission (keep prompt-on-first-track)
- Account / Sign in with Apple intro (see `DecisionLog.md` PD-001)
- Dedicated “About NextSeason” screen (may overlap with Feedback Mechanism)

### Success Criteria

- A new user can search, track a show, and understand why tracking matters without
  external help.
- First session does not feel like an unexplained prototype.
- No repeated blocking welcome on every launch (if a one-time sheet is added).

### Manual Verification

- Fresh install (or reset relevant `UserDefaults`): lands on Search; idle guidance is
  clear and actionable.
- Run first search → track from row → “Stay in the Loop” copy makes sense in context.
- Watchlist tab before tracking → empty state → “Find a Show” → Search at root.
- Second launch: no repeated welcome sheet (when implemented); idle guidance still
  works.

---

## Beta Feedback

**Primary Feedback Channel**

- Use TestFlight as the primary mechanism for beta distribution, crash reporting, screenshots, and tester comments.
- Do **not** build an in-app feedback feature for the MVP.

**Structured Feedback**

Create a simple Google Form and provide the link to all beta testers. This provides more consistent and actionable feedback than free-form comments while requiring virtually no engineering effort.

Suggested questions:

- What were you trying to accomplish?
- What happened?
- What did you expect to happen?
- How severe is the issue? (Critical / Major / Minor / Suggestion)
- Device model
- iOS version
- Additional comments

Revisit the need for an in-app feedback screen only if beta testing demonstrates that the TestFlight + Google Form workflow is insufficient.


## Analytics

**Goal:** Collect enough anonymous usage data during beta testing to answer product questions and prioritize post-MVP development, rather than measuring engagement or marketing metrics.

### Implement

- Search performed (query length only, result count, search duration)
- Search result opened
- Added to watchlist from search
- Removed from watchlist from search
- Show detail viewed
- Added to watchlist from detail
- Removed from watchlist from detail
- Watchlist viewed
- Watchlist item opened
- Watchlist item removed
- Notification permission granted or denied
- Notification tapped
- App opened from notification
- Empty watchlist shown
- Empty search results shown
- Non-fatal errors (API failures, decoding errors, notification scheduling failures)
- Actor name tapped (analytics only; no user-visible behavior)

### Design Notes

- Do **not** record search text or other personally identifying information.
- Avoid instrumenting every UI interaction; collect only data that informs product decisions.
- Implement analytics behind a simple `AnalyticsService` abstraction so providers can be changed without affecting the rest of the app.

---

# Beta Testing

## Initial Test Group

Target 5-10 users.

Prefer:

- Non-technical users.
- Frequent television viewers.
- iPhone users of varying experience levels.

---

## Validation Tasks

Ask testers to:

1. Search for a favorite show.
2. Add a show to the watchlist.
3. Remove a show from the watchlist.
4. Understand recent updates.
5. Enable notifications.

Observe without providing instructions.

---

## Success Criteria

Users can complete common tasks without assistance.

Repeated confusion should generate roadmap items.

---

# Technical Validation

## Notifications

Verify:

- Permission request flow.
- Background delivery.
- Notification tap routing.
- Duplicate suppression.
- Cold-launch behavior.

Status: Implemented. Continue validation during beta.

---

## Data Accuracy

Verify:

- Search results are relevant.
- Season information is accurate.
- Change detection behaves as expected.

---

## Accessibility Review

### Status

Accessibility is considered MVP-ready from an implementation standpoint (combined
row labels, hidden decorative images, descriptive track controls). A **full manual
accessibility pass** (Dynamic Type, VoiceOver, Increased Contrast, Xcode audit) is
planned before portfolio release. Visual polish introduced `AppMutedText` and accent
primary text — verify contrast during that pass.

### Dynamic Type

- Verify Search, Watchlist, Show Detail, empty states, notification banner, and undo toast at the largest Accessibility text size.
- Confirm posters do not overlap text.
- Confirm text does not truncate unexpectedly.
- Confirm interactive controls remain reachable.

### VoiceOver

- Verify complete user flow using VoiceOver:
  1. Search for a show
  2. Open show detail
  3. Add/remove a show from the watchlist
  4. Navigate the Watchlist
  5. Enable notifications

- Confirm rows are announced as a single combined element and that decorative images remain hidden.

### Button Labels

- Confirm watchlist controls announce descriptive labels such as:
  - "Track <Show Name>"
  - "Stop tracking <Show Name>"
- Confirm accessibility hints remain present.

### Color & Contrast

Verify in Light Mode, Dark Mode, and Increased Contrast:

- Tracked star remains clearly distinguishable from accent purple text.
- "No longer on TVMaze" warning remains readable.
- `AppMutedText` secondary lines (genres, "Updated" timestamps, descriptions) remain legible against `AppSurface` / `AppBackground`.
- Accent primary text remains readable on lavender-gray surfaces.

### Xcode Accessibility Audit

Run Xcode's Accessibility Audit / Accessibility Inspector and resolve any reported issues.

## Release Decision

Complete the Accessibility Review manual verification steps before distributing the
app to resume reviewers and initial beta testers. Visual polish and core flows are
implemented; no known critical defects block an internal beta once accessibility
sign-off is complete.

---

# Portfolio Readiness

Before linking from resume:

- README updated.
- Screenshots available.
- Architecture documented.
- AI-assisted development process documented.
- No known critical issues.
- Remove the beta analytics tap target from show summaries (`SummaryFormatter.analyticsTapTargetMarkdown` — the bold “Tap here for Actor Name Analytics” line injected into About text).
- Remove or re-wrap the beta theme switcher in `#if DEBUG` before portfolio release. The palette button and picker live in `ThemeSwitcherView.swift` and the overlay in `NextSeasonApp.swift` (`ThemeSwitcherButton`); search the project for `ThemeSwitcher` to find all call sites. Pick a default palette in `AppThemeController` when removing the switcher.

The application should demonstrate product thinking, engineering judgment, and effective AI collaboration.


---
