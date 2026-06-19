# Nextseason project access

## User

Please create a branch called Phase2-Slice2 and switch to it.

### Tool Run Terminal Command V2

### Tool Unspecified

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason","branchName":"Phase2-Slice2"}
```

## Assistant

You're on **`Phase2-Slice2`**, branched from `main` with a clean working tree.

## User

Please begin work on Slice 2

## Assistant

Starting Slice 2 by reviewing architecture, skills, and the current codebase to plan and implement Save & Notify in reviewable steps.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftdata-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-concurrency-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Architecture.md","offset":280}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","globPattern":"**/*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"FR-0|watchlist|notification|US-00","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","glob":"FunctionalRequirements.md","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4074cd3d-f1d8-42f9-9794-32324fe5277","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/Show.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/DecisionLog.md","offset":80,"limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"change|signature|updates/shows|meaningful","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","caseInsensitive":false,"multiline":false,"toolCallId":"tool_9490ee57-0a8b-4f7d-839f-751a4ae015c","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":190,"limit":90}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ShowDetailView|NextSeasonCalculator|Persistence","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_5aaf9151-0e81-4678-a095-c200150995b","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Architecture.md","offset":200,"limit":85}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeClient.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","limit":200}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/NextSeasonStatus+Display.swift"}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","globPattern":"**/*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"INFOPLIST|UIBackgroundModes|NSUserNotification","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4390ab1f-78e3-4fd0-bb70-17432457074","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SearchViewModelTests.swift","limit":60}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/ShowStatus.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Previews/Show+Preview.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/NextSeasonCalculatorTests.swift","limit":80}
```

## Assistant

Implementing Slice 2 in two steps: persistence and watchlist UI first, then notifications and background refresh.

### Tool Todo Write

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Simplifying `ShowDetailView` initialization — the placeholder approach was too hacky.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","offset":380}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeClient.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Todo Write

### Tool Run Terminal Command V2

## Assistant

Slice 2 (**Save & Notify**) is implemented on `Phase2-Slice2`. Skills used: `swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`, `swift-testing-pro`.

## What was built

### Step A — Watchlist persistence + UI
- **`TrackedShow`** domain model and **`NextSeasonStatus` Codable** encoding for snapshots
- **`WatchlistRepository`** with **`SwiftDataWatchlistRepository`** and **`InMemoryWatchlistRepository`**
- **`TrackedShowEntity`** SwiftData `@Model` with unique TVMaze ID (FR-005)
- **TabView** in `ContentView` — Search + Watchlist tabs
- **`WatchlistView`** — list, swipe-to-delete, pull-to-refresh, “last updated” timestamp
- **Track / Tracking** toolbar button on show detail (enabled after full load)
- Notification permission requested gently on first track (FR-011)

### Step B — Notifications + background refresh
- **`StatusChangeDetector`** — meaningful deltas, debounce (PD-008), dedup signatures
- **`NotificationService`** — local notifications with show-specific copy
- **`WatchlistRefreshService`** — `/updates/shows?since=day` gating, force-refresh on pull, `404` → stale flag
- **`RefreshScheduler`** — `BGAppRefreshTask` (~12h target cadence)
- **`TVMazeService`** extended with `updatedShows(since:)` and `show(id:bypassCache:)`
- Info.plist keys added: notification usage description, background fetch, BG task identifier

### Tests added
- `StatusChangeDetectorTests` — immediate date-backed alerts, debounce, dedup
- `WatchlistRepositoryTests` — add, duplicate prevention, remove

## Architecture alignment
- Local on-device watchlist only — no login (PD-001)
- Repository protocol boundary — SwiftData stays private (PD-007)
- Debounced, date-backed notifications (PD-008)
- HTTP cache bypass on background refresh (PD-010)

## What you should test in Xcode

1. **Build & run tests** — confirm everything compiles and all tests pass.
2. **Track a show** — open Severance (or any show), tap **Track**, switch to Watchlist tab.
3. **Remove** — swipe delete on watchlist row; confirm Track button resets on detail.
4. **Pull to refresh** — watchlist pull should force-refresh tracked shows from TVMaze.
5. **Notifications** — allow permission when prompted; background delivery is best-effort on simulator (real device is better for BG tasks).

