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
    /// Set by `ProfileFlowRunner` so SearchView can drive a query during Instruments runs.
    var profileFlowSearchQuery: String?
    /// Bumped when search reaches a settled outcome during a profile flow run.
    private(set) var profileFlowSearchSettledToken = 0
    /// Bumped when show detail finishes loading during a profile flow run.
    private(set) var profileFlowDetailLoadedToken = 0

    func notifyProfileFlowSearchSettled() {
        profileFlowSearchSettledToken &+= 1
    }

    func notifyProfileFlowDetailLoaded() {
        profileFlowDetailLoadedToken &+= 1
    }

    private(set) var pendingShowID: Int?
    private(set) var watchlistReloadToken = 0

    func queueShowNavigation(showID: Int) {
        pendingShowID = showID
    }

    /// Switches to the Search tab at its root, popping any detail screen the
    /// search stack was left on (e.g. a show viewed while adding to the
    /// watchlist) so the user lands on the search screen itself.
    func showSearchRoot() {
        searchPath = NavigationPath()
        selectedTab = .search
    }

    /// Bumps a token `WatchlistView` observes so it reloads from persistence.
    func notifyWatchlistDataChanged(reloadWatchlist: Bool = true) {
        if reloadWatchlist {
            watchlistReloadToken &+= 1
        }
    }

    func resolvePendingNavigation(
        repository: any WatchlistRepository,
        tvMaze: any TVMazeService,
        analytics: any AnalyticsTracking
    ) async {
        guard let showID = pendingShowID else { return }
        pendingShowID = nil

        if let tracked = try? await repository.all().first(where: { $0.id == showID }) {
            selectedTab = .watchlist
            watchlistPath.append(tracked)
            analytics.track(.appOpenedFromNotification(showID: showID))
            return
        }

        if let show = try? await tvMaze.show(id: showID) {
            selectedTab = .search
            searchPath.append(show)
            analytics.track(.appOpenedFromNotification(showID: showID))
        }
    }
}
