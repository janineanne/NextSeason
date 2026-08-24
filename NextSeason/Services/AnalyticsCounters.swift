//
//  AnalyticsCounters.swift
//  NextSeason
//

import Foundation

/// Aggregate usage counts persisted locally for beta diagnostics. No search text,
/// show titles, or other user content is stored — only tallies of `AnalyticsEvent`s
/// that `record(_:)` chooses to increment (many catalog events are intentionally ignored).
struct AnalyticsCounters: Codable, Equatable, Sendable {
    var appLaunches = 0
    var searchesPerformed = 0
    var successfulSearches = 0
    var noResultSearches = 0
    var exampleSearchesUsed = 0
    var showDetailViews = 0
    var watchlistAdditions = 0
    var watchlistRemovals = 0
    var notificationPermissionRequests = 0
    var notificationPermissionGrants = 0
    var notificationRemindersScheduled = 0
}

extension AnalyticsCounters {
    /// Increments the counters that back the Diagnostics "Usage" section.
    ///
    /// Mapped events: `appLaunched`, `searchPerformed` (+ `successfulSearches` when
    /// `resultCount > 0`), `emptySearchResultsShown` → `noResultSearches`,
    /// `exampleSearchUsed`, `showDetailViewed`, watchlist add/remove, notification
    /// permission (+ grants), `notificationReminderScheduled`.
    /// Navigation / error events (`searchResultOpened`, taps, `nonFatalError`, etc.)
    /// are tracked for logging but do not bump these aggregates.
    mutating func record(_ event: AnalyticsEvent) {
        switch event {
        case .appLaunched:
            appLaunches += 1
        case .searchPerformed(_, let resultCount, _, _):
            searchesPerformed += 1
            if resultCount > 0 {
                successfulSearches += 1
            }
        case .emptySearchResultsShown:
            noResultSearches += 1
        case .exampleSearchUsed:
            exampleSearchesUsed += 1
        case .showDetailViewed:
            showDetailViews += 1
        case .watchlistAdded:
            watchlistAdditions += 1
        case .watchlistRemoved:
            watchlistRemovals += 1
        case .notificationPermission(let result):
            notificationPermissionRequests += 1
            if result == .granted {
                notificationPermissionGrants += 1
            }
        case .notificationReminderScheduled:
            notificationRemindersScheduled += 1
        case .searchResultSelected, .searchResultOpened, .watchlistViewed, .watchlistItemOpened,
            .notificationTapped, .appOpenedFromNotification, .emptyWatchlistShown,
            .nonFatalError:
            break
        }
    }
}

/// Loads and saves `AnalyticsCounters` under UserDefaults key `analyticsCounters`.
/// Survives launches so Diagnostics / shareable reports show cumulative beta usage.
final class AnalyticsCountersStore {
    /// UserDefaults key for the JSON-encoded `AnalyticsCounters` blob.
    private static let storageKey = "analyticsCounters"

    private(set) var counters: AnalyticsCounters
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode(AnalyticsCounters.self, from: data)
        {
            counters = decoded
        } else {
            counters = AnalyticsCounters()
        }
    }

    func snapshot() -> AnalyticsCounters {
        counters
    }

    func record(_ event: AnalyticsEvent) {
        counters.record(event)
        persist()
    }

    #if DEBUG
        func resetForTesting() {
            counters = AnalyticsCounters()
            userDefaults.removeObject(forKey: Self.storageKey)
        }
    #endif

    private func persist() {
        guard let data = try? JSONEncoder().encode(counters) else { return }
        userDefaults.set(data, forKey: Self.storageKey)
    }
}