Nothing is committed yet. Want me to commit this on `Phase2-Slice2`, or pause here for your review first?

## User

The project won't build... please fix errors

## Assistant

Investigating build failures by running the build and reviewing the code for issues.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests"]}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeService|WatchlistRepository|show\\(id:","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_3a3166f1-99fd-4e08-8925-40e30e9af8f","offset":0}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"error:","path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-tools/711bae56-28d4-4e97-bd96-cd4869666302.txt","caseInsensitive":false,"multiline":false,"toolCallId":"tool_85b942c5-1e1a-4e07-9676-b65f098ead3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-tools/711bae56-28d4-4e97-bd96-cd4869666302.txt","offset":170}
```

## Assistant

Fixing Swift 6 actor-isolation errors: marking Codable conformance and persistence helpers as `nonisolated` to match the domain types.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus+Codable.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift","offset":105}
```

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift","limit":15}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift","limit":20}
```

### Tool Ripgrep Raw Search

```
{"pattern":"^enum NextSeasonCalculator|^nonisolated enum","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_2a9bfa77-0e9c-4bea-bffb-7600624c416","offset":0}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Fixing debounce logic: the second poll should confirm a pending change even when the status no longer differs from the stored snapshot.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift","offset":60}
```

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Build is fixed — the project compiles and all tests pass.

## Fixes applied

### 1. Swift 6 actor isolation (`TrackedShowEntity` ↔ SwiftData)
With default `MainActor` isolation, `NextSeasonStatus` Codable and `ShowStatus.persistenceRawValue` were MainActor-only but called from SwiftData’s nonisolated context.

**Fix:** Marked the Codable extension and helpers as `nonisolated`:
- `nonisolated extension NextSeasonStatus: Codable`
- `nonisolated init(from:)` / `encode(to:)`
- `nonisolated var persistenceRawValue`

### 2. Missing return in `StatusChangeDetector`
The `body` computed property mixed implicit and explicit returns in a `switch`.

**Fix:** Use explicit `return` in every case.

### 3. Test isolation (`StatusChangeDetector`)
Pure logic was MainActor-isolated by default, breaking tests.

**Fix:** `nonisolated enum StatusChangeDetector` (same pattern as `NextSeasonCalculator`).

### 4. Missing import in tests
`WatchlistRepositoryTests` used `Date.now` without `import Foundation`.

### 5. Debounce logic bug (found while verifying tests)
The second poll didn’t notify because the snapshot was already updated on the first poll, so `isMeaningfulChange` returned false.

**Fix:** Confirm a pending change when `pendingChangeSignature` matches the current signature, even if the status didn’t change again.

## Verification
- **Build:** succeeded (iPhone 17 simulator)
- **Tests:** all passed (33 tests)

You should be able to build and run in Xcode now. If anything still fails on your machine, tell me the error and I’ll take a look.

## User

It all looks good, but there's really no way to verify the app's behavior as the incoming data changes.  Are you sure you have enough tests to cover this area?

## Assistant

Reviewing existing tests against the change-detection and refresh behavior, then identifying meaningful gaps.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/StatusChangeDetectorTests.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests","globPattern":"**/*Tests*.swift"}
```

## Assistant

You're right to question this — the refresh pipeline is largely untested. Assessing gaps and adding tests for `WatchlistRefreshService` and expanded change-detection scenarios.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-testing-pro/SKILL.md","limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

## Assistant

Adding integration tests for the refresh pipeline and expanding change-detection coverage. Introducing a small test seam so we can record notifications without hitting `UNUserNotificationCenter`.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Moving `RecordingNotificationService` into the test target so it's always available to tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

You were right to question it. **Before this, coverage for “data changed → app reacted correctly” was thin.**

## What we had (not enough)

| Layer | Tests | Gap |
|-------|-------|-----|
| `NextSeasonCalculator` | 14 tests | Good — core status derivation |
| `StatusChangeDetector` | **3 tests** | Only happy-path debounce, date-backed notify, dedup |
| `WatchlistRefreshService` | **0 tests** | Entire poll → fetch → diff → notify pipeline untested |
| `NotificationService` | **0 tests** | Real `UNUserNotificationCenter` — not unit-testable as-is |
| UI / BG refresh | **0 tests** | No way to simulate TVMaze changing live in the app |

