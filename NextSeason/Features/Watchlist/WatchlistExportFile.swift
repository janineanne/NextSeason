//
//  WatchlistExportFile.swift
//  NextSeason
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A cached CSV file ready for the system share sheet.
nonisolated struct WatchlistExportFile: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .watchlistCSV) { file in
            SentTransferredFile(file.url)
        }
        .suggestedFileName { file in
            file.url.lastPathComponent
        }
    }

    /// Writes a UTF-8 CSV (with BOM) using a stable, user-visible filename.
    ///
    /// The date stamp uses the given time zone so an evening export on the
    /// West Coast is not labeled with the next UTC calendar day.
    static func make(
        shows: [TrackedShow],
        tvdbIDsByTVMazeID: [Int: Int],
        now: Date = .now,
        timeZone: TimeZone = .current,
        directory: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> WatchlistExportFile {
        let csv = WatchlistCSVFormatter.csv(
            shows: shows,
            tvdbIDsByTVMazeID: tvdbIDsByTVMazeID
        )
        let directory =
            directory
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WatchlistExport", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName(now: now, timeZone: timeZone))
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))
        try data.write(to: url, options: .atomic)
        return WatchlistExportFile(url: url)
    }

    /// User-visible export filename: `NextSeason-Watchlist-YYYY-MM-DD.csv`.
    ///
    /// The date stamp uses `timeZone` (default `.current`) so an evening export
    /// on the West Coast is not labeled with the next UTC calendar day.
    static func fileName(now: Date, timeZone: TimeZone = .current) -> String {
        let stamp = now.formatted(
            Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day()
        )
        return "NextSeason-Watchlist-\(stamp).csv"
    }
}
