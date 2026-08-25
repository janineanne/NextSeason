//
//  WatchlistPreferencesTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct WatchlistPreferencesTests {
    @Test("Collapsed sections persist across instances")
    func collapsedSectionsPersist() {
        let defaults = makeDefaults()
        let preferences = WatchlistPreferences(userDefaults: defaults)
        preferences.collapsedSections = [.ended, .comingSoon]

        let reloaded = WatchlistPreferences(userDefaults: defaults)
        #expect(reloaded.collapsedSections == [.comingSoon, .ended])
    }

    @Test("Missing storage means every section is expanded")
    func missingStorageMeansExpanded() {
        let preferences = WatchlistPreferences(userDefaults: makeDefaults())
        #expect(preferences.collapsedSections.isEmpty)
    }

    @Test("Unknown stored identifiers are ignored")
    func unknownIdentifiersAreIgnored() {
        let defaults = makeDefaults()
        defaults.set(["ended", "notASection"], forKey: WatchlistPreferences.collapsedSectionsKey)

        let preferences = WatchlistPreferences(userDefaults: defaults)
        #expect(preferences.collapsedSections == [.ended])
    }

    @Test("Saving an empty set restores all-expanded on reload")
    func emptySetMeansAllExpanded() {
        let defaults = makeDefaults()
        let preferences = WatchlistPreferences(userDefaults: defaults)
        preferences.collapsedSections = [.ended]
        preferences.collapsedSections = []

        let reloaded = WatchlistPreferences(userDefaults: defaults)
        #expect(reloaded.collapsedSections.isEmpty)
    }

    @Test("Every section has a unique persistence identifier")
    func persistenceIDsAreUnique() {
        let ids = WatchlistSection.allCases.map(\.persistenceID)
        #expect(Set(ids).count == ids.count)

        for section in WatchlistSection.allCases {
            #expect(WatchlistSection.fromPersistenceID(section.persistenceID) == section)
        }
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "WatchlistPreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
