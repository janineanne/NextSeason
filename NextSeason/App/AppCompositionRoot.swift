//
//  AppCompositionRoot.swift
//  NextSeason
//

import SwiftData
import SwiftUI

/// Builds long-lived app services and persistence so `NextSeasonApp` stays readable.
@MainActor
struct AppCompositionRoot {
    let modelContainer: ModelContainer
    let watchlistRepository: any WatchlistRepository
    let refreshService: WatchlistRefreshService
    let watchlistUndoRemoval: WatchlistUndoRemoval
    let analyticsService: AnalyticsService
    let notificationService: NotificationService
    let betaRefreshDiagnostics: BetaRefreshDiagnostics
    let tvMaze: any TVMazeService

    init() throws {
        analyticsService = AnalyticsService()
        notificationService = NotificationService(analytics: analyticsService)
        betaRefreshDiagnostics = BetaRefreshDiagnostics()
        tvMaze = TVMazeClient()

        let repository: any WatchlistRepository
        if UITestingConfiguration.isEnabled {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(
                for: TrackedShowEntity.self,
                configurations: configuration
            )
            repository = InMemoryWatchlistRepository()
        } else {
            let container = try ModelContainer(for: TrackedShowEntity.self)
            modelContainer = container
            repository = SwiftDataWatchlistRepository(context: ModelContext(container))
        }

        watchlistRepository = repository
        refreshService = WatchlistRefreshService(
            tvMaze: tvMaze,
            repository: repository,
            notifications: notificationService,
            analytics: analyticsService,
            diagnostics: betaRefreshDiagnostics
        )
        watchlistUndoRemoval = WatchlistUndoRemoval(
            repository: repository,
            analytics: analyticsService
        )
    }

    func configureNonUITestRuntime() {
        AppDiagnosticsLogger.recordAppLaunch()
        MetricKitDiagnosticsSubscriber.installIfNeeded()

        // The tap coordinator is attached from the view layer (see ContentView) so
        // routing always targets the exact AppNavigationCoordinator instance SwiftUI
        // observes. Installing the delegate here lets a launch-from-notification tap
        // buffer until the coordinator attaches.
        NotificationRouting.setAnalytics(analyticsService)
        NotificationRouting.install()

        configureBackgroundRefresh()
        analyticsService.track(.appLaunched)
    }

    private func configureBackgroundRefresh() {
        if BackgroundRefreshConfiguration.forceAcceleratedForSoakTest
            || ProcessInfo.processInfo.arguments.contains(BackgroundRefreshConfiguration.launchFlag)
        {
            BackgroundRefreshConfiguration.persistAcceleratedModeIfRequested()
            if BackgroundRefreshConfiguration.isAccelerated {
                AppDiagnosticsLogger.breadcrumb("background_refresh_accelerated_10m")
            }
        } else {
            BackgroundRefreshConfiguration.clearPersistedAcceleratedMode()
        }

        RefreshScheduler.registerBackgroundTask()
        let refreshServiceForBackground = refreshService
        AppDiagnosticsLogger.breadcrumb("refresh_scheduler_configure")
        RefreshScheduler.configure(diagnostics: betaRefreshDiagnostics) {
            AppDiagnosticsLogger.logTaskStart("background_watchlist_refresh")
            await refreshServiceForBackground.refreshAll(recordDiagnostics: true)
            AppDiagnosticsLogger.logTaskComplete("background_watchlist_refresh")
        }
        RefreshScheduler.scheduleNextRefresh()
    }
}
