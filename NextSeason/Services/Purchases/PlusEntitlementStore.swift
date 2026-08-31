//
//  PlusEntitlementStore.swift
//  NextSeason
//

import Foundation

/// Persists the one-time beta grandfathering decision in UserDefaults.
///
/// Testers who already had more than three shows when StoreKit shipped keep an
/// unlimited watchlist. The flag is sticky: later removals do not revoke it.
@MainActor
final class PlusEntitlementStore {
    /// UserDefaults flag: grandfathering was evaluated on first StoreKit launch.
    static let evaluatedKey = "plusGrandfatheringEvaluated"
    /// UserDefaults flag: user exceeded the free cap before the limit shipped.
    static let grandfatheredKey = "plusGrandfathered"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Whether the one-time grandfathering check has already run.
    var hasEvaluatedGrandfathering: Bool {
        userDefaults.bool(forKey: Self.evaluatedKey)
    }

    /// Whether the user keeps an unlimited watchlist from beta grandfathering.
    var isGrandfathered: Bool {
        userDefaults.bool(forKey: Self.grandfatheredKey)
    }

    /// Records grandfathering on the first StoreKit-aware launch only.
    func evaluateGrandfatheringIfNeeded(watchlistCount: Int, freeLimit: Int) {
        guard !hasEvaluatedGrandfathering else { return }
        userDefaults.set(true, forKey: Self.evaluatedKey)
        if watchlistCount > freeLimit {
            userDefaults.set(true, forKey: Self.grandfatheredKey)
        }
    }

    #if DEBUG
        /// Clears grandfathering flags in this store's defaults suite between tests.
        func resetForTesting() {
            userDefaults.removeObject(forKey: Self.evaluatedKey)
            userDefaults.removeObject(forKey: Self.grandfatheredKey)
        }
    #endif
}
