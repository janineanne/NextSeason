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
    @State private var notificationService = NotificationService()
    @State private var navigationCoordinator = AppNavigationCoordinator()

    init() {
        _notificationService = State(initialValue: NotificationService())
        _navigationCoordinator = State(initialValue: AppNavigationCoordinator())

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
            refreshService = WatchlistRefreshService(repository: repository)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        if !UITestingConfiguration.isEnabled {
            RefreshScheduler.registerBackgroundTask()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                navigationCoordinator: navigationCoordinator,
                refreshService: refreshService
            )
            .environment(\.watchlistRepository, watchlistRepository)
            .environment(\.watchlistRefreshService, refreshService)
            .environment(\.notificationService, notificationService)
            .task {
                guard !UITestingConfiguration.isEnabled else { return }
                NotificationRouting.coordinator = navigationCoordinator
                NotificationRouting.install()
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
    let refreshService: WatchlistRefreshService

    var body: some View {
        ContentView(coordinator: navigationCoordinator, tvMaze: uiTestingTVMazeService)
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
