//
//  WatchlistExportBuilder.swift
//  NextSeason
//

import Foundation

/// Loads the complete on-device watchlist and writes a shareable CSV.
///
/// Does not consult Plus entitlement or the free-tier cap — every stored show
/// is exported, including shows kept after a subscription expires.
@MainActor
enum WatchlistExportBuilder {
    static func makeFile(
        repository: any WatchlistRepository,
        showIDMapping: any ShowIDMapping,
        now: Date = .now,
        directory: URL? = nil
    ) async throws -> WatchlistExportFile {
        let shows = try await repository.all()
        var tvdbIDsByTVMazeID: [Int: Int] = [:]
        for show in shows {
            if let tvdbID = await showIDMapping.tvdbID(forTVMazeID: show.id) {
                tvdbIDsByTVMazeID[show.id] = tvdbID
            }
        }
        return try WatchlistExportFile.make(
            shows: shows,
            tvdbIDsByTVMazeID: tvdbIDsByTVMazeID,
            now: now,
            directory: directory
        )
    }
}
