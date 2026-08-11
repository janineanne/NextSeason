//
//  SearchViewModel.swift
//  NextSeason
//

import Foundation

/// Debounced TheTVDB title search for `SearchView`, with TVMaze resolution on select.
///
/// Intended to be driven by `.task(id: query)`: each keystroke cancels the prior
/// task, and `search()` sleeps for `debounce` before hitting the network — so
/// rapid typing only fetches the final query.
///
/// Provider split:
/// - **Search list** — TheTVDB hits (`TVDBSearchResult`), paginated.
/// - **Open / track** — resolve to a TVMaze `Show` first, then use the existing
///   detail and watchlist flows unchanged (those still key off TVMaze ids).
///
/// `displayedQuery` is the trimmed query that produced the current `.results` or
/// `.empty` outcome. When `.task` re-runs with the same text (e.g. returning from
/// show detail), `search()` skips the loading flash and keeps that outcome.
/// Failures clear `displayedQuery` so a retry is not short-circuited.
@Observable
@MainActor
final class SearchViewModel {
    /// Visible page of TheTVDB hits plus whether "Load more" should appear.
    struct ResultsPage: Equatable {
        var items: [TVDBSearchResult]
        var hasMore: Bool
    }

    enum State: Equatable {
        case idle
        case loading
        case results(ResultsPage)
        case empty
        case failed(String)
    }

    private(set) var state: State = .idle
    var query: String = ""
    /// TheTVDB series ids currently resolving to TVMaze (row / navigation lock).
    private(set) var resolvingResultIDs: Set<Int> = []
    /// User-facing error from a failed resolve or load-more (alert).
    private(set) var resolveErrorMessage: String?
    /// True while a "Load more" request is in flight.
    private(set) var isLoadingMore = false

    private let searchService: any TheTVDBService
    private let tvMaze: any TVMazeService
    private let analytics: any AnalyticsTracking
    private let debounce: Duration
    /// Trimmed query that produced the current `.results` or `.empty` state; `nil`
    /// while idle, loading, or after a failed search.
    private var displayedQuery: String?
    /// Next TheTVDB `offset` for the active `displayedQuery` (sum of fetched counts).
    private var nextOffset = 0
    /// Cache of TheTVDB series id → resolved TVMaze show (lookup payload).
    /// Used for open/track and to light search-row stars after prefetch.
    private var resolvedShowsByTVDBID: [Int: Show] = [:]

    init(
        searchService: any TheTVDBService,
        tvMaze: any TVMazeService,
        analytics: any AnalyticsTracking,
        debounce: Duration = .milliseconds(300)
    ) {
        self.searchService = searchService
        self.tvMaze = tvMaze
        self.analytics = analytics
        self.debounce = debounce
    }

