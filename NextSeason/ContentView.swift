//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// The app's root view: Search and Watchlist tabs (Slice 2).
struct ContentView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.analytics) private var analytics
    @Environment(\.appThemeColors) private var themeColors

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
        .tint(themeColors.controlTint)
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
            if tab == .watchlist {
                coordinator.notifyWatchlistDataChanged()
            }
        }
        .task {
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
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(
            repository: repository,
            analytics: RecordingAnalyticsService()
        ))
        .appThemePreview()
}
#endif
