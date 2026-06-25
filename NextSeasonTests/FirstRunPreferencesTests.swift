//
//  FirstRunPreferencesTests.swift
//  NextSeasonTests
//

import Testing
@testable import NextSeason

@MainActor
struct FirstRunPreferencesTests {
    @Test("Search results hint starts undismissed and persists dismissal")
    func searchResultsHintDismissal() {
        FirstRunPreferences.resetSearchResultsHintForTesting()
        #expect(FirstRunPreferences.hasDismissedSearchResultsHint == false)

        FirstRunPreferences.dismissSearchResultsHint()
        #expect(FirstRunPreferences.hasDismissedSearchResultsHint)

        FirstRunPreferences.resetSearchResultsHintForTesting()
        #expect(FirstRunPreferences.hasDismissedSearchResultsHint == false)
    }
}
