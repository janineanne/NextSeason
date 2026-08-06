//
//  WatchlistPendingRemoval.swift
//  NextSeason
//

import Foundation

/// Holds a watchlist removal undo window, shared by the watchlist list, show
/// detail, and search flows.
///
/// Two presentation modes:
/// - **Deferred** (star / detail / search): row stays until the window ends or
///   the user confirms; persistence runs on commit.
/// - **Immediate** (swipe-to-delete): persistence runs right away and the toast
///   is informational; Undo restores the show.
@Observable
@MainActor
final class WatchlistPendingRemoval {
    private enum Mode {
        case deferred
        case immediate
    }

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
    private var pendingMode: Mode = .deferred

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

        // Only one undo window at a time: finalize the previous show so its
        // removal is not lost when the user untracks another.
        finalizeReplacedPendingRemoval()

        pendingMode = .deferred
        pendingOnCommitted = onCommitted
        pendingRemovalSource = source
        performRequestRemoval(tracked, anchor: anchor)
    }

    /// Persists removal immediately, then shows the undo toast. Undo restores
    /// the show to the repository; OK / timeout only dismisses the toast.
    ///
    /// Callers should update list UI synchronously before invoking this so
    /// `List` + `.onDelete` stay consistent.
    func requestImmediateRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect,
        source: WatchlistActionSource,
        onCommitted: @escaping () -> Void = {},
        onFailure: @escaping () -> Void = {}
    ) {
        commitRemovalTask?.cancel()
        AppDiagnosticsLogger.logTaskCancel("undo_removal_timer")
        removalErrorMessage = nil

        finalizeReplacedPendingRemoval()

        pendingMode = .immediate
        pendingOnCommitted = nil
        pendingRemovalSource = source
        pendingRemoval = tracked
        toastAnchor = anchor

        AppDiagnosticsLogger.logTaskStart("immediate_removal")
        commitRemovalTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.repository.remove(showID: tracked.id)
                self.analytics.track(.watchlistRemoved(source: source, showID: tracked.id))
                onCommitted()
            } catch {
                self.analytics.trackNonFatalError(error, context: "watchlist_remove")
                self.removalErrorMessage = WatchlistTracking.updateFailedMessage
                self.clearPendingPresentation()
                onFailure()
                AppDiagnosticsLogger.logTaskComplete("immediate_removal")
                return
            }

            // Informational toast window — dismiss only; already persisted.
            try? await Task.sleep(for: .seconds(self.undoWindowSeconds))
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("immediate_removal")
                return
            }
            guard self.pendingRemoval?.id == tracked.id else { return }
            self.clearPendingPresentation()
            AppDiagnosticsLogger.logTaskComplete("immediate_removal")
        }
    }

    /// Cancels a deferred removal, or restores an immediately deleted show.
    @discardableResult
    func undoRemoval() async -> TrackedShow? {
        commitRemovalTask?.cancel()
        commitRemovalTask = nil
        guard let tracked = pendingRemoval else { return nil }
        let mode = pendingMode

        if mode == .immediate {
            do {
                try await restore(tracked)
            } catch {
                analytics.trackNonFatalError(error, context: "watchlist_restore")
                removalErrorMessage = WatchlistTracking.updateFailedMessage
                return nil
            }
        }

        clearPendingPresentation()
        return tracked
    }

    /// Dismisses the toast when navigating away. Deferred removals are cancelled
    /// (still persisted, so the show stays tracked). Immediate removals keep the
    /// delete and only hide the toast.
    func dismissPendingRemovalForNavigation() {
        guard pendingRemoval != nil else { return }
        commitRemovalTask?.cancel()
        commitRemovalTask = nil
        clearPendingPresentation()
    }

    /// Forces any in-flight undoable removal to its terminal state (e.g. before
    /// refresh or leaving a screen where the toast would otherwise outlive the
    /// context). Deferred: persists. Immediate: dismisses toast only.
    func commitPendingRemovalIfNeeded(onCommitted: (() -> Void)? = nil) async {
        await commitPendingRemoval(cancelTimer: true, onCommitted: onCommitted)
    }

    private func finalizeReplacedPendingRemoval() {
        guard let pending = pendingRemoval else { return }
        let previous = pending
        let previousSource = pendingRemovalSource ?? .watchlist
        let previousOnCommitted = pendingOnCommitted
        let previousMode = pendingMode
        clearPendingPresentation()

        if previousMode == .deferred {
            Task { [weak self] in
                await self?.persistRemoval(
                    previous, source: previousSource, onCommitted: previousOnCommitted)
            }
        }
        // Immediate replacements are already persisted; nothing to do.
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

        if pendingMode == .immediate {
            clearPendingPresentation()
            return
        }

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
        clearPendingPresentation()

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
                    self.clearPendingPresentation()
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
                    self.clearPendingPresentation()
                }
            }
        }.value
    }

    /// Re-inserts a previously tracked show, preserving next-season and refresh fields.
    private func restore(_ tracked: TrackedShow) async throws {
        try await repository.add(Show(tracked: tracked))
        try await repository.updateAfterRefresh(tracked)
    }

    private func clearPendingPresentation() {
        pendingRemoval = nil
        toastAnchor = nil
        pendingOnCommitted = nil
        pendingRemovalSource = nil
        pendingMode = .deferred
    }
}
