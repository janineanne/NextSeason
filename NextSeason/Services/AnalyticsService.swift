//
//  AnalyticsService.swift
//  NextSeason
//

import Foundation
import os

/// Anonymous product events for beta prioritization. Do not log search text,
/// show titles, or other identifying content.
enum AnalyticsEvent: Equatable, Sendable {
    case searchPerformed(queryLength: Int, resultCount: Int, durationMs: Int)
    case searchResultOpened(showID: Int)
    case watchlistAdded(source: WatchlistActionSource, showID: Int)
    case watchlistRemoved(source: WatchlistActionSource, showID: Int)
    case showDetailViewed(showID: Int)
    case watchlistViewed
    case watchlistItemOpened(showID: Int)
    case notificationPermission(result: NotificationPermissionResult)
    case notificationTapped(showID: Int)
    case appOpenedFromNotification(showID: Int)
    case emptyWatchlistShown
    case emptySearchResultsShown
    case nonFatalError(category: AnalyticsErrorCategory, context: String)
    case actorNameTapped(showID: Int)
}

enum WatchlistActionSource: String, Sendable {
    case search
    case detail
    case watchlist
}

enum NotificationPermissionResult: String, Sendable {
    case granted
    case denied
}

enum AnalyticsErrorCategory: String, Sendable {
    case api
    case decoding
    case network
    case notification
    case persistence

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
@MainActor
protocol AnalyticsTracking: AnyObject {
    func track(_ event: AnalyticsEvent)
}

extension AnalyticsTracking {
    func trackNonFatalError(_ error: Error, context: String) {
        track(.nonFatalError(category: AnalyticsErrorCategory.category(for: error), context: context))
    }
}

extension AnalyticsEvent {
    var name: String {
        switch self {
        case .searchPerformed: "search_performed"
        case .searchResultOpened: "search_result_opened"
        case .watchlistAdded: "watchlist_added"
        case .watchlistRemoved: "watchlist_removed"
        case .showDetailViewed: "show_detail_viewed"
        case .watchlistViewed: "watchlist_viewed"
        case .watchlistItemOpened: "watchlist_item_opened"
        case .notificationPermission: "notification_permission"
        case .notificationTapped: "notification_tapped"
        case .appOpenedFromNotification: "app_opened_from_notification"
        case .emptyWatchlistShown: "empty_watchlist_shown"
        case .emptySearchResultsShown: "empty_search_results_shown"
        case .nonFatalError: "non_fatal_error"
        case .actorNameTapped: "actor_name_tapped"
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
             let .appOpenedFromNotification(showID),
             let .actorNameTapped(showID):
            ["show_id": String(showID)]
        case let .watchlistAdded(source, showID),
             let .watchlistRemoved(source, showID):
            ["source": source.rawValue, "show_id": String(showID)]
        case let .notificationPermission(result):
            ["result": result.rawValue]
        case let .nonFatalError(category, context):
            ["category": category.rawValue, "context": context]
        case .watchlistViewed, .emptyWatchlistShown, .emptySearchResultsShown:
            [:]
        }
    }
}

/// Default beta implementation: logs structured events locally via `os.Logger`.
/// Replace or compose with a remote provider when ready.
@MainActor
final class AnalyticsService: AnalyticsTracking {
    private let logger: Logger
    private let isEnabled: Bool

    init(isEnabled: Bool = !UITestingConfiguration.isEnabled) {
        self.isEnabled = isEnabled
        // Match the app bundle ID so Console.app can associate logs with NextSeason.
        let subsystem = Bundle.main.bundleIdentifier ?? "com.TrialByFyre.NextSeason"
        self.logger = Logger(subsystem: subsystem, category: "Analytics")
    }

    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
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
/// Records events in memory for unit tests.
@MainActor
final class RecordingAnalyticsService: AnalyticsTracking {
    private(set) var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }

    func reset() {
        events.removeAll()
    }
}
#endif
