//
//  ProfileFlowRunner.swift
//  NextSeason
//

import Foundation
import os
import SwiftUI

/// Drives a single user flow for Instruments when launched with `-ProfileFlow`.
@MainActor
struct ProfileFlowRunner {
    private static let signposter = OSSignposter(
        subsystem: "com.TrialByFyre.NextSeason",
        category: "ProfileFlow"
    )

    let flow: ProfileFlowConfiguration.Flow
    let coordinator: AppNavigationCoordinator
    let repository: any WatchlistRepository
    let tvMaze: any TVMazeService
    let analytics: any AnalyticsTracking

    func run() async {
        let interval = beginFlowInterval()
        defer { endFlowInterval(interval) }

        // Allow the root SwiftUI hierarchy to appear before driving navigation.
        try? await Task.sleep(for: .milliseconds(750))

        switch flow {
        case .search:
            await runSearch()
        case .showDetails:
            await runShowDetails()
        case .viewWishlist:
            await runViewWishlist()
        case .addToWishlist:
            await runAddToWishlist()
        case .removeFromWishlist:
            await runRemoveFromWishlist()
        }

        // Keep the process alive briefly so xctrace can capture post-flow work.
        try? await Task.sleep(for: .seconds(2))
    }

    private func beginFlowInterval() -> OSSignpostIntervalState {
        switch flow {
        case .search:
            Self.signposter.beginInterval("flow.search")
        case .showDetails:
            Self.signposter.beginInterval("flow.showDetails")
        case .viewWishlist:
            Self.signposter.beginInterval("flow.viewWishlist")
        case .addToWishlist:
            Self.signposter.beginInterval("flow.addToWishlist")
        case .removeFromWishlist:
            Self.signposter.beginInterval("flow.removeFromWishlist")
        }
    }

    private func endFlowInterval(_ interval: OSSignpostIntervalState) {
        switch flow {
        case .search:
            Self.signposter.endInterval("flow.search", interval)
        case .showDetails:
            Self.signposter.endInterval("flow.showDetails", interval)
        case .viewWishlist:
            Self.signposter.endInterval("flow.viewWishlist", interval)
        case .addToWishlist:
            Self.signposter.endInterval("flow.addToWishlist", interval)
        case .removeFromWishlist:
            Self.signposter.endInterval("flow.removeFromWishlist", interval)
        }
    }

    private func runSearch() async {
        let interval = Self.signposter.beginInterval("search.query")
        coordinator.selectedTab = .search
        coordinator.profileFlowSearchQuery = FirstRunCopy.exampleSearchQuery
        await waitForSearchResults()
        Self.signposter.endInterval("search.query", interval)
    }

    private func runShowDetails() async {
        guard let show = await resolveExampleShow() else { return }

        let interval = Self.signposter.beginInterval("showDetails.load")
        coordinator.selectedTab = .search
        coordinator.searchPath.append(show)
        analytics.track(.showDetailViewed(showID: show.id))
        try? await Task.sleep(for: .seconds(2))
        Self.signposter.endInterval("showDetails.load", interval)
    }

    private func runViewWishlist() async {
        let interval = Self.signposter.beginInterval("watchlist.view")
        coordinator.selectedTab = .watchlist
        coordinator.notifyWatchlistDataChanged()
        try? await Task.sleep(for: .seconds(1))
        Self.signposter.endInterval("watchlist.view", interval)
    }

    private func runAddToWishlist() async {
        guard let show = await resolveExampleShow() else { return }

        let interval = Self.signposter.beginInterval("watchlist.add")
        if (try? await repository.contains(showID: show.id)) == true {
            try? await repository.remove(showID: show.id)
        }

        coordinator.selectedTab = .search
        coordinator.profileFlowSearchQuery = FirstRunCopy.exampleSearchQuery
        await waitForSearchResults()

        do {
            try await repository.add(show)
            analytics.track(.watchlistAdded(source: .search, showID: show.id))
            coordinator.notifyWatchlistDataChanged()
        } catch {
            analytics.trackNonFatalError(error, context: "profile_flow_add")
        }
        Self.signposter.endInterval("watchlist.add", interval)
    }

    private func runRemoveFromWishlist() async {
        guard let show = await resolveExampleShow() else { return }

        let interval = Self.signposter.beginInterval("watchlist.remove")
        if (try? await repository.contains(showID: show.id)) != true {
            try? await repository.add(show)
            coordinator.notifyWatchlistDataChanged()
        }

        coordinator.selectedTab = .watchlist
        coordinator.notifyWatchlistDataChanged()
        try? await Task.sleep(for: .milliseconds(500))

        do {
            try await repository.remove(showID: show.id)
            analytics.track(.watchlistRemoved(source: .watchlist, showID: show.id))
            coordinator.notifyWatchlistDataChanged()
        } catch {
            analytics.trackNonFatalError(error, context: "profile_flow_remove")
        }
        Self.signposter.endInterval("watchlist.remove", interval)
    }

    private func resolveExampleShow() async -> Show? {
        let query = FirstRunCopy.exampleSearchQuery
        do {
            let shows = try await tvMaze.searchShows(matching: query)
            return shows.first { $0.name.localizedCaseInsensitiveContains(query) } ?? shows.first
        } catch {
            analytics.trackNonFatalError(error, context: "profile_flow_search")
            return nil
        }
    }

    private func waitForSearchResults() async {
        // Allow debounce, network, and SwiftUI list rendering to settle.
        try? await Task.sleep(for: .seconds(5))
    }
}
