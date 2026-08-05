# MVP Architecture

This document describes the architecture of the completed MVP implementation of NextSeason TV.

Unlike [`InitialArchitecture.md`](InitialArchitecture.md), which captures the original architectural design, this document reflects the architecture of the implemented MVP. It serves as the authoritative architecture reference for the MVP milestone.

---

## 1. Architectural Overview

NextSeason TV is an iPhone application built with SwiftUI, Swift Concurrency, Observation, SwiftData, BackgroundTasks, UserNotifications, MetricKit, XCTest, and XCUITest.

The application follows a pragmatic MVVM-style architecture:

- SwiftUI views render state and forward user actions.
- `@Observable`, `@MainActor` view models coordinate presentation logic.
- Services own networking, refresh decisions, notification delivery, analytics, navigation, and diagnostics.
- A repository protocol isolates the application from SwiftData.
- Network DTOs, domain models, and persistence models remain separate.
- Long-lived dependencies are constructed in a central composition root and injected into the view hierarchy.

The architecture favors explicit dependencies and small, testable components without introducing abstraction solely for hypothetical future needs.

---

## 2. Application Composition and Dependency Injection

`AppCompositionRoot` constructs the application’s long-lived dependencies:

- `ModelContainer`
- `WatchlistRepository`
- `TVMazeClient`
- `WatchlistRefreshService`
- `NotificationService`
- `AnalyticsService`
- `BetaRefreshDiagnostics`
- `WatchlistPendingRemoval`

For normal execution, the composition root creates a SwiftData-backed repository. UI tests instead receive an in-memory repository and an in-memory `ModelContainer`.

`NextSeasonApp` injects shared services through SwiftUI environment values and passes explicit dependencies where ownership or clarity makes that preferable. This produces one stable service graph for the lifetime of the application scene.

The application startup path also configures:

- notification routing,
- MetricKit diagnostics,
- background refresh registration and scheduling,
- app-launch diagnostics,
- local analytics.

This setup is skipped or replaced where necessary during UI testing.

---

## 3. Presentation Layer

The root interface is a two-tab `TabView`:

- **Search**
- **Watchlist**

Each tab owns an independent `NavigationStack` path through `AppNavigationCoordinator`.

The principal feature boundaries are:

### Search

`SearchView` and `SearchViewModel` handle:

- user-entered TVMaze searches,
- loading, empty, success, and error states,
- search-result presentation,
- navigation to show details,
- watchlist membership state,
- adding and removing shows,
- first-run guidance,
- analytics and profile-flow hooks.

Search results come from TVMaze and are not persisted unless the user adds a show to the watchlist.

### Show Detail

`ShowDetailView` and `ShowDetailViewModel` load full show information, including embedded season and next-episode data. The feature calculates and presents the show’s next-season status and exposes watchlist actions.

A watchlist-originated detail route begins with a lightweight `TrackedShow`. The detail feature then reloads the complete `Show` from TVMaze.

### Watchlist

`WatchlistView` and `WatchlistViewModel` read persisted tracked shows and present them in non-empty status sections.

Current section behavior is:

- **Airing Now**
- **Coming Soon**
- **Returning**
- **Ended**

Coming Soon is sorted by premiere date, soonest first. Other sections are sorted alphabetically. Watchlist search is performed locally using case- and diacritic-insensitive matching.

Pull-to-refresh performs a forced network refresh but suppresses local notifications because the user is already viewing the updated information.

### Undoable Removal

`WatchlistPendingRemoval` coordinates deferred deletion. A removal first enters a pending state and displays an undo affordance. The repository deletion is committed when the undo window expires, the user confirms, another removal replaces it, or the user leaves the Watchlist tab.

This coordination is intentionally separate from `WatchlistViewModel` because pending removal state and the global toast outlive individual row interactions.

---

## 4. Navigation Architecture

`AppNavigationCoordinator` is an `@Observable`, `@MainActor` service that owns:

- the selected tab,
- the Search navigation path,
- the Watchlist navigation path,
- the initial-tab decision,
- notification-driven deep links,
- watchlist reload tokens,
- performance-profile navigation hooks.

On cold launch, the application opens:

- Watchlist when at least one show is tracked,
- Search when the watchlist is empty.

That decision is made once per launch and does not override notification routing.

Notification taps are routed by `NotificationCenterDelegate` through `NotificationRouting`. A tapped show opens in the Watchlist tab when it is still tracked. Otherwise, the coordinator retrieves the show from TVMaze and opens it in Search.

A deferred Watchlist push is used when changing tabs because immediately mutating the destination path during the same SwiftUI update can be dropped before the Watchlist `NavigationStack` is mounted.

---

## 5. Data Model Boundaries

NextSeason uses three distinct model layers.

### Network DTOs

Types under `Models/DTO` mirror TVMaze response shapes and conform to `Codable`. They exist only at the network boundary.

### Domain Models

Types under `Models/Domain` are the application’s working models:

- `Show`
- `Season`
- `NextEpisode`
- `ShowStatus`
- `NextSeasonStatus`
- `TrackedShow`

