//
//  TVMazeService.swift
//  NextSeason
//

import Foundation

/// Abstraction over the TVMaze API so view models can be tested with a mock.
nonisolated protocol TVMazeService: Sendable {
    /// Shows matching a free-text query, best matches first. Empty query → `[]`.
    func searchShows(matching query: String) async throws -> [Show]

    /// Full show info including embedded seasons and next episode.
    func show(id: Int, bypassCache: Bool) async throws -> Show

    /// Show IDs updated since the given window (`GET /updates/shows`).
    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date]
}

nonisolated enum TVMazeUpdatePeriod: String, Sendable {
    case day, week, month
}

extension TVMazeService {
    func show(id: Int) async throws -> Show {
        try await show(id: id, bypassCache: false)
    }
}
