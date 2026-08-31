//
//  WatchlistCSVFormatterTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

struct WatchlistCSVFormatterTests {
    @Test("CSV includes a header and one row per show")
    func includesHeaderAndRows() throws {
        let premiere = try #require(TVMazeDate.dateOnly("2026-03-20"))
        let dateAdded = try #require(TVMazeDate.dateOnly("2026-01-15"))
        let show = trackedShow(
            id: 44933,
            name: "Severance",
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/44933/severance"),
            nextSeason: .scheduled(season: 3, premiere: premiere),
            dateAdded: dateAdded
        )

        let csv = WatchlistCSVFormatter.csv(
            shows: [show],
            tvdbIDsByTVMazeID: [44933: 371980]
        )
        let lines = csv.split(separator: "\r\n", omittingEmptySubsequences: false)
            .filter { !$0.isEmpty }

        #expect(lines.count == 2)
        #expect(
            String(lines[0])
                == "Show Name,TVMaze ID,TVDB ID,Status,Next Season,Next Season Premiere,Date Added,TVMaze URL"
        )
        #expect(lines[1].contains("Severance"))
        #expect(lines[1].contains("44933"))
        #expect(lines[1].contains("371980"))
        #expect(lines[1].contains("2026-03-20"))
        #expect(lines[1].contains("2026-01-15T00:00:00Z"))
        #expect(lines[1].contains("https://www.tvmaze.com/shows/44933/severance"))
    }

    @Test("Missing TVDB ID leaves that column empty")
    func missingTVDBIDIsEmpty() {
        let show = trackedShow(id: 1, name: "Unknown Mapping")
        let csv = WatchlistCSVFormatter.csv(shows: [show], tvdbIDsByTVMazeID: [:])
        let row = csv.split(separator: "\r\n").dropFirst().first.map(String.init) ?? ""

        #expect(row.hasPrefix("Unknown Mapping,1,,"))
    }

    @Test("Empty watchlist still writes a header row")
    func emptyWatchlistWritesHeader() {
        let csv = WatchlistCSVFormatter.csv(shows: [], tvdbIDsByTVMazeID: [:])
        #expect(csv.hasPrefix("Show Name,TVMaze ID,TVDB ID,"))
        #expect(csv.split(separator: "\r\n", omittingEmptySubsequences: true).count == 1)
    }

    @Test("Show names with commas and quotes are escaped")
    func escapesCommasAndQuotes() {
        let show = trackedShow(id: 2, name: #"The "Good" Place, Again"#)
        let csv = WatchlistCSVFormatter.csv(shows: [show], tvdbIDsByTVMazeID: [:])
        let row = csv.split(separator: "\r\n").dropFirst().first.map(String.init) ?? ""

        #expect(row.hasPrefix(#""The ""Good"" Place, Again",2,"#))
    }

    @Test("Shows are sorted by name, then TVMaze ID")
    func sortsByNameThenID() {
        let shows = [
            trackedShow(id: 20, name: "Beta"),
            trackedShow(id: 10, name: "Alpha"),
            trackedShow(id: 11, name: "Alpha"),
        ]
        let csv = WatchlistCSVFormatter.csv(shows: shows, tvdbIDsByTVMazeID: [:])
        let rows = csv.split(separator: "\r\n", omittingEmptySubsequences: true).dropFirst()
        let ids = rows.compactMap { row in
            row.split(separator: ",", omittingEmptySubsequences: false).dropFirst().first
                .map(String.init)
        }

        #expect(ids == ["10", "11", "20"])
    }

    private func trackedShow(
        id: Int,
        name: String,
        tvMazeURL: URL? = nil,
        nextSeason: NextSeasonStatus = .unknown,
        dateAdded: Date = Date(timeIntervalSince1970: 0)
    ) -> TrackedShow {
        TrackedShow(
            id: id,
            name: name,
            posterMediumURL: nil,
            tvMazeURL: tvMazeURL,
            status: .running,
            nextSeason: nextSeason,
            sourceUpdatedAt: dateAdded,
            lastCheckedAt: dateAdded,
            dateAdded: dateAdded
        )
    }
}
