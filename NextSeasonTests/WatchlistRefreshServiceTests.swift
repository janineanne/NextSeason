//
//  WatchlistRefreshServiceTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

@MainActor
struct WatchlistRefreshServiceTests {
    private let fixedNow = TVMazeDate.dateOnly("2026-06-14")!
    private let showID = 44933

    private final class RecordingNotificationService: NotificationDelivering {
        private(set) var delivered: [SeasonNotificationContent] = []

        func deliver(_ content: SeasonNotificationContent) async {
            delivered.append(content)
        }
    }

    private final class MockTVMazeService: TVMazeService, @unchecked Sendable {
        var updates: [Int: Date] = [:]
        var shows: [Int: Show] = [:]
        private(set) var fetchedShowIDs: [Int] = []
        private(set) var lastBypassCache: Bool?

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            fetchedShowIDs.append(id)
            lastBypassCache = bypassCache
            guard let show = shows[id] else { throw TVMazeError.notFound }
            return show
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            updates
        }
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

    private func show(nextEpisode: NextEpisode? = nil, extraSeason: Season? = nil) -> Show {
        var seasons = [
            season(1, premiere: "2022-02-18", end: "2022-04-08"),
            season(2, premiere: "2025-01-17", end: "2025-03-21")
        ]
        if let extraSeason { seasons.append(extraSeason) }

        return Show(
            id: showID,
            name: "Severance",
            tvMazeURL: nil,
            summaryHTML: nil,
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2022-02-18"),
            ended: nil,
            network: "Apple TV",
            genres: ["Drama"],
            averageRuntime: 49,
            seasons: seasons,
            nextEpisode: nextEpisode,
            updatedAt: fixedNow
        )
    }

    private func makeService(
        repository: InMemoryWatchlistRepository,
        tvMaze: MockTVMazeService,
        notifications: RecordingNotificationService
    ) -> WatchlistRefreshService {
        WatchlistRefreshService(
            tvMaze: tvMaze,
            repository: repository,
            notifications: notifications,
            now: { self.fixedNow }
        )
    }

    @Test("Background refresh skips shows that did not change on TVMaze")
    func skipsUnchangedShowsInUpdatesMap() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let notifications = RecordingNotificationService()

        let initial = show(extraSeason: season(3, premiere: nil))
        try await repository.add(initial)

        var tracked = try await repository.all()[0]
        tracked.sourceUpdatedAt = fixedNow
        try await repository.updateAfterRefresh(tracked)

        tvMaze.updates = [:]
        tvMaze.shows[showID] = initial

        await makeService(repository: repository, tvMaze: tvMaze, notifications: notifications).refreshAll()

        #expect(tvMaze.fetchedShowIDs.isEmpty)
        #expect(notifications.delivered.isEmpty)
    }

    @Test("Background refresh re-fetches and notifies when TVMaze reports an update")
    func notifiesWhenUpdatesMapHasNewerEpoch() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let notifications = RecordingNotificationService()

        let initial = show(extraSeason: season(3, premiere: nil))
        try await repository.add(initial)

        var tracked = try await repository.all()[0]
        tracked.sourceUpdatedAt = .distantPast
        try await repository.updateAfterRefresh(tracked)

        let premiere = TVMazeDate.dateOnly("2026-09-01")!
        let updated = show(extraSeason: season(3, premiere: "2026-09-01"))
        tvMaze.updates = [showID: fixedNow]
        tvMaze.shows[showID] = updated

        await makeService(repository: repository, tvMaze: tvMaze, notifications: notifications).refreshAll()

        #expect(tvMaze.fetchedShowIDs == [showID])
        #expect(tvMaze.lastBypassCache == true)
        #expect(notifications.delivered.count == 1)
        #expect(notifications.delivered[0].status == .scheduled(season: 3, premiere: premiere))

        let stored = try await repository.all()[0]
        #expect(stored.nextSeason == .scheduled(season: 3, premiere: premiere))
    }

    @Test("Force refresh re-fetches every tracked show regardless of the updates map")
    func forceRefreshFetchesAllTrackedShows() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let notifications = RecordingNotificationService()

        try await repository.add(show())
        try await repository.add(
            Show(
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
                updatedAt: fixedNow
            )
        )

        tvMaze.updates = [:]
        tvMaze.shows[showID] = show()
        tvMaze.shows[82] = tvMaze.shows[showID]!

        await makeService(repository: repository, tvMaze: tvMaze, notifications: notifications)
            .refreshAll(force: true)

        #expect(Set(tvMaze.fetchedShowIDs) == Set([showID, 82]))
    }

    @Test("A 404 from TVMaze marks the tracked show stale without delivering a notification")
    func notFoundMarksShowStale() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let notifications = RecordingNotificationService()

        try await repository.add(show())

        var tracked = try await repository.all()[0]
        tracked.sourceUpdatedAt = .distantPast
        try await repository.updateAfterRefresh(tracked)

        tvMaze.updates = [showID: fixedNow]
        tvMaze.shows = [:]

        await makeService(repository: repository, tvMaze: tvMaze, notifications: notifications).refreshAll()

        let stored = try await repository.all()[0]
        #expect(stored.isStale)
        #expect(notifications.delivered.isEmpty)
    }

    @Test("Debounced changes notify only after a second refresh sees the same status")
    func debouncedChangeRequiresTwoRefreshCycles() async throws {
        let repository = InMemoryWatchlistRepository()
        let tvMaze = MockTVMazeService()
        let notifications = RecordingNotificationService()
        let service = makeService(repository: repository, tvMaze: tvMaze, notifications: notifications)

        let betweenSeasons = show()
        try await repository.add(betweenSeasons)

        var tracked = try await repository.all()[0]
        tracked.nextSeason = .returningNoSeasonYet
        tracked.sourceUpdatedAt = .distantPast
        try await repository.updateAfterRefresh(tracked)

        let announced = show(extraSeason: season(3, premiere: nil))
        tvMaze.updates = [showID: fixedNow]
        tvMaze.shows[showID] = announced

        await service.refreshAll()
        #expect(notifications.delivered.isEmpty)

        let pending = try await repository.all()[0]
        #expect(pending.pendingChangeSignature == StatusChangeDetector.signature(for: .announcedUndated(season: 3)))

        await service.refreshAll(force: true)
        #expect(notifications.delivered.count == 1)
        #expect(notifications.delivered[0].status == .announcedUndated(season: 3))
    }
}
