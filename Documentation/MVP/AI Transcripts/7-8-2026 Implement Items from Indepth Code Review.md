# iOS engineering review feedback

## User

I have asked ChatGPT to do a "senior iOS engineering review" of the project.  Overall its impression was positive, but it did list a few things that could be improved.  Would you prefer me to give these to you one at a time, or all at once?

## Assistant

Either works — I have a slight preference for **all at once**.

If you paste the full list, I can:

- **Triage** — separate real issues from stylistic nitpicks or things that don’t fit this codebase
- **Group related items** — e.g. concurrency, SwiftData, and navigation feedback often overlap
- **Prioritize** — quick wins vs. larger refactors
- **Propose an order** — so we don’t fix the same area twice

**One at a time** is better if you want to:

- Discuss each suggestion before anything gets changed
- Cherry-pick only the items you agree with
- Treat it more like a review conversation than an implementation pass

A good middle ground: paste everything at once, and say whether you want **review + triage first** or **start implementing** (and if there are any you already disagree with).

## User

Ok, here's the whole list.  There are none I disagree with so you can start implementing when ready.  I will be available to help triage if you find that any of these changes conflict or are confusing.

Should-fix

1. SearchView is doing too much

SearchView.swift is 371 lines and owns search UI, navigation behavior, keyboard workarounds, tracking state, notification prompting, undo removal coordination, and profile-flow hooks.

That is the biggest “AI code smell” I saw: not wrong, but somewhat accreted.

I’d consider extracting:

* notification prompt state/logic
* tracked-show state management
* search keyboard workaround
* profile-flow hooks

A reviewer might not hate this, but they might think: “This View is becoming the coordinator.”

2. Repeated full-repository reads for single-show questions

Examples:

* SearchView.refreshTrackedShowIDs()
* SearchView.handleTrackButton(...)
* ShowDetailViewModel.trackedShow()
* AppNavigationCoordinator.resolvePendingNavigation(...)

Several places do repository.all().first(where:).

For a tiny app, fine. In a code sample, I’d prefer repository methods like:

func trackedShow(showID: Int) async throws -> TrackedShow?
func trackedShowIDs() async throws -> Set<Int>

That would make the intent cleaner and avoid “load everything to answer one question.”

3. Too many default live dependencies in initializers

Examples:

tvMaze: any TVMazeService = TVMazeClient()
analytics: any AnalyticsTracking = AnalyticsService()

his appears in multiple views/view models/services.

It’s convenient, but in a portfolio repo it slightly weakens the dependency-injection story. Since the app root already builds the real services, I’d prefer most production types require explicit dependencies, with defaults only in previews/tests or composition helpers.

4. WatchlistRefreshService is main-actor isolated

It is marked @MainActor, but it performs network refresh orchestration. The actual network client is an actor, so this is not catastrophic, but a senior reviewer might ask why a service doing background refresh coordination is main-actor-bound.

This may be because the repository is also @MainActor due to SwiftData. Still, I’d consider narrowing main-actor work to persistence/UI-facing pieces rather than making the whole refresh service main-actor isolated.

5. App startup/composition is a little dense

NextSeasonApp.init() is doing persistence setup, analytics, MetricKit, notification routing, background refresh configuration, test-mode setup, and service creation.

It works, but it reads as “bootstrap code accumulated here.” I’d consider an AppCompositionRoot or AppServices type so NextSeasonApp becomes easier to scan.

Optional polish

1. Isolate beta/diagnostics/profiling code more aggressively

The diagnostics work is useful, but it adds a lot of code and environment hooks. I’d make sure a reviewer can quickly distinguish:

* core app
* beta diagnostics
* profiling/instruments support
* test scaffolding

This is more repo-presentation than code correctness.

2. Some UIKit escape hatches deserve comments or wrappers

The keyboard workaround using UIApplication.shared.sendAction(...) is understandable, but it’s the kind of thing reviewers notice. The comment helps. A tiny wrapper could make it feel more intentional.

3. View/action Task { ... } usage is common but scattered

There are many button/onChange tasks. Not wrong. But where possible, using .task(id:), view-model methods, or explicit task cancellation can make async lifetime easier to reason about.

4. Naming is mostly good, but a few names feel implementation-driven

Examples like watchlistReloadToken, profileFlowSearchSettledToken, and pendingShowID are clear enough, but they expose mechanism. Not a serious issue.

## Assistant

Implemented the review items. Here's what changed:

### Should-fix

