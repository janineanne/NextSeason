//
//  AppNavigationCoordinator.swift
//  NextSeason
//

import SwiftUI

/// Routes deep links from notifications into the correct tab and detail screen.
@Observable
@MainActor
final class AppNavigationCoordinator {
    enum Tab: Hashable {
        case search
        case watchlist
    }

    var selectedTab: Tab = .search
    var watchlistPath = NavigationPath()
    var searchPath = NavigationPath()

    private(set) var pendingShowID: Int?

    func queueShowNavigation(showID: Int) {
        pendingShowID = showID
    }

    func resolvePendingNavigation(
        repository: any WatchlistRepository,
        tvMaze: any TVMazeService
    ) async {
        guard let showID = pendingShowID else { return }
        pendingShowID = nil

        if let tracked = try? await repository.all().first(where: { $0.id == showID }) {
            selectedTab = .watchlist
            watchlistPath.append(tracked)
            return
        }

        if let show = try? await tvMaze.show(id: showID) {
            selectedTab = .search
            searchPath.append(show)
        }
    }
}
