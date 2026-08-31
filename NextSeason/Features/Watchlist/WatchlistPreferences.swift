//
//  WatchlistPreferences.swift
//  NextSeason
//

import Foundation

/// Persists watchlist UI configuration across launches (UserDefaults).
struct WatchlistPreferences {
    /// UserDefaults key for `WatchlistSection.persistenceID` strings. Public so
    /// tests can seed or inspect raw storage without going through the accessor.
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
        /// Clears persisted collapse state in the standard defaults suite between tests.
        static func resetCollapsedSectionsForTesting() {
            UserDefaults.standard.removeObject(forKey: collapsedSectionsKey)
        }
    #endif
}
