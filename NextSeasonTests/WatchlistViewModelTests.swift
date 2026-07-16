//
//  WatchlistViewModelTests.swift
//  NextSeasonTests
//

import CoreGraphics
import Foundation
import Testing
@testable import NextSeason

@MainActor
struct WatchlistViewModelTests {
    private var sampleShow: Show {
        makeShow(id: 44933, name: "Severance")
    }

    private func makeShow(id: Int, name: String) -> Show {
        Show(
            id: id,
            name: name,
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/\(id)"),
            summaryHTML: "<p>A workplace thriller.</p>",
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .running,
            premiered: TVMazeDate.dateOnly("2022-02-18"),
            ended: nil,
            network: "Apple TV",
            genres: ["Drama"],
            averageRuntime: 49,
            seasons: [],
            nextEpisode: nil,
            updatedAt: .now
        )
    }

    private func loadedViewModel(with shows: [Show]) async throws -> WatchlistViewModel {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        for show in shows {
            try await repository.add(show)
        }
        await viewModel.reload()
        return viewModel
    }

    @Test("Reload loads tracked shows from persistence")
    func reloadLoadsTrackedShows() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        try await repository.add(sampleShow)

        await viewModel.reload()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.shows.count == 1)
        #expect(viewModel.shows[0].name == sampleShow.name)
    }

    @Test("A pending removal keeps the show visible in the loaded list")
    func pendingRemovalKeepsRowVisible() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        try await repository.add(sampleShow)
        await viewModel.reload()
        let tracked = try #require((try await repository.all()).first)

        viewModel.requestRemoval(tracked, anchor: .zero)

        #expect(viewModel.isPendingRemoval(tracked))
        #expect(viewModel.shows.count == 1)
        #expect(try await repository.contains(showID: tracked.id))
    }

    @Test("Committing a pending removal reloads an empty watchlist")
    func commitPendingRemovalReloadsList() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        try await repository.add(sampleShow)
        await viewModel.reload()
        let tracked = try #require((try await repository.all()).first)

        viewModel.requestRemoval(tracked, anchor: .zero)
        await viewModel.commitPendingRemovalIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.shows.isEmpty)
        #expect(viewModel.pendingRemoval == nil)
    }

    @Test("Animated removal drops the row from the loaded list")
    func removeShowAnimatedDropsRow() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        try await repository.add(sampleShow)
        await viewModel.reload()
        let tracked = try #require((try await repository.all()).first)

        viewModel.removeShowAnimated(showID: tracked.id)

        #expect(viewModel.state == .loaded)
        #expect(viewModel.shows.isEmpty)
    }

    @Test("Undo clears the pending removal flag")
    func undoPendingRemovalClearsPendingState() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        try await repository.add(sampleShow)
        await viewModel.reload()
        let tracked = try #require((try await repository.all()).first)

        viewModel.requestRemoval(tracked, anchor: .zero)
        viewModel.undoPendingRemoval()

        #expect(viewModel.pendingRemoval == nil)
        #expect(viewModel.isPendingRemoval(tracked) == false)
    }

    @Test("An empty search query shows every tracked show")
    func emptySearchReturnsAllShows() async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Severance"),
            makeShow(id: 2, name: "The Bear"),
        ])

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.filteredShows.count == 2)
    }

    @Test("A whitespace-only query is treated as no filter")
    func whitespaceQueryReturnsAllShows() async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Severance"),
            makeShow(id: 2, name: "The Bear"),
        ])

        viewModel.searchText = "   "

        #expect(viewModel.filteredShows.count == 2)
    }

    @Test("Search matches a partial substring of the show name")
    func searchMatchesPartialName() async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Severance"),
            makeShow(id: 2, name: "The Bear"),
            makeShow(id: 3, name: "Slow Horses"),
        ])

        viewModel.searchText = "ear"

        #expect(viewModel.filteredShows.map(\.name) == ["The Bear"])
    }

    @Test("Search ignores case and diacritics", arguments: ["POKEMON", "pokemon", "pokémon"])
    func searchIgnoresCaseAndDiacritics(query: String) async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Pokémon"),
            makeShow(id: 2, name: "The Bear"),
        ])

        viewModel.searchText = query

        #expect(viewModel.filteredShows.map(\.id) == [1])
    }

    @Test("A query with no matches yields an empty filtered list")
    func searchWithNoMatchesReturnsEmpty() async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Severance"),
            makeShow(id: 2, name: "The Bear"),
        ])

        viewModel.searchText = "zzz"

        #expect(viewModel.filteredShows.isEmpty)
        #expect(viewModel.shows.count == 2)
    }

    @Test("Filtering leaves the underlying show list intact")
    func filteringDoesNotMutateBackingList() async throws {
        let viewModel = try await loadedViewModel(with: [
            makeShow(id: 1, name: "Severance"),
            makeShow(id: 2, name: "The Bear"),
        ])

        viewModel.searchText = "Severance"

        #expect(viewModel.filteredShows.count == 1)
        #expect(viewModel.shows.count == 2)
    }
}
