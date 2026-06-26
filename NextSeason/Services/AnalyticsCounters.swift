//
//  AnalyticsCounters.swift
//  NextSeason
//

import Foundation

/// Aggregate usage counts persisted locally for beta diagnostics. No search text,
/// show titles, or other user content is stored.
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
    var themeSelections = 0
    var actorNameTaps = 0
}

extension AnalyticsCounters {
    mutating func record(_ event: AnalyticsEvent) {
        switch event {
        case .appLaunched:
            appLaunches += 1
        case let .searchPerformed(_, resultCount, _):
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
        case let .notificationPermission(result):
            notificationPermissionRequests += 1
            if result == .granted {
                notificationPermissionGrants += 1
            }
        case .notificationReminderScheduled:
            notificationRemindersScheduled += 1
        case let .themeSelected:
            themeSelections += 1
        case .actorNameTapped:
            actorNameTaps += 1
        case .searchResultOpened, .watchlistViewed, .watchlistItemOpened,
             .notificationTapped, .appOpenedFromNotification, .emptyWatchlistShown,
             .nonFatalError:
            break
        }
    }
}

final class AnalyticsCountersStore {
    private static let storageKey = "analyticsCounters"

    private(set) var counters: AnalyticsCounters
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(AnalyticsCounters.self, from: data) {
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
