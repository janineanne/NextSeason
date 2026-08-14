//
//  TVDBSearchResult.swift
//  NextSeason
//

import Foundation

/// A series hit from TheTVDB search.
///
/// Identity is TheTVDB's series id — not a TVMaze id. Search filters hits through
/// the local TVDB↔TVMaze show ID mapping before display, overlaying TVMaze title
/// and poster from that snapshot. Open/track resolves via the mapped TVMaze id
/// (`show(id:)`), falling back to `lookupShow(theTVDBID:)` when a mapping is stale.
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

    /// Returns a copy using cached TVMaze display fields.
    ///
    /// The title falls back to TheTVDB when the mapping has no name.
    /// Posters intentionally never fall back to TheTVDB artwork  —
    /// TheTVDB artwork is not licensed for this use.
    func overlayingTVMazeDisplayFields(_ record: ShowIDMappingRecord) -> TVDBSearchResult {
        let trimmedName = record.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return TVDBSearchResult(
            id: id,
            name: trimmedName.isEmpty ? name : trimmedName,
            year: year,
            network: network,
            status: status,
            posterURL: record.posterMediumURL
        )
    }
}
