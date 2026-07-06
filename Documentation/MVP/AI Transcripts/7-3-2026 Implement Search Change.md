# NextSeason project review

## User

Please reread the whole NextSeason project

## Assistant

I've reread the full NextSeason project. Here's my current understanding:

## What It Is

**NextSeason TV** is an iOS 18+ SwiftUI app that lets users search TV shows (via [TVMaze](https://www.tvmaze.com)), save them to a local watchlist, and get local notifications when a next season is announced or scheduled. No user accounts or backend — everything is on-device.

## Architecture

Three-layer model split (PD-004):

| Layer | Examples |
|-------|----------|
| **DTO** | `ShowData`, `SeasonData`, `ShowSearchResultData` |
| **Domain** | `Show`, `TrackedShow`, `NextSeasonStatus`, `Season` |
| **Persistence** | `TrackedShowEntity` (SwiftData) |

**Pattern:** MVVM with `@Observable` view models, protocol-based services, and environment injection from a single composition root in `NextSeasonApp.swift`.

## App Flow

```
NextSeasonApp
  └─ AppRootView (scene-phase refresh, undo toast, theme switcher)
       └─ ContentView (TabView)
            ├─ Search → SearchView → ShowDetailView
            └─ Watchlist → WatchlistView → ShowDetailView
```

Navigation is centralized in `AppNavigationCoordinator` — tab selection, navigation paths, watchlist reload tokens, and notification deep links (`pendingShowID`).

## Core Business Logic

- **`NextSeasonCalculator`** — Derives `NextSeasonStatus` from show status + seasons + next episode (no native TVMaze field)
- **`StatusChangeDetector`** — Decides when a change is meaningful enough to notify; requires two consecutive polls for non-date-backed changes (PD-008)
- **`RefreshPolicy`** — 15-minute minimum between foreground refreshes
- **`WatchlistRefreshService`** — Full pipeline: `/updates/shows` → fetch changed shows → detect changes → persist → notify

## Services

| Service | Role |
|---------|------|
| `TVMazeClient` (actor) | HTTP + URLCache, search/show/updates |
| `WatchlistRefreshService` | Background + foreground refresh |
| `RefreshScheduler` | `BGAppRefreshTask` ~12h cadence |
| `NotificationService` | Local notifications + permission flow |
| `AnalyticsService` | Anonymous counters (no PII) |
| `WatchlistUndoRemoval` | 5s undo window for removals |

## Features

- **Search** — Debounced via `.task(id:)`, track/untrack from rows, first-run hints
- **Watchlist** — Pull-to-refresh, empty state, notifications-denied banner
- **Show Detail** — Artwork, HTML summary, next-season status, track button
- **Debug (beta/TestFlight)** — Diagnostics, analytics export, simulated update runner, theme switcher

## Persistence

SwiftData behind `WatchlistRepository` protocol (PD-007). No `@Query` in views — explicit fetches via view models. `InMemoryWatchlistRepository` for tests/previews.

## Tests

- **18 unit test files** (Swift Testing) — calculator, status detection, refresh, repository, view models, analytics, navigation
- **UI tests** — Navigation + search/track flows with `PreviewTVMazeService` stub (no live network)

## Documentation

Rich MVP docs in `Documentation/MVP/` — product spec, architecture, decision log (PD-001 through PD-010), release readiness checklist, and AI development transcripts. P0 backlog items appear complete; release readiness focuses on polish (search quality, portfolio prep, theme switcher removal before App Store).

## Current State

The MVP (Slice 1: Guest Search + Slice 2: Save & Notify) looks **feature-complete**. Recent work (July 2026 transcripts) covers diagnostics improvements, diagram updates, and script cleanup. The app is positioned for beta testing and portfolio use, with post-MVP items (accounts, cloud sync, streaming info) deferred.

I'm up to speed on the codebase. What would you like to work on next?

## User

When the user is sitting on the Search Detail page, looking at show details, and presses the Search button in the toolbar, they are currently left on the detail page. Please change it so that they go back to the Search page, but the search string they entered is preserved.

## Assistant

I'll trace how Search tab navigation and the toolbar Search button work, then wire it so tapping Search pops to the root while keeping the query.

## Assistant

I've updated `SearchView` so activating search from a show detail screen returns you to the results list with your query intact.

## Change

When you're on a show detail screen and tap the **Search** button in the navigation bar (the magnifying glass from `.searchable`), the app now pops back to the search results instead of staying on detail.

The fix uses `@Environment(\.isSearching)` on the same view that owns `.searchable`. When search becomes active while the navigation stack is pushed, it clears `navigationPath`. The query stays in `SearchViewModel` because that state lives in `SearchView`, not on the detail screen.

```72:74:NextSeason/Features/Search/SearchView.swift
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
                .modifier(ReturnToSearchResultsOnActivateModifier(navigationPath: $navigationPath))
                .onSubmit(of: .search) {
```

## What to test

1. Search for a show (e.g. "Severance") and open its detail page.
2. Tap the **Search** button in the navigation bar.
3. Confirm you land on the results list (not detail).
4. Confirm the search field still shows your query and the results are still there.

**Note:** This handles the navigation bar search button. Re-tapping the **Search tab** in the tab bar while already on Search does not pop to root in SwiftUI by default — say if you want that behavior too and we can add it separately.

## User

That works, but there's another case. If I'm on the detail page, tap the watchlist button, then tap the search button, it stays on the detail page.I think that any time the user taps Search they should be taken to the main search page, with the last search string saved if applicable.

## Assistant

The Search tab now always returns to the main search screen while keeping your last query. Three pieces work together:

## Changes

1. **`AppNavigationCoordinator.popSearchToRoot()`** — Clears the search navigation stack without changing tabs. The query stays in `SearchViewModel`.

2. **`ContentView` tab selection binding** — Any user tap on the Search tab (including from Watchlist) calls `popSearchToRoot()` before switching tabs. Programmatic navigation (e.g. notification deep links) still sets `selectedTab` directly, so those can still push detail.

3. **`TabBarReselectHandler`** — SwiftUI doesn't detect re-tapping the already-selected tab, so a small UIKit bridge handles that case: Search tab → detail → Search tab again now pops to root.

The nav-bar search button behavior from the previous fix is unchanged.

## What to test

1. **Detail → Watchlist → Search** — Search for a show, open detail, switch to Watchlist, tap Search. You should see results with your query preserved.
2. **Detail → Search (re-tap)** — Open detail, tap Search tab again without visiting Watchlist. Same result.
3. **Nav-bar search button** — Still pops to results from detail (previous fix).
4. **Notification deep link** — Should still open show detail on the Search tab when appropriate.

Also added a unit test for `popSearchToRoot()` and a UI test for the Watchlist → Search case.

## User

This is unrelated,but can you fix the warning on 122 of DiagnosticsSimulatedUpdateRunner?

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsSimulatedUpdateRunner.swift"}
```

## Assistant

Fixed. `BetaRefreshDiagnostics.lastNotificationDecision` is a non-optional `String` (defaults to `"No notification decision yet."`), so the `??` on line 122 was unnecessary and triggered the warning. It now matches line 73 and uses the property directly.

## User

Tests testSearchOpensShowDetail and testSearchResultsHintDismissesAfterOpeningDetail are failing after these changes.  Please fix those and run all the tests to check for other failures.

## Assistant

Investigating the failing UI tests and running the full test suite to find what broke.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/SearchAndTrackUITests.swift","limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NavigationUITests.swift"}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":70,"limit":60}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Investigating: detail navigation likely triggers `isSearching`, which immediately pops the stack. Fixing that and switching tab reselection to `didSelect`.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":315}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/TabBarReselectHandler.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Isolating the failure: running the failing tests with targeted fixes.

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

The custom tab binding is firing during detail navigation. Switching to `onChange` so we only pop when switching from another tab.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"navigationTitle|navigationBar","glob":"**/ShowDetailView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_04475df1-4462-4de8-aba7-e192b60feb2","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"navigationTitle","glob":"**/SearchView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_14bd2104-ab71-4ccd-aebf-33e586e6e0f","offset":0}
```

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Implementing the fix: the custom `tabSelection` binding was calling `popSearchToRoot()` during NavigationLink navigation. Applying the correct approach.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/TabBarReselectHandler.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","limit":80}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":250}
```

### Tool Ripgrep Raw Search

```
{"pattern":"trackShowFromDetail|func search\\(","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests","caseInsensitive":false,"multiline":false,"toolCallId":"tool_25a1b7e1-db4b-475e-8043-7eb9be455c3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/SearchAndTrackUITests.swift","offset":340}
```

### Tool Run Terminal Command V2

## Assistant

Detail opens fine — the tests fail because they assert `navigationBars["Severance"]`, but `ShowDetailView` never sets a navigation title. Fixing navigation properly and updating the tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Await

```
{"taskId":"856884","blockUntilMs":600000,"regex":"TEST (SUCCEEDED|FAILED)"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"failed|Failing tests|TEST FAILED|TEST SUCCEEDED","path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/856884.txt","caseInsensitive":false,"multiline":false,"toolCallId":"tool_3d67b833-e678-4c47-91d2-12b9a58de14","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/856884.txt","offset":85}
```

### Tool Ripgrep Raw Search

```
{"pattern":"failed|Failing tests","path":"/tmp/nextseason-full-test.log","caseInsensitive":false,"multiline":false,"toolCallId":"tool_78d13454-8043-4ed4-8cb6-3931326930d","offset":0}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"TEST SUCCEEDED|TEST FAILED|Failing tests","path":"/tmp/nextseason-full-test2.log","caseInsensitive":false,"multiline":false,"toolCallId":"tool_723e4a46-33bf-4914-8464-df8e973c4b8","offset":0}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/SearchAndTrackUITests.swift"]}
```

## Assistant

Two separate issues were causing the failures:

## Root causes

1. **Custom `tabSelection` binding** — Calling `popSearchToRoot()` in the TabView setter also ran during normal NavigationLink pushes, so detail never stayed on screen.

2. **Brittle UI test assertions** — `testSearchOpensShowDetail` checked `navigationBars["Severance"]`, but `ShowDetailView` never set a navigation title. Detail was opening (as `testTrackShowAppearsOnWatchlist` confirmed), but that assertion failed.

## Fixes

**Navigation (`ContentView`)**
- Use `$coordinator.selectedTab` directly again
- Pop to search root only when switching **from another tab** (`oldTab != .search`)
- Re-tap Search tab handled via `TabBarReselectHandler` using `didSelect` (not `shouldSelect`)

**Search toolbar (`SearchView`)**
- Restored `ReturnToSearchResultsOnActivateModifier` with a guard for false→true `isSearching` only, plus a short settling window after navigation pushes

**Show detail (`ShowDetailView`)**
- Added `.navigationTitle(viewModel.displayShow.name)` for proper inline title

**UI tests (`SearchAndTrackUITests`)**
- Use `waitForShowDetail()` instead of checking the navigation bar title

## Test results

Full suite run: **TEST SUCCEEDED** (all unit + UI tests passing).

Worth a quick manual check:
1. Search → open detail → still works
2. Detail → Watchlist → Search → returns to results with query
3. Detail → tap Search tab again → returns to results
4. Detail → tap nav-bar search button → returns to results
