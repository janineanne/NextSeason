//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// The app's root view: Search and Watchlist tabs (Slice 2).
struct ContentView: View {
    @Environment(\.watchlistRepository) private var repository

    @Bindable var coordinator: AppNavigationCoordinator

    private let tvMaze: any TVMazeService

    init(coordinator: AppNavigationCoordinator, tvMaze: any TVMazeService = TVMazeClient()) {
        _coordinator = Bindable(coordinator)
        self.tvMaze = tvMaze
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            SearchView(navigationPath: $coordinator.searchPath, tvMaze: tvMaze)
                .accessibilityIdentifier(AccessibilityID.Tab.search)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppNavigationCoordinator.Tab.search)

            WatchlistView(navigationPath: $coordinator.watchlistPath, tvMaze: tvMaze)
                .accessibilityIdentifier(AccessibilityID.Tab.watchlist)
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }
                .tag(AppNavigationCoordinator.Tab.watchlist)
        }
        .task {
            await coordinator.resolvePendingNavigation(
                repository: repository,
                tvMaze: tvMaze
            )
        }
        .onChange(of: coordinator.pendingShowID) { _, showID in
            guard showID != nil else { return }
            Task {
                await coordinator.resolvePendingNavigation(
                    repository: repository,
                    tvMaze: tvMaze
                )
            }
        }
    }
}

#Preview {
    ContentView(coordinator: AppNavigationCoordinator())
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
}
