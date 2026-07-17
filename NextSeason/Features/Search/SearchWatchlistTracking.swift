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
            var ids = try await repository.trackedShowIDs()
            if let pendingID = undoRemoval?.pendingRemoval?.id {
                ids.remove(pendingID)
            }
            trackedShowIDs = ids
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

        if trackedShowIDs.contains(show.id) {
            guard let undoRemoval = context.undoRemoval else { return }
            do {
                guard let tracked = try await context.repository.trackedShow(showID: show.id) else { return }
                undoRemoval.requestRemoval(
                    tracked,
                    anchor: anchor,
                    source: .search,
                    onCommitted: context.onWatchlistChanged
                )
                trackedShowIDs.remove(show.id)
            } catch is CancellationError {
                return
            } catch {
                context.analytics.trackNonFatalError(error, context: "search_watchlist_tracking_lookup")
            }
            return
        }

        updatingShowIDs.insert(show.id)
        defer { updatingShowIDs.remove(show.id) }

        do {
            try await WatchlistAdding.add(
                show,
                source: .search,
                repository: context.repository,
                analytics: context.analytics,
                notifications: context.notificationService,
                prompt: context.notificationPrompt
            )
            trackedShowIDs.insert(show.id)
            context.onSearchResultsHintDismissed()
            context.onWatchlistChanged()
        } catch is CancellationError {
            return
        } catch {
            context.analytics.trackNonFatalError(error, context: "watchlist_add_search")
            await refresh(
                repository: context.repository,
                excludingPendingRemovalFrom: context.undoRemoval,
                analytics: context.analytics
            )
        }
    }
}
