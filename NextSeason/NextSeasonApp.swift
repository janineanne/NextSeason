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
    @State private var notificationService = NotificationService()
    @State private var navigationCoordinator = AppNavigationCoordinator()

    init() {
        let coordinator = AppNavigationCoordinator()
        _navigationCoordinator = State(initialValue: coordinator)
        _notificationService = State(initialValue: NotificationService())

        if !UITestingConfiguration.isEnabled {
            NotificationRouting.setCoordinator(coordinator)
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
            refreshService = WatchlistRefreshService(repository: repository)
            watchlistUndoRemoval = WatchlistUndoRemoval(repository: repository)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        if !UITestingConfiguration.isEnabled {
            RefreshScheduler.registerBackgroundTask()
        } else {
            FirstRunPreferences.resetSearchResultsHintForTesting()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                navigationCoordinator: navigationCoordinator,
                undoRemoval: watchlistUndoRemoval,
                refreshService: refreshService
            )
            .environment(\.watchlistRepository, watchlistRepository)
            .environment(\.watchlistRefreshService, refreshService)
            .environment(\.watchlistUndoRemoval, watchlistUndoRemoval)
            .environment(\.notificationService, notificationService)
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
