//
//  AnalyticsService.swift
//  NextSeason
//

import Aptabase
import Foundation
import os

/// Catalog of anonymous product events for beta prioritization and local diagnostics.
///
/// Privacy: parameters stay structural only (`show_id`, lengths, counts, result enums).
/// Never attach search text, show titles, or other user-identifying content — the same
/// rule applies to Console logs and to `AnalyticsCounters` persistence.
enum AnalyticsEvent: Equatable, Sendable {
    case appLaunched
    case searchPerformed(
        queryLength: Int,
        resultCount: Int,
        durationMs: Int,
        outcome: SearchPerformedOutcome
    )
    /// User tapped a search row (before detail appears). Distinct from
    /// `searchResultOpened`, which fires when detail loads. Remote-only.
    case searchResultSelected(alreadyOnWatchlist: Bool)
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

/// Coarse search-quality outcome for remote `search_performed` events.
/// Local logs and counters still use query length, result count, and duration only.
enum SearchPerformedOutcome: String, Sendable {
    case results
    case empty
    case failed
}

/// Resolves the Aptabase app key from Info.plist (`AptabaseAppKey` ← `APTABASE_APP_KEY`).
/// Unsubstituted `${…}` placeholders and empty values are treated as missing.
enum AptabaseAppKey {
    static let infoDictionaryKey = "AptabaseAppKey"

    /// Returns a trimmed Aptabase key, or `nil` when missing, empty, or still
    /// an unsubstituted `${…}` build placeholder.
    static func resolved(from infoDictionary: [String: Any]?) -> String? {
        let key =
            (infoDictionary?[infoDictionaryKey] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty, !key.hasPrefix("$") else { return nil }
        return key
    }
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
        track(
            .nonFatalError(category: AnalyticsErrorCategory.category(for: error), context: context))
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
        case .searchResultSelected: "search_result_selected"
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
        case .searchPerformed(let queryLength, let resultCount, let durationMs, _):
            [
                "query_length": String(queryLength),
                "result_count": String(resultCount),
                "duration_ms": String(durationMs),
            ]
        case .searchResultSelected(let alreadyOnWatchlist):
            ["already_on_watchlist": String(alreadyOnWatchlist)]
        case .searchResultOpened(let showID),
            .showDetailViewed(let showID),
            .watchlistItemOpened(let showID),
            .notificationTapped(let showID),
            .appOpenedFromNotification(let showID):
            ["show_id": String(showID)]
        case .watchlistAdded(let source, let showID),
            .watchlistRemoved(let source, let showID):
            ["source": source.rawValue, "show_id": String(showID)]
        case .notificationPermission(let result):
            ["result": result.rawValue]
        case .nonFatalError(let category, let context):
            ["category": category.rawValue, "context": context]
        case .appLaunched, .exampleSearchUsed, .notificationReminderScheduled,
            .watchlistViewed, .emptyWatchlistShown, .emptySearchResultsShown:
            [:]
        }
    }

    /// Aptabase payload for the production whitelist, or `nil` to keep the event local.
    /// New catalog cases stay local unless they are added here explicitly.
    var remoteEvent: RemoteEvent? {
        switch self {
        case .appLaunched:
            RemoteEvent(name: name, properties: [:])
        case .searchPerformed(let queryLength, let resultCount, let durationMs, let outcome):
            RemoteEvent(
                name: name,
                properties: [
                    "query_length": .int(queryLength),
                    "result_count": .int(resultCount),
                    "duration_ms": .int(durationMs),
                    "outcome": .string(outcome.rawValue),
                ]
            )
        case .searchResultSelected(let alreadyOnWatchlist):
            RemoteEvent(
                name: name,
                properties: ["already_on_watchlist": .bool(alreadyOnWatchlist)]
            )
        default:
            nil
        }
    }

    /// Structural Aptabase properties. Visible to tests via `@testable import`.
    enum RemoteValue: Equatable, Sendable {
        case int(Int)
        case bool(Bool)
        case string(String)
    }

    /// Remote event after the Aptabase whitelist. Visible to tests via `@testable import`.
    struct RemoteEvent: Equatable, Sendable {
        let name: String
        let properties: [String: RemoteValue]

        fileprivate var aptabaseProperties: [String: any Value] {
            var props: [String: any Value] = [:]
            props.reserveCapacity(properties.count)
            for (key, value) in properties {
                switch value {
                case .int(let int): props[key] = int
                case .bool(let bool): props[key] = bool
                case .string(let string): props[key] = string
                }
            }
            return props
        }
    }
}

/// Default implementation: increments local counters, logs structured events via
/// `os.Logger`, and forwards the Aptabase whitelist (`remoteEvent`) remotely.
/// Disabled under UI tests (`isEnabled` defaults false) so test runs do not
/// pollute Console, UserDefaults, or remote analytics. Call sites only depend
/// on `AnalyticsTracking`.
@MainActor
final class AnalyticsService: AnalyticsTracking {
    private let logger: Logger
    private let isEnabled: Bool
    private let countersStore: AnalyticsCountersStore

    /// XCTest / Swift Testing and `-UITesting` runs must not send production events.
    static var allowsAptabaseTransmission: Bool {
        !isRunningAutomatedTests
    }

    private static var isRunningAutomatedTests: Bool {
        UITestingConfiguration.isEnabled
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    init(
        isEnabled: Bool = !UITestingConfiguration.isEnabled,
        countersStore: AnalyticsCountersStore = AnalyticsCountersStore()
    ) {
        self.isEnabled = isEnabled
        self.countersStore = countersStore
        // Match the app bundle ID so Console.app can associate logs with NextSeason.
        let subsystem = Bundle.main.bundleIdentifier ?? "com.TrialByFyre.NextSeason"
        self.logger = Logger(subsystem: subsystem, category: "Analytics")
        if isEnabled {
            Self.initializeAptabaseIfNeeded(logger: logger)
        }
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
        sendToAptabase(event)
    }

    // MARK: - Aptabase

    /// Aptabase's shared client is a process-wide Objective-C singleton.
    /// All access stays on the main actor through `AnalyticsService`.
    private enum AptabaseClient {
        nonisolated(unsafe) static let shared = Aptabase.shared
    }

    private static var didAttemptAptabaseInitialization = false
    private static var isAptabaseConfigured = false

    /// One-shot Aptabase setup from Info.plist. Skipped under automated tests
    /// and when the key is missing.
    private static func initializeAptabaseIfNeeded(logger: Logger) {
        guard !didAttemptAptabaseInitialization else { return }
        didAttemptAptabaseInitialization = true
        guard allowsAptabaseTransmission else { return }
        guard let key = AptabaseAppKey.resolved(from: Bundle.main.infoDictionary) else {
            logger.error("aptabase_disabled missing_or_malformed_app_key")
            return
        }
        AptabaseClient.shared.initialize(appKey: key)
        isAptabaseConfigured = true
    }

    /// Forwards whitelisted events only; catalog cases without a `remoteEvent` stay local.
    private func sendToAptabase(_ event: AnalyticsEvent) {
        guard Self.isAptabaseConfigured, let remote = event.remoteEvent else { return }
        if remote.properties.isEmpty {
            AptabaseClient.shared.trackEvent(remote.name)
        } else {
            AptabaseClient.shared.trackEvent(remote.name, with: remote.aptabaseProperties)
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
