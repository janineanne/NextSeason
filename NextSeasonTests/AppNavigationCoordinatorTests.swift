//
//  AppNavigationCoordinatorTests.swift
//  NextSeasonTests
//

import Foundation
import SwiftUI
import Testing
@testable import NextSeason

@MainActor
struct AppNavigationCoordinatorTests {
    private final class MockTVMazeService: TVMazeService, @unchecked Sendable {
        var shows: [Int: Show] = [:]
        private(set) var fetchedIDs: [Int] = []

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            fetchedIDs.append(id)
            guard let show = shows[id] else { throw TVMazeError.notFound }
            return show
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] { [:] }
    }

    @Test("Notification routing extracts show IDs from userInfo payloads")
    func showIDFromUserInfo() {
        #expect(NotificationRouting.showID(from: ["showID": 44933]) == 44933)
        #expect(NotificationRouting.showID(from: ["showID": NSNumber(value: 82)]) == 82)
        #expect(NotificationRouting.showID(from: ["showID": "44933"]) == nil)
    }

    @Test("Buffered notification routing flushes when the coordinator is attached")
    func buffersShowNavigationUntilCoordinatorIsReady() {
        NotificationRouting.resetForTesting()
        defer { NotificationRouting.resetForTesting() }

        let coordinator = AppNavigationCoordinator()
        NotificationRouting.routeToShow(showID: 44933)
        #expect(coordinator.pendingShowID == nil)

        NotificationRouting.setCoordinator(coordinator)
        #expect(coordinator.pendingShowID == 44933)
    }

    @Test("Pending navigation opens a tracked show on the watchlist tab")
    func resolvesTrackedShowOnWatchlistTab() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let coordinator = AppNavigationCoordinator()
        let show = Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: nil,
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: nil,
            ended: nil,
            network: nil,
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )

        try await repository.add(show)
        coordinator.queueShowNavigation(showID: show.id)
        await coordinator.resolvePendingNavigation(repository: repository, tvMaze: tvMaze)

        #expect(coordinator.selectedTab == .watchlist)
        #expect(coordinator.watchlistPath.count == 1)
        #expect(coordinator.pendingShowID == nil)
        #expect(tvMaze.fetchedIDs.isEmpty)
    }

    @Test("Find a Show clears the search stack and selects the search tab")
    func showSearchRoot() {
        let coordinator = AppNavigationCoordinator()
        let show = Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: nil,
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: nil,
            ended: nil,
            network: nil,
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )

        coordinator.selectedTab = .watchlist
        coordinator.searchPath.append(show)
        coordinator.watchlistPath.append(TrackedShow(from: show))

        coordinator.showSearchRoot()

        #expect(coordinator.selectedTab == .search)
        #expect(coordinator.searchPath.isEmpty)
        #expect(coordinator.watchlistPath.count == 1)
    }

    @Test("Pending navigation falls back to search when the show is no longer tracked")
    func resolvesUntrackedShowOnSearchTab() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let coordinator = AppNavigationCoordinator()
        let show = Show(
            id: 82,
            name: "Game of Thrones",
            tvMazeURL: nil,
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .ended,
            premiered: nil,
            ended: nil,
            network: nil,
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )

        tvMaze.shows[82] = show
        coordinator.queueShowNavigation(showID: show.id)
        await coordinator.resolvePendingNavigation(repository: repository, tvMaze: tvMaze)

        #expect(coordinator.selectedTab == .search)
        #expect(coordinator.searchPath.count == 1)
        #expect(coordinator.pendingShowID == nil)
        #expect(tvMaze.fetchedIDs == [82])
    }
}
