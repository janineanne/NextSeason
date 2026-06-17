//
//  RefreshPolicy.swift
//  NextSeason
//

import Foundation

/// Rules for when automatic foreground refresh should hit the network.
nonisolated enum RefreshPolicy {
    /// Minimum time between foreground-triggered refreshes.
    static let foregroundMinimumInterval: TimeInterval = 15 * 60

    static func shouldPerformForegroundRefresh(
        lastRefreshAt: Date?,
        now: Date,
        minimumInterval: TimeInterval = foregroundMinimumInterval
    ) -> Bool {
        guard let lastRefreshAt else { return true }
        return now.timeIntervalSince(lastRefreshAt) >= minimumInterval
    }
}
