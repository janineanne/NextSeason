//
//  RefreshScheduler.swift
//  NextSeason
//

import BackgroundTasks
import Foundation

/// Schedules best-effort background watchlist refresh (~12h target cadence).
enum RefreshScheduler {
    static let taskIdentifier = "com.TrialByFyre.NextSeason.watchlist-refresh"
    private static let refreshInterval: TimeInterval = 12 * 60 * 60

    @MainActor private static var refreshHandler: (() async -> Void)?

    @MainActor
    static func configure(refreshHandler: @escaping () async -> Void) {
        self.refreshHandler = refreshHandler
    }

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            scheduleNextRefresh()

            let work = Task { @MainActor in
                await refreshHandler?()
                refreshTask.setTaskCompleted(success: true)
            }

            refreshTask.expirationHandler = {
                work.cancel()
            }
        }
    }

    static func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        try? BGTaskScheduler.shared.submit(request)
    }
}
