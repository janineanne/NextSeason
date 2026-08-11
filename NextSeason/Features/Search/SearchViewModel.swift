//
//  SearchViewModel.swift
//  NextSeason
//

import Foundation

/// Debounced TheTVDB title search for `SearchView`, with local compatibility
/// filtering and TVMaze resolution on select.
///
/// Intended to be driven by `.task(id: query)`: each keystroke cancels the prior
/// task, and `search()` sleeps for `debounce` before hitting the network — so
/// rapid typing only fetches the final query.
///
/// Provider split:
/// - **Search list** — TheTVDB hits (`TVDBSearchResult`), paginated, then filtered
///   through the local TVDB↔TVMaze compatibility index (not a TVMaze network
///   lookup per hit). Pages are advanced until a reasonable actionable batch is
///   collected or TheTVDB results are exhausted.
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
    /// Visible page of actionable TheTVDB hits plus whether "Load more" should appear.
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

    /// Soft target for how many actionable rows to gather before stopping page fill.
    nonisolated static let actionablePageTarget = TheTVDBConfiguration.pageSize
    /// Cap on TheTVDB pages fetched per search / load-more burst.
    nonisolated static let maxTheTVDBPagesPerFill = 6

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
    private let compatibilityIndex: any TVDBTVMazeCompatibilityIndex
    private let analytics: any AnalyticsTracking
    private let debounce: Duration
    /// Trimmed query that produced the current `.results` or `.empty` state; `nil`
    /// while idle, loading, or after a failed search.
    private var displayedQuery: String?
    /// Next TheTVDB `offset` for the active `displayedQuery` (sum of fetched counts).
    private var nextOffset = 0
    /// Cache of TheTVDB series id → TVMaze show id from the local index.
    /// Used for search-row stars without network prefetch.
    private var resolvedTVMazeIDsByTVDBID: [Int: Int] = [:]
    /// Cache of full TVMaze shows after an explicit open/track resolve.
    private var resolvedShowsByTVDBID: [Int: Show] = [:]

    init(
        searchService: any TheTVDBService,
        tvMaze: any TVMazeService,
        compatibilityIndex: any TVDBTVMazeCompatibilityIndex,
        analytics: any AnalyticsTracking,
        debounce: Duration = .milliseconds(300)
    ) {
        self.searchService = searchService
        self.tvMaze = tvMaze
        self.compatibilityIndex = compatibilityIndex
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
        resolvedTVMazeIDsByTVDBID.removeAll(keepingCapacity: true)
        resolvedShowsByTVDBID.removeAll(keepingCapacity: true)
        let searchStarted = Date.now
        AppDiagnosticsLogger.breadcrumb("search_viewmodel_start")
        do {
            let fill = try await collectActionableResults(
                matching: trimmed,
                startingOffset: 0,
                existingIDs: [],
                targetCount: Self.actionablePageTarget
            )
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("search_viewmodel")
                return
            }
            let durationMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
            displayedQuery = trimmed
            nextOffset = fill.nextOffset
            if fill.items.isEmpty, !fill.hasMore {
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
                // Empty items with hasMore means the page-fill cap found nothing
                // actionable yet, but TheTVDB still has pages — keep Load More.
                state = .results(ResultsPage(items: fill.items, hasMore: fill.hasMore))
                analytics.track(
                    .searchPerformed(
                        queryLength: trimmed.count,
                        resultCount: fill.items.count,
                        durationMs: max(durationMs, 0)
                    )
                )
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

    /// Appends another batch of actionable TheTVDB hits for the current query.
    ///
    /// Continues requesting TheTVDB pages (with a safety cap) until enough
    /// locally mappable results are gathered or TheTVDB has no more pages.
    func loadMore() async {
        guard case .results(let page) = state, page.hasMore, !isLoadingMore else { return }
        let trimmed = displayedQuery ?? query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let existingIDs = Set(page.items.map(\.id))
            let fill = try await collectActionableResults(
                matching: trimmed,
                startingOffset: nextOffset,
                existingIDs: existingIDs,
                targetCount: Self.actionablePageTarget
            )
            guard !Task.isCancelled else { return }
            guard case .results(let current) = state else { return }

            var merged = current.items
            for result in fill.items where !existingIDs.contains(result.id) {
                merged.append(result)
            }
            nextOffset = fill.nextOffset
            if merged.isEmpty, !fill.hasMore {
                state = .empty
                analytics.track(.emptySearchResultsShown)
            } else {
                state = .results(ResultsPage(items: merged, hasMore: fill.hasMore))
            }
        } catch is CancellationError {
            return
        } catch {
            analytics.trackNonFatalError(error, context: "search_load_more")
            presentResolveError(error.localizedDescription)
        }
    }

    /// Resolves a TheTVDB hit to the canonical TVMaze `Show` (with seasons when possible).
    ///
    /// Uses the in-memory show cache when present. Otherwise prefers the local
    /// compatibility id (`show(id:)`), then live TheTVDB lookup if that mapping
    /// is missing or stale.
    func resolveShow(for result: TVDBSearchResult) async throws -> Show {
        if let cached = resolvedShowsByTVDBID[result.id] {
            return try await enrichedShow(from: cached)
        }

        resolvingResultIDs.insert(result.id)
        defer { resolvingResultIDs.remove(result.id) }

        let lookedUp = try await lookupTVMazeShow(for: result)
        resolvedShowsByTVDBID[result.id] = lookedUp
        resolvedTVMazeIDsByTVDBID[result.id] = lookedUp.id
        return try await enrichedShow(from: lookedUp)
    }

    /// TVMaze show id known for a TheTVDB hit (local index / prior resolve).
    func resolvedTVMazeID(for resultID: Int) -> Int? {
        resolvedTVMazeIDsByTVDBID[resultID] ?? resolvedShowsByTVDBID[resultID]?.id
    }

    func clearResolveError() {
        resolveErrorMessage = nil
    }

    /// Surfaces a resolve / follow-up failure on the search screen alert.
    func presentResolveError(_ message: String) {
        resolveErrorMessage = message
    }

    // MARK: - Compatibility filtering

    private struct ActionableFill {
        var items: [TVDBSearchResult]
        var nextOffset: Int
        var hasMore: Bool
    }

    /// Fetches TheTVDB pages and keeps only hits present in the local
    /// TVDB→TVMaze compatibility index.
    private func collectActionableResults(
        matching query: String,
        startingOffset: Int,
        existingIDs: Set<Int>,
        targetCount: Int
    ) async throws -> ActionableFill {
        var collected: [TVDBSearchResult] = []
        var seen = existingIDs
        var offset = startingOffset
        var pagesFetched = 0
        var tvdbHasMore = true

        while collected.count < targetCount, tvdbHasMore, pagesFetched < Self.maxTheTVDBPagesPerFill
        {
            try Task.checkCancellation()
            let previousOffset = offset
            let page = try await searchService.searchSeries(matching: query, offset: offset)
            pagesFetched += 1
            // Trust the service's cursor — it advances by raw API row count, not
            // domain `results.count` after sparse records are dropped.
            offset = page.nextOffset
            tvdbHasMore = page.hasMore

            // Refuse to spin if a page claims more results but did not advance.
            if page.hasMore, offset <= previousOffset {
                tvdbHasMore = false
                break
            }

            let actionable = await filterActionable(page.results)
            for result in actionable where !seen.contains(result.id) {
                seen.insert(result.id)
                collected.append(result)
                if collected.count >= targetCount { break }
            }

            // Stop when TheTVDB reports exhaustion even if under target — do not
            // keep requesting solely to chase an arbitrary count.
            if !page.hasMore { break }
        }

        return ActionableFill(items: collected, nextOffset: offset, hasMore: tvdbHasMore)
    }

    private func filterActionable(_ results: [TVDBSearchResult]) async -> [TVDBSearchResult] {
        var actionable: [TVDBSearchResult] = []
        actionable.reserveCapacity(results.count)

        for result in results {
            guard let mappedID = await compatibilityIndex.tvMazeID(forTVDBID: result.id) else {
                continue
            }
            resolvedTVMazeIDsByTVDBID[result.id] = mappedID
            actionable.append(result)
        }

        return actionable
    }

    private func lookupTVMazeShow(for result: TVDBSearchResult) async throws -> Show {
        let mappedID: Int?
        if let cached = resolvedTVMazeIDsByTVDBID[result.id] {
            mappedID = cached
        } else {
            mappedID = await compatibilityIndex.tvMazeID(forTVDBID: result.id)
        }

        if let mappedID {
            do {
                return try await tvMaze.show(id: mappedID)
            } catch TVMazeError.notFound {
                // Mapping may be stale; fall through to live TheTVDB lookup.
            }
        }

        return try await tvMaze.lookupShow(theTVDBID: result.id)
    }

    /// Lookup / index payloads may omit embeds; fetch full detail when seasons
    /// are missing so tracking / detail have next-season inputs immediately.
    private func enrichedShow(from show: Show) async throws -> Show {
        if !show.seasons.isEmpty { return show }
        return try await tvMaze.show(id: show.id)
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
