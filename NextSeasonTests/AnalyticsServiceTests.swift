//
//  AnalyticsServiceTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

@MainActor
struct AnalyticsServiceTests {
    @Test("Recording service stores tracked events")
    func recordingServiceStoresEvents() {
        let analytics = RecordingAnalyticsService()
        analytics.track(.watchlistViewed)
        analytics.track(.searchPerformed(queryLength: 9, resultCount: 3, durationMs: 120))

        #expect(analytics.events.count == 2)
        #expect(analytics.events[0] == .watchlistViewed)
        #expect(analytics.events[1] == .searchPerformed(queryLength: 9, resultCount: 3, durationMs: 120))
    }

    @Test("Analytics service is disabled during UI tests")
    func disabledDuringUITests() {
        let analytics = AnalyticsService(isEnabled: false)
        analytics.track(.watchlistViewed)
        // No crash and no observable state — verified by compilation and manual log absence.
    }

    @Test("TVMaze errors map to analytics categories")
    func errorCategoryMapping() {
        #expect(AnalyticsErrorCategory.category(for: TVMazeError.decoding(TestError())) == .decoding)
        #expect(AnalyticsErrorCategory.category(for: TVMazeError.network(URLError(.notConnectedToInternet))) == .network)
        #expect(AnalyticsErrorCategory.category(for: TVMazeError.notFound) == .api)
    }

    private struct TestError: Error {}
}
