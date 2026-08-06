//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

/// App entry: builds `AppCompositionRoot`, injects services into the environment,
/// and hosts `AppRootView` for scene-phase refresh and watchlist undo.
@main
struct NextSeasonApp: App {
    private let composition: AppCompositionRoot
    @State private var navigationCoordinator = AppNavigationCoordinator()

    init() {
        let coordinator = AppNavigationCoordinator()
        _navigationCoordinator = State(initialValue: coordinator)

        do {
            let root = try AppCompositionRoot()
            composition = root

            if !UITestingConfiguration.isEnabled {
                root.configureNonUITestRuntime()
            } else {
                #if DEBUG
                    FirstRunPreferences.resetSearchResultsHintForTesting()
                    FirstRunPreferences.resetFirstSearchCompletedForTesting()
                #endif
            }
        } catch {
            AppDiagnosticsLogger.logModelContainerInitFailure(error)
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                navigationCoordinator: navigationCoordinator,
                removalCoordinator: composition.watchlistPendingRemoval,
                refreshService: composition.refreshService,
                tvMaze: composition.tvMaze
            )
            .environment(\.watchlistRepository, composition.watchlistRepository)
            .environment(\.watchlistRefreshService, composition.refreshService)
            .environment(\.watchlistPendingRemoval, composition.watchlistPendingRemoval)
            .environment(\.notificationService, composition.notificationService)
            .environment(\.analytics, composition.analyticsService)
            .environment(\.betaRefreshDiagnostics, composition.betaRefreshDiagnostics)
            .task {
                guard let flow = ProfileFlowConfiguration.activeFlow else { return }
                await ProfileFlowRunner(
                    flow: flow,
                    coordinator: navigationCoordinator,
                    repository: composition.watchlistRepository,
                    tvMaze: composition.tvMaze,
                    analytics: composition.analyticsService
                ).run()
            }
        }
        .modelContainer(composition.modelContainer)
    }
}

/// Root content host: scene-phase watchlist refresh, undo toast for deferred
/// watchlist removals, and UITest TVMaze stubbing.
///
/// Undo lives here (not inside Watchlist) so the toast remains visible across
/// tab switches while a removal is still pending confirmation.
private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var navigationCoordinator: AppNavigationCoordinator
    @Bindable var removalCoordinator: WatchlistPendingRemoval
    let refreshService: WatchlistRefreshService
    let tvMaze: any TVMazeService

    var body: some View {
        ContentView(
            coordinator: navigationCoordinator,
            tvMaze: tvMazeService(testing: UITestingConfiguration.isEnabled)
        )
        .appAccentTint()
        .watchlistUndoToast(
            isPresented: removalCoordinator.pendingRemoval != nil,
            anchor: removalCoordinator.toastAnchor,
            undoAction: {
                Task { _ = await removalCoordinator.undoRemoval() }
            },
            confirmAction: {
                Task {
                    await removalCoordinator.commitPendingRemovalIfNeeded()
                }
            }
        )
        .alert(
            "Couldn't Update Watchlist",
            isPresented: Binding(
                get: { removalCoordinator.removalErrorMessage != nil },
                set: { if !$0 { removalCoordinator.clearRemovalError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                removalCoordinator.clearRemovalError()
            }
        } message: {
            Text(removalCoordinator.removalErrorMessage ?? "")
        }
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
                // Refresh (or a background task while we were away) updates
                // SwiftData; the watchlist UI keeps an in-memory snapshot and
                // must reload so section/status match what just notified.
                navigationCoordinator.notifyWatchlistDataChanged()
                AppDiagnosticsLogger.logTaskComplete("foreground_watchlist_refresh")
            }
        }
    }

    /// UI tests get `PreviewTVMazeService` so search / detail never hit the network;
    /// production always uses the injected live client.
    private func tvMazeService(testing: Bool) -> any TVMazeService {
        #if DEBUG
            if testing {
                return PreviewTVMazeService(stub: .preview)
            }
        #endif
        return tvMaze
    }
}
