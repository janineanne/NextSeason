# MVP Analytics

> **Status:** This document describes the analytics architecture implemented for the completed MVP. The MVP intentionally uses local, privacy-first analytics with no third-party SDKs or backend services. The final section describes how this architecture can evolve after the initial App Store release.


## Goals

The MVP analytics system:

-   Remains completely free.
-   Avoids third-party SDKs.
-   Respects user privacy.
-   Provides actionable feedback during TestFlight.
-   Demonstrates a scalable analytics architecture.

## Guiding Philosophy

Rather than collecting every possible interaction, instrument only the
events that answer real product questions.

Examples:

-   Can users successfully search?
-   Do users find shows that interest them?
-   Do they build a watchlist?
-   Are notifications being enabled?

Everything else is unnecessary noise.

------------------------------------------------------------------------

# Layer 1 — Structured Analytics Events

The MVP implements a strongly typed event model in
`AnalyticsService.swift`.

```swift
enum AnalyticsEvent {
    case appLaunched
    case searchPerformed(queryLength: Int, resultCount: Int, durationMs: Int)
    case searchResultOpened(showID: Int)
    case exampleSearchUsed
    case watchlistAdded(source: WatchlistActionSource, showID: Int)
    case watchlistRemoved(source: WatchlistActionSource, showID: Int)
    case showDetailViewed(showID: Int)
    case watchlistViewed
    case watchlistItemOpened(showID: Int)
    case notificationPermission(result: NotificationPermissionResult)
    case notificationReminderScheduled
    case notificationTapped(showID: Int)
    case appOpenedFromNotification(showID: Int)
    case emptyWatchlistShown
    case emptySearchResultsShown
    case themeSelected(variant: AppPaletteVariant)
    case nonFatalError(category: AnalyticsErrorCategory, context: String)
}
```

Benefits:

-   Compile-time safety
-   Consistent event names
-   Easier future expansion
-   Cleaner logging implementation

Events are logged locally via `os.Logger` (visible in Console.app) and
also update persisted counters (Layer 2).

------------------------------------------------------------------------

# Layer 2 — Local Usage Counters

`AnalyticsCountersStore` persists aggregate counters in UserDefaults.
`AnalyticsService.track(_:)` increments counters automatically — call sites
do not write to UserDefaults directly.

Stored counters:

-   App launches
-   Searches performed
-   Successful searches (result count greater than zero)
-   Searches returning zero results
-   Example searches used
-   Show detail views
-   Watchlist additions
-   Watchlist removals
-   Notification permission requests
-   Notification permission grants
-   Notification reminders scheduled

Only aggregate counts are stored.

Do **not** store search text, show names, or other user content.

Implementation: `AnalyticsCounters.swift`, `AnalyticsCountersStore`.

------------------------------------------------------------------------

# Layer 3 — Diagnostics Screen

`DiagnosticsView` is a beta diagnostics screen with Copy and Share
controls. Nothing is transmitted automatically.

**Access:** Long-press the version label below the TVMaze attribution
footer on Search or Watchlist (for example, “Version 1.0 (24)”).

Display information:

-   App version and build number
-   All Layer 2 counters
-   Notifications enabled (current authorization state)
-   Current theme

The exported report matches this shape:

```text
NextSeason Diagnostics

Version: 1.0 (24)

App launches: 19
Searches: 52
Successful searches: 48
No-result searches: 4
Example searches: 3
Show detail views: 12
Watchlist adds: 17
Watchlist removals: 6
Notification permission requests: 2
Notification permission grants: 1
Notification reminders scheduled: 4
```

Implementation: `DiagnosticsView.swift`, `AnalyticsDiagnosticsReport.swift`.

------------------------------------------------------------------------

# Implemented Events

## Search

Record:

-   Search performed (query length, result count, duration)
-   Empty search results shown
-   Search result opened
-   Example search used

Do not record:

-   Every keystroke
-   Search text

------------------------------------------------------------------------

## Watchlist

Record:

-   Watchlist viewed
-   Watchlist item opened
-   Show added (with source: search, detail, or watchlist)
-   Show removed (with source)
-   Show detail viewed
-   Empty watchlist shown

------------------------------------------------------------------------

## Notifications

Record:

-   Permission granted or denied (when the system prompt is shown)
-   Reminder scheduled (when a local notification is successfully added)
-   Notification tapped
-   App opened from notification

Reminder cancellation is not tracked yet — the app does not cancel
scheduled reminders today.

------------------------------------------------------------------------

# Events Not Worth Tracking

Avoid recording:

-   Every button tap
-   Every navigation transition
-   Scrolling
-   Poster taps
-   Typing every character

These produce large amounts of data with little product value.

------------------------------------------------------------------------

# Privacy

The analytics system:

-   Never collects personally identifiable information.
-   Never collects search text.
-   Never transmits data automatically.
-   Never requires an account.
-   Works completely offline.

Users explicitly choose whether to share diagnostics with the developer
via Copy or Share on the diagnostics screen.

------------------------------------------------------------------------

# Future Evolution

The MVP intentionally avoids remote analytics services. This keeps operating
costs at zero, minimizes privacy concerns, and is sufficient for TestFlight
validation and portfolio demonstration.

After the initial App Store release, the existing analytics abstraction can be
extended without affecting the rest of the application. Potential enhancements
include:

- Optional anonymous aggregate telemetry.
- Crash reporting.
- Feature adoption metrics.
- Search quality metrics (including search-result limitations).
- Background refresh success/failure rates.
- Notification delivery and engagement metrics.

Because analytics are already isolated behind an abstraction, these capabilities
can be added incrementally without requiring widespread architectural changes.