**1. SearchView decomposition** — `SearchView` is now ~280 lines and delegates to:
- `SearchWatchlistTracking` — tracked IDs + row add/remove
- `WatchlistNotificationPromptState` + alert modifier — notification prompts
- `SearchKeyboardDismissal` + `KeyboardEditing` — keyboard dismiss workaround
- `SearchProfileFlowModifier` — Instruments profile-flow hooks

**2. Targeted repository lookups** — Added `trackedShow(showID:)` and `trackedShowIDs()` to `WatchlistRepository` and updated call sites in search, show detail, and navigation.

**3. Explicit dependency injection** — Removed default live service construction from production types (`SearchView`, `SearchViewModel`, `ShowDetailView`, `ShowDetailViewModel`, `WatchlistView`, `WatchlistViewModel`, `WatchlistUndoRemoval`, `WatchlistRefreshService`, `NotificationService`, `ContentView`). Previews and tests pass explicit dependencies via `RecordingAnalyticsService()` / `TVMazeClient()`.

**4. WatchlistRefreshService isolation** — Tried converting to an `actor`, but Swift 6 rejects storing the `@MainActor` SwiftData repository across actor boundaries. Kept `@MainActor` with a comment explaining why; network work still suspends off the main thread while awaiting `TVMazeService`.

**5. App bootstrap** — Extracted `AppCompositionRoot` so `NextSeasonApp.init()` focuses on wiring the scene.

### Optional polish (done)

- Moved `BetaDiagnosticsPresentationModifier` to `Features/Debug/`
- Wrapped the UIKit keyboard call in `KeyboardEditing.dismissEditing()`
- Replaced some `onChange` + `Task` refresh patterns in `SearchView` with `.task(id:)`

### Optional polish (skipped)

- Renaming `watchlistReloadToken` / `profileFlowSearchSettledToken` / `pendingShowID` — low value vs. churn across `ProfileFlowRunner` and tests

Build verified: **TEST BUILD SUCCEEDED**.

### What to test

1. Search → track/untrack shows; confirm row buttons stay in sync after navigating back
2. First track triggers notification prompt flow (Not Now / Enable)
3. Notification deep link opens tracked show on Watchlist vs. untracked on Search
4. Watchlist pull-to-refresh and foreground refresh still work
5. Beta About/Diagnostics sheet still presents in TestFlight builds
6. Run unit tests in Xcode (`Cmd+U`) — the CLI couldn't run them here without a concrete simulator device

If you want to pursue non–MainActor refresh coordination later, the path would be a `Sendable` persistence boundary (e.g. actor-backed repository) rather than storing `WatchlistRepository` directly in a background actor.

## User

I asked ChatGPT to review it again.  It says it looks much better, but still flagged a few things:

The main remaining cleanup I’d ask Cursor for is:
Replace live SwiftUI environment defaults for analytics and notifications with explicit no-op or unconfigured dependencies, and ensure NotificationService is composed once in AppCompositionRoot and reused everywhere. Also review MainActor.assumeIsolated usages and either remove them or document why they are safe.

More details:
Should-fix

1. Environment defaults still create live services

These still exist:
@MainActor static let defaultValue: any AnalyticsTracking = AnalyticsService()
@MainActor static let defaultValue = NotificationService(analytics: AnalyticsService())

For portfolio-quality DI, I’d prefer the same pattern used for WatchlistRepository: an unconfigured/default-failing dependency, or a no-op analytics service.

Otherwise a missing injection silently creates real app services.

2. NotificationService is created twice at app startup

AppCompositionRoot creates one for WatchlistRefreshService, and NextSeasonApp creates another for the environment.

Probably harmless, because the service is mostly stateless and uses shared system/user-default resources. But from a design-review standpoint, I’d rather see one long-lived NotificationService owned by the composition root and passed everywhere.

3. SearchWatchlistTracking.handleTrackButton(...) has a long parameter list

The extraction helped, but this method now takes many dependencies and callbacks. That can read slightly “utility object glued to a View.”

Not terrible, but a reviewer might prefer a small context struct or a more conventional view model/coordinator.

4. MainActor.assumeIsolated is a yellow flag

There are a few uses in RefreshScheduler / composition setup. They may be justified, but assumeIsolated is the kind of thing a senior reviewer notices immediately.

I would either add very explicit comments explaining why each use is safe, or avoid it where possible.

Optional polish

1. Preview dependency mismatch