    /// Runs the current `query`. Intended to be driven by `.task(id: query)`,
    /// which cancels the previous run when the text changes, giving us debounce.
    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            displayedQuery = nil
            nextOffset = 0
            isLoadingMore = false
            return
        }

        do {
            try await Task.sleep(for: debounce)
        } catch {
            return  // superseded by a newer query
        }

        // `.task(id: query)` runs again when returning from show detail; keep
        // existing results instead of flashing the loading placeholder.
        if trimmed == displayedQuery, isShowingSearchOutcome {
            return
        }

        state = .loading
        isLoadingMore = false
        nextOffset = 0
        let searchStarted = Date.now
        AppDiagnosticsLogger.breadcrumb("search_viewmodel_start")
        do {
            let page = try await searchService.searchSeries(matching: trimmed, offset: 0)
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("search_viewmodel")
                return
            }
            let durationMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
            displayedQuery = trimmed
            nextOffset = page.results.count
            if page.results.isEmpty {
                state = .empty
                analytics.track(
                    .searchPerformed(
                        queryLength: trimmed.count,
                        resultCount: 0,
                        durationMs: max(durationMs, 0)
                    )
                )
                analytics.track(.emptySearchResultsShown)
            } else {
                // Publish results before prefetch so the list is not blocked on
                // TVMaze lookups; stars fill in as mappings arrive.
                state = .results(ResultsPage(items: page.results, hasMore: page.hasMore))
                analytics.track(
                    .searchPerformed(
                        queryLength: trimmed.count,
                        resultCount: page.results.count,
                        durationMs: max(durationMs, 0)
                    )
                )
                await prefetchResolutions(for: page.results)
            }
        } catch is CancellationError {
            AppDiagnosticsLogger.logTaskCancel("search_viewmodel")
            return
        } catch {
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("search_viewmodel")
                return
            }
            let durationMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
            displayedQuery = nil
            nextOffset = 0
            state = .failed(error.localizedDescription)
            analytics.track(
                .searchPerformed(
                    queryLength: trimmed.count,
                    resultCount: 0,
                    durationMs: max(durationMs, 0)
                )
            )
            analytics.trackNonFatalError(error, context: "search")
        }
    }

    /// Appends the next TheTVDB page for the current query.
    ///
    /// Dedupes by TheTVDB id in case a later page repeats a hit, then
    /// prefetches TVMaze mappings for the newly appended rows only.
    func loadMore() async {
        guard case .results(let page) = state, page.hasMore, !isLoadingMore else { return }
        let trimmed = displayedQuery ?? query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = try await searchService.searchSeries(
                matching: trimmed,
                offset: nextOffset
            )
            guard !Task.isCancelled else { return }
            guard case .results(let current) = state else { return }

            var merged = current.items
            let existingIDs = Set(merged.map(\.id))
            for result in nextPage.results where !existingIDs.contains(result.id) {
                merged.append(result)
            }
            // Advance by the raw fetch count (including any skipped dupes) so
            // the next offset stays aligned with TheTVDB's pagination cursor.
            nextOffset += nextPage.results.count
            state = .results(ResultsPage(items: merged, hasMore: nextPage.hasMore))
            await prefetchResolutions(for: nextPage.results)
        } catch is CancellationError {
            return
        } catch {
            analytics.trackNonFatalError(error, context: "search_load_more")
            presentResolveError(error.localizedDescription)
        }
    }

    /// Resolves a TheTVDB hit to the canonical TVMaze `Show` (with seasons when possible).
    ///
    /// Uses the in-memory cache when present, otherwise looks up via TheTVDB id
    /// (IMDb fallback). Lookup payloads omit season embeds, so we fetch full
    /// detail when seasons are empty before returning to the caller.
    func resolveShow(for result: TVDBSearchResult) async throws -> Show {
        if let cached = resolvedShowsByTVDBID[result.id] {
            return try await enrichedShow(from: cached)
        }

        resolvingResultIDs.insert(result.id)
        defer { resolvingResultIDs.remove(result.id) }

        let lookedUp = try await lookupTVMazeShow(for: result)
        resolvedShowsByTVDBID[result.id] = lookedUp
        return try await enrichedShow(from: lookedUp)
    }

    /// TVMaze show id previously resolved for a TheTVDB hit, if any.
    func resolvedTVMazeID(for resultID: Int) -> Int? {
        resolvedShowsByTVDBID[resultID]?.id
    }

    func clearResolveError() {
        resolveErrorMessage = nil
    }

    /// Surfaces a resolve / follow-up failure on the search screen alert.
    func presentResolveError(_ message: String) {
        resolveErrorMessage = message
    }

    private func lookupTVMazeShow(for result: TVDBSearchResult) async throws -> Show {
        try await Self.lookupTVMazeShow(result, tvMaze: tvMaze)
    }

    /// Lookup payloads omit embeds; fetch full detail when seasons are missing
    /// so tracking / detail have next-season inputs immediately.
    private func enrichedShow(from show: Show) async throws -> Show {
        if !show.seasons.isEmpty { return show }
        return try await tvMaze.show(id: show.id)
    }

    /// Best-effort TheTVDB → TVMaze id mapping so search-row stars can reflect
    /// the watchlist without waiting for an explicit open/track.
    ///
    /// Failures are swallowed per-hit: a missing TVMaze counterpart should not
    /// block the rest of the page (the user still sees the TheTVDB row and gets
    /// a clear error if they try to open that one).
    private func prefetchResolutions(for results: [TVDBSearchResult]) async {
        let pending = results.filter { resolvedShowsByTVDBID[$0.id] == nil }
        guard !pending.isEmpty else { return }

        await withTaskGroup(of: (Int, Show)?.self) { group in
            for result in pending {
                group.addTask { [tvMaze] in
                    do {
                        let show = try await Self.lookupTVMazeShow(result, tvMaze: tvMaze)
                        return (result.id, show)
                    } catch {
                        return nil
                    }
                }
            }
            for await mapped in group {
                guard let (tvdbID, show) = mapped else { continue }
                resolvedShowsByTVDBID[tvdbID] = show
            }
        }
    }

    /// Shared TheTVDB → TVMaze lookup used by resolve and prefetch.
    /// `nonisolated` so task-group workers can call it without hopping to MainActor.
    private nonisolated static func lookupTVMazeShow(
        _ result: TVDBSearchResult,
        tvMaze: any TVMazeService
    ) async throws -> Show {
        do {
            return try await tvMaze.lookupShow(theTVDBID: result.id)
        } catch TVMazeError.notFound {
            // Some catalog gaps still have an IMDb id on the TheTVDB hit.
            if let imdbID = result.imdbID {
                return try await tvMaze.lookupShow(imdbID: imdbID)
            }
            throw TVMazeError.notFound
        }
    }

    private var isShowingSearchOutcome: Bool {
        switch state {
        case .results, .empty:
            true
        default:
            false
        }
    }
}
