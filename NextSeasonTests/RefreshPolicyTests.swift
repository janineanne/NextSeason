//
//  RefreshPolicyTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

struct RefreshPolicyTests {
    private let now = TVMazeDate.dateOnly("2026-06-14")!

    @Test("Foreground refresh runs when there is no prior refresh")
    func runsWithoutPriorRefresh() {
        #expect(RefreshPolicy.shouldPerformForegroundRefresh(lastRefreshAt: nil, at: now))
    }

    @Test("Foreground refresh is skipped inside the minimum interval")
    func skipsRecentRefresh() {
        let lastRefresh = now.addingTimeInterval(-5 * 60)
        #expect(
            RefreshPolicy.shouldPerformForegroundRefresh(
                lastRefreshAt: lastRefresh,
                at: now
            ) == false
        )
    }

    @Test("Foreground refresh runs again after the minimum interval elapses")
    func runsAfterMinimumInterval() {
        let lastRefresh = now.addingTimeInterval(-16 * 60)
        #expect(
            RefreshPolicy.shouldPerformForegroundRefresh(
                lastRefreshAt: lastRefresh,
                at: now
            )
        )
    }
}
