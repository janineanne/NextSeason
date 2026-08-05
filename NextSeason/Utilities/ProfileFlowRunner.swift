//
//  ProfileFlowRunner.swift
//  NextSeason
//

import Foundation
import os
import SwiftUI

/// Drives a single user flow for Instruments when launched with `-ProfileFlow`.
///
/// Sets coordinator state (tab, search query, navigation path) and waits on
/// tokens that Search/Show Detail bump when UI work settles
/// (`profileFlowSearchSettledToken`, `profileFlowDetailLoadedToken`). Emits
/// `OSSignposter` intervals for Instruments and records durations via
/// `AppDiagnosticsLogger` / `ProfileFlowTimingStore`.
///
/// Setup-only flows (e.g. seed) exit early; others sleep briefly after the flow
/// so xctrace can capture trailing work.
@MainActor
struct ProfileFlowRunner {
    private static var signposter: OSSignposter { ProfileFlowConfiguration.Signpost.signposter }

    let flow: ProfileFlowConfiguration.Flow
    let coordinator: AppNavigationCoordinator
    let repository: any WatchlistRepository
    let tvMaze: any TVMazeService
    let analytics: any AnalyticsTracking

    func run() async {
        let flowStart = Date.now
        let interval = beginFlowInterval()
        defer {
            endFlowInterval(interval)
            AppDiagnosticsLogger.logProfileFlowTiming(
                flow: flow.rawValue,
                durationMs: max(0, Int(Date.now.timeIntervalSince(flowStart) * 1000))
            )
        }

        if flow.isSetupOnly {
            try? await Task.sleep(for: .milliseconds(500))
            await runSeedWatchlist()
            return
        }

        ProfileFlowTimingStore.clear()

        // Allow the root SwiftUI hierarchy to appear before driving navigation.
        try? await Task.sleep(for: .milliseconds(750))

        switch flow {
        case .seedWatchlist:
            break
        case .search:
            await runSearch()
        case .searchEmpty:
            await runSearchEmpty()
        case .showDetails:
            await runShowDetails()
        case .viewWishlist:
            await runViewWishlist()
        case .addToWishlist:
            await runAddToWishlist()
        case .removeFromWishlist:
            await runRemoveFromWishlist()
        case .stressSearchDetailsBack:
            await runStressSearchDetailsBack()
        case .stressAddRemoveWishlist:
            await runStressAddRemoveWishlist()
        case .stressSearchEmpty:
            await runStressSearchEmpty()
        case .launchWithData:
            await runLaunchWithDataIdle()
        }

        // Keep the process alive briefly so xctrace can capture post-flow work.
        try? await Task.sleep(for: .seconds(2))
    }

    private func beginFlowInterval() -> OSSignpostIntervalState {
        switch flow {
        case .seedWatchlist:
            Self.signposter.beginInterval("flow.seedWatchlist")
        case .search:
            Self.signposter.beginInterval("flow.search")
        case .searchEmpty:
            Self.signposter.beginInterval("flow.searchEmpty")
        case .showDetails:
            Self.signposter.beginInterval("flow.showDetails")
        case .viewWishlist:
            Self.signposter.beginInterval("flow.viewWishlist")
        case .addToWishlist:
            Self.signposter.beginInterval("flow.addToWishlist")
        case .removeFromWishlist:
            Self.signposter.beginInterval("flow.removeFromWishlist")
        case .stressSearchDetailsBack:
            Self.signposter.beginInterval("flow.stressSearchDetailsBack")
        case .stressAddRemoveWishlist:
            Self.signposter.beginInterval("flow.stressAddRemoveWishlist")
        case .stressSearchEmpty:
            Self.signposter.beginInterval("flow.stressSearchEmpty")
        case .launchWithData:
            Self.signposter.beginInterval("flow.launchWithData")
        }
    }