So you could verify search, detail, and save/remove manually, but **not** “TVMaze updated → we noticed → we notified correctly.”

## What I added

**`StatusChangeDetectorTests`** — now 8 tests covering:
- Premiere date appears → immediate notification
- Ambiguous change → debounce across two polls
- Duplicate transition suppressed
- Premiere **date change**
- Transition to **airing** (immediate)
- Transition to **ended** (debounced — matches PD-008)
- **Flapping** edit reverts before confirm → no notification
- Non-meaningful churn → no notification

**`WatchlistRefreshServiceTests`** — 5 integration-style tests with mock TVMaze + in-memory repository + recording notifications:
- Skips unchanged shows when `/updates/shows` has no entry
- Re-fetches and notifies when TVMaze reports a newer epoch
- Force refresh (pull-to-refresh) fetches all tracked shows
- `404` marks show stale, no notification
- Full two-cycle debounce through the refresh service

**Small production seam:** `NotificationDelivering` protocol so the refresh pipeline can be tested without touching UserNotifications.

**All 41 tests pass.**

## What still can’t be verified in unit tests

- Real `BGTaskScheduler` firing on a schedule
- Notification permission UI and tap-to-open routing
- Live TVMaze API behavior over time
- SwiftUI watchlist UI updating after a background refresh

Those need manual/device testing or UI tests. For the **business logic** of reacting to changing data, the gap is now much smaller — the refresh orchestration and change-detection rules are exercised with simulated API responses.

Want me to commit these test additions on `Phase2-Slice2`?

## User

I haven't reviewed the code yet, but the app itself looks good. I just found another data problem which is evading the summary formatter.  The first line of the summary includes the text "**Murdoch Mysteries **is".  I have verified that the data from TVMaze looks like this:  "<b>Murdoch Mysteries </b>is".  I realize we'll never catch all of these but I think it's worth fixing that case, and generalizing that fix to other HTML tags.

## Assistant

Inspecting how the summary formatter handles HTML tags like `<b>`.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/String+HTML.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SummaryFormatterTests.swift"}
```

## Assistant

The issue is trailing space inside `<b>` producing `**Murdoch Mysteries **`, which breaks Markdown parsing and falls back to literal `**`. Fixing by converting inline tags via regex and trimming inner content before wrapping in emphasis markers.

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Checking the test failure — Markdown may still fail when bold is immediately followed by a letter (`**Title**is`).

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Markdown parsing is still fragile when bold runs directly into following text. Switching to direct `AttributedString` construction from parsed HTML segments.

### Tool Edit File V2

## Assistant

Fixing tag processing order: emphasis tags were being stripped before parsing.

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## User

It looks to me like you're going the wrong way.  Can you recognize the fact that in this pattern "<b>Murdoch Mysteries </b>is" the space is in the wrong place, and replace " </b>" with "** "?

## Assistant

Using your simpler approach: move trailing space out of bold tags before Markdown conversion. Checking the formatter's current state.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SummaryFormatterTests.swift"}
```

## Assistant

Reverting to the Markdown-based formatter and applying your fix: move trailing space out of emphasis tags (e.g. ` </b>` → `** `) before converting tags.

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

You're right — the simpler fix was the correct one. I over-engineered it.

The problem in `<b>Murdoch Mysteries </b>is` is that trailing space **inside** the tag. The old code turned that into `**Murdoch Mysteries **is`, which breaks Markdown parsing and shows literal `**`.

**Fix:** Before converting tags, move that space outside the emphasis marker:

- ` </b>` → `** ` (and the same pattern for `</strong>`, `</i>`, `</em>`)

So `<b>Murdoch Mysteries </b>is` becomes `**Murdoch Mysteries** is`, which parses as bold title + plain “is”.

I reverted the segment parser and kept the original Markdown-based formatter, adding:
1. The spaced-closing-tag replacements you described
2. Regex for opening tags with attributes (`<strong class="foo">`, etc.)

All 13 `SummaryFormatterTests` pass, including the Murdoch Mysteries case. Rebuild and check that show’s detail screen to confirm it looks right.

## User

Yes, that's perfect.

## Assistant

Glad that did the trick. The spaced-closing-tag fix is a small, targeted change that handles a common TVMaze pattern without overcomplicating the formatter.

