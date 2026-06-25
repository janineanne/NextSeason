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

    init(coordinator: AppNavigationCoordinator, tvMaze: any TVMazeService = TVMazeClient()) {
        _coordinator = Bindable(coordinator)
        self.tvMaze = tvMaze
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            SearchView(
                navigationPath: $coordinator.searchPath,
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
        .onChange(of: coordinator.selectedTab) { _, tab in
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

#Preview {
    ContentView(coordinator: AppNavigationCoordinator())
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(repository: InMemoryWatchlistRepository()))
        .appThemePreview()
}
