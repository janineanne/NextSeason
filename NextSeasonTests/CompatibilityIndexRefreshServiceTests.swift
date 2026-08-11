//
//  CompatibilityIndexRefreshServiceTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

struct CompatibilityIndexRefreshServiceTests {
    private func makeDatabase() async throws -> (CompatibilityIndexDatabase, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compat-refresh-\(UUID().uuidString).sqlite")
        try CompatibilityIndexDatabase.createEmptyDatabase(at: url)
        let database = try CompatibilityIndexDatabase(preparedFileURL: url)
        return (database, url)
    }

    @Test("Pending updates sort by timestamp newest-first, not by show id")
    func pendingUpdatesSortByTimestamp() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        // Lower show id is newer; sorting by id desc would put 200 first incorrectly.
        let updates = [
            200: older,
            100: newer,
        ]

        let pending = CompatibilityIndexRefreshService.pendingUpdates(
            from: updates,
            updatedAfter: nil,
            horizonAt: newer,
            resumeCursor: nil
        )

        #expect(pending.map(\.showID) == [100, 200])
        #expect(pending.map(\.updatedAt) == [newer, older])
    }

    @Test("Pending updates ignore changes newer than the sync horizon")
    func pendingUpdatesRespectHorizon() {
        let within = Date(timeIntervalSince1970: 1_000)
        let horizon = Date(timeIntervalSince1970: 2_000)
        let after = Date(timeIntervalSince1970: 3_000)
        let updates = [
            1: within,
            2: horizon,
            3: after,
        ]

        let pending = CompatibilityIndexRefreshService.pendingUpdates(
            from: updates,
            updatedAfter: nil,
            horizonAt: horizon,
            resumeCursor: nil
        )

        #expect(pending.map(\.showID) == [2, 1])
    }

    @Test("Resume cursor keeps only updates older than the pause point")
    func pendingUpdatesRespectResumeCursor() {
        let t1 = Date(timeIntervalSince1970: 1_000)
        let t2 = Date(timeIntervalSince1970: 2_000)
        let t3 = Date(timeIntervalSince1970: 3_000)
        let updates = [
            1: t1,
            2: t2,
            3: t3,
        ]
        let cursor = CompatibilityIndexUpdatesResumeCursor(updatedAt: t3, showID: 3)

        let pending = CompatibilityIndexRefreshService.pendingUpdates(
            from: updates,
            updatedAfter: nil,
            horizonAt: t3,
            resumeCursor: cursor
        )

        #expect(pending.map(\.showID) == [2, 1])
    }

    @Test("Pending updates ignore changes at or before the prior sync watermark")
    func pendingUpdatesRespectUpdatedAfter() {
        let watermark = Date(timeIntervalSince1970: 2_000)
        let before = Date(timeIntervalSince1970: 1_000)
        let after = Date(timeIntervalSince1970: 3_000)
        let updates = [
            1: before,
            2: watermark,
            3: after,
        ]

        let pending = CompatibilityIndexRefreshService.pendingUpdates(
            from: updates,
            updatedAfter: watermark,
            horizonAt: after,
            resumeCursor: nil
        )

        #expect(pending.map(\.showID) == [3])
    }

    @Test("First refresh uses bundled generatedAt as the updates watermark")
    func firstRefreshUsesGeneratedAtWatermark() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let now = Date(timeIntervalSince1970: 1_700_000_000 + 3_600)
        try await database.setGeneratedAt(generatedAt)

        let beforeGeneration = Date(timeIntervalSince1970: 1_699_999_000)
        let afterGeneration = Date(timeIntervalSince1970: 1_700_000_500)

        let tvMaze = RecordingIndexTVMazeService(
            updates: [
                10: beforeGeneration,
                20: afterGeneration,
            ],
            externalsByShowID: [
                10: 1_010,
                20: 1_020,
            ]
        )

        let refresh = CompatibilityIndexRefreshService(
            database: database,
            tvMaze: tvMaze,
            now: { now },
            maxShowDetailFetchesPerRefresh: 10,
            requestPause: .zero
        )

        await refresh.refreshIfNeeded()

        #expect(await tvMaze.lastFilteredPeriod == .day)
        #expect(await tvMaze.fetchedShowIDs == [20])
        #expect(await database.tvMazeID(forTVDBID: 1_020) == 20)
        #expect(await database.tvMazeID(forTVDBID: 1_010) == nil)

        let metadata = try await database.metadata()
        #expect(metadata.lastSuccessfulSyncAt == now)
    }

    @Test("Long absence uses the unfiltered updates map and still applies local watermark")
    func longAbsenceUsesUnfilteredUpdates() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        let lastSync = Date(timeIntervalSince1970: 1_000_000_000)
        // Two months later: beyond TVMaze's since=month window.
        let horizon = Date(
            timeIntervalSince1970: 1_000_000_000 + (2 * TVMazeUpdatePeriod.monthWindow)
        )
        try await database.setLastSuccessfulSyncAt(lastSync)

        // Older than since=month can cover from `horizon`, but still after lastSync.
        let oldChange = Date(timeIntervalSince1970: 1_000_000_000 + 7 * 86_400)
        let recentChange = Date(
            timeIntervalSince1970: 1_000_000_000 + TVMazeUpdatePeriod.monthWindow + 7 * 86_400
        )
        let alreadySynced = lastSync

        let tvMaze = RecordingIndexTVMazeService(
            updates: [
                10: oldChange,
                20: recentChange,
                30: alreadySynced,
            ],
            externalsByShowID: [
                10: 1_010,
                20: 1_020,
                30: 1_030,
            ]
        )

        let refresh = CompatibilityIndexRefreshService(
            database: database,
            tvMaze: tvMaze,
            now: { horizon },
            maxShowDetailFetchesPerRefresh: 10,
            requestPause: .zero
        )

        await refresh.refreshIfNeeded()

        #expect(await tvMaze.didFetchAllUpdatedShows)
        #expect(await tvMaze.lastFilteredPeriod == nil)
        #expect(await tvMaze.fetchedShowIDs == [20, 10])
        #expect(await database.tvMazeID(forTVDBID: 1_010) == 10)
        #expect(await database.tvMazeID(forTVDBID: 1_020) == 20)
        #expect(await database.tvMazeID(forTVDBID: 1_030) == nil)

        let metadata = try await database.metadata()
        #expect(metadata.lastSuccessfulSyncAt == horizon)
    }

    @Test("Capped update pass stores a resume cursor and does not mark sync complete")
    func cappedPassIsResumable() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        let syncStart = Date(timeIntervalSince1970: 1_700_000_000)
        let tNewer = Date(timeIntervalSince1970: 3_000)
        let tMid = Date(timeIntervalSince1970: 2_000)
        let tOlder = Date(timeIntervalSince1970: 1_000)
        let tvMaze = RecordingIndexTVMazeService(
            updates: [
                10: tNewer,
                20: tMid,
                30: tOlder,
            ],
            externalsByShowID: [
                10: 1_010,
                20: 1_020,
                30: 1_030,
            ]
        )

        let refresh = CompatibilityIndexRefreshService(
            database: database,
            tvMaze: tvMaze,
            now: { syncStart },
            maxShowDetailFetchesPerRefresh: 2,
            requestPause: .zero
        )

        await refresh.refreshIfNeeded()

        let metadataAfterFirst = try await database.metadata()
        #expect(metadataAfterFirst.lastSuccessfulSyncAt == nil)
        #expect(metadataAfterFirst.syncHorizonAt == syncStart)
        let cursor = try #require(metadataAfterFirst.updatesResumeCursor)
        #expect(cursor.showID == 20)
        #expect(cursor.updatedAt == tMid)
        #expect(await tvMaze.fetchedShowIDs == [10, 20])
        #expect(await database.tvMazeID(forTVDBID: 1_010) == 10)
        #expect(await database.tvMazeID(forTVDBID: 1_020) == 20)
        #expect(await database.tvMazeID(forTVDBID: 1_030) == nil)

        await refresh.refreshIfNeeded()

        let metadataAfterSecond = try await database.metadata()
        #expect(metadataAfterSecond.updatesResumeCursor == nil)
        #expect(metadataAfterSecond.syncHorizonAt == nil)
        // Commit the original horizon, not a later wall-clock time.
        #expect(metadataAfterSecond.lastSuccessfulSyncAt == syncStart)
        #expect(await tvMaze.fetchedShowIDs == [10, 20, 30])
        #expect(await database.tvMazeID(forTVDBID: 1_030) == 30)
    }

    @Test("Mid-drain updates after the horizon are deferred to the next sync")
    func midDrainUpdatesAreNotSkippedForever() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        let syncStart = Date(timeIntervalSince1970: 1_700_000_000)
        let nextSyncNow = Date(
            timeIntervalSince1970: 1_700_000_000
                + CompatibilityIndexRefreshService.refreshInterval + 1
        )

        let tNewer = Date(timeIntervalSince1970: 3_000)
        let tOlder = Date(timeIntervalSince1970: 1_000)
        let midDrainUpdate = Date(timeIntervalSince1970: 1_700_000_100)

        // Pass 1 consumes syncStart for the horizon. Pass 2 reuses the stored
        // horizon (no clock read). Pass 3 reads nextSyncNow twice: once for the
        // weekly-interval check and once when opening a new horizon.
        let clock = SyncClock(dates: [syncStart, nextSyncNow, nextSyncNow])
        let tvMaze = RecordingIndexTVMazeService(
            updates: [
                10: tNewer,
                20: tOlder,
            ],
            externalsByShowID: [
                10: 1_010,
                20: 1_020,
                99: 1_099,
            ]
        )

        let refresh = CompatibilityIndexRefreshService(
            database: database,
            tvMaze: tvMaze,
            now: { clock.next() },
            maxShowDetailFetchesPerRefresh: 1,
            requestPause: .zero
        )

        await refresh.refreshIfNeeded()
        #expect(await tvMaze.fetchedShowIDs == [10])
        let afterFirst = try await database.metadata()
        #expect(afterFirst.syncHorizonAt == syncStart)
        #expect(afterFirst.lastSuccessfulSyncAt == nil)

        // A show updates after the sync horizon while we still have backlog.
        await tvMaze.setUpdates([
            10: tNewer,
            20: tOlder,
            99: midDrainUpdate,
        ])

        await refresh.refreshIfNeeded()
        let afterSecond = try await database.metadata()
        #expect(afterSecond.syncHorizonAt == nil)
        #expect(afterSecond.lastSuccessfulSyncAt == syncStart)
        #expect(await tvMaze.fetchedShowIDs == [10, 20])
        #expect(await database.tvMazeID(forTVDBID: 1_099) == nil)

        // Next weekly window: only the deferred change remains outstanding.
        await tvMaze.setUpdates([99: midDrainUpdate])

        await refresh.refreshIfNeeded()
        #expect(await tvMaze.fetchedShowIDs.contains(99))
        #expect(await database.tvMazeID(forTVDBID: 1_099) == 99)
        let afterThird = try await database.metadata()
        #expect(afterThird.lastSuccessfulSyncAt == nextSyncNow)
        #expect(afterThird.syncHorizonAt == nil)
    }

    private final class SyncClock: @unchecked Sendable {
        private let lock = NSLock()
        private var dates: [Date]
        private var index = 0

        init(dates: [Date]) {
            self.dates = dates
        }

        func next() -> Date {
            lock.lock()
            defer { lock.unlock() }
            let date = dates[min(index, dates.count - 1)]
            index += 1
            return date
        }
    }

    private actor RecordingIndexTVMazeService: TVMazeService {
        private var updates: [Int: Date]
        let externalsByShowID: [Int: Int]
        private(set) var fetchedShowIDs: [Int] = []
        private(set) var didFetchAllUpdatedShows = false
        private(set) var lastFilteredPeriod: TVMazeUpdatePeriod?

        init(updates: [Int: Date], externalsByShowID: [Int: Int]) {
            self.updates = updates
            self.externalsByShowID = externalsByShowID
        }

        func setUpdates(_ updates: [Int: Date]) {
            self.updates = updates
        }

        func searchShows(matching query: String) async throws -> [Show] { [] }
        func lookupShow(theTVDBID: Int) async throws -> Show { throw TVMazeError.notFound }
        func show(id: Int, bypassCache: Bool) async throws -> Show { throw TVMazeError.notFound }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            lastFilteredPeriod = period
            return updates
        }

        func allUpdatedShows() async throws -> [Int: Date] {
            didFetchAllUpdatedShows = true
            return updates
        }

        func showsIndex(page: Int) async throws -> [ShowIndexEntryData] {
            throw TVMazeError.notFound
        }

        func showIndexEntry(id: Int) async throws -> ShowIndexEntryData {
            fetchedShowIDs.append(id)
            return ShowIndexEntryData(
                id: id,
                externals: ShowExternalsData(thetvdb: externalsByShowID[id])
            )
        }
    }
}