Views, view models, services, and repository protocols operate on these types rather than raw API or SwiftData objects.

### Persistence Model

`TrackedShowEntity` is the SwiftData `@Model` representation of a tracked show. Mapping between `TrackedShowEntity` and `TrackedShow` is contained within the persistence layer.

This separation prevents API response details and persistence mechanics from leaking into feature code.

---

## 6. Networking

`TVMazeService` defines the network boundary:

```swift
nonisolated protocol TVMazeService: Sendable {
    func searchShows(matching query: String) async throws -> [Show]
    func show(id: Int, bypassCache: Bool) async throws -> Show
    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date]
}
```

`TVMazeClient` is an actor-backed implementation using `URLSession`.

Its responsibilities include:

- free-text show search,
- full show retrieval with embedded seasons and next-episode data,
- retrieval of TVMaze’s updated-show map,
- DTO decoding and domain mapping,
- a descriptive `User-Agent`,
- typed error mapping,
- one retry after a rate-limit response,
- protocol-aware URL caching for ordinary requests,
- explicit cache bypass for refresh-sensitive requests.

The dedicated `URLSession` uses a modest private cache. TVMaze detail requests may therefore reuse valid cached responses, while background and forced refresh paths can request fresh data.

`TVMazeUpdatePeriod` selects the smallest update window that covers the time since the oldest tracked show was checked. Because background execution may be delayed, the window expands from day to week to month as necessary.

---

## 7. Persistence

`WatchlistRepository` is the persistence boundary:

```swift
@MainActor
protocol WatchlistRepository: AnyObject {
    func all() async throws -> [TrackedShow]
    func trackedShow(showID: Int) async throws -> TrackedShow?
    func trackedShowIDs() async throws -> Set<Int>
    func contains(showID: Int) async throws -> Bool
    func add(_ show: Show) async throws
    func remove(showID: Int) async throws
    func updateAfterRefresh(_ tracked: TrackedShow) async throws
}
```

The production implementation, `SwiftDataWatchlistRepository`, owns a `ModelContext` and performs all SwiftData work on the main actor.

`InMemoryWatchlistRepository` supports tests, previews, and UI-testing scenarios.

Tracked records include:

- the show’s identifying and display information,
- the most recently calculated next-season status,
- TVMaze’s source update timestamp,
- the last local check time,
- notification deduplication state,
- pending-change confirmation state,
- stale-record state,
- the date the show was added.

The repository is the only layer that reads and writes `TrackedShowEntity`.

---

## 8. Next-Season Calculation and Change Detection

`NextSeasonCalculator` is a pure domain component that derives `NextSeasonStatus` from a fully loaded `Show` and an injectable current date.

The calculated states drive both UI presentation and refresh comparison.

`StatusChangeDetector` determines whether a refreshed status represents a meaningful user-facing change. It also produces stable signatures used to avoid duplicate notifications.

For changes not backed by a concrete date, `TrackedShow.pendingChangeSignature` supports a confirmation step across polling runs. This reduces the likelihood that a transient or incomplete TVMaze update produces a false notification.

---

## 9. Refresh Pipeline

`WatchlistRefreshService` owns watchlist polling and update coordination. It remains `@MainActor` because the repository is main-actor-bound, while awaited network operations execute within the actor-backed TVMaze client.

The refresh service supports three principal paths:

1. **Foreground return**  
   When the app becomes active, `AppRootView` asks the service to refresh if allowed by `RefreshPolicy`.

2. **Background app refresh**  
   `RefreshScheduler` registers and handles the BackgroundTasks request, invokes the refresh service, records diagnostics, and schedules the next request.

3. **Interactive pull-to-refresh**  
   The Watchlist forces a refresh and reloads persistence, but notification delivery is disabled for that run.

The updates endpoint avoids retrieving complete data for every show when TVMaze indicates that no relevant source update has occurred. Forced refreshes bypass this optimization.

If TVMaze no longer returns a tracked show, the record is retained and marked stale rather than silently deleted.

### Background Execution Limitation

Background refresh is opportunistic. iOS decides whether and when to launch the app for a scheduled background task. As a result, local notification discovery is most reliable when the user launches the app periodically and allows Background App Refresh.

The present system does not include a server that independently monitors shows and sends remote push notifications. That is a planned future architectural evolution.

---

## 10. Notification Architecture

`NotificationService` implements notification authorization and local delivery behind `NotificationDelivering` and `NotificationManaging` protocols.

Responsibilities include:

- reading current authorization status,
- requesting authorization according to app policy,
- scheduling local season notifications,
- attaching the TVMaze show ID for deep-link routing,
- creating stable request identifiers based on show and status signatures,
- recording notification analytics,
- exposing delayed delivery for beta diagnostics.

`NotificationAuthorizationPolicy` centralizes decisions about when permission may be requested and whether the current notification settings permit alert delivery.

