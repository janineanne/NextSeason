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
        Show(
            id: 44933,
            name: "Severance",
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/44933/severance"),
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

    @Test("Reload loads tracked shows from persistence")
    func reloadLoadsTrackedShows() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository)
        let viewModel = WatchlistViewModel(repository: repository, undoRemoval: undoRemoval)
        try await repository.add(sampleShow)

        await viewModel.reload()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.shows.count == 1)
        #expect(viewModel.shows[0].name == sampleShow.name)
    }

    @Test("A pending removal keeps the show visible in the loaded list")
    func pendingRemovalKeepsRowVisible() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository)
        let viewModel = WatchlistViewModel(repository: repository, undoRemoval: undoRemoval)
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
        let undoRemoval = WatchlistUndoRemoval(repository: repository)
        let viewModel = WatchlistViewModel(repository: repository, undoRemoval: undoRemoval)
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
        let undoRemoval = WatchlistUndoRemoval(repository: repository)
        let viewModel = WatchlistViewModel(repository: repository, undoRemoval: undoRemoval)
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
        let undoRemoval = WatchlistUndoRemoval(repository: repository)
        let viewModel = WatchlistViewModel(repository: repository, undoRemoval: undoRemoval)
        try await repository.add(sampleShow)
        await viewModel.reload()
        let tracked = try #require((try await repository.all()).first)

        viewModel.requestRemoval(tracked, anchor: .zero)
        viewModel.undoPendingRemoval()

        #expect(viewModel.pendingRemoval == nil)
        #expect(viewModel.isPendingRemoval(tracked) == false)
    }
}
