//
//  TheTVDBService.swift
//  NextSeason
//

import Foundation

/// One page of TheTVDB series search hits.
///
/// `hasMore` is derived from TheTVDB's `links` metadata (or a full page of
/// results) so `SearchViewModel` can show a "Load more" control without
/// parsing their occasionally-malformed `next` URLs.
nonisolated struct TheTVDBSearchPage: Sendable, Equatable {
    let results: [TVDBSearchResult]
    /// `true` when another `offset` page may still contain matches.
    let hasMore: Bool
}

/// Abstraction over TheTVDB search so view models can be tested with a mock.
///
/// Production uses `TheTVDBClient`. UI tests / previews use
/// `PreviewTheTVDBService`. Keeping search behind this protocol mirrors
/// `TVMazeService` and lets Search stay provider-swappable without touching
/// detail or watchlist code.
nonisolated protocol TheTVDBService: Sendable {
    /// Series matching a free-text query, best matches first.
    ///
    /// Empty / whitespace query → empty page with `hasMore == false`.
    /// `offset` is the zero-based result index (`page * pageSize`), matching
    /// TheTVDB's query parameter (not a 1-based page number).
    func searchSeries(matching query: String, offset: Int) async throws -> TheTVDBSearchPage
}
