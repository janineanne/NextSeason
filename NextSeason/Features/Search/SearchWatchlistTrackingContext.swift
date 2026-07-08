//
//  SearchWatchlistTrackingContext.swift
//  NextSeason
//

import Foundation

/// Dependencies for search-row watchlist add/remove actions.
struct SearchWatchlistTrackingContext {
    let repository: any WatchlistRepository
    let undoRemoval: WatchlistUndoRemoval?
    let notificationService: any NotificationManaging
    let notificationPrompt: WatchlistNotificationPromptState
    let analytics: any AnalyticsTracking
    let onWatchlistChanged: () -> Void
    let onSearchResultsHintDismissed: () -> Void
}
