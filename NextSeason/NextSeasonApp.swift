//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

@main
struct NextSeasonApp: App {
    private let modelContainer: ModelContainer
    private let watchlistRepository: any WatchlistRepository
    private let refreshService: WatchlistRefreshService
    private let watchlistUndoRemoval: WatchlistUndoRemoval
    private let analyticsService = AnalyticsService()
    private let betaRefreshDiagnostics = BetaRefreshDiagnostics()
    @State private var notificationService: NotificationService
    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var themeController = AppThemeController()

    init() {
        if !UITestingConfiguration.isEnabled {
            AppDiagnosticsLogger.recordAppLaunch()
            MetricKitDiagnosticsSubscriber.installIfNeeded()
        }

        let coordinator = AppNavigationCoordinator()
        _navigationCoordinator = State(initialValue: coordinator)
        _notificationService = State(initialValue: NotificationService(analytics: analyticsService))

        if !UITestingConfiguration.isEnabled {
            NotificationRouting.setCoordinator(coordinator)
            NotificationRouting.setAnalytics(analyticsService)
            NotificationRouting.install()
        }

        do {
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
                repository: repository,
                analytics: analyticsService,
                diagnostics: betaRefreshDiagnostics
            )
            watchlistUndoRemoval = WatchlistUndoRemoval(repository: repository, analytics: analyticsService)
        } catch {
            AppDiagnosticsLogger.logModelContainerInitFailure(error)
            fatalError("Failed to create ModelContainer: \(error)")
        }

        if !UITestingConfiguration.isEnabled {
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
            MainActor.assumeIsolated {
                AppDiagnosticsLogger.breadcrumb("refresh_scheduler_configure")
                RefreshScheduler.configure(diagnostics: betaRefreshDiagnostics) {
                    AppDiagnosticsLogger.logTaskStart("background_watchlist_refresh")
                    await refreshServiceForBackground.refreshAll()
                    AppDiagnosticsLogger.logTaskComplete("background_watchlist_refresh")
                }
                RefreshScheduler.scheduleNextRefresh()
            }
            analyticsService.track(.appLaunched)
        } else {
            #if DEBUG
            FirstRunPreferences.resetSearchResultsHintForTesting()
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                navigationCoordinator: navigationCoordinator,
                undoRemoval: watchlistUndoRemoval,
                refreshService: refreshService
            )
            .environment(themeController)
            .appThemeColors(from: themeController)
            .appThemeIcon(from: themeController)
            .environment(\.watchlistRepository, watchlistRepository)
            .environment(\.watchlistRefreshService, refreshService)
            .environment(\.watchlistUndoRemoval, watchlistUndoRemoval)
            .environment(\.notificationService, notificationService)
            .environment(\.analytics, analyticsService)
            .environment(\.betaRefreshDiagnostics, betaRefreshDiagnostics)
            .task {
                guard let flow = ProfileFlowConfiguration.activeFlow else { return }
                await ProfileFlowRunner(
                    flow: flow,
                    coordinator: navigationCoordinator,
                    repository: watchlistRepository,
                    tvMaze: TVMazeClient(),
                    analytics: analyticsService
                ).run()
            }
        }
        .modelContainer(modelContainer)
    }
}

/// Hosts scene-phase refresh so foreground returns pick up watchlist changes.
private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var navigationCoordinator: AppNavigationCoordinator
    @Bindable var undoRemoval: WatchlistUndoRemoval
    let refreshService: WatchlistRefreshService

    var body: some View {
        ContentView(coordinator: navigationCoordinator, tvMaze: uiTestingTVMazeService)
            // Beta theme switcher lives in each tab's nav bar (see `.betaThemeSwitcherToolbar()`).
            .watchlistUndoToast(
                isPresented: undoRemoval.pendingRemoval != nil,
                anchor: undoRemoval.toastAnchor,
                undoAction: { _ = undoRemoval.undoRemoval() },
                confirmAction: {
                    Task {
                        await undoRemoval.commitPendingRemovalIfNeeded()
                    }
                }
            )
            .onChange(of: scenePhase) { previousPhase, phase in
                guard !UITestingConfiguration.isEnabled else { return }
                AppDiagnosticsLogger.logScenePhase(
                    from: String(describing: previousPhase),
                    to: String(describing: phase)
                )

                if phase == .background {
                    AppDiagnosticsLogger.recordEnterBackground()
                }

                guard phase == .active, previousPhase != .active else { return }
                AppDiagnosticsLogger.breadcrumb("foreground_refresh_scheduled")
                Task {
                    AppDiagnosticsLogger.logTaskStart("foreground_watchlist_refresh")
                    await refreshService.refreshAllIfNeeded()
                    AppDiagnosticsLogger.logTaskComplete("foreground_watchlist_refresh")
                }
            }
    }

    private var uiTestingTVMazeService: any TVMazeService {
        #if DEBUG
        if UITestingConfiguration.isEnabled {
            return PreviewTVMazeService(stub: .preview)
        }
        #endif
        return TVMazeClient()
    }
}
