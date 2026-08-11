//
//  TheTVDBService.swift
//  NextSeason
//

import Foundation

/// One page of TheTVDB series search hits.
///
/// Pagination bookkeeping (`hasMore`, `nextOffset`) is owned by the service
/// implementation and must be based on the **raw** API row count / links
/// metadata — not the number of domain results after sparse records are
/// dropped. That keeps TheTVDB's `offset` cursor aligned across pages.
nonisolated struct TheTVDBSearchPage: Sendable, Equatable {
    let results: [TVDBSearchResult]
    /// `true` when another `offset` page may still contain matches.
    let hasMore: Bool
    /// Absolute TheTVDB `offset` to request for the next page.
    let nextOffset: Int
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
    /// Callers must continue with `page.nextOffset` rather than reconstructing
    /// offset from `results.count`.
    func searchSeries(matching query: String, offset: Int) async throws -> TheTVDBSearchPage
}
