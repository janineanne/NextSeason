# Analytics recommendations review

## User

ChatGPT added a file called Analytics Recommendations.md to the Documentation folder.  Please read it and tel me what you think.

## User

Yes, please, and update the document to match what you're doing.

## User

Looks good!  Please also implement and document ChatGPT's suggestion for Actor names

## Assistant

Implementing tappable actor names with a friendly placeholder message. I'll review how summaries and actor-name analytics work today.

Replacing the fake analytics tap target with tappable bold actor names in summaries and a user-facing placeholder alert.

Restoring the truncated `SummaryFormatter.swift` — the write accidentally cut off the rest of the file.

Implemented ChatGPT’s actor-name suggestion: real tappable names in summaries, a user-facing placeholder, and updated docs.

## What changed

**Removed the beta hack**
- Deleted the injected **“Tap here for Actor Name Analytics”** line from summaries

**Tappable actor names**
- TVMaze `<b>` / `<strong>` segments in the About section are now tappable links (`SummaryFormatter.attributedStringWithTappableActorNames`)
- On tap: shows a **Coming Soon** alert — “Actor details are planned for a future release.”
- Still records `actorNameTapped` and increments the diagnostics counter

**Files touched**
- `SummaryFormatter.swift` — simplified formatter, actor-name links only on bold text
- `ShowDetailView.swift` — alert + analytics on tap
- `FirstRunCopy.swift` — shared message string
- `SummaryFormatterTests.swift` — updated tests
- `Analytics Recommendations.md` and `Release Readiness.md` — documented new behavior; removed the old portfolio cleanup item for the fake tap target

## What to test

1. Open a show with bold names in its summary (e.g. Severance preview, or any show where TVMaze bolds actor names)
2. Tap a **bold name** in About → alert should appear
3. Confirm diagnostics **Actor name taps** increments (long-press version → Diagnostics)
4. Try a show whose summary has no bold text → nothing should be tappable (expected)

**Note:** Whether names are tappable depends on TVMaze markup. When they use `<b>` for actor names, taps work; plain-text summaries won’t have tap targets.

## User

That all looks good. Are any additional unit or ui tests needed?

## Assistant

Reviewing existing test coverage for analytics, diagnostics, and actor-name behavior.

Short answer: **no, nothing else is required** for beta or portfolio readiness. The important logic is already covered; what’s missing is mostly UI wiring and hidden beta entry points, which are reasonable to leave to manual TestFlight testing.

## What’s already covered (unit tests)

| Area | Coverage |
|---|---|
| Counter increment logic | `AnalyticsCountersTests` |
| UserDefaults persistence | `AnalyticsCountersStoreTests` |
| Report formatting | `AnalyticsDiagnosticsReportTests` |
| `AnalyticsService` + recording | `AnalyticsServiceTests` |
| Actor-name links in summaries | `SummaryFormatterTests` |

That matches the project’s pattern: test pure logic and services, not every SwiftUI screen.

## Gaps (optional, not blocking)

**Unit tests you could add, but don’t need to:**

1. **`notificationReminderScheduled` at the service layer** — `NotificationService` doesn’t assert that a successful schedule fires the event. Proving it would mean mocking `UNUserNotificationCenter`, which is a lot of setup for a one-line `track` call.

2. **Call-site wiring** — e.g. “Try an Example” → `exampleSearchUsed`, theme picker → `themeSelected`. These are thin glue; counter mapping for those events is already tested via `AnalyticsCounters.record`.

3. **`ShowDetailView` alert flow** — openURL → alert + analytics. Would need a view test or heavy SwiftUI testing; low payoff for a simple alert.

**UI tests you could skip:**

1. **Diagnostics screen** — long-press on the version label is intentionally hidden. Automating it is brittle and fights the design.

2. **Actor-name tap + alert** — tappable links live inside an `AttributedString`; XCUITest doesn’t handle that cleanly without extra accessibility hooks (and even then it’s fragile).

3. **Theme switcher / example search analytics** — beta-only flows; manual validation in TestFlight is enough.

## Recommendation

- **Ship as-is** for TestFlight and portfolio review.
- **Add tests later only if** you promote a feature out of beta (e.g. real actor details) or see regressions in manual testing.
- **If you want one low-cost addition**, a single unit test that `AnalyticsCounters.record(.notificationReminderScheduled)` increments the counter would mirror what you already do for other events — nice symmetry, but not necessary since that case is already in `countersIncrementFromEvents`.

Your existing UI tests rightly focus on core product flows (search, track, watchlist, navigation). Extending them for analytics/diagnostics wouldn’t buy much relative to manual beta verification.
