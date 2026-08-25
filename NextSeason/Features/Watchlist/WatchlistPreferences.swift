//
//  WatchlistPreferences.swift
//  NextSeason
//

import Foundation

/// Persists watchlist UI configuration across launches (UserDefaults).
struct WatchlistPreferences {
    static let collapsedSectionsKey = "watchlistCollapsedSections"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Sections the user has collapsed. Missing IDs are treated as expanded.
    var collapsedSections: Set<WatchlistSection> {
        get {
            let ids = userDefaults.stringArray(forKey: Self.collapsedSectionsKey) ?? []
            return Set(ids.compactMap(WatchlistSection.fromPersistenceID))
        }
        nonmutating set {
            userDefaults.set(
                newValue.map(\.persistenceID).sorted(),
                forKey: Self.collapsedSectionsKey
            )
        }
    }

    #if DEBUG
        static func resetCollapsedSectionsForTesting() {
            UserDefaults.standard.removeObject(forKey: collapsedSectionsKey)
        }
    #endif
}
