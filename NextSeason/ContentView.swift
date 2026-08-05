//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// Root tab shell: Search and Watchlist, wired to `AppNavigationCoordinator` for
/// tab selection, navigation paths, watchlist reload tokens, notification deep
/// links, and (when enabled) the profile-driven search flow.
struct ContentView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistPendingRemoval) private var removalCoordinator
    @Environment(\.analytics) private var analytics
    @Bindable var coordinator: AppNavigationCoordinator

    private let tvMaze: any TVMazeService

    init(coordinator: AppNavigationCoordinator, tvMaze: any TVMazeService) {
        _coordinator = Bindable(coordinator)
        self.tvMaze = tvMaze
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            SearchView(
                navigationPath: $coordinator.searchPath,
                profileFlowSearchQuery: $coordinator.profileFlowSearchQuery,
                onProfileFlowSearchSettled: { coordinator.notifyProfileFlowSearchSettled() },
                onProfileFlowDetailLoaded: { coordinator.notifyProfileFlowDetailLoaded() },
                tvMaze: tvMaze,
                analytics: analytics,
                onWatchlistChanged: { coordinator.notifyWatchlistDataChanged() }
            )
                .accessibilityIdentifier(AccessibilityID.Tab.search)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppNavigationCoordinator.Tab.search)

            WatchlistView(
                navigationPath: $coordinator.watchlistPath,
                tvMaze: tvMaze,
                watchlistReloadToken: coordinator.watchlistReloadToken,
                pendingDetailToken: coordinator.pendingWatchlistDetail?.id,
                onApplyPendingDetail: {
                    coordinator.applyPendingWatchlistDetail()
                },
                onFindShow: {
                    coordinator.showSearchRoot()
                },
                onWatchlistChanged: {
                    coordinator.notifyWatchlistDataChanged()
                }
            )
                .accessibilityIdentifier(AccessibilityID.Tab.watchlist)
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }
                .tag(AppNavigationCoordinator.Tab.watchlist)
        }
        .appScreenBackground()
        .background {
            TabBarReselectHandler(tabIndex: AppNavigationCoordinator.Tab.search.tabBarIndex) {
                coordinator.popSearchToRoot()
            }
        }
        .modifier(BetaDiagnosticsPresentationModifier())
        .onChange(of: coordinator.selectedTab) { oldTab, tab in
            if tab == .search, oldTab != .search {
                coordinator.popSearchToRoot()
            }
            // Commit deferred removals when leaving the Watchlist tab — not when
            // pushing Show Detail (NavigationStack onDisappear would false-trigger).
            if oldTab == .watchlist, tab != .watchlist {
                Task {
                    AppDiagnosticsLogger.logTaskStart("watchlist_commit_on_leave_tab")
                    await removalCoordinator?.commitPendingRemovalIfNeeded()
                    AppDiagnosticsLogger.logTaskComplete("watchlist_commit_on_leave_tab")
                }
            }
            if tab == .watchlist {
                coordinator.notifyWatchlistDataChanged()
            }
        }
        .task {
            if !UITestingConfiguration.isEnabled {
                // Attach the exact coordinator SwiftUI observes so notification taps
                // route into this view's navigation state; this also flushes any
                // launch-time tap that NotificationRouting buffered before attach.
                NotificationRouting.setCoordinator(coordinator)
            }
            await coordinator.resolveInitialTab(repository: repository)
            await coordinator.resolvePendingNavigation(
                repository: repository,
                tvMaze: tvMaze,
                analytics: analytics
            )
        }
        .onChange(of: coordinator.pendingShowID) { _, showID in
            guard showID != nil else { return }
            Task {
                await coordinator.resolvePendingNavigation(
                    repository: repository,
                    tvMaze: tvMaze,
                    analytics: analytics
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    let repository = InMemoryWatchlistRepository()
    ContentView(coordinator: AppNavigationCoordinator(), tvMaze: TVMazeClient())
        .environment(\.watchlistRepository, repository)
        .environment(\.watchlistPendingRemoval, WatchlistPendingRemoval(
            repository: repository,
            analytics: RecordingAnalyticsService()
        ))
}
#endif
