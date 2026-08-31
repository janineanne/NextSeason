//
//  WatchlistSectionTests.swift
//  NextSeasonTests
//

import Testing

@testable import NextSeason

/// Section header copy: row counts appear only when a section is collapsed.
@MainActor
struct WatchlistSectionTests {
    @Test("Expanded section headers omit the row count")
    func expandedHeaderOmitsCount() {
        #expect(WatchlistSection.ended.headerTitle(showCount: 4, isExpanded: true) == "Ended")
    }

    @Test("Collapsed section headers include the row count")
    func collapsedHeaderIncludesCount() {
        #expect(WatchlistSection.ended.headerTitle(showCount: 4, isExpanded: false) == "Ended (4)")
    }

    @Test(
        "Collapsed headers use each section's localized name",
        arguments: WatchlistSection.allCases
    )
    func collapsedHeaderUsesSectionName(section: WatchlistSection) {
        let title = section.headerTitle(showCount: 2, isExpanded: false)
        #expect(title == "\(section.title) (2)")
    }
}