When you're ready, we can commit the Slice 2 work and this formatter fix on `Phase2-Slice2`.

## User

It looks to me like you are applying the summary formatter every time you display the detail page.  Would it make sense to save that data for shows on the watchlist so it only has to be done once?

## Assistant

Checking how summaries flow from storage to the detail screen.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":140,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/TrackedShow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Persistence/TrackedShowEntity.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"summaryHTML|SummaryFormatter","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_7ad28657-abb1-4285-8fcb-4cbd4e2f388","offset":0}
```

## Assistant

You're observing the right thing, but I'd split it into two separate questions.

## What's happening today

1. **Every time** `ShowDetailView` renders the About section, it calls `SummaryFormatter.attributedString(from:)` on whatever HTML is in `displayShow.summaryHTML`.

2. **Watchlist shows don't store the summary at all.** `Show(tracked:)` sets `summaryHTML` to `nil`, so opening from the watchlist always refetches the full show first. Formatting only happens after that load — but it can still run on every re-render while you're on the screen.

So for watchlist rows you're paying for **network + format**, not just format.

## Should you cache the *formatted* summary?

**Probably not on disk.** Storing an `AttributedString` in SwiftData is awkward, and if you change `SummaryFormatter` (like the Murdoch Mysteries fix), cached formatted text stays stale until you invalidate it.

Formatting is also cheap: a few string replacements and a Markdown parse on a short blurb. That's not the bottleneck.

## What *does* make sense

**Persist raw `summaryHTML` on the watchlist** (and refresh it when you poll TVMaze), same as you already do for name, poster, and next-season snapshot.

That gives you:

- No extra network fetch just to show About when opening from the watchlist
- Format-on-display still works, so formatter improvements apply automatically
- One source of truth: TVMaze HTML, not a derived cache

**Optionally**, cache the formatted result **in memory** on `ShowDetailViewModel` after the first conversion (`private var formattedSummary: AttributedString?`), so SwiftUI re-renders don't repeat the work. That's a small win with no schema change.

## Recommendation

| Approach | Worth it? |
|----------|-----------|
| Store formatted `AttributedString` on watchlist | No — fragile, hard to persist |
| Store raw `summaryHTML` on watchlist | Yes — avoids refetch, simple |
| In-memory format cache in view model | Nice-to-have — stops repeat work per visit |
| Format once at save time only | Only if you also store HTML and re-format when it changes |

**Bottom line:** Saving the **HTML** on the watchlist makes sense; saving the **formatted output** usually doesn't. The bigger gap today is that watchlist entries don't keep the summary at all, not that formatting runs more than once.

Want me to add `summaryHTML` (and maybe `tvMazeURL`) to `TrackedShow` and wire it through save/refresh?

## User

Yes

## Assistant

Adding `summaryHTML` and `tvMazeURL` to the watchlist model and wiring them through save, refresh, and navigation.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Persistence/SwiftDataWatchlistRepository.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TrackedShow\\(","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_a62ae4c1-8b74-424d-ba81-82769fea51b","offset":0}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

`summaryHTML` and `tvMazeURL` are now stored on the watchlist and kept up to date on refresh.

## Changes

**`TrackedShow` / `TrackedShowEntity`**
- Added optional `summaryHTML` and `tvMazeURL`
- Populated when a show is tracked (`TrackedShow(from: show)`)
- Persisted in SwiftData alongside the other watchlist fields

**`Show(tracked:)`**
- Uses the stored summary and TVMaze link instead of `nil`, so the About section can render immediately when opening from the watchlist (before the network reload finishes)

**`WatchlistRefreshService`**
- Updates `summaryHTML` and `tvMazeURL` whenever a show is re-fetched during background or pull-to-refresh

**Tests**
- `WatchlistRepositoryTests` now asserts summary and URL are saved on add

## Behavior

| Path | Before | After |
|------|--------|-------|
| Open detail from watchlist | No summary until API load | Cached About text + link show immediately |
| Track a show | Summary not saved | Saved at track time |
| Background refresh | Name/poster/status only | Summary + URL updated too |

`SummaryFormatter` still runs on display (so formatter fixes apply automatically), but the watchlist no longer depends on a fetch just to have the HTML.

**What to test:** Track a show with a summary, open it from the Watchlist tab (About should appear right away), pull to refresh, and confirm existing watchlist entries still load (new fields default to `nil`).

All 44 tests pass. Nothing committed yet — say the word when you want that.

## User

I'm seeing this error in the Xcode console, please fix:

com.nextseason.watchlist-refresh is not advertised in the application's Info.plist

### Tool Ripgrep Raw Search

```
{"pattern":"BGTaskScheduler|watchlist-refresh|INFOPLIST","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_69191c36-1c32-4640-afb6-a66b8cf13f6","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshScheduler.swift"}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","offset":394,"limit":30}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

