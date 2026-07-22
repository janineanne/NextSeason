//
//  WatchlistRefreshService.swift
//  NextSeason
//

import Foundation
import os

struct WatchlistRefreshOutcome: Sendable, Equatable {
    let fetchResult: String
    let notificationDecision: String
}

/// Polls TVMaze for watchlist changes and emits notifications when appropriate.
///
/// Remains `@MainActor` because `WatchlistRepository` is MainActor-bound for SwiftData;
/// network work still runs off the actor while awaiting `TVMazeService`.
@MainActor
final class WatchlistRefreshService {
    private let tvMaze: any TVMazeService
    private let repository: any WatchlistRepository
    private let notifications: any NotificationDelivering
    private let analytics: any AnalyticsTracking
    private let diagnostics: BetaRefreshDiagnostics?
    private let now: @Sendable () -> Date
    private var lastForegroundRefreshAt: Date?

    init(
        tvMaze: any TVMazeService,
        repository: any WatchlistRepository,
        notifications: any NotificationDelivering,
        analytics: any AnalyticsTracking,
        diagnostics: BetaRefreshDiagnostics? = nil,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.tvMaze = tvMaze
        self.repository = repository
        self.notifications = notifications
        self.analytics = analytics
        self.diagnostics = diagnostics
        self.now = now
    }

    /// Foreground-only refresh that skips network work if a refresh ran recently.
    func refreshAllIfNeeded() async {
        guard RefreshPolicy.shouldPerformForegroundRefresh(
            lastRefreshAt: lastForegroundRefreshAt,
            now: now()
        ) else {
            AppDiagnosticsLogger.logger(for: .cache).notice("watchlist_refresh_skipped policy")
            return
        }

        AppDiagnosticsLogger.breadcrumb("watchlist_refresh_foreground")
        await refreshAll(force: false)
        lastForegroundRefreshAt = now()
    }

