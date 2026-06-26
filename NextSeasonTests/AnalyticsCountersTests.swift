//
//  AnalyticsCountersTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

@MainActor
struct AnalyticsCountersTests {
    @Test("Counters increment from tracked events")
    func countersIncrementFromEvents() {
        var counters = AnalyticsCounters()

        counters.record(.appLaunched)
        counters.record(.searchPerformed(queryLength: 9, resultCount: 3, durationMs: 120))
        counters.record(.emptySearchResultsShown)
        counters.record(.exampleSearchUsed)
        counters.record(.watchlistAdded(source: .search, showID: 1))
        counters.record(.notificationPermission(result: .granted))
        counters.record(.notificationReminderScheduled)
        counters.record(.themeSelected(variant: .lavender))

        #expect(counters.appLaunches == 1)
        #expect(counters.searchesPerformed == 1)
        #expect(counters.successfulSearches == 1)
        #expect(counters.noResultSearches == 1)
        #expect(counters.exampleSearchesUsed == 1)
        #expect(counters.watchlistAdditions == 1)
        #expect(counters.notificationPermissionRequests == 1)
        #expect(counters.notificationPermissionGrants == 1)
        #expect(counters.notificationRemindersScheduled == 1)
        #expect(counters.themeSelections == 1)
    }

    @Test("Failed searches do not count as successful")
    func failedSearchNotSuccessful() {
        var counters = AnalyticsCounters()
        counters.record(.searchPerformed(queryLength: 4, resultCount: 0, durationMs: 50))
        #expect(counters.searchesPerformed == 1)
        #expect(counters.successfulSearches == 0)
    }
}

@MainActor
struct AnalyticsCountersStoreTests {
    @Test("Store persists counters across instances")
    func persistence() {
        let suiteName = "AnalyticsCountersStoreTests.persistence"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AnalyticsCountersStore(userDefaults: defaults)
        store.record(.appLaunched)
        store.record(.exampleSearchUsed)

        let reloaded = AnalyticsCountersStore(userDefaults: defaults)
        #expect(reloaded.snapshot().appLaunches == 1)
        #expect(reloaded.snapshot().exampleSearchesUsed == 1)
    }
}

@MainActor
struct AnalyticsDiagnosticsReportTests {
    @Test("Report includes version and counters")
    func formattedReport() {
        var counters = AnalyticsCounters()
        counters.appLaunches = 19
        counters.searchesPerformed = 52

        let report = AnalyticsDiagnosticsReport.formatted(
            counters: counters,
            notificationsEnabled: true,
            currentTheme: "Lavender (Current)"
        )

        #expect(report.contains("NextSeason Diagnostics"))
        #expect(report.contains("App launches: 19"))
        #expect(report.contains("Searches: 52"))
        #expect(report.contains("Notifications enabled: true"))
        #expect(report.contains("Current theme: Lavender (Current)"))
    }
}
