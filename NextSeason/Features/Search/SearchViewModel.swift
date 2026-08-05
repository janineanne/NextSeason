//
//  SearchViewModel.swift
//  NextSeason
//

import Foundation

/// Debounced TVMaze title search for `SearchView`.
///
/// Intended to be driven by `.task(id: query)`: each keystroke cancels the prior
/// task, and `search()` sleeps for `debounce` before hitting the network — so
/// rapid typing only fetches the final query.
///
/// `displayedQuery` is the trimmed query that produced the current `.results` or
/// `.empty` outcome. When `.task` re-runs with the same text (e.g. returning from
/// show detail), `search()` skips the loading flash and keeps that outcome.
/// Failures clear `displayedQuery` so a retry is not short-circuited.
@Observable
@MainActor
final class SearchViewModel {
    enum State: Equatable {
        case idle
        case loading
        case results([Show])
        case empty
        case failed(String)
    }

    private(set) var state: State = .idle
    var query: String = ""

    private let service: any TVMazeService
    private let analytics: any AnalyticsTracking
    private let debounce: Duration
    /// Trimmed query that produced the current `.results` or `.empty` state; `nil`
    /// while idle, loading, or after a failed search.
    private var displayedQuery: String?

    init(
        service: any TVMazeService,
        analytics: any AnalyticsTracking,
        debounce: Duration = .milliseconds(300)
    ) {
        self.service = service
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
            return
        }

        do {
            try await Task.sleep(for: debounce)
        } catch {
            return // superseded by a newer query
        }

        // `.task(id: query)` runs again when returning from show detail; keep
        // existing results instead of flashing the loading placeholder.
        if trimmed == displayedQuery, isShowingSearchOutcome {
            return
        }

        state = .loading
        let searchStarted = Date.now
        AppDiagnosticsLogger.breadcrumb("search_viewmodel_start")
        do {
            let shows = try await service.searchShows(matching: trimmed)
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("search_viewmodel")
                return
            }
            let durationMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
            displayedQuery = trimmed
            state = shows.isEmpty ? .empty : .results(shows)
            analytics.track(
                .searchPerformed(
                    queryLength: trimmed.count,
                    resultCount: shows.count,
                    durationMs: max(durationMs, 0)
                )
            )
            if shows.isEmpty {
                analytics.track(.emptySearchResultsShown)
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

    private var isShowingSearchOutcome: Bool {
        switch state {
        case .results, .empty:
            true
        default:
            false
        }
    }
}
