//
//  WatchlistTrackingTests.swift
//  NextSeasonTests
//

import CoreGraphics
import Foundation
import Testing
import UserNotifications

@testable import NextSeason

@MainActor
struct WatchlistTrackingTests {
    private var sampleShow: Show {
        Show(
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
    }

    private final class MockTVMazeService: TVMazeService, @unchecked Sendable {
        var showByID: [Int: Show] = [:]
        private(set) var fetchedShowIDs: [Int] = []

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            fetchedShowIDs.append(id)
            guard let show = showByID[id] else { throw TVMazeError.notFound }
            return show
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] { [:] }
    }

    private func makeNotificationService(analytics: any AnalyticsTracking) -> NotificationService {
        let suiteName = "WatchlistTrackingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return NotificationService(
            userDefaults: defaults,
            authorizationStatusForTesting: .denied,
            analytics: analytics
        )
    }

    private func season(_ number: Int, premiere: String?, end: String? = nil) -> Season {
        Season(
            id: number,
            number: number,
            premiereDate: TVMazeDate.dateOnly(premiere),
            endDate: TVMazeDate.dateOnly(end),
            episodeOrder: nil
        )
    }

    @Test("Toggle with a missing undo coordinator returns ignored without mutating persistence")
    func toggleWithoutCoordinatorReturnsIgnored() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        let tvMaze = MockTVMazeService()
        try await repository.add(sampleShow)

        let outcome = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: true,
            anchor: .zero,
            source: .search,
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: nil,
            analytics: analytics,
            notifications: makeNotificationService(analytics: analytics),
            prompt: WatchlistNotificationPromptState()
        )

        #expect(outcome == .ignored)
        #expect(try await repository.contains(showID: sampleShow.id))
        #expect(analytics.events.isEmpty)
        #expect(tvMaze.fetchedShowIDs.isEmpty)
    }

    @Test("A second quick tap while removal is pending undoes that removal")
    func secondTapUndoesPendingRemoval() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        let removalCoordinator = WatchlistPendingRemoval(
            repository: repository, analytics: analytics)
        let notifications = makeNotificationService(analytics: analytics)
        let prompt = WatchlistNotificationPromptState()
        let tvMaze = MockTVMazeService()
        try await repository.add(sampleShow)

        let first = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: true,
            anchor: .zero,
            source: .detail,
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: removalCoordinator,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )
        #expect(first == .removalRequested)
        #expect(removalCoordinator.pendingRemoval?.id == sampleShow.id)
        #expect(try await repository.contains(showID: sampleShow.id))

        let second = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: false,
            anchor: .zero,
            source: .detail,
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: removalCoordinator,
            analytics: analytics,
            notifications: notifications,
            prompt: prompt
        )

        #expect(second == .undidPendingRemoval)
        #expect(removalCoordinator.pendingRemoval == nil)
        #expect(try await repository.contains(showID: sampleShow.id))
        #expect(tvMaze.fetchedShowIDs.isEmpty)
    }

    @Test("Tracking a search stub fetches full show data before storing next-season status")
    func addFromSearchStubStoresResolvedNextSeason() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        let tvMaze = MockTVMazeService()
        let now = TVMazeDate.dateOnly("2026-07-22")!

        let fullShow = Show(
            id: sampleShow.id,
            name: sampleShow.name,
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
            seasons: [
                season(16, premiere: "2025-03-09", end: "2025-07-27"),
                season(17, premiere: "2026-04-05", end: "2026-08-23"),
            ],
            nextEpisode: NextEpisode(
                season: 17,
                airdate: TVMazeDate.dateOnly("2026-07-26")
            ),
            updatedAt: now
        )
        tvMaze.showByID[fullShow.id] = fullShow

        // Search stubs have no seasons; without a detail fetch they would store
        // `.returningNoSeasonYet` even while a season is still airing.
        #expect(NextSeasonCalculator.status(for: sampleShow, at: now) == .returningNoSeasonYet)
        #expect(NextSeasonCalculator.status(for: fullShow, at: now) == .airing(season: 17))

        let outcome = try await WatchlistTracking.toggle(
            sampleShow,
            isTracked: false,
            anchor: .zero,
            source: .search,
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: nil,
            analytics: analytics,
            notifications: makeNotificationService(analytics: analytics),
            prompt: WatchlistNotificationPromptState()
        )

        #expect(outcome == .added)
        #expect(tvMaze.fetchedShowIDs == [sampleShow.id])

        let tracked = try #require(await repository.trackedShow(showID: sampleShow.id))
        #expect(tracked.nextSeason == .airing(season: 17))
    }

    @Test("Tracking a show that already has seasons skips the detail fetch")
    func addWithSeasonsSkipsDetailFetch() async throws {
        let repository = InMemoryWatchlistRepository()
        let analytics = RecordingAnalyticsService()
        let tvMaze = MockTVMazeService()
        let now = TVMazeDate.dateOnly("2026-07-22")!

        let detailedShow = Show(
            id: sampleShow.id,
            name: sampleShow.name,
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
            seasons: [
                season(17, premiere: "2026-04-05", end: "2026-08-23")
            ],
            nextEpisode: nil,
            updatedAt: now
        )

        let outcome = try await WatchlistTracking.toggle(
            detailedShow,
            isTracked: false,
            anchor: .zero,
            source: .detail,
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: nil,
            analytics: analytics,
            notifications: makeNotificationService(analytics: analytics),
            prompt: WatchlistNotificationPromptState()
        )

        #expect(outcome == .added)
        #expect(tvMaze.fetchedShowIDs.isEmpty)

        let tracked = try #require(await repository.trackedShow(showID: sampleShow.id))
        #expect(tracked.nextSeason == .airing(season: 17))
    }
}