    private func endFlowInterval(_ interval: OSSignpostIntervalState) {
        switch flow {
        case .seedWatchlist:
            Self.signposter.endInterval("flow.seedWatchlist", interval)
        case .search:
            Self.signposter.endInterval("flow.search", interval)
        case .searchEmpty:
            Self.signposter.endInterval("flow.searchEmpty", interval)
        case .showDetails:
            Self.signposter.endInterval("flow.showDetails", interval)
        case .viewWishlist:
            Self.signposter.endInterval("flow.viewWishlist", interval)
        case .addToWishlist:
            Self.signposter.endInterval("flow.addToWishlist", interval)
        case .removeFromWishlist:
            Self.signposter.endInterval("flow.removeFromWishlist", interval)
        case .stressSearchDetailsBack:
            Self.signposter.endInterval("flow.stressSearchDetailsBack", interval)
        case .stressAddRemoveWishlist:
            Self.signposter.endInterval("flow.stressAddRemoveWishlist", interval)
        case .stressSearchEmpty:
            Self.signposter.endInterval("flow.stressSearchEmpty", interval)
        case .launchWithData:
            Self.signposter.endInterval("flow.launchWithData", interval)
        }
    }

    /// Sets the search query; SearchView’s `.task(id:)` performs the network work.
    private func runSearch() async {
        let phaseStart = Date.now
        let interval = Self.signposter.beginInterval("search.query")
        coordinator.selectedTab = .search
        coordinator.profileFlowSearchQuery = FirstRunCopy.exampleSearchQuery
        await waitForSearchResults()
        Self.signposter.endInterval("search.query", interval)
        AppDiagnosticsLogger.logProfileFlowTiming(
            flow: flow.rawValue,
            durationMs: max(0, Int(Date.now.timeIntervalSince(phaseStart) * 1000)),
            phase: "search.query"
        )
    }

    private func runSearchEmpty() async {
        let interval = Self.signposter.beginInterval("search.empty")
        coordinator.selectedTab = .search
        coordinator.profileFlowSearchQuery = ProfileFlowConfiguration.SearchQuery.emptyResults
        await waitForSearchResults()
        Self.signposter.endInterval("search.empty", interval)
    }

    /// Populates the watchlist from fixed queries (setup before other flows).
    private func runSeedWatchlist() async {
        let interval = Self.signposter.beginInterval("watchlist.seed")
        for query in ProfileFlowConfiguration.SeedData.watchlistSearchQueries {
            guard let show = await resolveShow(matching: query) else { continue }
            if (try? await repository.contains(showID: show.id)) == true { continue }
            do {
                try await repository.add(show)
            } catch {
                analytics.trackNonFatalError(error, context: "profile_flow_seed")
            }
        }
        coordinator.notifyWatchlistDataChanged()
        try? await Task.sleep(for: .seconds(1))
        Self.signposter.endInterval("watchlist.seed", interval)
    }

    /// Push show detail, wait for load, then pop — captures retention after dismiss.
    private func runShowDetails() async {
        guard let show = await resolveExampleShow() else { return }

        let phaseStart = Date.now
        let interval = Self.signposter.beginInterval("showDetails.load")
        let detailToken = coordinator.profileFlowDetailLoadedToken
        coordinator.selectedTab = .search
        coordinator.searchPath.append(show)
        analytics.track(.showDetailViewed(showID: show.id))
        await waitForDetailLoaded(since: detailToken)
        try? await Task.sleep(for: .milliseconds(300))
        Self.signposter.endInterval("showDetails.load", interval)
        AppDiagnosticsLogger.logProfileFlowTiming(
            flow: flow.rawValue,
            durationMs: max(0, Int(Date.now.timeIntervalSince(phaseStart) * 1000)),
            phase: "showDetails.load"
        )

        let retentionInterval = Self.signposter.beginInterval("showDetails.retentionCheck")
        coordinator.showSearchRoot()
        try? await Task.sleep(for: .seconds(1))
        Self.signposter.endInterval("showDetails.retentionCheck", retentionInterval)
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

        let phaseStart = Date.now
        let interval = Self.signposter.beginInterval("watchlist.add")
        if (try? await repository.contains(showID: show.id)) == true {
            try? await repository.remove(showID: show.id)
        }

        coordinator.selectedTab = .search
        let searchToken = coordinator.profileFlowSearchSettledToken
        coordinator.profileFlowSearchQuery = FirstRunCopy.exampleSearchQuery
        await waitForSearchResults(since: searchToken)

        do {
            try await repository.add(show)
            analytics.track(.watchlistAdded(source: .search, showID: show.id))
            coordinator.notifyWatchlistDataChanged()
        } catch {
            analytics.trackNonFatalError(error, context: "profile_flow_add")
        }
        Self.signposter.endInterval("watchlist.add", interval)
        AppDiagnosticsLogger.logProfileFlowTiming(
            flow: flow.rawValue,
            durationMs: max(0, Int(Date.now.timeIntervalSince(phaseStart) * 1000)),
            phase: "watchlist.add"
        )
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
        await resolveShow(matching: FirstRunCopy.exampleSearchQuery)
    }

