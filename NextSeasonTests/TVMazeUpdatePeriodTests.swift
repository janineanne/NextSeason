//
//  TVMazeUpdatePeriodTests.swift
//  NextSeasonTests
//

import Foundation
import Testing
@testable import NextSeason

struct TVMazeUpdatePeriodTests {
    private let now = TVMazeDate.dateOnly("2026-06-14")!

    @Test("Day window covers checks within the last 24 hours")
    func dayWindow() {
        let oldest = now.addingTimeInterval(-86_400)
        #expect(TVMazeUpdatePeriod.covering(since: oldest, at: now) == .day)
    }

    @Test("Week window covers checks between one and seven days ago")
    func weekWindow() {
        let oldest = now.addingTimeInterval(-2 * 86_400)
        #expect(TVMazeUpdatePeriod.covering(since: oldest, at: now) == .week)
    }

    @Test("Month window covers checks older than a week")
    func monthWindow() {
        let oldest = now.addingTimeInterval(-8 * 86_400)
        #expect(TVMazeUpdatePeriod.covering(since: oldest, at: now) == .month)
    }
}
