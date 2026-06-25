//
//  SearchViewModel.swift
//  NextSeason
//

import Foundation

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
    private let debounce: Duration
    /// Query that produced the current `.results` or `.empty` state.
    private var displayedQuery: String?

    init(service: any TVMazeService = TVMazeClient(), debounce: Duration = .milliseconds(300)) {
        self.service = service
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
        do {
            let shows = try await service.searchShows(matching: trimmed)
            guard !Task.isCancelled else { return }
            displayedQuery = trimmed
            state = shows.isEmpty ? .empty : .results(shows)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            displayedQuery = nil
            state = .failed(error.localizedDescription)
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
