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
    @State private var notificationService: NotificationService
    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var themeController = AppThemeController()

    init() {
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
            refreshService = WatchlistRefreshService(repository: repository, analytics: analyticsService)
            watchlistUndoRemoval = WatchlistUndoRemoval(repository: repository, analytics: analyticsService)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        if !UITestingConfiguration.isEnabled {
            RefreshScheduler.registerBackgroundTask()
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
            .environment(\.watchlistRepository, watchlistRepository)
            .environment(\.watchlistRefreshService, refreshService)
            .environment(\.watchlistUndoRemoval, watchlistUndoRemoval)
            .environment(\.notificationService, notificationService)
            .environment(\.analytics, analyticsService)
            .task {
                guard !UITestingConfiguration.isEnabled else { return }
                RefreshScheduler.configure {
                    await refreshService.refreshAll()
                }
                RefreshScheduler.scheduleNextRefresh()
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
            // Beta: theme switcher left enabled for palette feedback. Before portfolio release,
            // wrap in #if DEBUG or remove — see Release Readiness.md § Portfolio Readiness.
            // #if DEBUG
            .overlay(alignment: .bottomTrailing) {
                if !UITestingConfiguration.isEnabled {
                    ThemeSwitcherButton()
                }
            }
            // #endif
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
                guard phase == .active, previousPhase != .active else { return }
                guard !UITestingConfiguration.isEnabled else { return }
                Task { await refreshService.refreshAllIfNeeded() }
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
