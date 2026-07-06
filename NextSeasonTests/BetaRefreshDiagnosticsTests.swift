//
//  BetaRefreshDiagnosticsTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

@MainActor
struct BetaRefreshDiagnosticsTests {
    @Test("Last background refresh outcomes persist across new instances")
    func lastBackgroundRefreshPersists() {
        BetaRefreshDiagnostics.resetLastBackgroundRefreshForTesting()
        defer { BetaRefreshDiagnostics.resetLastBackgroundRefreshForTesting() }

        let refreshDate = Date(timeIntervalSince1970: 1_700_000_000)
        let diagnostics = BetaRefreshDiagnostics()
        diagnostics.recordBackgroundRefreshCompleted(
            at: refreshDate,
            fetchResult: "Refreshed 2 show(s)",
            notificationDecision: "No notification for Severance (no meaningful change)"
        )

        let reloaded = BetaRefreshDiagnostics()
        #expect(reloaded.lastBackgroundRefreshAt == refreshDate)
        #expect(reloaded.lastBackgroundFetchResult == "Refreshed 2 show(s)")
        #expect(
            reloaded.lastBackgroundNotificationDecision ==
                "No notification for Severance (no meaningful change)"
        )
    }
}
