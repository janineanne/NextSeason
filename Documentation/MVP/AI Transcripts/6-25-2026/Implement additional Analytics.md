# Analytics recommendations review

## User

ChatGPT added a file called Analytics Recommendations.md to the Documentation folder.  Please read it and tel me what you think.

## User

Yes, please, and update the document to match what you're doing.

## User

Looks good!  Please also implement and document ChatGPT's suggestion for Actor names

## Assistant

Implementing tappable actor names with a friendly placeholder message. I'll review how summaries and actor-name analytics work today.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"actorName|actor_name|analyticsEmphasis|analyticsTapTarget","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_45c2fda0-3190-445b-b33d-af7c11cca2f","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":220}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SummaryFormatterTests.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Actor Name Analytics|analyticsTapTarget|actor name","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","caseInsensitive":false,"multiline":false,"toolCallId":"tool_d4b167ed-00f4-4e55-8a61-e5fe568f81e","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"preview.*summary|summaryHTML","glob":"**/*.swift","caseInsensitive":false,"headLimit":20,"multiline":false,"toolCallId":"tool_c1b18541-d92d-4699-823c-8cae0f4107f","offset":0}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Actor Name Analytics|analyticsTapTarget|actor_name","caseInsensitive":false,"multiline":false,"toolCallId":"tool_fc019b9a-134e-49cb-aed4-31b867751a4","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"About|ShowDetail|summary","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests","caseInsensitive":false,"multiline":false,"toolCallId":"tool_2addb33e-9748-4eb7-9420-0cc7c48b397","offset":0}
```

## Assistant

Replacing the fake analytics tap target with tappable bold actor names in summaries and a user-facing placeholder alert.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Release Readiness.md","offset":395,"limit":15}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Analytics Recommendations.md","offset":205,"limit":25}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift","offset":50}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

## Assistant

Restoring the truncated `SummaryFormatter.swift` — the write accidentally cut off the rest of the file.

### Tool Edit File V2

### Tool Ripgrep Raw Search

```
{"pattern":"attributedStringWithTappableEmphasis|analyticsEmphasisScheme|analyticsTapTarget","caseInsensitive":false,"multiline":false,"toolCallId":"tool_48b915d8-1579-4739-866c-6bafdd2d306","offset":0}
```

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"]}
```

## Assistant

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

### Tool Ripgrep Raw Search

```
{"pattern":"Diagnostics|actorName|AnalyticsCounters|exampleSearch|themeSelected|appLaunched","glob":"**/*Tests*","caseInsensitive":false,"multiline":false,"toolCallId":"tool_62a4c241-18fd-4fc3-912b-fef6e3147ad","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*UITests*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ShowDetail|About|actor","glob":"**/*UITests*","caseInsensitive":false,"multiline":false,"toolCallId":"tool_a4602bde-bb11-443e-be63-83ca3021cc0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SearchViewModelTests.swift","limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Previews/Show+Preview.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"AccessibilityID|UITestAccessibilityID","glob":"**/*.swift","caseInsensitive":false,"headLimit":40,"multiline":false,"toolCallId":"tool_03acb8e3-5367-40e5-9d92-28fb3372761","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"NextSeasonTests/*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/NotificationServiceTests.swift","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Release Readiness.md","offset":377,"limit":50}
```

## Assistant

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
