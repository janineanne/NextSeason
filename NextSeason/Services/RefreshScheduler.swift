//
//  RefreshScheduler.swift
//  NextSeason
//

import BackgroundTasks
import Foundation
import os

/// Schedules best-effort background watchlist refresh (~12h production, 10m soak-test cadence).
enum RefreshScheduler {
    static let taskIdentifier = "com.TrialByFyre.NextSeason.watchlist-refresh"

    @MainActor private static var refreshHandler: (() async -> Void)?
    @MainActor private static var diagnostics: BetaRefreshDiagnostics?

    @MainActor
    static func configure(
        diagnostics: BetaRefreshDiagnostics? = nil,
        refreshHandler: @escaping () async -> Void
    ) {
        self.diagnostics = diagnostics
        self.refreshHandler = refreshHandler
    }

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: .main
        ) { task in
            MainActor.assumeIsolated {
                handleAppRefresh(task)
            }
        }
    }

    @MainActor
    private static func handleAppRefresh(_ task: BGTask) {
        guard let refreshTask = task as? BGAppRefreshTask else {
            AppDiagnosticsLogger.logger(for: .tasks)
                .fault("background_task_unexpected_type")
            task.setTaskCompleted(success: false)
            return
        }

        let completion = BackgroundRefreshCompletion(refreshTask: refreshTask)

        AppDiagnosticsLogger.breadcrumb("background_task_started")
        scheduleNextRefresh()

        let work = Task {
            AppDiagnosticsLogger.logTaskStart("bg_app_refresh")
            await refreshHandler?()
            if Task.isCancelled {
                AppDiagnosticsLogger.logTaskCancel("bg_app_refresh")
                completion.finish(success: false)
            } else {
                AppDiagnosticsLogger.logTaskComplete("bg_app_refresh")
                completion.finish(success: true)
            }
        }

        refreshTask.expirationHandler = {
            AppDiagnosticsLogger.logger(for: .tasks).notice("background_task_expired")
            AppDiagnosticsLogger.breadcrumb("background_task_expired")
            work.cancel()
            completion.finish(success: false)
        }
    }

    static func scheduleNextRefresh() {
        let interval = BackgroundRefreshConfiguration.refreshInterval
        let nextRefreshAt = Date(timeIntervalSinceNow: interval)
        MainActor.assumeIsolated {
            diagnostics?.recordNextScheduledRefresh(at: nextRefreshAt)
        }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = nextRefreshAt
        do {
            try BGTaskScheduler.shared.submit(request)
            AppDiagnosticsLogger.logger(for: .tasks)
                .notice(
                    """
                    background_task_scheduled earliest=\(interval, privacy: .public)s \
                    accelerated=\(BackgroundRefreshConfiguration.isAccelerated, privacy: .public)
                    """
                )
            AppDiagnosticsLogger.breadcrumb("background_task_scheduled")
        } catch {
            AppDiagnosticsLogger.logger(for: .tasks)
                .error("background_task_schedule_failed error=\(String(describing: error), privacy: .public)")
        }
    }
}

// MARK: - Completion guard

/// Ensures `BGAppRefreshTask.setTaskCompleted` is invoked at most once.
private final class BackgroundRefreshCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false
    private let refreshTask: BGAppRefreshTask

    init(refreshTask: BGAppRefreshTask) {
        self.refreshTask = refreshTask
    }

    func finish(success: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard !finished else { return }
        finished = true
        refreshTask.setTaskCompleted(success: success)
    }
}
