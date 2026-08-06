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
    ///
    /// Search hits omit seasons / next episode. When those are missing, this loads the
    /// full `/shows/:id` payload so stored `nextSeason` matches show detail.
    static func add(
        _ show: Show,
        source: WatchlistActionSource,
        repository: any WatchlistRepository,
        tvMaze: any TVMazeService,
        analytics: any AnalyticsTracking,
        notifications: any NotificationManaging,
        prompt: WatchlistNotificationPromptState
    ) async throws {
        let showToStore = try await resolvedShowForTracking(show, tvMaze: tvMaze)
        try await repository.add(showToStore)
        analytics.track(.watchlistAdded(source: source, showID: showToStore.id))
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
        tvMaze: any TVMazeService,
        removalCoordinator: WatchlistPendingRemoval?,
        analytics: any AnalyticsTracking,
        notifications: any NotificationManaging,
        prompt: WatchlistNotificationPromptState,
        onRemovalCommitted: @escaping () -> Void = {}
    ) async throws -> ToggleOutcome {
        if removalCoordinator?.pendingRemoval?.id == show.id {
            _ = await removalCoordinator?.undoRemoval()
            return .undidPendingRemoval
        }

        if isTracked {
            guard let removalCoordinator else { return .ignored }
            guard let tracked = try await repository.trackedShow(showID: show.id) else {
                return .ignored
            }
            removalCoordinator.requestRemoval(
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
            tvMaze: tvMaze,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )
        return .added
    }

    /// Uses the caller's show when it already has season data; otherwise fetches detail.
    private static func resolvedShowForTracking(
        _ show: Show,
        tvMaze: any TVMazeService
    ) async throws -> Show {
        guard show.seasons.isEmpty else { return show }
        return try await tvMaze.show(id: show.id)
    }
}