    /// - Parameter force: When true, re-fetches every tracked show instead of
    ///   consulting TVMaze's updates map.
    /// - Parameter deliverNotifications: When false, status is still updated and
    ///   dedupe signatures recorded, but no local notification is scheduled.
    ///   Use for interactive pull-to-refresh where the user can see the list.
    /// - Parameter recordDiagnostics: When true, writes a beta diagnostics sample.
    @discardableResult
    func refreshAll(
        force: Bool = false,
        deliverNotifications: Bool = true,
        recordDiagnostics: Bool = false
    ) async -> WatchlistRefreshOutcome? {
        AppDiagnosticsLogger.logger(for: .cache)
            .notice("watchlist_refresh_start force=\(force, privacy: .public) notify=\(deliverNotifications, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("watchlist_refresh_start")
        var fetchResult = "Completed"
        var lastNotificationDecision = "No notification (no meaningful change)"
        var refreshedShowCount = 0
        var skippedShowCount = 0

        let trackedShows: [TrackedShow]
        do {
            trackedShows = try await repository.all()
        } catch {
            if error is CancellationError {
                AppDiagnosticsLogger.logTaskCancel("watchlist_refresh")
                return nil
            }
            analytics.trackNonFatalError(error, context: "watchlist_refresh_load")
            recordBackgroundDiagnosticsIfNeeded(
                recordDiagnostics,
                fetchResult: "Failed to load watchlist",
                notificationDecision: lastNotificationDecision
            )
            return WatchlistRefreshOutcome(
                fetchResult: "Failed to load watchlist",
                notificationDecision: lastNotificationDecision
            )
        }

        guard !trackedShows.isEmpty else {
            AppDiagnosticsLogger.logger(for: .cache).notice("watchlist_refresh_complete empty_watchlist")
            AppDiagnosticsLogger.breadcrumb("watchlist_refresh_complete")
            let outcome = WatchlistRefreshOutcome(
                fetchResult: "Skipped: empty watchlist",
                notificationDecision: lastNotificationDecision
            )
            recordBackgroundDiagnosticsIfNeeded(
                recordDiagnostics,
                fetchResult: outcome.fetchResult,
                notificationDecision: outcome.notificationDecision
            )
            return outcome
        }

        let updates: [Int: Date]
        if force {
            updates = [:]
        } else {
            let oldestCheck = trackedShows.map(\.lastCheckedAt).min() ?? now()
            let period = TVMazeUpdatePeriod.covering(since: oldestCheck, now: now())
            do {
                updates = try await tvMaze.updatedShows(since: period)
            } catch {
                analytics.trackNonFatalError(error, context: "watchlist_refresh_updates")
                recordBackgroundDiagnosticsIfNeeded(
                    recordDiagnostics,
                    fetchResult: "Failed to fetch TVMaze updates",
                    notificationDecision: lastNotificationDecision
                )
                return WatchlistRefreshOutcome(
                    fetchResult: "Failed to fetch TVMaze updates",
                    notificationDecision: lastNotificationDecision
                )
            }
        }

        for var tracked in trackedShows {
            if !force {
                let serverChanged = updates[tracked.id].map { $0 > tracked.sourceUpdatedAt } ?? false
                // `nextSeason` also depends on the calendar (airing → returning when a
                // season ends, scheduled → airing on premiere). Search-track used to
                // persist `.returningNoSeasonYet` without season data; re-check that
                // case even when TVMaze's `updated` epoch is unchanged.
                let needsRecheck = Self.needsCalendarOrStatusRecheck(tracked.nextSeason)
                guard serverChanged || needsRecheck else {
                    skippedShowCount += 1
                    continue
                }
            }

            do {
                let show = try await tvMaze.show(id: tracked.id, bypassCache: true)
                tracked.isStale = false
                tracked.name = show.name
                tracked.posterMediumURL = show.posterMediumURL
                tracked.summaryHTML = show.summaryHTML
                tracked.tvMazeURL = show.tvMazeURL
                tracked.status = show.status
                tracked.sourceUpdatedAt = show.updatedAt

                let newStatus = NextSeasonCalculator.status(for: show, now: now())
                let evaluation = StatusChangeDetector.evaluate(tracked: tracked, newStatus: newStatus, now: now())

                try await repository.updateAfterRefresh(evaluation.tracked)
                refreshedShowCount += 1
                lastNotificationDecision = Self.describeNotificationDecision(
                    for: tracked.name,
                    evaluation: evaluation,
                    deliverNotifications: deliverNotifications
                )
                if deliverNotifications, let notification = evaluation.notification {
                    await notifications.deliver(notification)
                }
            } catch is CancellationError {
                AppDiagnosticsLogger.logTaskCancel("watchlist_refresh_show")
                return nil
            } catch TVMazeError.notFound {
                tracked.isStale = true
                tracked.lastCheckedAt = now()
                try? await repository.updateAfterRefresh(tracked)
                refreshedShowCount += 1
                lastNotificationDecision = "Marked stale: \(tracked.name) not found on TVMaze"
            } catch {
                analytics.trackNonFatalError(error, context: "watchlist_refresh_show")
                continue
            }
        }

        if refreshedShowCount == 0, skippedShowCount > 0 {
            fetchResult = "No TVMaze changes for \(skippedShowCount) tracked show(s)"
        } else {
            fetchResult = "Refreshed \(refreshedShowCount) show(s)"
            if skippedShowCount > 0 {
                fetchResult += ", skipped \(skippedShowCount) unchanged"
            }
            if force {
                fetchResult += " (forced)"
            }
        }

        let outcome = WatchlistRefreshOutcome(
            fetchResult: fetchResult,
            notificationDecision: lastNotificationDecision
        )
        recordBackgroundDiagnosticsIfNeeded(
            recordDiagnostics,
            fetchResult: outcome.fetchResult,
            notificationDecision: outcome.notificationDecision
        )
        AppDiagnosticsLogger.logger(for: .cache).notice("watchlist_refresh_complete")
        AppDiagnosticsLogger.breadcrumb("watchlist_refresh_complete")
        return outcome
    }

    private func recordBackgroundDiagnosticsIfNeeded(
        _ recordDiagnostics: Bool,
        fetchResult: String,
        notificationDecision: String
    ) {
        guard recordDiagnostics else { return }
        diagnostics?.recordBackgroundRefreshCompleted(
            at: now(),
            fetchResult: fetchResult,
            notificationDecision: notificationDecision
        )
    }

    private static func describeNotificationDecision(
        for showName: String,
        evaluation: StatusChangeDetector.Evaluation,
        deliverNotifications: Bool
    ) -> String {
        if let notification = evaluation.notification {
            if deliverNotifications {
                return "Delivered for \(showName): \(notification.body)"
            }
            return "Suppressed for \(showName) (interactive refresh): \(notification.body)"
        }
        if evaluation.tracked.pendingChangeSignature != nil {
            return "Pending debounce for \(showName)"
        }
        return "No notification for \(showName) (no meaningful change)"
    }

    /// Statuses that can change without TVMaze bumping `updated` (calendar drift,
    /// or a previously incomplete `.returningNoSeasonYet` snapshot).
    private static func needsCalendarOrStatusRecheck(_ status: NextSeasonStatus) -> Bool {
        switch status {
        case .airing, .scheduled, .returningNoSeasonYet:
            true
        case .announcedUndated, .ended, .unknown:
            false
        }
    }
}
