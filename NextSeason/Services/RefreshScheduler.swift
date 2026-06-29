//
//  RefreshScheduler.swift
//  NextSeason
//

import BackgroundTasks
import Foundation
import os

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
                AppDiagnosticsLogger.logger(for: .tasks)
                    .fault("background_task_unexpected_type")
                task.setTaskCompleted(success: false)
                return
            }

            AppDiagnosticsLogger.breadcrumb("background_task_started")
            scheduleNextRefresh()

            let work = Task { @MainActor in
                AppDiagnosticsLogger.logTaskStart("bg_app_refresh")
                await refreshHandler?()
                guard !Task.isCancelled else {
                    AppDiagnosticsLogger.logTaskCancel("bg_app_refresh")
                    return
                }
                AppDiagnosticsLogger.logTaskComplete("bg_app_refresh")
                refreshTask.setTaskCompleted(success: true)
            }

            refreshTask.expirationHandler = {
                AppDiagnosticsLogger.logger(for: .tasks).notice("background_task_expired")
                AppDiagnosticsLogger.breadcrumb("background_task_expired")
                work.cancel()
                refreshTask.setTaskCompleted(success: false)
            }
        }
    }

    static func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
            AppDiagnosticsLogger.logger(for: .tasks)
                .notice("background_task_scheduled earliest=\(refreshInterval, privacy: .public)s")
            AppDiagnosticsLogger.breadcrumb("background_task_scheduled")
        } catch {
            AppDiagnosticsLogger.logger(for: .tasks)
                .error("background_task_schedule_failed error=\(String(describing: error), privacy: .public)")
        }
    }
}
