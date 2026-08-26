//
//  PlusEntitlementStoreTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct PlusEntitlementStoreTests {
    @Test("First launch with more than three shows grandfathers unlimited access")
    func grandfathersOversizedWatchlistOnce() {
        let store = makeStore()
        store.evaluateGrandfatheringIfNeeded(watchlistCount: 4, freeLimit: 3)

        #expect(store.hasEvaluatedGrandfathering)
        #expect(store.isGrandfathered)

        store.evaluateGrandfatheringIfNeeded(watchlistCount: 0, freeLimit: 3)
        #expect(store.isGrandfathered)
    }

    @Test("First launch with three or fewer shows does not grandfather")
    func doesNotGrandfatherSmallWatchlist() {
        let store = makeStore()
        store.evaluateGrandfatheringIfNeeded(watchlistCount: 3, freeLimit: 3)

        #expect(store.hasEvaluatedGrandfathering)
        #expect(store.isGrandfathered == false)

        store.evaluateGrandfatheringIfNeeded(watchlistCount: 10, freeLimit: 3)
        #expect(store.isGrandfathered == false)
    }

    private func makeStore() -> PlusEntitlementStore {
        let suiteName = "PlusEntitlementStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return PlusEntitlementStore(userDefaults: defaults)
    }
}
