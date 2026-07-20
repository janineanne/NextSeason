//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

@main
struct NextSeasonApp: App {
    private let composition: AppCompositionRoot
    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var themeController = AppThemeController()

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
                undoRemoval: composition.watchlistUndoRemoval,
                refreshService: composition.refreshService,
                tvMaze: composition.tvMaze
            )
            .environment(themeController)
            .appThemeColors(from: themeController)
            .appThemeIcon(from: themeController)
            .environment(\.watchlistRepository, composition.watchlistRepository)
            .environment(\.watchlistRefreshService, composition.refreshService)
            .environment(\.watchlistUndoRemoval, composition.watchlistUndoRemoval)
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

/// Hosts scene-phase refresh so foreground returns pick up watchlist changes.
private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var navigationCoordinator: AppNavigationCoordinator
    @Bindable var undoRemoval: WatchlistUndoRemoval
    let refreshService: WatchlistRefreshService
    let tvMaze: any TVMazeService

    var body: some View {
        ContentView(coordinator: navigationCoordinator, tvMaze: uiTestingTVMazeService)
            // Theme switcher parked; see ThemeSwitcherView.swift status comment.
            // Previously: beta theme switcher lived in each tab's nav bar via `.betaThemeSwitcherToolbar()`.
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
            .alert(
                "Couldn't Update Watchlist",
                isPresented: Binding(
                    get: { undoRemoval.removalErrorMessage != nil },
                    set: { if !$0 { undoRemoval.clearRemovalError() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    undoRemoval.clearRemovalError()
                }
            } message: {
                Text(undoRemoval.removalErrorMessage ?? "")
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
        return tvMaze
    }
}
