//
//  NextSeasonApp.swift
//  NextSeason
//

import SwiftData
import SwiftUI

/// App entry: bootstraps `AppCompositionRoot` when the watchlist store opens,
/// or shows `PersistenceRecoveryView` so a damaged store or crash loop can be
/// recovered instead of crashing. Hosts `AppRootView` for scene-phase refresh
/// and watchlist undo.
@main
struct NextSeasonApp: App {
    @State private var launchState: AppLaunchState
    @State private var navigationCoordinator: AppNavigationCoordinator

    init() {
        _navigationCoordinator = State(initialValue: AppNavigationCoordinator())
        _launchState = State(initialValue: AppLaunchState.bootstrap())
    }

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case .ready(let composition):
                AppRootView(
                    navigationCoordinator: navigationCoordinator,
                    removalCoordinator: composition.watchlistPendingRemoval,
                    refreshService: composition.refreshService,
                    purchaseService: composition.purchaseService,
                    searchService: composition.theTVDB,
                    tvMaze: composition.tvMaze,
                    showIDMapping: composition.showIDMapping,
                    onForegroundShowIDMappingRefresh: {
                        await composition.refreshShowIDMappingIfNeeded()
                    },
                    reviewPromptCoordinator: composition.reviewPromptCoordinator
                )
                .environment(\.watchlistRepository, composition.watchlistRepository)
                .environment(\.showIDMapping, composition.showIDMapping)
                .environment(\.watchlistRefreshService, composition.refreshService)
                .environment(\.watchlistPendingRemoval, composition.watchlistPendingRemoval)
                .environment(\.notificationService, composition.notificationService)
                .environment(\.analytics, composition.analyticsService)
                .environment(\.betaRefreshDiagnostics, composition.betaRefreshDiagnostics)
                .environment(composition.purchaseService)
                .modelContainer(composition.modelContainer)
                .task {
                    let count =
                        (try? await composition.watchlistRepository.trackedShowIDs().count) ?? 0
                    await composition.purchaseService.start(watchlistCount: count)
                }
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
            case .recovery(let context):
                PersistenceRecoveryView(
                    context: context,
                    onResetLocalData: {
                        launchState.resetLocalData()
                    },
                    onRetryLaunch: {
                        launchState.retryLaunch()
                    }
                )
            }
        }
    }
}

/// Root content host: scene-phase watchlist and StoreKit entitlement refresh,
/// undo toast for deferred watchlist removals, and UITest network stubbing.
///
/// Undo lives here (not inside Watchlist) so the toast remains visible across
/// tab switches while a removal is still pending confirmation.
private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var navigationCoordinator: AppNavigationCoordinator
    @Bindable var removalCoordinator: WatchlistPendingRemoval
    let refreshService: WatchlistRefreshService
    let purchaseService: PurchaseService
    let searchService: any TheTVDBService
    let tvMaze: any TVMazeService
    let showIDMapping: any ShowIDMapping
    let onForegroundShowIDMappingRefresh: @MainActor () async -> Void
    let reviewPromptCoordinator: ReviewPromptCoordinator

    var body: some View {
        ContentView(
            coordinator: navigationCoordinator,
            searchService: theTVDBService(testing: UITestingConfiguration.isEnabled),
            tvMaze: tvMazeService(testing: UITestingConfiguration.isEnabled),
            showIDMapping: showIDMapping
        )
        .appAccentTint()
        .requestReviewAfterShowNotification(coordinator: reviewPromptCoordinator)
        .watchlistUndoToast(
            isPresented: removalCoordinator.pendingRemoval != nil,
            undoAction: {
                Task { _ = await removalCoordinator.undoRemoval() }
            },
            confirmAction: {
                removalCoordinator.confirmPendingRemoval()
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
            Task {
                await onForegroundShowIDMappingRefresh()
            }
            // Subscription expiration is not reliably delivered through
            // Transaction.updates; re-read current entitlements on foreground.
            Task {
                await purchaseService.handleSceneBecameActive()
            }
        }
        // Cancelled when leaving `.active` so backgrounding during startup
        // is neither a healthy launch nor a crash.
        .task(id: scenePhase) {
            guard !UITestingConfiguration.isEnabled else { return }
            guard scenePhase == .active else { return }
            await LaunchStabilization.waitUntilStable()
        }
    }

    /// UI tests get preview stubs so search / detail never hit the network;
    /// production always uses the injected live clients.
    private func tvMazeService(testing: Bool) -> any TVMazeService {
        #if DEBUG
            if testing {
                return PreviewTVMazeService(stub: .preview)
            }
        #endif
        return tvMaze
    }

    private func theTVDBService(testing: Bool) -> any TheTVDBService {
        #if DEBUG
            if testing {
                return PreviewTheTVDBService(stub: .previewSearchResult)
            }
        #endif
        return searchService
    }
}