`NotificationCenterDelegate` handles foreground presentation and user interaction. `NotificationRouting` buffers launch-time notification taps until the live `AppNavigationCoordinator` has been attached by the SwiftUI hierarchy.

---

## 11. Analytics and Diagnostics

The current app does not use a third-party analytics SDK.

`AnalyticsService` writes structured local events using `os.Logger` and maintains on-device counters. `AnalyticsTracking` allows tests and future providers to substitute another implementation without changing feature code.

Tracked events cover major actions such as:

- app launches,
- searches and search-result opens,
- watchlist additions and removals,
- detail views,
- notification authorization and delivery,
- notification taps,
- empty states,
- categorized non-fatal errors.

`AppDiagnosticsLogger` provides subsystem logging and breadcrumbs across networking, persistence, refresh, and lifecycle operations.

`MetricKitDiagnosticsSubscriber` installs MetricKit diagnostics collection for production-quality crash and performance investigation.

Beta builds additionally expose `BetaRefreshDiagnostics`, which records:

- the most recent foreground refresh,
- the most recent background refresh,
- fetch results,
- notification decisions,
- the next scheduled refresh,
- simulated diagnostic scenarios.

Persisted background diagnostics survive relaunch so beta testers can determine whether iOS granted background execution while the app was not active.

---

## 12. Concurrency Model

The application uses Swift Concurrency with explicit isolation boundaries:

- UI state, repositories, coordinators, and most orchestration services are `@MainActor`.
- `TVMazeClient` is an actor, keeping network execution and decoding away from the main actor.
- `TVMazeService` and domain values are `Sendable` where they cross concurrency boundaries.
- Views start asynchronous work with SwiftUI `.task`, refresh actions, and narrowly scoped `Task` blocks.
- Injectable clocks and protocol-backed dependencies make asynchronous behavior deterministic in tests where needed.

SwiftData’s `ModelContext` is kept behind the main-actor repository rather than passed into views or background services.

---

## 13. Accessibility and Visual System

Accessibility is treated as a cross-cutting requirement rather than a separate feature layer.

The codebase includes:

- stable accessibility identifiers shared with UI tests,
- VoiceOver labels and hints,
- Dynamic Type-aware layouts,
- accessibility preference helpers,
- first-run explanatory copy,
- keyboard-dismissal behavior,
- theme and color helpers,
- centralized spacing and screen-background treatments.

The visual system remains intentionally lightweight. Reusable utilities provide consistency without introducing a separate design-system framework.

---

## 14. Testing Architecture

The test suite uses XCTest and XCUITest.

### Unit Tests

Unit coverage includes:

- next-season calculation,
- status-change detection,
- refresh policy,
- update-window selection,
- watchlist persistence,
- refresh orchestration,
- notification policy and delivery,
- navigation coordination,
- Search, Show Detail, and Watchlist view models,
- watchlist sectioning and tracking behavior,
- undoable removal,
- analytics counters and diagnostics,
- DTO decoding and domain presentation helpers,
- accessibility and first-run preferences.

Tests substitute:

- `InMemoryWatchlistRepository`,
- mock or preview `TVMazeService` implementations,
- recording analytics,
- test notification deliverers,
- injectable dates and refresh conditions.

### UI Tests

UI tests cover representative user flows including:

- tab and stack navigation,
- searching and opening a show,
- adding a show to the watchlist,
- watchlist search.

Launch arguments and `UITestingConfiguration` replace unstable external dependencies with deterministic test behavior.

### Performance and Reliability Tooling

The repository includes scripts and profile flows for:

- Instruments-driven user-flow profiling,
- uninstrumented performance logging,
- crash-report verification,
- trace analysis and resumption.

`ProfileFlowRunner` drives repeatable in-app navigation scenarios without becoming part of the normal user experience.

---

## 15. Current Architectural Constraints

The current implementation intentionally has the following constraints:

- It is an iPhone-only application.
- Data is stored locally on one device.
- There are no accounts or cloud synchronization.
- Search and show metadata depend on TVMaze.
- Search behavior is constrained by the current TVMaze search endpoint.
- Notifications depend on local polling and opportunistic iOS background execution.
- Analytics and diagnostics are local rather than remotely aggregated.
- There are no third-party runtime dependencies.

Planned product and architecture changes belong in the App Store Readiness and Product Evolution roadmaps. This document should describe planned work only when necessary to explain a current architectural boundary.

---

## 16. Scope and Maintenance

This document describes the architecture of the completed MVP implementation. It should remain an accurate description of the MVP as released.

Corrections, clarifications, and documentation improvements may be made at any time. However, architectural changes made after the MVP milestone should generally be documented in a new architecture document for that milestone (for example, a future App Store Release Architecture), rather than by rewriting this document.

If changes are made before the MVP milestone is finalized, update this document whenever they affect:

- application composition,
- major feature boundaries,
- data flow,
- persistence,
- navigation,
- background refresh,
- notification delivery,
- concurrency isolation,
- external services,
- testing strategy.

Minor refactorings and implementation details that do not change the architectural understanding of the MVP do not require updates.
