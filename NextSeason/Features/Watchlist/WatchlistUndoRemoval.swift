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
        AccessibilityPreferences.undoRemovalWindowSeconds()
    }

    private let repository: any WatchlistRepository
    private let analytics: any AnalyticsTracking
    private var commitRemovalTask: Task<Void, Never>?
    private var pendingOnCommitted: (() -> Void)?
    private var pendingRemovalSource: WatchlistActionSource?

    init(repository: any WatchlistRepository, analytics: any AnalyticsTracking) {
        self.repository = repository
        self.analytics = analytics
    }

    /// Removes `tracked` from persistence only after the undo window expires or
    /// `commitPendingRemovalIfNeeded()` runs.
    func requestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect,
        source: WatchlistActionSource,
        onCommitted: @escaping () -> Void = {}
    ) {
        commitRemovalTask?.cancel()
        AppDiagnosticsLogger.logTaskCancel("undo_removal_timer")

        if let pending = pendingRemoval, pending.id != tracked.id {
            let previous = pending
            let previousSource = pendingRemovalSource ?? .watchlist
            let previousOnCommitted = pendingOnCommitted
            pendingRemoval = nil
            toastAnchor = nil
            pendingRemovalSource = nil
            pendingOnCommitted = nil
            Task { [weak self] in
                await self?.persistRemoval(previous, source: previousSource, onCommitted: previousOnCommitted)
            }
        }

        pendingOnCommitted = onCommitted
        pendingRemovalSource = source
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
        pendingRemovalSource = nil
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

        AppDiagnosticsLogger.logTaskStart("undo_removal_timer")
        commitRemovalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.undoWindowSeconds))
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("undo_removal_timer")
                return
            }
            await self?.commitPendingRemoval()
            AppDiagnosticsLogger.logTaskComplete("undo_removal_timer")
        }
    }

    private func commitPendingRemoval(onCommitted: (() -> Void)? = nil) async {
        commitRemovalTask?.cancel()
        commitRemovalTask = nil
        guard let tracked = pendingRemoval else { return }
        let source = pendingRemovalSource ?? .watchlist
        let callback = onCommitted ?? pendingOnCommitted
        pendingOnCommitted = nil
        pendingRemovalSource = nil
        await persistRemoval(tracked, source: source, onCommitted: callback)
    }

    private func persistRemoval(
        _ tracked: TrackedShow,
        source: WatchlistActionSource,
        onCommitted: (() -> Void)? = nil
    ) async {
        do {
            try await repository.remove(showID: tracked.id)
            if pendingRemoval?.id == tracked.id {
                pendingRemoval = nil
                toastAnchor = nil
            }
            analytics.track(.watchlistRemoved(source: source, showID: tracked.id))
            onCommitted?()
        } catch is CancellationError {
            return
        } catch {
            analytics.trackNonFatalError(error, context: "watchlist_remove")
            if pendingRemoval?.id == tracked.id {
                pendingRemoval = nil
                toastAnchor = nil
            }
        }
    }
}
