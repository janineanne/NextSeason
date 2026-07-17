//
//  WatchlistAdding.swift
//  NextSeason
//

import Foundation

/// Shared post-track steps used by search rows and show detail.
@MainActor
enum WatchlistAdding {
    /// Persists the show, records analytics, and arms the notification prompt when needed.
    static func add(
        _ show: Show,
        source: WatchlistActionSource,
        repository: any WatchlistRepository,
        analytics: any AnalyticsTracking,
        notifications: any NotificationManaging,
        prompt: WatchlistNotificationPromptState
    ) async throws {
        try await repository.add(show)
        analytics.track(.watchlistAdded(source: source, showID: show.id))
        if await notifications.needsAuthorizationPrompt() {
            prompt.shouldPromptForNotifications = true
        }
    }
}
