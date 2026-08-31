//
//  PersistenceRecoveryExportPreparationTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Recovery-export UI state: probe availability, prepare success/failure, reset stays available.
@MainActor
struct PersistenceRecoveryExportPreparationTests {
    @Test("Probe with recovered shows offers export")
    func probeWithShowsOffersExport() async {
        let show = sampleShow(id: 44933, name: "Severance")
        let preparation = PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: [show], storeWasReadable: true)
        }

        await preparation.probeIfNeeded()

        #expect(preparation.canExport)
        #expect(preparation.availability == .available(showCount: 1))
        #expect(preparation.recoveredShows.map(\.id) == [44933])
    }

    @Test("Probe does not run again after the first result")
    func probeRunsOnce() async {
        var calls = 0
        let preparation = PersistenceRecoveryExportPreparation {
            calls += 1
            return WatchlistRecoveryExportRead(shows: [], storeWasReadable: false)
        }

        await preparation.probeIfNeeded()
        await preparation.probeIfNeeded()

        #expect(calls == 1)
        #expect(preparation.canExport == false)
        #expect(preparation.availability == .unavailable(.storeUnreadable))
    }

    @Test("An unreadable store skips export")
    func unreadableStoreSkipsExport() async {
        let preparation = PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: [], storeWasReadable: false)
        }

        await preparation.probeIfNeeded()

        #expect(preparation.canExport == false)
        #expect(preparation.availability == .unavailable(.storeUnreadable))
    }

    @Test("A readable empty store skips export")
    func readableEmptyStoreSkipsExport() async {
        let preparation = PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: [], storeWasReadable: true)
        }

        await preparation.probeIfNeeded()

        #expect(preparation.canExport == false)
        #expect(preparation.availability == .unavailable(.noRecoverableShows))
    }

    @Test("A failed prepare leaves export and reset available")
    func failedPrepareDoesNotBlockReset() async throws {
        let show = sampleShow(id: 1, name: "Show")
        let preparation = PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: [show], storeWasReadable: true)
        }
        await preparation.probeIfNeeded()

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("recovery-export-file-\(UUID().uuidString)")
        try Data().write(to: directory)

        let file = await preparation.prepareFile(
            showIDMapping: InMemoryShowIDMapping(map: [:]),
            directory: directory
        )

        #expect(file == nil)
        #expect(preparation.exportErrorMessage != nil)
        #expect(preparation.canExport)
        #expect(preparation.availability == .available(showCount: 1))
    }

    @Test("A successful prepare writes a CSV from recovered shows")
    func successfulPrepareWritesCSV() async throws {
        let show = sampleShow(id: 44933, name: "Severance")
        let preparation = PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: [show], storeWasReadable: true)
        }
        await preparation.probeIfNeeded()

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "recovery-export-ok-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = try #require(
            await preparation.prepareFile(
                showIDMapping: InMemoryShowIDMapping(map: [371980: 44933]),
                directory: directory
            )
        )
        let csv = try String(contentsOf: file.url, encoding: .utf8)
        #expect(csv.contains("Severance"))
        #expect(csv.contains("44933"))
        #expect(csv.contains("371980"))
        #expect(preparation.exportErrorMessage == nil)
        #expect(preparation.canExport)
    }

    private func sampleShow(id: Int, name: String) -> TrackedShow {
        TrackedShow(
            id: id,
            name: name,
            posterMediumURL: nil,
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/\(id)"),
            status: .running,
            nextSeason: .unknown,
            sourceUpdatedAt: Date(timeIntervalSince1970: 0),
            lastCheckedAt: Date(timeIntervalSince1970: 0),
            dateAdded: Date(timeIntervalSince1970: 0)
        )
    }
}
