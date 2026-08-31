//
//  AnalyticsCountersTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Verifies in-memory counter increments for tracked analytics events.
@MainActor
struct AnalyticsCountersTests {
    @Test("Counters increment from tracked events")
    func countersIncrementFromEvents() {
        var counters = AnalyticsCounters()

        counters.record(.appLaunched)
        counters.record(
            .searchPerformed(queryLength: 9, resultCount: 3, durationMs: 120, outcome: .results)
        )
        counters.record(.emptySearchResultsShown)
        counters.record(.exampleSearchUsed)
        counters.record(.watchlistAdded(source: .search, showID: 1))
        counters.record(.notificationPermission(result: .granted))
        counters.record(.notificationReminderScheduled)

        #expect(counters.appLaunches == 1)
        #expect(counters.searchesPerformed == 1)
        #expect(counters.successfulSearches == 1)
        #expect(counters.noResultSearches == 1)
        #expect(counters.exampleSearchesUsed == 1)
        #expect(counters.watchlistAdditions == 1)
        #expect(counters.notificationPermissionRequests == 1)
        #expect(counters.notificationPermissionGrants == 1)
        #expect(counters.notificationRemindersScheduled == 1)
    }

    @Test("Failed searches do not count as successful")
    func failedSearchNotSuccessful() {
        var counters = AnalyticsCounters()
        counters.record(
            .searchPerformed(queryLength: 4, resultCount: 0, durationMs: 50, outcome: .failed)
        )
        #expect(counters.searchesPerformed == 1)
        #expect(counters.successfulSearches == 0)
    }
}

/// Verifies `AnalyticsCountersStore` persists counters via isolated `UserDefaults`.
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

/// Verifies diagnostics report formatting, including optional launch and persistence fields.
@MainActor
struct AnalyticsDiagnosticsReportTests {
    @Test("Report includes version and counters")
    func formattedReport() {
        var counters = AnalyticsCounters()
        counters.appLaunches = 19
        counters.searchesPerformed = 52

        let report = AnalyticsDiagnosticsReport.formatted(
            counters: counters,
            notificationsEnabled: true
        )

        #expect(report.contains("NextSeason Diagnostics"))
        #expect(report.contains("App launches: 19"))
        #expect(report.contains("Searches: 52"))
        #expect(report.contains("Notifications enabled: true"))
    }

    @Test("Report marks notification status unavailable when it was not queried")
    func formattedReportMarksNotificationsUnavailable() {
        let report = AnalyticsDiagnosticsReport.formatted(
            counters: AnalyticsCounters(),
            notificationsEnabled: nil
        )

        #expect(report.contains("Notifications enabled: Unavailable"))
        #expect(report.contains("Notifications enabled: false") == false)
        #expect(report.contains("Notifications enabled: true") == false)
    }

    @Test("Report includes persistence failure when provided")
    func formattedReportIncludesPersistenceFailure() {
        let report = AnalyticsDiagnosticsReport.formatted(
            counters: AnalyticsCounters(),
            notificationsEnabled: false,
            persistenceFailure: "store is corrupt"
        )

        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("store is corrupt"))
    }

    @Test("Report includes original and reset persistence failures when provided")
    func formattedReportIncludesOriginalAndResetFailures() {
        let report = AnalyticsDiagnosticsReport.formatted(
            counters: AnalyticsCounters(),
            notificationsEnabled: false,
            persistenceFailure: "new container error",
            originalPersistenceFailure: "original container error",
            persistenceResetFailure: "disk full",
            localStoreWasReset: false
        )

        #expect(report.contains("Original persistence failure:"))
        #expect(report.contains("original container error"))
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("new container error"))
        #expect(report.contains("Persistence reset failure:"))
        #expect(report.contains("disk full"))
        #expect(report.contains("Local watchlist store reset: succeeded") == false)
    }

    @Test("Report notes a successful local store reset")
    func formattedReportIncludesSuccessfulStoreReset() {
        let report = AnalyticsDiagnosticsReport.formatted(
            counters: AnalyticsCounters(),
            notificationsEnabled: false,
            persistenceFailure: "still failing",
            originalPersistenceFailure: "original failure",
            localStoreWasReset: true
        )

        #expect(report.contains("Local watchlist store reset: succeeded"))
        #expect(report.contains("still failing"))
        #expect(report.contains("original failure"))
    }

    @Test("Report includes consecutive unexpected launches and crash-loop skip")
    func formattedReportIncludesCrashLoopDiagnostics() {
        let launch = AppLaunchDiagnostics(
            currentLaunchStartedAt: nil,
            lastGracefulExitAt: nil,
            previousLaunchEndedUnexpectedly: true,
            previousLaunchStartedAt: nil,
            unexpectedTerminationDetectedAt: nil,
            priorBreadcrumbs: [],
            consecutiveUnexpectedLaunchCount: 2
        )
        let report = AnalyticsDiagnosticsReport.formatted(
            counters: AnalyticsCounters(),
            notificationsEnabled: false,
            launchDiagnostics: launch,
            persistenceFailure: "Repeated launch failure (consecutive unexpected launches: 2)",
            consecutiveLaunchFailures: 2,
            compositionSkippedDueToCrashLoop: true
        )

        #expect(report.contains("Consecutive unexpected launches: 2"))
        #expect(report.contains("Crash-loop recovery: composition skipped"))
        #expect(report.contains("Repeated launch failure"))
        #expect(report.contains("Previous launch status: Ended unexpectedly"))
    }
}
