//
//  AppCompositionRoot.swift
//  NextSeason
//

import SwiftData
import SwiftUI

/// Extracted from `NextSeasonApp` to handle the building of long-lived app services and persistence so
/// `NextSeasonApp` stays readable.
@MainActor
struct AppCompositionRoot {
    let modelContainer: ModelContainer
    let watchlistRepository: any WatchlistRepository
    let refreshService: WatchlistRefreshService
    let watchlistPendingRemoval: WatchlistPendingRemoval
    let analyticsService: AnalyticsService
    let notificationService: NotificationService
    let betaRefreshDiagnostics: BetaRefreshDiagnostics
    let tvMaze: any TVMazeService
    let theTVDB: any TheTVDBService

    init() throws {
        analyticsService = AnalyticsService()
        notificationService = NotificationService(analytics: analyticsService)
        betaRefreshDiagnostics = BetaRefreshDiagnostics()
        tvMaze = TVMazeClient()
        theTVDB = TheTVDBClient()

        let repository: any WatchlistRepository
        if UITestingConfiguration.isEnabled {
            // XCUITest: in-memory store + repository so runs stay isolated and don't
            // touch the developer's on-device watchlist.
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
        watchlistPendingRemoval = WatchlistPendingRemoval(
            repository: repository,
            analytics: analyticsService
        )
    }

    func configureNonUITestRuntime() {
        AppDiagnosticsLogger.recordAppLaunch()
        MetricKitDiagnosticsSubscriber.installIfNeeded()

        // The coordinator that handles notification taps is attached from the view
        // layer (see ContentView). NotificationRouting is set up here and is able to
        // handle taps before ContentView is able to set the coordinator. Installing
        // the delegate here lets a launch-from-notification tap buffer until the
        // coordinator attaches.
        NotificationRouting.setAnalytics(analyticsService)
        NotificationRouting.installDelegate()

        configureBackgroundRefresh()
        analyticsService.track(.appLaunched)
    }

    // registers the ~12h background watchlist refresh task (aka background refresh)
    private func configureBackgroundRefresh() {
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
