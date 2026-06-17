//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

@main
struct NextSeasonApp: App {
    private let modelContainer: ModelContainer
    @State private var watchlistRepository: SwiftDataWatchlistRepository
    @State private var refreshService: WatchlistRefreshService
    @State private var notificationService = NotificationService()
    @State private var navigationCoordinator = AppNavigationCoordinator()

    init() {
        do {
            let container = try ModelContainer(for: TrackedShowEntity.self)
            modelContainer = container
            let repository = SwiftDataWatchlistRepository(context: ModelContext(container))
            _watchlistRepository = State(initialValue: repository)
            _refreshService = State(initialValue: WatchlistRefreshService(repository: repository))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        RefreshScheduler.registerBackgroundTask()
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
        ContentView(coordinator: navigationCoordinator)
            .onChange(of: scenePhase) { previousPhase, phase in
                guard phase == .active, previousPhase != .active else { return }
                Task { await refreshService.refreshAllIfNeeded() }
            }
    }
}
