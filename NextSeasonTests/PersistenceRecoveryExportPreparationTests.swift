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

        // A file at the destination path makes `createDirectory` throw so
        // prepare fails without blocking reset.
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

    @Test("An overlapping probe waits for the in-flight read and still offers export")
    func overlappingProbeAwaitsInFlightRead() async {
        let show = sampleShow(id: 44933, name: "Severance")
        let loader = GatedRecoveryExportLoader(
            result: WatchlistRecoveryExportRead(shows: [show], storeWasReadable: true)
        )
        let preparation = PersistenceRecoveryExportPreparation {
            await loader.load()
        }

        let first = Task {
            await preparation.probeIfNeeded()
        }
        await loader.waitUntilLoadBegan()
        #expect(preparation.availability == .probing)
        #expect(preparation.canExport == false)
        #expect(loader.callCount == 1)

        var secondFinished = false
        let second = Task {
            await preparation.probeIfNeeded()
            secondFinished = true
        }
        await Task.yield()
        #expect(secondFinished == false)
        #expect(preparation.availability == .probing)
        #expect(loader.callCount == 1)

        loader.resume()
        await first.value
        await second.value

        #expect(secondFinished)
        #expect(preparation.canExport)
        #expect(preparation.availability == .available(showCount: 1))
        #expect(loader.callCount == 1)
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

    /// Minimal tracked show for probe/prepare assertions.
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

/// Suspends inside `load()` until released so overlapping `probeIfNeeded()`
/// calls can be observed before recoverability is known.
@MainActor
private final class GatedRecoveryExportLoader {
    var result: WatchlistRecoveryExportRead
    private(set) var callCount = 0
    private var beganContinuation: CheckedContinuation<Void, Never>?
    private var gateContinuation: CheckedContinuation<Void, Never>?

    init(result: WatchlistRecoveryExportRead) {
        self.result = result
    }

    func waitUntilLoadBegan() async {
        await withCheckedContinuation { continuation in
            if gateContinuation != nil {
                continuation.resume()
                return
            }
            beganContinuation = continuation
        }
    }

    func resume() {
        gateContinuation?.resume()
        gateContinuation = nil
    }

    func load() async -> WatchlistRecoveryExportRead {
        callCount += 1
        beganContinuation?.resume()
        beganContinuation = nil
        await withCheckedContinuation { continuation in
            gateContinuation = continuation
        }
        return result
    }
}
