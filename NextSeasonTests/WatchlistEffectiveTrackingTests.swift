//
//  WatchlistEffectiveTrackingTests.swift
//  NextSeasonTests
//

import CoreGraphics
import Foundation
import Testing
@testable import NextSeason

@MainActor
struct WatchlistEffectiveTrackingTests {
    @Test("A persisted show is tracked unless it is pending removal")
    func isTrackedExcludesPendingRemoval() {
        #expect(
            WatchlistEffectiveTracking.isTracked(
                showID: 1,
                isPersisted: true,
                pendingRemovalID: nil
            )
        )
        #expect(
            WatchlistEffectiveTracking.isTracked(
                showID: 1,
                isPersisted: true,
                pendingRemovalID: 1
            ) == false
        )
        #expect(
            WatchlistEffectiveTracking.isTracked(
                showID: 1,
                isPersisted: true,
                pendingRemovalID: 2
            )
        )
        #expect(
            WatchlistEffectiveTracking.isTracked(
                showID: 1,
                isPersisted: false,
                pendingRemovalID: nil
            ) == false
        )
    }

    @Test("Tracked ID sets drop the pending removal")
    func trackedIDsExcludePendingRemoval() {
        let persisted: Set<Int> = [1, 2, 3]

        #expect(
            WatchlistEffectiveTracking.trackedIDs(
                persistedIDs: persisted,
                pendingRemovalID: nil
            ) == persisted
        )
        #expect(
            WatchlistEffectiveTracking.trackedIDs(
                persistedIDs: persisted,
                pendingRemovalID: 2
            ) == [1, 3]
        )
        #expect(
            WatchlistEffectiveTracking.trackedIDs(
                persistedIDs: persisted,
                pendingRemovalID: 99
            ) == persisted
        )
    }

    @Test("Repository helpers apply the same pending-removal rule")
    func repositoryHelpersMatchPureLogic() async throws {
        let repository = InMemoryWatchlistRepository()
        let show = Show(
            id: 10,
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

        let undoRemoval = WatchlistUndoRemoval(
            repository: repository,
            analytics: RecordingAnalyticsService()
        )
        let tracked = try #require(await repository.trackedShow(showID: show.id))
        undoRemoval.requestRemoval(tracked, anchor: .zero, source: .search)

        #expect(
            try await WatchlistEffectiveTracking.isTracked(
                showID: show.id,
                repository: repository,
                undoRemoval: undoRemoval
            ) == false
        )
        #expect(
            try await WatchlistEffectiveTracking.trackedIDs(
                repository: repository,
                undoRemoval: undoRemoval
            ).isEmpty
        )

        _ = undoRemoval.undoRemoval()

        #expect(
            try await WatchlistEffectiveTracking.isTracked(
                showID: show.id,
                repository: repository,
                undoRemoval: undoRemoval
            )
        )
        #expect(
            try await WatchlistEffectiveTracking.trackedIDs(
                repository: repository,
                undoRemoval: undoRemoval
            ) == [show.id]
        )
    }
}
