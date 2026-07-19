//
//  SearchWatchlistTracking.swift
//  NextSeason
//

import Foundation

/// Tracks which search results are on the watchlist and handles row-level add/remove.
@Observable
@MainActor
final class SearchWatchlistTracking {
    private(set) var trackedShowIDs: Set<Int> = []
    private(set) var updatingShowIDs: Set<Int> = []

    func refresh(
        repository: any WatchlistRepository,
        excludingPendingRemovalFrom undoRemoval: WatchlistUndoRemoval?,
        analytics: any AnalyticsTracking
    ) async {
        do {
            trackedShowIDs = try await WatchlistEffectiveTracking.trackedIDs(
                repository: repository,
                undoRemoval: undoRemoval
            )
        } catch is CancellationError {
            return
        } catch {
            analytics.trackNonFatalError(error, context: "search_watchlist_tracking_refresh")
        }
    }

    func handleTrackButton(
        for show: Show,
        anchor: CGRect,
        context: SearchWatchlistTrackingContext
    ) async {
        guard !updatingShowIDs.contains(show.id) else { return }

        let isTracked = trackedShowIDs.contains(show.id)
        let isPendingRemoval = context.undoRemoval?.pendingRemoval?.id == show.id
        // Only the add path needs an in-flight lock; untrack/undo update local
        // star state immediately. Capture before await so defer still clears.
        let shouldLockForAdd = !isTracked && !isPendingRemoval

        if shouldLockForAdd {
            updatingShowIDs.insert(show.id)
        }
        defer {
            if shouldLockForAdd {
                updatingShowIDs.remove(show.id)
            }
        }

        do {
            let outcome = try await WatchlistAdding.toggle(
                show,
                isTracked: isTracked,
                anchor: anchor,
                source: .search,
                repository: context.repository,
                undoRemoval: context.undoRemoval,
                analytics: context.analytics,
                notifications: context.notificationService,
                prompt: context.notificationPrompt,
                onRemovalCommitted: context.onWatchlistChanged
            )
            apply(outcome, for: show.id, context: context)
        } catch is CancellationError {
            return
        } catch {
            let errorContext = isTracked || isPendingRemoval
                ? "search_watchlist_tracking_lookup"
                : "watchlist_add_search"
            context.analytics.trackNonFatalError(error, context: errorContext)
            if shouldLockForAdd {
                await refresh(
                    repository: context.repository,
                    excludingPendingRemovalFrom: context.undoRemoval,
                    analytics: context.analytics
                )
            }
        }
    }

    private func apply(
        _ outcome: WatchlistAdding.ToggleOutcome,
        for showID: Int,
        context: SearchWatchlistTrackingContext
    ) {
        switch outcome {
        case .undidPendingRemoval:
            trackedShowIDs.insert(showID)
        case .removalRequested:
            trackedShowIDs.remove(showID)
        case .added:
            trackedShowIDs.insert(showID)
            context.onSearchResultsHintDismissed()
            context.onWatchlistChanged()
        case .ignored:
            break
        }
    }
}
