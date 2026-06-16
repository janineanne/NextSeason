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
            return
        }

        do {
            try await Task.sleep(for: debounce)
        } catch {
            return // superseded by a newer query
        }

        state = .loading
        do {
            let shows = try await service.searchShows(matching: trimmed)
            guard !Task.isCancelled else { return }
            state = shows.isEmpty ? .empty : .results(shows)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
