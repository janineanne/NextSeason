//
//  AccessibilityPreferencesTests.swift
//  NextSeasonTests
//

import Testing

@testable import NextSeason

@MainActor
struct AccessibilityPreferencesTests {
    @Test("Undo window is longer for VoiceOver and UI tests")
    func undoRemovalWindowSeconds() {
        #expect(AccessibilityPreferences.undoRemovalWindowSeconds(isVoiceOverRunning: false) == 5)
        #expect(AccessibilityPreferences.undoRemovalWindowSeconds(isVoiceOverRunning: true) == 20)
    }
}
