//
//  ShowDetailViewModel.swift
//  NextSeason
//

import Foundation

@Observable
@MainActor
final class ShowDetailViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    /// Header data carried over from search for instant display.
    let initialShow: Show
    private(set) var fullShow: Show?
    private(set) var loadState: LoadState = .loading

    private let service: any TVMazeService

    init(show: Show, service: any TVMazeService = TVMazeClient()) {
        self.initialShow = show
        self.service = service
    }

    /// Best available show data: the fully-loaded show once fetched, else the
    /// lighter version passed from search.
    var displayShow: Show { fullShow ?? initialShow }

    /// Next-season status, available only once seasons have been loaded.
    var nextSeasonStatus: NextSeasonStatus? {
        fullShow.map { NextSeasonCalculator.status(for: $0) }
    }

    /// Loads full show details (seasons + next episode) needed to derive status.
    func load() async {
        loadState = .loading
        do {
            fullShow = try await service.show(id: initialShow.id)
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
