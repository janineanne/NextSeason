//
//  SearchViewModelTests.swift
//  NextSeasonTests
//

import Testing
import Foundation
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
            service: MockService { _ in Issue.record("service should not be called"); return [] },
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
            debounce: .zero
        )
        viewModel.query = "severance"
        await viewModel.search()
        #expect(viewModel.state == .failed("Something failed"))
    }
}
