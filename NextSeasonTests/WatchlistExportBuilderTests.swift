//
//  WatchlistExportBuilderTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct WatchlistExportBuilderTests {
    @Test("Export includes every stored show, including those above the free-tier limit")
    func exportsAllShowsAboveFreeLimit() async throws {
        let repository = InMemoryWatchlistRepository()
        let showCount = WatchlistLimitPolicy.freeShowLimit + 2
        for index in 1...showCount {
            try await repository.add(makeShow(id: index, name: "Show \(index)"))
        }
        let mapping = InMemoryShowIDMapping(map: [
            1001: 1,
            1002: 2,
        ])

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("watchlist-export-\(UUID().uuidString)", isDirectory: true)
        let file = try await WatchlistExportBuilder.makeFile(
            repository: repository,
            showIDMapping: mapping,
            now: Date(timeIntervalSince1970: 1_777_000_000),
            directory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(file.url.pathExtension == "csv")
        #expect(
            file.url.lastPathComponent.wholeMatch(
                of: /NextSeason-Watchlist-\d{4}-\d{2}-\d{2}\.csv/
            ) != nil
        )

        let data = try Data(contentsOf: file.url)
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))

        let csv = String(decoding: data.dropFirst(3), as: UTF8.self)
        for index in 1...showCount {
            #expect(csv.contains("Show \(index)"))
            #expect(csv.contains(",\(index),"))
        }
        #expect(csv.contains("1001"))
        #expect(csv.contains("1002"))
        #expect(try await repository.all().count == showCount)
        #expect(showCount > WatchlistLimitPolicy.freeShowLimit)
    }

    @Test("Export does not require a Plus entitlement")
    func exportIgnoresSubscriptionState() async throws {
        let repository = InMemoryWatchlistRepository()
        try await repository.add(makeShow(id: 44933, name: "Severance"))
        let mapping = InMemoryShowIDMapping(map: [:])

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("watchlist-export-\(UUID().uuidString)", isDirectory: true)
        let file = try await WatchlistExportBuilder.makeFile(
            repository: repository,
            showIDMapping: mapping,
            directory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let csv = try String(contentsOf: file.url, encoding: .utf8)
        #expect(csv.contains("Severance"))
        #expect(csv.contains("44933"))
    }

    private func makeShow(id: Int, name: String) -> Show {
        Show(
            id: id,
            name: name,
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/\(id)"),
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
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }
}
