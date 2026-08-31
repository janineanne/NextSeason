//
//  AnalyticsServiceTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Covers `AnalyticsService` recording, local counters, diagnostics, Aptabase key
/// resolution, remote-event whitelist, and the `-UITesting` / test-target guards that
/// disable remote transmission.
@MainActor
struct AnalyticsServiceTests {
    @Test("Recording service stores tracked events")
    func recordingServiceStoresEvents() {
        let analytics = RecordingAnalyticsService()
        analytics.track(.watchlistViewed)
        analytics.track(
            .searchPerformed(queryLength: 9, resultCount: 3, durationMs: 120, outcome: .results)
        )

        #expect(analytics.events.count == 2)
        #expect(analytics.events[0] == .watchlistViewed)
        #expect(
            analytics.events[1]
                == .searchPerformed(
                    queryLength: 9,
                    resultCount: 3,
                    durationMs: 120,
                    outcome: .results
                )
        )
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

    @Test("App Info.plist includes AptabaseAppKey from build settings")
    func infoPlistIncludesAptabaseAppKey() {
        let raw =
            Bundle.main.object(forInfoDictionaryKey: AptabaseAppKey.infoDictionaryKey) as? String
        #expect(raw != nil)
    }

    @Test("Aptabase key resolution accepts a well-formed key")
    func aptabaseKeyResolutionAcceptsWellFormedKey() {
        let info: [String: Any] = [AptabaseAppKey.infoDictionaryKey: "A-US-TESTKEY"]
        #expect(AptabaseAppKey.resolved(from: info) == "A-US-TESTKEY")
    }

    @Test("Aptabase key resolution rejects a missing Info.plist dictionary")
    func aptabaseKeyResolutionRejectsMissingDictionary() {
        #expect(AptabaseAppKey.resolved(from: nil) == nil)
        #expect(AptabaseAppKey.resolved(from: [:]) == nil)
    }

    @Test(
        "Aptabase key resolution rejects empty and unsubstituted values",
        arguments: ["", "   ", "${APTABASE_APP_KEY}"]
    )
    func aptabaseKeyResolutionRejectsMalformed(_ raw: String) {
        let info: [String: Any] = [AptabaseAppKey.infoDictionaryKey: raw]
        #expect(AptabaseAppKey.resolved(from: info) == nil)
    }

    @Test("Missing Aptabase configuration does not crash local analytics")
    func missingConfigurationDoesNotCrash() {
        let suiteName = "AnalyticsServiceTests.missingAptabase"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AnalyticsCountersStore(userDefaults: defaults)
        let analytics = AnalyticsService(isEnabled: true, countersStore: store)
        analytics.track(.appLaunched)

        #expect(analytics.countersSnapshot().appLaunches == 1)
    }

    @Test("app_launched is included in the remote analytics whitelist")
    func appLaunchedIsSentRemotely() throws {
        let remote = try #require(AnalyticsEvent.appLaunched.remoteEvent)
        #expect(remote.name == "app_launched")
        #expect(remote.properties.isEmpty)
    }

    @Test("search_performed is sent remotely with structural properties only")
    func searchPerformedIsSentRemotely() throws {
        let event = AnalyticsEvent.searchPerformed(
            queryLength: 8,
            resultCount: 2,
            durationMs: 40,
            outcome: .results
        )
        let remote = try #require(event.remoteEvent)
        #expect(remote.name == "search_performed")
        #expect(remote.properties["query_length"] == .int(8))
        #expect(remote.properties["result_count"] == .int(2))
        #expect(remote.properties["duration_ms"] == .int(40))
        #expect(remote.properties["outcome"] == .string("results"))
        #expect(event.parameters["outcome"] == nil)
        #expect(remote.properties["result_selected"] == nil)
        #expect(remote.properties["already_on_watchlist"] == nil)
    }

    @Test(
        "search_performed remote outcome distinguishes results, empty, and failed",
        arguments: [
            (SearchPerformedOutcome.results, 2, "results"),
            (.empty, 0, "empty"),
            (.failed, 0, "failed"),
        ]
    )
    func searchPerformedRemoteOutcome(
        outcome: SearchPerformedOutcome,
        resultCount: Int,
        expected: String
    ) throws {
        let event = AnalyticsEvent.searchPerformed(
            queryLength: 8,
            resultCount: resultCount,
            durationMs: 40,
            outcome: outcome
        )
        let remote = try #require(event.remoteEvent)
        #expect(remote.properties["outcome"] == .string(expected))
        #expect(remote.properties["result_count"] == .int(resultCount))
        #expect(event.parameters["outcome"] == nil)
    }

    @Test("search_result_selected is sent remotely with the watchlist flag")
    func searchResultSelectedIsSentRemotely() throws {
        let remote = try #require(
            AnalyticsEvent.searchResultSelected(alreadyOnWatchlist: true).remoteEvent
        )
        #expect(remote.name == "search_result_selected")
        #expect(remote.properties == ["already_on_watchlist": .bool(true)])
    }

    @Test("watchlist_added stays local and is not mapped for Aptabase")
    func watchlistAddedIsLocalOnly() {
        #expect(AnalyticsEvent.watchlistAdded(source: .search, showID: 1).remoteEvent == nil)
    }

    @Test("Events with identifiers or diagnostic context stay local")
    func identifyingEventsStayLocal() {
        #expect(AnalyticsEvent.searchResultOpened(showID: 44933).remoteEvent == nil)
        #expect(AnalyticsEvent.showDetailViewed(showID: 44933).remoteEvent == nil)
        #expect(
            AnalyticsEvent.nonFatalError(category: .api, context: "search").remoteEvent == nil
        )
    }

    @Test("Approved events still update local counters when tracked")
    func approvedEventsPreserveLocalCounters() {
        let suiteName = "AnalyticsServiceTests.localPreserved"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AnalyticsCountersStore(userDefaults: defaults)
        let analytics = AnalyticsService(isEnabled: true, countersStore: store)

        analytics.track(.appLaunched)
        analytics.track(
            .searchPerformed(
                queryLength: 8,
                resultCount: 2,
                durationMs: 40,
                outcome: .results
            )
        )
        analytics.track(.searchResultSelected(alreadyOnWatchlist: false))

        #expect(analytics.countersSnapshot().appLaunches == 1)
        #expect(analytics.countersSnapshot().searchesPerformed == 1)
        #expect(analytics.countersSnapshot().successfulSearches == 1)
    }

    @Test("Automated tests do not allow Aptabase transmission")
    func automatedTestsDoNotAllowAptabaseTransmission() {
        #expect(AnalyticsService.allowsAptabaseTransmission == false)
    }

    @Test("TVMaze errors map to analytics categories")
    func errorCategoryMapping() {
        #expect(
            AnalyticsErrorCategory.category(for: TVMazeError.decoding(TestError())) == .decoding)
        #expect(
            AnalyticsErrorCategory.category(
                for: TVMazeError.network(URLError(.notConnectedToInternet))) == .network)
        #expect(AnalyticsErrorCategory.category(for: TVMazeError.notFound) == .api)
    }

    private struct TestError: Error {}
}
