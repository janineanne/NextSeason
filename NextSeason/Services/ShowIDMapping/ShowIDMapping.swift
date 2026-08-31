//
//  ShowIDMapping.swift
//  NextSeason
//

import Foundation

/// Cached TVMaze display fields keyed from a TheTVDB series id.
///
/// Used to filter Search and to overlay TVMaze title/poster on the results list
/// without a network fetch. Live TVMaze remains canonical after open/track.
nonisolated struct ShowIDMappingRecord: Equatable, Sendable {
    let tvMazeID: Int
    /// TVMaze show name; `nil` when the snapshot has no title yet.
    let name: String?
    /// TVMaze medium poster; `nil` when the snapshot has no artwork.
    let posterMediumURL: URL?
}

/// Offline TheTVDB → TVMaze lookup used to filter Search to actionable shows
/// and overlay TVMaze title/poster on the results list.
///
/// This is a search-display cache, not the source of truth for seasons or
/// watchlist state. After the user selects a result, live TVMaze remains canonical.
/// Watchlist export also uses the reverse lookup for a TVDB id when one exists.
nonisolated protocol ShowIDMapping: Sendable {
    /// Mapping row for a TheTVDB series id, or `nil` when unknown locally.
    func record(forTVDBID id: Int) async -> ShowIDMappingRecord?
    /// A TheTVDB series id for this TVMaze show, or `nil` when unknown locally.
    ///
    /// A TVMaze show can theoretically map from more than one TheTVDB id; the
    /// lowest id is returned so the result is stable.
    func tvdbID(forTVMazeID id: Int) async -> Int?
}

extension ShowIDMapping {
    /// TVMaze show id for a TheTVDB series id, or `nil` when unknown locally.
    func tvMazeID(forTVDBID id: Int) async -> Int? {
        await record(forTVDBID: id)?.tvMazeID
    }
}
