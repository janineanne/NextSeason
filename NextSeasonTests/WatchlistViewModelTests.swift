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

    @Test("Pending-removal clear animates row away only after persistence removes it")
    func pendingRemovalClearAnimatesCommittedRemoval() async throws {
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
        await undoRemoval.commitPendingRemovalIfNeeded()
        await viewModel.handlePendingRemovalIDChange(from: tracked.id, to: nil)

        #expect(viewModel.shows.isEmpty)
    }

    @Test("Pending-removal clear leaves the row when undo restored it")
    func pendingRemovalClearKeepsRowAfterUndo() async throws {
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
        await viewModel.handlePendingRemovalIDChange(from: tracked.id, to: nil)

        #expect(viewModel.shows.count == 1)
        #expect(try await repository.contains(showID: tracked.id))
    }

    @Test("Replacing a pending removal drops the first show from the displayed list")
    func replacingPendingRemovalDropsFirstShowFromDisplayedList() async throws {
        let repository = InMemoryWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        let firstShow = makeShow(id: 44933, name: "Severance")
        let secondShow = makeShow(id: 82, name: "Game of Thrones")
        try await repository.add(firstShow)
        try await repository.add(secondShow)
        await viewModel.reload()

        let first = try #require(viewModel.shows.first { $0.id == firstShow.id })
        let second = try #require(viewModel.shows.first { $0.id == secondShow.id })

        viewModel.requestRemoval(first, anchor: .zero)
        viewModel.requestRemoval(second, anchor: .zero)

        #expect(viewModel.pendingRemoval?.id == second.id)

        let deadline = Date().addingTimeInterval(1)
        while Date() < deadline, try await repository.contains(showID: first.id) {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(try await repository.contains(showID: first.id) == false)
        #expect(viewModel.shows.map(\.id).contains(first.id) == false)
        #expect(viewModel.shows.map(\.id).contains(second.id))
        #expect(viewModel.isPendingRemoval(second))
        #expect(try await repository.contains(showID: second.id))
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

    @Test("A slower older reload cannot overwrite a newer reload result")
    func slowerOlderReloadDoesNotOverwriteNewerResult() async throws {
        let repository = ReentrantWatchlistRepository()
        let undoRemoval = WatchlistUndoRemoval(repository: repository, analytics: RecordingAnalyticsService())
        let viewModel = WatchlistViewModel(
            repository: repository,
            undoRemoval: undoRemoval,
            analytics: RecordingAnalyticsService()
        )
        repository.viewModel = viewModel
        repository.showToInsertDuringFirstAll = TrackedShow(from: sampleShow)

        await viewModel.reload()

        // Nested reload during the first `all()` applies the newer list; the
        // outer reload's empty result must not overwrite it.
        #expect(viewModel.shows.map(\.id) == [sampleShow.id])
        #expect(viewModel.state == .loaded)
        #expect(repository.allCallCount == 2)
    }
}

/// On the first `all()`, inserts a show and re-enters `reload()` before returning
/// an empty (stale) snapshot — exercising generation discard without concurrent tasks.
@MainActor
private final class ReentrantWatchlistRepository: WatchlistRepository {
    weak var viewModel: WatchlistViewModel?
    var showToInsertDuringFirstAll: TrackedShow?
    private(set) var allCallCount = 0
    private var shows: [Int: TrackedShow] = [:]

    func all() async throws -> [TrackedShow] {
        allCallCount += 1
        if allCallCount == 1, let showToInsertDuringFirstAll, let viewModel {
            shows[showToInsertDuringFirstAll.id] = showToInsertDuringFirstAll
            await viewModel.reload()
            return []
        }
        return shows.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    func trackedShow(showID: Int) async throws -> TrackedShow? {
        shows[showID]
    }

    func trackedShowIDs() async throws -> Set<Int> {
        Set(shows.keys)
    }

    func contains(showID: Int) async throws -> Bool {
        shows[showID] != nil
    }

    func add(_ show: Show) async throws {
        guard shows[show.id] == nil else { return }
        shows[show.id] = TrackedShow(from: show)
    }

    func remove(showID: Int) async throws {
        shows.removeValue(forKey: showID)
    }

    func updateAfterRefresh(_ tracked: TrackedShow) async throws {
        shows[tracked.id] = tracked
    }
}
