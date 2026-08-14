//
//  ShowIDMappingDatabaseTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

struct ShowIDMappingDatabaseTests {
    private func makeDatabase(
        seed: [(tvdb: Int, tvmaze: Int)] = []
    ) async throws -> (ShowIDMappingDatabase, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mapping-\(UUID().uuidString).sqlite")
        try ShowIDMappingDatabase.createEmptyDatabase(at: url)
        let database = try ShowIDMappingDatabase(preparedFileURL: url)
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

        let refresh = ShowIDMappingRefreshService(
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

        try ShowIDMappingDatabase.createEmptyDatabase(at: bundledURL)
        let bundled = try ShowIDMappingDatabase(preparedFileURL: bundledURL)
        try await bundled.upsert(tvdbID: 371980, tvMazeID: 44933)
        await bundled.close()

        let database = try ShowIDMappingDatabase(
            fileURL: writableURL,
            bundledURL: bundledURL
        )
        try await database.upsert(tvdbID: 1, tvMazeID: 2)
        #expect(await database.tvMazeID(forTVDBID: 1) == 2)

        try await database.recreateFromBundledBaseline()
        #expect(await database.tvMazeID(forTVDBID: 1) == nil)
        #expect(await database.tvMazeID(forTVDBID: 371980) == 44933)
    }

    @Test("Corrupt writable database is replaced from the bundled baseline")
    func openRecoversCorruptWritableFromBundledBaseline() async throws {
        let bundledURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundled-\(UUID().uuidString).sqlite")
        let writableURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("writable-\(UUID().uuidString).sqlite")
        defer {
            try? FileManager.default.removeItem(at: bundledURL)
            try? FileManager.default.removeItem(at: writableURL)
        }

        try ShowIDMappingDatabase.createEmptyDatabase(at: bundledURL)
        let bundled = try ShowIDMappingDatabase(preparedFileURL: bundledURL)
        try await bundled.upsert(tvdbID: 371980, tvMazeID: 44933)
        await bundled.close()

        // Not a SQLite file — prepare drops it and copies the bundled baseline.
        try Data("not a sqlite database".utf8).write(to: writableURL)

        let database = try ShowIDMappingDatabase.open(
            fileURL: writableURL,
            bundledURL: bundledURL
        )
        #expect(await database.tvMazeID(forTVDBID: 371980) == 44933)
    }

    @Test("Valid writable database opens without being replaced")
    func openKeepsValidWritableDatabase() async throws {
        let bundledURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundled-\(UUID().uuidString).sqlite")
        let writableURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("writable-\(UUID().uuidString).sqlite")
        defer {
            try? FileManager.default.removeItem(at: bundledURL)
            try? FileManager.default.removeItem(at: writableURL)
        }

        try ShowIDMappingDatabase.createEmptyDatabase(at: bundledURL)
        let bundled = try ShowIDMappingDatabase(preparedFileURL: bundledURL)
        try await bundled.upsert(tvdbID: 371980, tvMazeID: 44933)
        await bundled.close()

        try ShowIDMappingDatabase.createEmptyDatabase(at: writableURL)
        let existing = try ShowIDMappingDatabase(preparedFileURL: writableURL)
        try await existing.upsert(tvdbID: 1, tvMazeID: 2)
        await existing.close()

        let database = try ShowIDMappingDatabase.open(
            fileURL: writableURL,
            bundledURL: bundledURL
        )
        #expect(await database.tvMazeID(forTVDBID: 1) == 2)
        #expect(await database.tvMazeID(forTVDBID: 371980) == nil)
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
