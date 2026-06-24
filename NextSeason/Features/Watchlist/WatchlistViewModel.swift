//
//  WatchlistViewModel.swift
//  NextSeason
//

import Foundation

@Observable
@MainActor
final class WatchlistViewModel {
    enum State: Equatable {
        case loading
        case loaded([TrackedShow])
        case failed(String)
    }

    private(set) var state: State = .loaded([])

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
            let shows = try await repository.all()
            state = .loaded(shows)
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
        await removalCoordinator.commitPendingRemovalIfNeeded(onCommitted: onCommitted)
        await reload()
    }

    func isPendingRemoval(_ tracked: TrackedShow) -> Bool {
        pendingRemoval?.id == tracked.id
    }
}