    private func resolveShow(matching query: String) async -> Show? {
        do {
            let shows = try await tvMaze.searchShows(matching: query)
            return shows.first { $0.name.localizedCaseInsensitiveContains(query) } ?? shows.first
        } catch {
            analytics.trackNonFatalError(error, context: "profile_flow_search")
            return nil
        }
    }

    /// Polls until SearchView bumps `profileFlowSearchSettledToken`, or times out.
    private func waitForSearchResults(since startToken: Int? = nil) async {
        let baseline = startToken ?? coordinator.profileFlowSearchSettledToken
        let deadline = Date.now.addingTimeInterval(15)
        while Date.now < deadline {
            if coordinator.profileFlowSearchSettledToken > baseline {
                return
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    /// Polls until ShowDetailView bumps `profileFlowDetailLoadedToken`, or times out.
    private func waitForDetailLoaded(since startToken: Int) async {
        let deadline = Date.now.addingTimeInterval(12)
        while Date.now < deadline {
            if coordinator.profileFlowDetailLoadedToken > startToken {
                return
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    /// Repeated search → detail → back to stress navigation / retention.
    private func runStressSearchDetailsBack() async {
        guard let show = await resolveExampleShow() else { return }

        let interval = Self.signposter.beginInterval("stress.searchDetailsBack")
        for _ in 1 ... 20 {
            coordinator.selectedTab = .search
            coordinator.profileFlowSearchQuery = FirstRunCopy.exampleSearchQuery
            await waitForSearchResults()
            coordinator.searchPath.append(show)
            try? await Task.sleep(for: .milliseconds(500))
            coordinator.showSearchRoot()
            try? await Task.sleep(for: .milliseconds(200))
        }
        Self.signposter.endInterval("stress.searchDetailsBack", interval)
    }

    private func runStressAddRemoveWishlist() async {
        guard let show = await resolveExampleShow() else { return }

        let interval = Self.signposter.beginInterval("stress.addRemoveWishlist")
        for _ in 1 ... 50 {
            do {
                try await repository.add(show)
                coordinator.notifyWatchlistDataChanged()
                try await repository.remove(showID: show.id)
                coordinator.notifyWatchlistDataChanged()
            } catch {
                analytics.trackNonFatalError(error, context: "profile_flow_stress_add_remove")
            }
            try? await Task.sleep(for: .milliseconds(100))
        }
        Self.signposter.endInterval("stress.addRemoveWishlist", interval)
    }

    private func runStressSearchEmpty() async {
        let interval = Self.signposter.beginInterval("stress.searchEmpty")
        for _ in 1 ... 20 {
            coordinator.selectedTab = .search
            coordinator.profileFlowSearchQuery = ProfileFlowConfiguration.SearchQuery.emptyResults
            await waitForSearchResults()
        }
        Self.signposter.endInterval("stress.searchEmpty", interval)
    }

    /// Exercises a populated watchlist at idle after launch (seed data must exist).
    private func runLaunchWithDataIdle() async {
        let interval = Self.signposter.beginInterval("launchWithData.idle")
        coordinator.selectedTab = .watchlist
        coordinator.notifyWatchlistDataChanged()
        try? await Task.sleep(for: .seconds(3))
        Self.signposter.endInterval("launchWithData.idle", interval)
    }
}
