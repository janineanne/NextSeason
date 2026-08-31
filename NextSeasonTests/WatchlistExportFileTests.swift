//
//  WatchlistExportFileTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Export filename uses the local calendar day (not UTC) and writes without a unique suffix.
struct WatchlistExportFileTests {
    @Test("File name uses the local calendar day, not UTC")
    func fileNameUsesLocalCalendarDay() throws {
        let pacific = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacific
        let evening = try #require(
            calendar.date(
                from: DateComponents(year: 2026, month: 8, day: 30, hour: 20, minute: 9)
            )
        )

        #expect(
            WatchlistExportFile.fileName(now: evening, timeZone: pacific)
                == "NextSeason-Watchlist-2026-08-30.csv"
        )
        #expect(
            WatchlistExportFile.fileName(now: evening, timeZone: .gmt)
                == "NextSeason-Watchlist-2026-08-31.csv"
        )
    }

    @Test("Written file uses the local-date name with no unique suffix")
    func writesStableLocalFileName() throws {
        let pacific = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacific
        let evening = try #require(
            calendar.date(
                from: DateComponents(year: 2026, month: 8, day: 30, hour: 20, minute: 9)
            )
        )

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("watchlist-export-\(UUID().uuidString)", isDirectory: true)
        let file = try WatchlistExportFile.make(
            shows: [],
            tvdbIDsByTVMazeID: [:],
            now: evening,
            timeZone: pacific,
            directory: directory
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(file.url.lastPathComponent == "NextSeason-Watchlist-2026-08-30.csv")
        #expect(file.url.deletingLastPathComponent() == directory)
    }
}
