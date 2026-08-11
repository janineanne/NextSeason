//
//  TVDBTVMazeCompatibilityIndex.swift
//  NextSeason
//

import Foundation

/// Offline TheTVDB → TVMaze id lookup used to filter Search to actionable shows.
///
/// This is an index only — never the source of truth for show metadata, seasons,
/// or watchlist state. After the user selects a result, TVMaze remains canonical.
nonisolated protocol TVDBTVMazeCompatibilityIndex: Sendable {
    /// TVMaze show id for a TheTVDB series id, or `nil` when unknown locally.
    func tvMazeID(forTVDBID id: Int) async -> Int?
}
