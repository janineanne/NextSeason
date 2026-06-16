//
//  WatchlistViewModel.swift
//  NextSeason
//

import Foundation

@Observable
@MainActor
final class WatchlistViewModel {
    enum State: Equatable {
        case loading
        case loaded([TrackedShow])
        case failed(String)
    }

    private(set) var state: State = .loading

    private let repository: any WatchlistRepository
    private let refreshService: WatchlistRefreshService?

    init(repository: any WatchlistRepository, refreshService: WatchlistRefreshService? = nil) {
        self.repository = repository
        self.refreshService = refreshService
    }

    func load() async {
        state = .loading
        do {
            let shows = try await repository.all()
            state = .loaded(shows)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refreshFromNetwork() async {
        await refreshService?.refreshAll(force: true)
        await load()
    }

    func remove(showID: Int) async {
        do {
            try await repository.remove(showID: showID)
            await load()
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
