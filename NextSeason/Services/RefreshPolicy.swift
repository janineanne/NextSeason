//
//  RefreshPolicy.swift
//  NextSeason
//

import Foundation

/// Throttle rules for automatic foreground watchlist refresh.
///
/// Keeps scene-active refreshes from hammering TVMaze when the app is
/// backgrounded and resumed repeatedly; pull-to-refresh / `force` bypass this.
nonisolated enum RefreshPolicy {
    /// Minimum time between foreground-triggered refreshes.
    static let foregroundMinimumInterval: TimeInterval = 15 * 60

    /// `true` when there was never a foreground refresh, or enough time has passed.
    static func shouldPerformForegroundRefresh(
        lastRefreshAt: Date?,
        at: Date,
        minimumInterval: TimeInterval = foregroundMinimumInterval
    ) -> Bool {
        guard let lastRefreshAt else { return true }
        return at.timeIntervalSince(lastRefreshAt) >= minimumInterval
    }
}