`INFOPLIST_KEY_*` doesn't generate array keys like `BGTaskSchedulerPermittedIdentifiers`. Adding an explicit `Info.plist` and aligning the task identifier with the bundle ID.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"PBXFileSystemSynchronized|exceptions|Info.plist","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_cd880164-cd32-40e1-8bf6-8d30b09fd3f","offset":0}
```

## Assistant

Moving `Info.plist` out of the synchronized folder to avoid a duplicate copy in the bundle.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","limit":100}
```

### Tool Delete File

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Info.plist","toolCallId":"tool_f659f905-d899-4e37-893e-de20c7737ad"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Fixed. The `INFOPLIST_KEY_*` build settings weren’t actually producing `BGTaskSchedulerPermittedIdentifiers` in the generated plist (it needs to be an **array**, not a string).

## What changed

1. **Added `App-Info.plist`** at the project root with:
   - `BGTaskSchedulerPermittedIdentifiers` → `com.TrialByFyre.NextSeason.watchlist-refresh`
   - `UIBackgroundModes` → `fetch`
   - `NSUserNotificationsUsageDescription`

2. **Pointed the target at it** via `INFOPLIST_FILE = App-Info.plist` (merged with the generated plist).

3. **Updated `RefreshScheduler`** to use the same identifier, prefixed with your bundle ID (Apple’s requirement).

4. **Removed** the ineffective `INFOPLIST_KEY_BGTaskSchedulerPermittedIdentifiers` entries.

The built app’s Info.plist now includes the background task identifier. Clean build and run again — that console error should be gone.

**Note:** If you had the old `com.nextseason.watchlist-refresh` identifier scheduled on a device, delete and reinstall the app so the new identifier takes effect.

## User

I'm seeing some build warnings in StatusChangeDetector;  please fix

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"]}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Removing the redundant `(.announcedUndated, .airing)` case — it's already covered by `(_, .airing)`.

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Fixed. The warning was on line 49: `(.announcedUndated, .airing)` was redundant because `case (_, .airing)` already covers it.

Removed that duplicate case. Behavior is unchanged — `announcedUndated → airing` still counts as a meaningful change via the `(_, .airing)` pattern.

Rebuild in Xcode; the `StatusChangeDetector` warning should be gone.

## User

Looks good.  In WatchlistRow, please remove the system image to the left of the show headline, unless there's a good reason for keeping it.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/ShowRow.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"systemImage|headline","glob":"**/NextSeasonStatus*","caseInsensitive":false,"multiline":false,"toolCallId":"tool_296910f9-8fb0-4f2f-990d-f310620e54f","offset":0}
```

## Assistant

Removing the status `Label` icon — it’s decorative and `ShowRow` already uses plain text for status.

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift"]}
```

## Assistant

The next-season status line used a `Label` with a SF Symbol beside the text. That icon was redundant—the headline already states the status—and it didn’t match `ShowRow`, which uses plain text.

It’s now a simple `Text` for the status line. The stale warning still uses an exclamation icon, since that one carries meaning.

**What to test:** Open the Watchlist tab and confirm each row shows the show name and next-season status without a symbol beside the status text. The poster on the left is unchanged.

## User

Ok, please commit but don't push yet

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Staging all Slice 2 changes and creating a commit with a message focused on the watchlist feature.

### Tool Run Terminal Command V2

## Assistant

Committed on `Phase2-Slice2` as `2560733`:

**Add local watchlist with notifications and background refresh.**

31 files changed (watchlist persistence, TabView UI, track/remove on detail, notification + refresh services, `App-Info.plist`, tests, and the `WatchlistRow` status text tweak). Working tree is clean. Not pushed.
