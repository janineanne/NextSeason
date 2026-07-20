//
//  WatchlistTracking.swift
//  NextSeason
//

import Foundation

/// Shared watchlist track/untrack orchestration used by search rows and show detail.
@MainActor
enum WatchlistTracking {
    /// Generic user-facing copy for thrown watchlist add/remove failures.
    static let updateFailedMessage =
        "NextSeason couldn’t update your Watchlist. Please try again."

    /// Result of a track-button tap after shared side effects have run.
    enum ToggleOutcome: Equatable {
        /// A pending undoable removal for this show was cancelled.
        case undidPendingRemoval
        /// An undoable removal was requested (persistence deferred).
        case removalRequested
        /// The show was persisted and analytics / notification prompt ran.
        case added
        /// No-op (e.g. missing undo coordinator, or show already gone from the repo).
        case ignored
    }

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

    /// Full track/untrack flow: undo a pending removal, request undoable untrack, or add.
    static func toggle(
        _ show: Show,
        isTracked: Bool,
        anchor: CGRect,
        source: WatchlistActionSource,
        repository: any WatchlistRepository,
        undoRemoval: WatchlistUndoRemoval?,
        analytics: any AnalyticsTracking,
        notifications: any NotificationManaging,
        prompt: WatchlistNotificationPromptState,
        onRemovalCommitted: @escaping () -> Void = {}
    ) async throws -> ToggleOutcome {
        if undoRemoval?.pendingRemoval?.id == show.id {
            _ = undoRemoval?.undoRemoval()
            return .undidPendingRemoval
        }

        if isTracked {
            guard let undoRemoval else { return .ignored }
            guard let tracked = try await repository.trackedShow(showID: show.id) else {
                return .ignored
            }
            undoRemoval.requestRemoval(
                tracked,
                anchor: anchor,
                source: source,
                onCommitted: onRemovalCommitted
            )
            return .removalRequested
        }

        try await add(
            show,
            source: source,
            repository: repository,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )
        return .added
    }
}