In ContentView preview, the repository injected into the environment and the repository used by WatchlistUndoRemoval are two different InMemoryWatchlistRepository() instances. Preview-only, but easy to clean.

2. Search helper files are good, but slightly fragmented

The extracted search files are individually reasonable. I would not undo them. But there is now a fine line between “well-factored” and “many tiny search support types.” It is acceptable.

3. The beta/diagnostics surface is still large

Moving BetaDiagnosticsPresentationModifier was good. The repo still has a lot of diagnostics/profile/test-support code relative to app size, so README/repo organization matters.

## Assistant

I'll tackle the should-fix items first: unconfigured environment defaults, a single shared `NotificationService`, slimming `SearchWatchlistTracking`, and reviewing `MainActor.assumeIsolated`.

## Assistant

Implementing unconfigured environment defaults, a single shared `NotificationService`, a tracking context struct, and cleaning up `MainActor.assumeIsolated`.

Implemented the second-round review items. Summary:

### Should-fix

**1. Environment defaults no longer create live services**
- `AnalyticsService+Environment` now uses `UnconfiguredAnalyticsService` (fatalError if used without injection), matching `WatchlistRepository`.
- `NotificationService+Environment` now uses `UnconfiguredNotificationService` via a new `NotificationManaging` protocol.
- Environment type is `any NotificationManaging`; `NotificationService` conforms.

**2. Single `NotificationService` at startup**
- `AppCompositionRoot` owns one `notificationService`, shared by `WatchlistRefreshService` and the SwiftUI environment.
- Removed the duplicate instance from `NextSeasonApp`.

**3. `SearchWatchlistTracking` parameter list**
- Added `SearchWatchlistTrackingContext` to bundle dependencies and callbacks.
- `handleTrackButton(for:anchor:context:)` takes one context instead of eight parameters.
- `SearchView` exposes a computed `watchlistTrackingContext`.

**4. `MainActor.assumeIsolated` removed**
- `AppCompositionRoot.configureBackgroundRefresh()` calls `RefreshScheduler` directly (already `@MainActor`).
- `RefreshScheduler.registerBackgroundTask()` uses `Task { @MainActor in ... }` with a comment that BGTaskScheduler delivers on the main queue when `using: .main`.
- `scheduleNextRefresh()` is now `@MainActor` and accesses diagnostics directly.

### Optional polish

**ContentView preview** — Uses one shared `InMemoryWatchlistRepository` for both environment and `WatchlistUndoRemoval`.

### What to test

1. App launch — notifications and analytics still wired (track a show, check notification prompt).
2. Background refresh — still schedules (Diagnostics screen shows next refresh if available).
3. Search track/untrack — row buttons still work.
4. Show detail track — notification prompts still work.
5. Previews — Search, ContentView, ShowDetail still compile and run.

Build verified: **TEST BUILD SUCCEEDED**.

## User

We've almost got it - last comment from ChatGPT:

One small thing: there are still a few try? calls where repository failures are silently ignored, especially in:

* SearchWatchlistTracking.refresh(...)
* ShowDetailViewModel.refreshTrackedState()
* AppNavigationCoordinator.resolvePendingNavigation(...)

That is not alarming, but a very picky reviewer might prefer explicit error logging through analytics/diagnostics.

## Assistant

I'll replace silent `try?` repository calls with explicit analytics logging in those three spots, matching how errors are handled elsewhere in the app.

Replacing silent `try?` with explicit error logging in those three spots, and fixing the same pattern in `handleTrackButton`'s tracked-show lookup.

Done. Silent `try?` repository/network failures now log through analytics with explicit context strings, while `CancellationError` is still ignored (task superseded).

**Changes:**

- **`SearchWatchlistTracking.refresh`** — uses `do/catch`; logs `search_watchlist_tracking_refresh` on failure. `SearchView` passes `analytics` into `refresh`.
- **`ShowDetailViewModel.refreshTrackedState()`** — logs `show_detail_refresh_tracked_state` on failure.
- **`AppNavigationCoordinator.resolvePendingNavigation`** — separate `do/catch` blocks for watchlist lookup (`notification_navigation_watchlist_lookup`) and TVMaze fallback (`notification_navigation_show_lookup`). A nil tracked show (not on watchlist) still falls through to search as before — only actual errors are logged.

Also fixed the same pattern in **`SearchWatchlistTracking.handleTrackButton`** removal path (`search_watchlist_tracking_lookup`).

Build verified: **TEST BUILD SUCCEEDED**.
