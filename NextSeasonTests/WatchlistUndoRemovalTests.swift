//
//  WatchlistUndoRemovalTests.swift
//  NextSeasonTests
//

import CoreGraphics
import Foundation
import Testing
@testable import NextSeason

@MainActor
struct WatchlistUndoRemovalTests {
    private var sampleShow: Show {
        Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/44933/severance"),
            summaryHTML: "<p>A workplace thriller.</p>",
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2022-02-18"),
            ended: nil,
            network: "Apple TV",
            genres: ["Drama"],
            averageRuntime: 49,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )
    }

    private var secondShow: Show {
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
            network: "HBO",
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )
    }

    @Test("Requesting removal defers persistence until commit")
    func requestRemovalDefersPersistence() async throws {
        let repository = InMemoryWatchlistRepository()
        let coordinator = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        try await repository.add(sampleShow)
        let tracked = try #require((try await repository.all()).first)

        var committed = false
        coordinator.requestRemoval(tracked, anchor: CGRect(x: 10, y: 20, width: 44, height: 44), source: .watchlist) {
            committed = true
        }

        #expect(coordinator.pendingRemoval?.id == tracked.id)
        #expect(coordinator.toastAnchor == CGRect(x: 10, y: 20, width: 44, height: 44))
        #expect(try await repository.contains(showID: tracked.id))
        #expect(committed == false)

        await coordinator.commitPendingRemovalIfNeeded()

        #expect(try await repository.contains(showID: tracked.id) == false)
        #expect(coordinator.pendingRemoval == nil)
        #expect(committed == true)
    }

    @Test("Undo cancels a pending removal without touching persistence")
    func undoLeavesRepositoryUntouched() async throws {
        let repository = InMemoryWatchlistRepository()
        let coordinator = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        try await repository.add(sampleShow)
        let tracked = try #require((try await repository.all()).first)

        coordinator.requestRemoval(tracked, anchor: .zero, source: .watchlist)
        let restored = coordinator.undoRemoval()

        #expect(restored?.id == tracked.id)
        #expect(coordinator.pendingRemoval == nil)
        #expect(coordinator.toastAnchor == nil)
        #expect(try await repository.contains(showID: tracked.id))
    }

    @Test("A new pending removal commits the previous show")
    func replacingPendingRemovalCommitsPrevious() async throws {
        let repository = InMemoryWatchlistRepository()
        let coordinator = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        try await repository.add(sampleShow)
        try await repository.add(secondShow)
        let first = try #require((try await repository.all()).first { $0.id == sampleShow.id })
        let second = try #require((try await repository.all()).first { $0.id == secondShow.id })

        coordinator.requestRemoval(first, anchor: .zero, source: .watchlist)
        coordinator.requestRemoval(second, anchor: .zero, source: .detail)

        #expect(coordinator.pendingRemoval?.id == second.id)

        try await Task.sleep(for: .milliseconds(50))

        #expect(try await repository.contains(showID: first.id) == false)
        #expect(try await repository.contains(showID: second.id))
    }
}
