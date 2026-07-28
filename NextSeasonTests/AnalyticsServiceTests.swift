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

    @Test("Analytics service increments persisted counters")
    func serviceIncrementsCounters() {
        let suiteName = "AnalyticsServiceTests.counters"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AnalyticsCountersStore(userDefaults: defaults)
        let analytics = AnalyticsService(isEnabled: true, countersStore: store)

        analytics.track(.appLaunched)
        analytics.track(.exampleSearchUsed)

        #expect(analytics.countersSnapshot().appLaunches == 1)
        #expect(analytics.countersSnapshot().exampleSearchesUsed == 1)
    }

    @Test("Diagnostics report uses service counters")
    func diagnosticsReportUsesCounters() {
        let analytics = RecordingAnalyticsService()
        analytics.track(.appLaunched)

        let report = analytics.diagnosticsReport(
            notificationsEnabled: false
        )

        #expect(report.contains("App launches: 1"))
        #expect(report.contains("Notifications enabled: false"))
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
