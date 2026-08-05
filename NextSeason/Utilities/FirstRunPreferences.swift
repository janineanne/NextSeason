//
//  FirstRunPreferences.swift
//  NextSeason
//

import Foundation

/// Persists one-time first-run affordances across launches (UserDefaults).
enum FirstRunPreferences {
    static let searchResultsHintDismissedKey = "searchResultsHintDismissed"
    static let hasCompletedFirstSearchKey = "hasCompletedFirstSearch"

    /// Whether the post-search "tap the star" coaching hint was dismissed.
    static var hasDismissedSearchResultsHint: Bool {
        get { UserDefaults.standard.bool(forKey: searchResultsHintDismissedKey) }
        set { UserDefaults.standard.set(newValue, forKey: searchResultsHintDismissedKey) }
    }

    static func dismissSearchResultsHint() {
        hasDismissedSearchResultsHint = true
    }

    /// Tracks whether the user has completed at least one search, used to hide
    /// the "Try an Example" affordance once they've shown they know how to search.
    static var hasCompletedFirstSearch: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedFirstSearchKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedFirstSearchKey) }
    }

    static func markFirstSearchCompleted() {
        hasCompletedFirstSearch = true
    }

    #if DEBUG
        static func resetSearchResultsHintForTesting() {
            UserDefaults.standard.removeObject(forKey: searchResultsHintDismissedKey)
        }

        static func resetFirstSearchCompletedForTesting() {
            UserDefaults.standard.removeObject(forKey: hasCompletedFirstSearchKey)
        }
    #endif
}
