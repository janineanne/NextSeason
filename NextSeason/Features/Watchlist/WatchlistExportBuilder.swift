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
    /// Fetches every persisted show, resolves TVDB IDs from the bundled mapping,
    /// and writes a cached CSV under `directory` (defaults to Caches/WatchlistExport).
    ///
    /// `now` stamps the filename; inject both for deterministic tests.
    static func makeFile(
        repository: any WatchlistRepository,
        showIDMapping: any ShowIDMapping,
        now: Date = .now,
        directory: URL? = nil
    ) async throws -> WatchlistExportFile {
        try await makeFile(
            shows: try await repository.all(),
            showIDMapping: showIDMapping,
            now: now,
            directory: directory
        )
    }

    /// Writes a CSV from an already-loaded watchlist. Used by About export and
    /// by best-effort recovery export when the store may only be partially readable.
    ///
    /// TVDB IDs are resolved when the mapping is available; missing IDs become
    /// empty CSV cells rather than failing the export.
    static func makeFile(
        shows: [TrackedShow],
        showIDMapping: any ShowIDMapping,
        now: Date = .now,
        directory: URL? = nil
    ) async throws -> WatchlistExportFile {
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
