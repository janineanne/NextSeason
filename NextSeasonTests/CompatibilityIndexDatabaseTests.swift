//
//  CompatibilityIndexDatabaseTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

struct CompatibilityIndexDatabaseTests {
    private func makeDatabase(
        seed: [(tvdb: Int, tvmaze: Int)] = []
    ) async throws -> (CompatibilityIndexDatabase, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("compat-\(UUID().uuidString).sqlite")
        try CompatibilityIndexDatabase.createEmptyDatabase(at: url)
        let database = try CompatibilityIndexDatabase(preparedFileURL: url)
        for pair in seed {
            try await database.upsert(tvdbID: pair.tvdb, tvMazeID: pair.tvmaze)
        }
        return (database, url)
    }

    @Test("TVDB ID maps to expected TVMaze ID")
    func mapsKnownTVDBID() async throws {
        let (database, url) = try await makeDatabase(seed: [(371980, 44933)])
        defer { try? FileManager.default.removeItem(at: url) }

        let mapped = await database.tvMazeID(forTVDBID: 371980)
        #expect(mapped == 44933)
    }

    @Test("Unknown TVDB ID returns no mapping")
    func unknownTVDBIDReturnsNil() async throws {
        let (database, url) = try await makeDatabase(seed: [(371980, 44933)])
        defer { try? FileManager.default.removeItem(at: url) }

        let mapped = await database.tvMazeID(forTVDBID: 999_999_999)
        #expect(mapped == nil)
    }

    @Test("Incremental addition of a new mapping")
    func addsNewMapping() async throws {
        let (database, url) = try await makeDatabase()
        defer { try? FileManager.default.removeItem(at: url) }

        try await database.upsert(tvdbID: 100, tvMazeID: 200)
        #expect(await database.tvMazeID(forTVDBID: 100) == 200)
    }

    @Test("Update/replacement/removal of an existing mapping")
    func updatesAndRemovesMapping() async throws {
        let (database, url) = try await makeDatabase(seed: [(10, 100)])
        defer { try? FileManager.default.removeItem(at: url) }

        try await database.applyMapping(tvMazeID: 100, tvdbID: 11)
        #expect(await database.tvMazeID(forTVDBID: 10) == nil)
        #expect(await database.tvMazeID(forTVDBID: 11) == 100)

        try await database.applyMapping(tvMazeID: 100, tvdbID: nil)
        #expect(await database.tvMazeID(forTVDBID: 11) == nil)
    }

    @Test("Failed incremental refresh leaves existing data usable")
    func failedRefreshLeavesData() async throws {
        let (database, url) = try await makeDatabase(seed: [(371980, 44933)])
        defer { try? FileManager.default.removeItem(at: url) }

        let refresh = CompatibilityIndexRefreshService(
            database: database,
            tvMaze: FailingIndexTVMazeService(),
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )
        await refresh.refreshIfNeeded()

        #expect(await database.tvMazeID(forTVDBID: 371980) == 44933)
        let metadata = try await database.metadata()
        #expect(metadata.lastSuccessfulSyncAt == nil)
    }

    @Test("Writable database can be recreated from the bundled baseline")
    func recreatesFromBundledBaseline() async throws {
        let bundledURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundled-\(UUID().uuidString).sqlite")
        let writableURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("writable-\(UUID().uuidString).sqlite")
        defer {
            try? FileManager.default.removeItem(at: bundledURL)
            try? FileManager.default.removeItem(at: writableURL)
        }

        try CompatibilityIndexDatabase.createEmptyDatabase(at: bundledURL)
        let bundled = try CompatibilityIndexDatabase(preparedFileURL: bundledURL)
        try await bundled.upsert(tvdbID: 371980, tvMazeID: 44933)
        await bundled.close()

        let database = try CompatibilityIndexDatabase(
            fileURL: writableURL,
            bundledURL: bundledURL
        )
        try await database.upsert(tvdbID: 1, tvMazeID: 2)
        #expect(await database.tvMazeID(forTVDBID: 1) == 2)

        try await database.recreateFromBundledBaseline()
        #expect(await database.tvMazeID(forTVDBID: 1) == nil)
        #expect(await database.tvMazeID(forTVDBID: 371980) == 44933)
    }

    private struct FailingIndexTVMazeService: TVMazeService {
        func searchShows(matching query: String) async throws -> [Show] { [] }
        func lookupShow(theTVDBID: Int) async throws -> Show { throw TVMazeError.notFound }
        func show(id: Int, bypassCache: Bool) async throws -> Show { throw TVMazeError.notFound }
        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            throw TVMazeError.network(URLError(.notConnectedToInternet))
        }
        func showsIndex(page: Int) async throws -> [ShowIndexEntryData] {
            throw TVMazeError.network(URLError(.notConnectedToInternet))
        }
        func showIndexEntry(id: Int) async throws -> ShowIndexEntryData {
            throw TVMazeError.network(URLError(.notConnectedToInternet))
        }
    }
}
