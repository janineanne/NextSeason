//
//  WatchlistPendingRemoval.swift
//  NextSeason
//

import Foundation

/// Holds a deferred watchlist removal and its undo window, shared by the
/// watchlist list, show detail, and search flows.
@Observable
@MainActor
final class WatchlistPendingRemoval {
    private(set) var pendingRemoval: TrackedShow?
    private(set) var toastAnchor: CGRect?
    /// Set when deferred persistence fails after the undo window ends.
    private(set) var removalErrorMessage: String?

    static var undoWindowSeconds: TimeInterval {
        AccessibilityPreferences.undoRemovalWindowSeconds()
    }

    private let repository: any WatchlistRepository
    private let analytics: any AnalyticsTracking
    private var commitRemovalTask: Task<Void, Never>?
    private var pendingOnCommitted: (() -> Void)?
    private var pendingRemovalSource: WatchlistActionSource?

    /// Test override for the undo window; nil uses the accessibility-aware default.
    var undoWindowSecondsOverride: TimeInterval?

    private var undoWindowSeconds: TimeInterval {
        undoWindowSecondsOverride ?? Self.undoWindowSeconds
    }

    init(repository: any WatchlistRepository, analytics: any AnalyticsTracking) {
        self.repository = repository
        self.analytics = analytics
    }

    func clearRemovalError() {
        removalErrorMessage = nil
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
        removalErrorMessage = nil

        // Only one undo window at a time: commit the previous show immediately
        // so its removal is not lost when the user untracks another.
        if let pending = pendingRemoval, pending.id != tracked.id {
            let previous = pending
            let previousSource = pendingRemovalSource ?? .watchlist
            let previousOnCommitted = pendingOnCommitted
            pendingRemoval = nil
            toastAnchor = nil
            pendingRemovalSource = nil
            pendingOnCommitted = nil
            Task { [weak self] in
                await self?.persistRemoval(
                    previous, source: previousSource, onCommitted: previousOnCommitted)
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

    /// Forces any in-flight undoable removal to persist now (e.g. before refresh
    /// or leaving a screen where the toast would otherwise outlive the context).
    func commitPendingRemovalIfNeeded(onCommitted: (() -> Void)? = nil) async {
        await commitPendingRemoval(cancelTimer: true, onCommitted: onCommitted)
    }

    private func performRequestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect
    ) {
        pendingRemoval = tracked
        toastAnchor = anchor

        AppDiagnosticsLogger.logTaskStart("undo_removal_timer")
        commitRemovalTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.undoWindowSeconds))
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("undo_removal_timer")
                return
            }
            // Do not cancel this task from inside `commitPendingRemoval` — a
            // cancellation-aware repository would otherwise abort the remove.
            await self.commitPendingRemoval(cancelTimer: false)
            AppDiagnosticsLogger.logTaskComplete("undo_removal_timer")
        }
    }

    private func commitPendingRemoval(
        cancelTimer: Bool,
        onCommitted: (() -> Void)? = nil
    ) async {
        if cancelTimer {
            commitRemovalTask?.cancel()
        }
        commitRemovalTask = nil

        guard let tracked = pendingRemoval else { return }

        let source = pendingRemovalSource ?? .watchlist
        let callback = onCommitted ?? pendingOnCommitted

        // End the undo window as soon as commit begins so Undo cannot race with
        // an in-flight `repository.remove`.
        //
        // Note for future cloud / suspending persistence: clearing `pendingRemoval`
        // here means Search/Detail may refresh while the show is still persisted
        // and briefly treat it as tracked again. A richer model that distinguishes
        // `.pending` from `.committing(showID:)` would keep both states untracked
        // for effective-tracking until delete finishes. Not needed for the local
        // SwiftData repository, which completes remove before observation resumes.
        pendingRemoval = nil
        toastAnchor = nil
        pendingOnCommitted = nil
        pendingRemovalSource = nil

        await persistRemoval(
            tracked,
            source: source,
            onCommitted: callback
        )
    }

    private func persistRemoval(
        _ tracked: TrackedShow,
        source: WatchlistActionSource,
        onCommitted: (() -> Void)? = nil
    ) async {
        // After the undo window ends, finish persistence even if the SwiftUI /
        // lifecycle task that started commit is cancelled (tab switch, refresh).
        await Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.repository.remove(showID: tracked.id)
                // Defensive: also covers the replace-pending path which persists a
                // prior show without going through `commitPendingRemoval`.
                if self.pendingRemoval?.id == tracked.id {
                    self.pendingRemoval = nil
                    self.toastAnchor = nil
                }
                self.analytics.track(.watchlistRemoved(source: source, showID: tracked.id))
                onCommitted?()
            } catch {
                // This task is unstructured, so caller cancellation should not
                // reach here. Any failure (including unexpected cancellation)
                // surfaces so the user can retry.
                self.analytics.trackNonFatalError(error, context: "watchlist_remove")
                self.removalErrorMessage = WatchlistTracking.updateFailedMessage
                if self.pendingRemoval?.id == tracked.id {
                    self.pendingRemoval = nil
                    self.toastAnchor = nil
                }
            }
        }.value
    }
}
