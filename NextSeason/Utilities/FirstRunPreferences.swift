//
//  FirstRunPreferences.swift
//  NextSeason
//

import Foundation

/// Persists one-time first-run affordances across launches.
enum FirstRunPreferences {
    static let searchResultsHintDismissedKey = "searchResultsHintDismissed"

    static var hasDismissedSearchResultsHint: Bool {
        get { UserDefaults.standard.bool(forKey: searchResultsHintDismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: searchResultsHintDismissedKey) }
    }

    static func dismissSearchResultsHint() {
        hasDismissedSearchResultsHint = true
    }

    #if DEBUG
    static func resetSearchResultsHintForTesting() {
        UserDefaults.standard.removeObject(forKey: searchResultsHintDismissedKey)
    }
    #endif
}
