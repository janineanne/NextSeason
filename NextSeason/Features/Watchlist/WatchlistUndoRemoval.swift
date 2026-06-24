//
//  WatchlistUndoRemoval.swift
//  NextSeason
//

import Foundation

/// Holds a deferred watchlist removal and its undo window, shared by the
/// watchlist list, show detail, and search flows.
@Observable
@MainActor
final class WatchlistUndoRemoval {
    private(set) var pendingRemoval: TrackedShow?
    private(set) var toastAnchor: CGRect?

    static var undoWindowSeconds: TimeInterval {
        // Keep the undo window long enough for UI tests to find the toast.
        UITestingConfiguration.isEnabled ? 30 : 5
    }

    private let repository: any WatchlistRepository
    private var commitRemovalTask: Task<Void, Never>?
    private var pendingOnCommitted: (() -> Void)?

    init(repository: any WatchlistRepository) {
        self.repository = repository
    }

    /// Removes `tracked` from persistence only after the undo window expires or
    /// `commitPendingRemovalIfNeeded()` runs.
    func requestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect,
        onCommitted: @escaping () -> Void = {}
    ) {
        commitRemovalTask?.cancel()

        if let pending = pendingRemoval, pending.id != tracked.id {
            let previous = pending
            let previousOnCommitted = pendingOnCommitted
            pendingRemoval = nil
            toastAnchor = nil
            pendingOnCommitted = nil
            Task { [weak self] in
                await self?.persistRemoval(previous, onCommitted: previousOnCommitted)
            }
        }

        pendingOnCommitted = onCommitted
        performRequestRemoval(tracked, anchor: anchor)
    }

    /// Cancels the pending removal and returns the restored show, if any.
    @discardableResult
    func undoRemoval() -> TrackedShow? {
        commitRemovalTask?.cancel()
        commitRemovalTask = nil
        guard let tracked = pendingRemoval else { return nil }
        pendingRemoval = nil
        toastAnchor = nil
        pendingOnCommitted = nil
        return tracked
    }

    func commitPendingRemovalIfNeeded(onCommitted: (() -> Void)? = nil) async {
        await commitPendingRemoval(onCommitted: onCommitted)
    }

    private func performRequestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect
    ) {
        pendingRemoval = tracked
        toastAnchor = anchor

        commitRemovalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.undoWindowSeconds))
            guard !Task.isCancelled else { return }
            await self?.commitPendingRemoval()
        }
    }

    private func commitPendingRemoval(onCommitted: (() -> Void)? = nil) async {
        commitRemovalTask?.cancel()
        commitRemovalTask = nil
        guard let tracked = pendingRemoval else { return }
        let callback = onCommitted ?? pendingOnCommitted
        pendingOnCommitted = nil
        await persistRemoval(tracked, onCommitted: callback)
    }

    private func persistRemoval(
        _ tracked: TrackedShow,
        onCommitted: (() -> Void)? = nil
    ) async {
        do {
            try await repository.remove(showID: tracked.id)
            if pendingRemoval?.id == tracked.id {
                pendingRemoval = nil
                toastAnchor = nil
            }
            onCommitted?()
        } catch is CancellationError {
            return
        } catch {
            if pendingRemoval?.id == tracked.id {
                pendingRemoval = nil
                toastAnchor = nil
            }
        }
    }
}
