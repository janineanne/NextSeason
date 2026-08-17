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
    /// Canonical show / season provider (detail, watchlist, refresh).
    let tvMaze: any TVMazeService
    /// Guest search provider (paginated series search only).
    let theTVDB: any TheTVDBService
    /// Offline TheTVDB → TVMaze filter and TVMaze title/poster overlay for Search.
    let showIDMapping: any ShowIDMapping
    /// Opportunistic on-device mapping refresh; `nil` under UI tests.
    let showIDMappingRefresh: ShowIDMappingRefreshService?

    init() throws {
        analyticsService = AnalyticsService()
        notificationService = NotificationService(analytics: analyticsService)
        betaRefreshDiagnostics = BetaRefreshDiagnostics()
        let liveTVMaze = TVMazeClient()  // needed later in this function
        tvMaze = liveTVMaze
        theTVDB = TheTVDBClient()

        let repository: any WatchlistRepository
        if UITestingConfiguration.isEnabled {
            // XCUITest: in-memory store + repository so runs stay isolated and don't
            // touch the developer's on-device watchlist.
            modelContainer = try NextSeasonModelContainer.make(
                configuration: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            repository = InMemoryWatchlistRepository()
            // Severance preview ids used by UI tests / PreviewTheTVDBService.
            showIDMapping = InMemoryShowIDMapping(map: [371980: 44933])
            showIDMappingRefresh = nil
        } else {
            modelContainer = try NextSeasonModelContainer.make()
            repository = SwiftDataWatchlistRepository(context: ModelContext(modelContainer))
            let database = try ShowIDMappingDatabase.openDefault()
            showIDMapping = database
            showIDMappingRefresh = ShowIDMappingRefreshService(
                database: database,
                tvMaze: liveTVMaze
            )
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

    /// Production-only launch wiring: diagnostics, MetricKit, notification
    /// routing, background refresh registration, and the launch analytics event.
    /// Skipped under `-UITesting` so XCUITests stay deterministic.
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

    /// Opportunistic show ID mapping refresh; never blocks launch or Search.
    func refreshShowIDMappingIfNeeded() async {
        await showIDMappingRefresh?.refreshIfNeeded()
    }

    /// Registers the ~12h background watchlist refresh task and schedules the
    /// next run. Show ID mapping refresh stays foreground-only.
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
