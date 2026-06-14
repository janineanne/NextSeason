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
    func show(id: Int) async throws -> Show
}
