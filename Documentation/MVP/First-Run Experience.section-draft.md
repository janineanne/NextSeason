<!-- Draft: replace ## First-Run Experience through --- before ## Analytics Foundation in Release Readiness.md -->

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
  supporting copy about status and upcoming season.
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
| Search idle: actionable first step (example query or “Try an example” button) | P0 | Not started |
| Unify value-prop copy across Search idle, watchlist empty, notification prompt | P0 | Not started |
| Optional one-time welcome sheet (2–3 bullets, dismissible, `@AppStorage`) | P1 | Not started |
| Full welcome / multi-screen onboarding | — | Deferred |

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
