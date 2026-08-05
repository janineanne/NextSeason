//
//  AnalyticsService.swift
//  NextSeason
//

import Foundation
import os

/// Catalog of anonymous product events for beta prioritization and local diagnostics.
///
/// Privacy: parameters stay structural only (`show_id`, lengths, counts, result enums).
/// Never attach search text, show titles, or other user-identifying content — the same
/// rule applies to Console logs and to `AnalyticsCounters` persistence.
enum AnalyticsEvent: Equatable, Sendable {
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
    case nonFatalError(category: AnalyticsErrorCategory, context: String)
}

/// Where a watchlist add/remove originated (search row, detail, or watchlist itself).
enum WatchlistActionSource: String, Sendable {
    case search
    case detail
    case watchlist
}

enum NotificationPermissionResult: String, Sendable {
    case granted
    case denied
}

/// Coarse buckets for non-fatal errors so beta triage can group failures without
/// shipping full error text into analytics parameters.
enum AnalyticsErrorCategory: String, Sendable {
    case api
    case decoding
    case network
    case notification
    case persistence

    /// Maps known `TVMazeError` cases to decoding/network; everything else (including
    /// non-TVMaze errors) defaults to `.api` so unknown failures still get a category.
    static func category(for error: Error) -> AnalyticsErrorCategory {
        if let tvMazeError = error as? TVMazeError {
            switch tvMazeError {
            case .decoding:
                return .decoding
            case .network:
                return .network
            default:
                return .api
            }
        }
        return .api
    }
}

/// Abstraction so analytics providers can be swapped without touching call sites.
/// Production uses `AnalyticsService` (os.Logger + persisted counters); DEBUG unit
/// tests use `RecordingAnalyticsService` (in-memory only, no Console / UserDefaults).
@MainActor
protocol AnalyticsTracking: AnyObject {
    func track(_ event: AnalyticsEvent)
    func countersSnapshot() -> AnalyticsCounters
    func diagnosticsReport(
        notificationsEnabled: Bool,
        betaRefreshDiagnostics: BetaRefreshDiagnostics?
    ) -> String
}

extension AnalyticsTracking {
    /// Convenience that derives `AnalyticsErrorCategory` via `category(for:)` and
    /// records a `nonFatalError` with a short call-site `context` string.
    func trackNonFatalError(_ error: Error, context: String) {
        track(.nonFatalError(category: AnalyticsErrorCategory.category(for: error), context: context))
    }

    func countersSnapshot() -> AnalyticsCounters {
        AnalyticsCounters()
    }

    func diagnosticsReport(
        notificationsEnabled: Bool,
        betaRefreshDiagnostics: BetaRefreshDiagnostics? = nil
    ) -> String {
        AnalyticsDiagnosticsReport.formatted(
            counters: countersSnapshot(),
            notificationsEnabled: notificationsEnabled,
            betaRefreshDiagnostics: betaRefreshDiagnostics
        )
    }
}

extension AnalyticsEvent {
    var name: String {
        switch self {
        case .appLaunched: "app_launched"
        case .searchPerformed: "search_performed"
        case .searchResultOpened: "search_result_opened"
        case .exampleSearchUsed: "example_search_used"
        case .watchlistAdded: "watchlist_added"
        case .watchlistRemoved: "watchlist_removed"
        case .showDetailViewed: "show_detail_viewed"
        case .watchlistViewed: "watchlist_viewed"
        case .watchlistItemOpened: "watchlist_item_opened"
        case .notificationPermission: "notification_permission"
        case .notificationReminderScheduled: "notification_reminder_scheduled"
        case .notificationTapped: "notification_tapped"
        case .appOpenedFromNotification: "app_opened_from_notification"
        case .emptyWatchlistShown: "empty_watchlist_shown"
        case .emptySearchResultsShown: "empty_search_results_shown"
        case .nonFatalError: "non_fatal_error"
        }
    }

    var parameters: [String: String] {
        switch self {
        case let .searchPerformed(queryLength, resultCount, durationMs):
            [
                "query_length": String(queryLength),
                "result_count": String(resultCount),
                "duration_ms": String(durationMs)
            ]
        case let .searchResultOpened(showID),
             let .showDetailViewed(showID),
             let .watchlistItemOpened(showID),
             let .notificationTapped(showID),
             let .appOpenedFromNotification(showID):
            ["show_id": String(showID)]
        case let .watchlistAdded(source, showID),
             let .watchlistRemoved(source, showID):
            ["source": source.rawValue, "show_id": String(showID)]
        case let .notificationPermission(result):
            ["result": result.rawValue]
        case let .nonFatalError(category, context):
            ["category": category.rawValue, "context": context]
        case .appLaunched, .exampleSearchUsed, .notificationReminderScheduled,
             .watchlistViewed, .emptyWatchlistShown, .emptySearchResultsShown:
            [:]
        }
    }
}

/// Default beta implementation: increments local counters and logs structured events
/// via `os.Logger`. Disabled under UI tests (`isEnabled` defaults false) so test runs
/// do not pollute Console or UserDefaults. Replace or compose with a remote provider
/// when ready — call sites only depend on `AnalyticsTracking`.
@MainActor
final class AnalyticsService: AnalyticsTracking {
    private let logger: Logger
    private let isEnabled: Bool
    private let countersStore: AnalyticsCountersStore

    init(
        isEnabled: Bool = !UITestingConfiguration.isEnabled,
        countersStore: AnalyticsCountersStore = AnalyticsCountersStore()
    ) {
        self.isEnabled = isEnabled
        self.countersStore = countersStore
        // Match the app bundle ID so Console.app can associate logs with NextSeason.
        let subsystem = Bundle.main.bundleIdentifier ?? "com.TrialByFyre.NextSeason"
        self.logger = Logger(subsystem: subsystem, category: "Analytics")
    }

    func countersSnapshot() -> AnalyticsCounters {
        countersStore.snapshot()
    }

    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        countersStore.record(event)
        let params = event.parameters
            .map { "\($0.key)=\($0.value)" }
            .sorted()
            .joined(separator: " ")
        // `.notice` is visible in Console.app by default; `.info` requires
        // Action → Include Info Messages.
        if params.isEmpty {
            logger.notice("\(event.name, privacy: .public)")
        } else {
            logger.notice("\(event.name, privacy: .public) \(params, privacy: .public)")
        }
    }
}

#if DEBUG
/// In-memory analytics for unit tests: captures events for assertions without
/// writing to Console or UserDefaults (unlike production `AnalyticsService`).
@MainActor
final class RecordingAnalyticsService: AnalyticsTracking {
    private(set) var events: [AnalyticsEvent] = []
    private var counters = AnalyticsCounters()

    func track(_ event: AnalyticsEvent) {
        events.append(event)
        counters.record(event)
    }

    func countersSnapshot() -> AnalyticsCounters {
        counters
    }

    func reset() {
        events.removeAll()
        counters = AnalyticsCounters()
    }
}
#endif
