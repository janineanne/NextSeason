//
//  SearchViewModelTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct SearchViewModelTests {
    /// A `TVMazeService` whose search behavior is supplied per test.
    private struct MockService: TVMazeService {
        let handler: @Sendable (String) async throws -> [Show]

        func searchShows(matching query: String) async throws -> [Show] {
            try await handler(query)
        }

        func show(id: Int, bypassCache: Bool) async throws -> Show {
            throw TVMazeError.notFound
        }

        func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
            [:]
        }
    }

    private struct TestError: LocalizedError {
        var errorDescription: String? { "Something failed" }
    }

    @Test("An empty/whitespace query resets to idle without calling the service")
    func emptyQueryStaysIdle() async {
        let viewModel = SearchViewModel(
            service: MockService { _ in
                Issue.record("service should not be called")
                return []
            },
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
            service: MockService { _ in [.preview] },
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(viewModel.state == .results([.preview]))
    }

    @Test("No matches yield the empty state")
    func noMatchesYieldEmpty() async {
        let viewModel = SearchViewModel(
            service: MockService { _ in [] },
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
            service: MockService { _ in throw TestError() },
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
            service: MockService { _ in [.preview] },
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = FirstRunCopy.exampleSearchQuery
        await viewModel.search()
        #expect(viewModel.state == .results([.preview]))

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
            service: MockService { _ in
                counter.value += 1
                return [.preview]
            },
            analytics: RecordingAnalyticsService(),
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(viewModel.state == .results([.preview]))
        #expect(counter.value == 1)

        await viewModel.search()
        #expect(viewModel.state == .results([.preview]))
        #expect(counter.value == 1)
    }
}
