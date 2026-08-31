//
//  AppNavigationCoordinatorTests.swift
//  NextSeasonTests
//

import Foundation
import SwiftUI
import Testing

@testable import NextSeason

/// Notification routing, review-prompt side effects, and tab/path navigation.
/// Tests call `NotificationRouting.resetForTesting()` because routing uses process-wide state.
@MainActor
struct AppNavigationCoordinatorTests {
    /// Stub TVMaze that records fetched show ids and serves preloaded shows.
    private final class MockTVMazeService: TVMazeService, @unchecked Sendable {
        var shows: [Int: Show] = [:]
        private(set) var fetchedIDs: [Int] = []

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func lookupShow(theTVDBID: Int) async throws -> Show {
            throw TVMazeError.notFound
        }

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

    @Test("Production show notifications are counted for review prompts")
    func productionShowNotificationsAreCounted() {
        #expect(
            NotificationRouting.isProductionShowNotification(
                userInfo: ["showID": 44933],
                requestIdentifier: "show-44933-scheduled:3:1"
            )
        )
        #expect(
            NotificationRouting.isProductionShowNotification(
                userInfo: ["showID": 44933],
                requestIdentifier: "debug-test-1"
            ) == false
        )
        #expect(
            NotificationRouting.isProductionShowNotification(
                userInfo: [:],
                requestIdentifier: "show-44933-airing:2"
            ) == false
        )
    }

    @Test("Review prompt records a production show notification experience")
    func notesProductionShowNotificationExperience() {
        NotificationRouting.resetForTesting()
        defer { NotificationRouting.resetForTesting() }

        let prompt = ReviewPromptCoordinator(
            userDefaults: isolatedDefaults(),
            marketingVersion: "1.0",
            sleep: { _ in }
        )
        NotificationRouting.setReviewPrompt(prompt)

        NotificationRouting.noteShowNotificationExperience(
            userInfo: ["showID": 44933],
            requestIdentifier: "debug-pipeline-44933"
        )
        #expect(prompt.isEligibleToRequest == false)

        NotificationRouting.noteShowNotificationExperience(
            userInfo: ["showID": 44933],
            requestIdentifier: "show-44933-airing:2"
        )
        #expect(prompt.isEligibleToRequest)
        #expect(prompt.deliveryGeneration == 1)
    }

    @Test("Unattached review prompt still persists a background schedule")
    func persistsShowNotificationWhenCoordinatorIsMissing() {
        NotificationRouting.resetForTesting()
        defer { NotificationRouting.resetForTesting() }

        let store = ReviewPromptStore(
            defaults: isolatedDefaults(),
            marketingVersion: "1.0"
        )
        NotificationRouting.unattachedReviewPromptStoreForTesting = store

        NotificationRouting.noteShowNotificationExperience(
            userInfo: ["showID": 44933],
            requestIdentifier: "debug-test-1"
        )
        #expect(store.isEligibleToRequest == false)

        NotificationRouting.noteShowNotificationExperience(
            userInfo: ["showID": 44933],
            requestIdentifier: "show-44933-airing:2"
        )
        #expect(store.isEligibleToRequest)
    }

    @Test("Buffered notification routing flushes when the coordinator is attached")
    func buffersShowNavigationUntilCoordinatorIsReady() {
        NotificationRouting.resetForTesting()
        defer { NotificationRouting.resetForTesting() }

        let coordinator = AppNavigationCoordinator()
        NotificationRouting.routeToShow(showID: 44933, animated: false)
        #expect(coordinator.pendingShowID == nil)

        NotificationRouting.setCoordinator(coordinator)
        #expect(coordinator.pendingShowID == 44933)
    }

    @Test("Pending navigation opens a tracked show on the watchlist tab")
    func resolvesTrackedShowOnWatchlistTab() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let analytics = RecordingAnalyticsService()
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
        await coordinator.resolvePendingNavigation(
            repository: repository,
            tvMaze: tvMaze,
            analytics: analytics
        )

        #expect(coordinator.selectedTab == .watchlist)
        // The push is deferred until WatchlistView is on screen (avoids SwiftUI
        // dropping a push made in the same update as the tab switch).
        #expect(coordinator.pendingWatchlistDetail?.id == show.id)
        #expect(coordinator.watchlistPath.isEmpty)
        #expect(coordinator.pendingShowID == nil)
        #expect(tvMaze.fetchedIDs.isEmpty)
        #expect(analytics.events.contains(.appOpenedFromNotification(showID: show.id)))

        coordinator.applyPendingWatchlistDetail()
        #expect(coordinator.watchlistPath.count == 1)
        #expect(coordinator.pendingWatchlistDetail == nil)
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

    @Test("popSearchToRoot clears the search stack without changing tabs")
    func popSearchToRoot() {
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

        coordinator.popSearchToRoot()

        #expect(coordinator.selectedTab == .watchlist)
        #expect(coordinator.searchPath.isEmpty)
    }

    @Test("Pending navigation falls back to search when the show is no longer tracked")
    func resolvesUntrackedShowOnSearchTab() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let analytics = RecordingAnalyticsService()
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
        await coordinator.resolvePendingNavigation(
            repository: repository,
            tvMaze: tvMaze,
            analytics: analytics
        )

        #expect(coordinator.selectedTab == .search)
        #expect(coordinator.searchPath.count == 1)
        #expect(coordinator.pendingShowID == nil)
        #expect(tvMaze.fetchedIDs == [82])
        #expect(analytics.events.contains(.appOpenedFromNotification(showID: show.id)))
    }

    /// Isolated `UserDefaults` for review-prompt persistence without cross-test leakage.
    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "AppNavigationCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
