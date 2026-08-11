//
//  TVDBSearchResult.swift
//  NextSeason
//

import Foundation

/// A series hit from TheTVDB search.
///
/// Identity is TheTVDB's series id — not a TVMaze id. The existing detail and
/// watchlist flows speak TVMaze ids only, so a hit must be resolved through
/// `TVMazeService.lookupShow(theTVDBID:)` (or IMDb fallback) before navigation
/// or tracking. Search rows can render from this type alone; stars light up
/// once `SearchViewModel` has cached the TVMaze mapping.
nonisolated struct TVDBSearchResult: Identifiable, Sendable, Hashable {
    /// TheTVDB series id (`tvdb_id` from the search payload).
    let id: Int
    let name: String
    let year: String?
    let network: String?
    /// Provider status string (e.g. "Continuing", "Ended"); shown as-is on
    /// search rows rather than mapped into TVMaze's `ShowStatus`.
    let status: String?
    let posterURL: URL?
    /// IMDb id when present (e.g. `tt11280740`), used as a TVMaze lookup
    /// fallback when `/lookup/shows?thetvdb=` returns 404.
    let imdbID: String?

    /// Compact subtitle for search rows (year and/or status).
    var searchSubtitle: String {
        let parts = [year, status].compactMap { value -> String? in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if parts.isEmpty {
            return String(localized: "TV series")
        }
        return parts.joined(separator: " · ")
    }
}
