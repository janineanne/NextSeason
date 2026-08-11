//
//  SearchViewModelTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct SearchViewModelTests {
    /// A `TheTVDBService` whose search behavior is supplied per test.
    private struct MockSearchService: TheTVDBService {
        let handler: @Sendable (String, Int) async throws -> TheTVDBSearchPage

        func searchSeries(matching query: String, offset: Int) async throws -> TheTVDBSearchPage {
            try await handler(query, offset)
        }
    }

    private struct MockTVMazeService: TVMazeService {
        var lookupHandler: @Sendable (Int) async throws -> Show = { _ in .preview }
        var showHandler: @Sendable (Int) async throws -> Show = { _ in .preview }
        var imdbHandler: @Sendable (String) async throws -> Show = { _ in
            throw TVMazeError.notFound
        }
        private(set) var lookupCallCount = 0
        private(set) var imdbCallCount = 0

        mutating func resetCounts() {
            lookupCallCount = 0
            imdbCallCount = 0
        }

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func lookupShow(theTVDBID: Int) async throws -> Show {
            // Counts are best-effort for assertions in single-threaded tests.
            return try await lookupHandler(theTVDBID)
        }

        func lookupShow(imdbID: String) async throws -> Show {
            try await imdbHandler(imdbID)
        }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            try await showHandler(id)
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            [:]
        }
    }

    /// Tracks TVMaze lookup traffic without mutating struct copies.
    private final class LookupCounter: @unchecked Sendable {
        private let lock = NSLock()
        private(set) var theTVDBLookups = 0
        private(set) var imdbLookups = 0

        func recordTheTVDB() {
            lock.lock()
            theTVDBLookups += 1
            lock.unlock()
        }

        func recordIMDb() {
            lock.lock()
            imdbLookups += 1
            lock.unlock()
        }
    }

    private struct CountingTVMazeService: TVMazeService {
        let counter: LookupCounter
        var showHandler: @Sendable (Int) async throws -> Show = { _ in .preview }
        var imdbHandler: @Sendable (String) async throws -> Show = { _ in
            throw TVMazeError.notFound
        }

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func lookupShow(theTVDBID: Int) async throws -> Show {
            counter.recordTheTVDB()
            throw TVMazeError.notFound
        }

        func lookupShow(imdbID: String) async throws -> Show {
            counter.recordIMDb()
            return try await imdbHandler(imdbID)
        }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            try await showHandler(id)
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            [:]
        }
    }

    private struct TestError: LocalizedError {
        var errorDescription: String? { "Something failed" }
    }

    private let sampleResult = TVDBSearchResult(
        id: 371980,
        name: "Severance",
        year: "2022",
        network: "Apple TV",
        status: "Continuing",
        posterURL: nil,
        imdbID: "tt11280740"
    )

    private func compatibleIndex(
        map: [Int: Int] = [371980: 44933]
    ) -> InMemoryCompatibilityIndex {
        InMemoryCompatibilityIndex(map: map)
    }

    private func makeViewModel(
        search: MockSearchService,
        tvMaze: some TVMazeService = MockTVMazeService(),
        index: InMemoryCompatibilityIndex? = nil
    ) -> SearchViewModel {
        SearchViewModel(
            searchService: search,
            tvMaze: tvMaze,
            compatibilityIndex: index ?? compatibleIndex(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
    }

    @Test("An empty/whitespace query resets to idle without calling the service")
    func emptyQueryStaysIdle() async {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                Issue.record("service should not be called")
                return TheTVDBSearchPage(results: [], hasMore: false)
            }
        )
        viewModel.query = "   "
        await viewModel.search()
        #expect(viewModel.state == .idle)
    }

    @Test("Matching compatible shows populate the results state")
    func resultsPopulateState() async {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            }
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )
        #expect(viewModel.resolvedTVMazeID(for: sampleResult.id) == 44933)
    }

    @Test("Filtering removes incompatible results")
    func filteringRemovesIncompatibleResults() async {
        let incompatible = TVDBSearchResult(
            id: 1,
            name: "Only On TheTVDB",
            year: "2020",
            network: nil,
            status: "Ended",
            posterURL: nil,
            imdbID: nil
        )
        let counter = LookupCounter()
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult, incompatible], hasMore: false)
            },
            tvMaze: CountingTVMazeService(counter: counter),
            index: compatibleIndex(map: [371980: 44933])
        )
        viewModel.query = "show"
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )
        #expect(counter.theTVDBLookups == 0)
    }

    @Test("Pagination continues when filtering leaves too few usable results")
    func paginationContinuesWhenFilteredThin() async {
        let page1Only = TVDBSearchResult(
            id: 1,
            name: "Unmapped",
            year: nil,
            network: nil,
            status: nil,
            posterURL: nil,
            imdbID: nil
        )
        let page2Mapped = TVDBSearchResult(
            id: 2,
            name: "Mapped",
            year: "2021",
            network: nil,
            status: "Continuing",
            posterURL: nil,
            imdbID: nil
        )
        let offsets = CallCounter()
        let viewModel = makeViewModel(
            search: MockSearchService { _, offset in
                offsets.value += 1
                if offset == 0 {
                    return TheTVDBSearchPage(results: [page1Only], hasMore: true)
                }
                return TheTVDBSearchPage(results: [page2Mapped], hasMore: false)
            },
            index: compatibleIndex(map: [2: 99])
        )
        viewModel.query = "thin"
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [page2Mapped], hasMore: false))
        )
        #expect(offsets.value == 2)
    }

    @Test("Pagination terminates correctly when there are no more results")
    func paginationTerminatesWhenExhausted() async {
        let unmapped = TVDBSearchResult(
            id: 1,
            name: "Unmapped",
            year: nil,
            network: nil,
            status: nil,
            posterURL: nil,
            imdbID: nil
        )
        let offsets = CallCounter()
        let viewModel = makeViewModel(
            search: MockSearchService { _, offset in
                offsets.value += 1
                #expect(offset == 0)
                return TheTVDBSearchPage(results: [unmapped], hasMore: false)
            },
            index: compatibleIndex(map: [:])
        )
        viewModel.query = "gone"
        await viewModel.search()
        #expect(viewModel.state == .empty)
        #expect(offsets.value == 1)
    }

    @Test("No matches yield the empty state")
    func noMatchesYieldEmpty() async {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [], hasMore: false)
            }
        )
        viewModel.query = "no-such-show"
        await viewModel.search()
        #expect(viewModel.state == .empty)
    }

    @Test("A service error surfaces as the failed state with its message")
    func serviceErrorYieldsFailed() async {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in throw TestError() }
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(viewModel.state == .failed("Something failed"))
    }

    @Test("Clearing the query after results returns to idle")
    func clearingQueryReturnsToIdle() async {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            }
        )
        viewModel.query = FirstRunCopy.exampleSearchQuery
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )

        viewModel.query = ""
        await viewModel.search()
        #expect(viewModel.state == .idle)
    }

    @Test("Repeating the same query while results are shown does not reload")
    func repeatedQuerySkipsReload() async {
        let counter = CallCounter()
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                counter.value += 1
                return TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            }
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(counter.value == 1)

        await viewModel.search()
        #expect(counter.value == 1)
    }

    @Test("Load more appends the next actionable page")
    func loadMoreAppendsNextPage() async {
        let second = TVDBSearchResult(
            id: 2,
            name: "Other Show",
            year: "2020",
            network: nil,
            status: "Ended",
            posterURL: nil,
            imdbID: nil
        )
        let viewModel = makeViewModel(
            search: MockSearchService { _, offset in
                if offset == 0 {
                    return TheTVDBSearchPage(results: [sampleResult], hasMore: true)
                }
                return TheTVDBSearchPage(results: [second], hasMore: false)
            },
            index: compatibleIndex(map: [371980: 44933, 2: 82])
        )
        viewModel.query = "severance"
        await viewModel.search()
        await viewModel.loadMore()
        #expect(
            viewModel.state
                == .results(
                    SearchViewModel.ResultsPage(items: [sampleResult, second], hasMore: false)
                )
        )
    }

    @Test("Resolve maps a TheTVDB hit to a TVMaze show via compatibility id")
    func resolveMapsToTVMazeShow() async throws {
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            }
        )
        let show = try await viewModel.resolveShow(for: sampleResult)
        #expect(show.id == Show.preview.id)
        #expect(viewModel.resolvedTVMazeID(for: sampleResult.id) == Show.preview.id)
    }

    @Test("Search does not prefetch TheTVDB lookups for compatible results")
    func searchDoesNotPrefetchTheTVDBLookups() async {
        let counter = LookupCounter()
        let viewModel = makeViewModel(
            search: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            },
            tvMaze: CountingTVMazeService(counter: counter),
            index: compatibleIndex(map: [371980: 44933])
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(counter.theTVDBLookups == 0)
        #expect(counter.imdbLookups == 0)
    }

    private final class CallCounter: @unchecked Sendable {
        var value = 0
    }
}
