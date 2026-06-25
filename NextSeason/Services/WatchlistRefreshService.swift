//
//  WatchlistRefreshService.swift
//  NextSeason
//

import Foundation

/// Polls TVMaze for watchlist changes and emits notifications when appropriate.
@MainActor
final class WatchlistRefreshService {
    private let tvMaze: any TVMazeService
    private let repository: any WatchlistRepository
    private let notifications: any NotificationDelivering
    private let analytics: any AnalyticsTracking
    private let now: @Sendable () -> Date
    private var lastForegroundRefreshAt: Date?

    init(
        tvMaze: any TVMazeService = TVMazeClient(),
        repository: any WatchlistRepository,
        notifications: any NotificationDelivering = NotificationService(),
        analytics: any AnalyticsTracking = AnalyticsService(),
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.tvMaze = tvMaze
        self.repository = repository
        self.notifications = notifications
        self.analytics = analytics
        self.now = now
    }

    /// Foreground-only refresh that skips network work if a refresh ran recently.
    func refreshAllIfNeeded() async {
        guard RefreshPolicy.shouldPerformForegroundRefresh(
            lastRefreshAt: lastForegroundRefreshAt,
            now: now()
        ) else { return }

        await refreshAll(force: false)
        lastForegroundRefreshAt = now()
    }

    func refreshAll(force: Bool = false) async {
        let trackedShows: [TrackedShow]
        do {
            trackedShows = try await repository.all()
        } catch {
            analytics.trackNonFatalError(error, context: "watchlist_refresh_load")
            return
        }

        guard !trackedShows.isEmpty else { return }

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
                return
            }
        }

        for var tracked in trackedShows {
            if !force {
                guard let updatedAt = updates[tracked.id], updatedAt > tracked.sourceUpdatedAt else { continue }
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
                if let notification = evaluation.notification {
                    await notifications.deliver(notification)
                }
            } catch TVMazeError.notFound {
                tracked.isStale = true
                tracked.lastCheckedAt = now()
                try? await repository.updateAfterRefresh(tracked)
            } catch {
                analytics.trackNonFatalError(error, context: "watchlist_refresh_show")
                continue
            }
        }
    }
}
