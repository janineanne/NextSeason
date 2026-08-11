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

        func searchShows(matching query: String) async throws -> [Show] { [] }

        func lookupShow(theTVDBID: Int) async throws -> Show {
            try await lookupHandler(theTVDBID)
        }

        func lookupShow(imdbID: String) async throws -> Show {
            throw TVMazeError.notFound
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

    @Test("An empty/whitespace query resets to idle without calling the service")
    func emptyQueryStaysIdle() async {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                Issue.record("service should not be called")
                return TheTVDBSearchPage(results: [], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "   "
        await viewModel.search()
        #expect(viewModel.state == .idle)
    }

    @Test("Matching shows populate the results state")
    func resultsPopulateState() async {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )
    }

    @Test("No matches yield the empty state")
    func noMatchesYieldEmpty() async {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "no-such-show"
        await viewModel.search()
        #expect(viewModel.state == .empty)
    }

    @Test("A service error surfaces as the failed state with its message")
    func serviceErrorYieldsFailed() async {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in throw TestError() },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(viewModel.state == .failed("Something failed"))
    }

    @Test("Clearing the query after results returns to idle")
    func clearingQueryReturnsToIdle() async {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
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
        final class CallCounter: @unchecked Sendable {
            var value = 0
        }
        let counter = CallCounter()
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                counter.value += 1
                return TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )
        #expect(counter.value == 1)

        await viewModel.search()
        #expect(
            viewModel.state
                == .results(SearchViewModel.ResultsPage(items: [sampleResult], hasMore: false))
        )
        #expect(counter.value == 1)
    }

    @Test("Load more appends the next page")
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
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, offset in
                if offset == 0 {
                    return TheTVDBSearchPage(results: [sampleResult], hasMore: true)
                }
                return TheTVDBSearchPage(results: [second], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
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

    @Test("Resolve maps a TheTVDB hit to a TVMaze show")
    func resolveMapsToTVMazeShow() async throws {
        let viewModel = SearchViewModel(
            searchService: MockSearchService { _, _ in
                TheTVDBSearchPage(results: [sampleResult], hasMore: false)
            },
            tvMaze: MockTVMazeService(),
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        let show = try await viewModel.resolveShow(for: sampleResult)
        #expect(show.id == Show.preview.id)
        #expect(viewModel.resolvedTVMazeID(for: sampleResult.id) == Show.preview.id)
    }
}
