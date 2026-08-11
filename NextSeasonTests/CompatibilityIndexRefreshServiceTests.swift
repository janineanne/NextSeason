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
            resumeCursor: nil
        )

        #expect(pending.map(\.showID) == [100, 200])
        #expect(pending.map(\.updatedAt) == [newer, older])
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
            resumeCursor: cursor
        )

        #expect(pending.map(\.showID) == [2, 1])
    }

    @Test("Capped update pass stores a resume cursor and does not mark sync complete")
    func cappedPassIsResumable() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

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
            now: { Date(timeIntervalSince1970: 1_700_000_000) },
            maxShowDetailFetchesPerRefresh: 2,
            requestPause: .zero
        )

        await refresh.refreshIfNeeded()

        let metadataAfterFirst = try await database.metadata()
        #expect(metadataAfterFirst.lastSuccessfulSyncAt == nil)
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
        #expect(
            metadataAfterSecond.lastSuccessfulSyncAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(await tvMaze.fetchedShowIDs == [10, 20, 30])
        #expect(await database.tvMazeID(forTVDBID: 1_030) == 30)
    }

    private actor RecordingIndexTVMazeService: TVMazeService {
        let updates: [Int: Date]
        let externalsByShowID: [Int: Int]
        private(set) var fetchedShowIDs: [Int] = []

        init(updates: [Int: Date], externalsByShowID: [Int: Int]) {
            self.updates = updates
            self.externalsByShowID = externalsByShowID
        }

        func searchShows(matching query: String) async throws -> [Show] { [] }
        func lookupShow(theTVDBID: Int) async throws -> Show { throw TVMazeError.notFound }
        func lookupShow(imdbID: String) async throws -> Show { throw TVMazeError.notFound }
        func show(id: Int, bypassCache: Bool) async throws -> Show { throw TVMazeError.notFound }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            updates
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
