//
//  WatchlistViewModel.swift
//  NextSeason
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class WatchlistViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .loaded
    /// Rows rendered by the list. Kept separate from `state` so `ForEach` can
    /// diff removals and animate instead of replacing the whole list.
    private(set) var shows: [TrackedShow] = []

    var pendingRemoval: TrackedShow? { removalCoordinator.pendingRemoval }

    private let repository: any WatchlistRepository
    private let refreshService: WatchlistRefreshService?
    private let removalCoordinator: WatchlistUndoRemoval

    init(
        repository: any WatchlistRepository,
        refreshService: WatchlistRefreshService? = nil,
        undoRemoval: WatchlistUndoRemoval
    ) {
        self.repository = repository
        self.refreshService = refreshService
        self.removalCoordinator = undoRemoval
    }

    func load() async {
        await reload()
    }

    /// Re-reads the watchlist from persistence without flashing the loading
    /// spinner, so `.task(id:)` cancellations cannot strand the list in
    /// `.loading` when the reload token bumps in quick succession.
    func reload() async {
        do {
            let fetched = try await repository.all()
            shows = fetched
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refreshFromNetwork() async {
        await removalCoordinator.commitPendingRemovalIfNeeded()
        await refreshService?.refreshAll(force: true)
        await reload()
    }

    /// Starts the undo window for removing `tracked`. The row stays visible
    /// until the removal is committed or the user confirms with OK.
    func requestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect,
        onCommitted: @escaping () -> Void = {}
    ) {
        removalCoordinator.requestRemoval(tracked, anchor: anchor, onCommitted: onCommitted)
    }

    func undoPendingRemoval() {
        removalCoordinator.undoRemoval()
    }

    func commitPendingRemovalIfNeeded(onCommitted: (() -> Void)? = nil) async {
        let removedID = removalCoordinator.pendingRemoval?.id
        await removalCoordinator.commitPendingRemovalIfNeeded(onCommitted: onCommitted)
        if let removedID, await showWasRemoved(showID: removedID) {
            removeShowAnimated(showID: removedID)
        } else {
            await reload()
        }
    }

    /// Removes a row from the displayed list. Wrap in `withAnimation` at the call
    /// site so SwiftUI can run the standard list removal animation.
    func removeShow(showID: Int) {
        guard let index = shows.firstIndex(where: { $0.id == showID }) else { return }
        shows.remove(at: index)
        state = .loaded
    }

    func removeShowAnimated(showID: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            removeShow(showID: showID)
        }
    }

    private func showWasRemoved(showID: Int) async -> Bool {
        do {
            return try await repository.contains(showID: showID) == false
        } catch {
            return false
        }
    }

    func isPendingRemoval(_ tracked: TrackedShow) -> Bool {
        pendingRemoval?.id == tracked.id
    }
}
