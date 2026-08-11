//
//  TVDBSearchResult.swift
//  NextSeason
//

import Foundation

/// A series hit from TheTVDB search.
///
/// Identity is TheTVDB's series id — not a TVMaze id. Search filters hits through
/// the local TVDB↔TVMaze compatibility index before display. Open/track still
/// resolves through TVMaze (`show(id:)` / lookup / IMDb fallback) so TVMaze
/// remains the source of truth for detail and watchlist.
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
    /// fallback during open/track when TheTVDB → TVMaze resolution fails.
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
