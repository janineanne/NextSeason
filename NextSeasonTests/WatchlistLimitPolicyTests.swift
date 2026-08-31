//
//  WatchlistLimitPolicyTests.swift
//  NextSeasonTests
//

import Testing

@testable import NextSeason

/// Free-tier add cap (three shows) vs unlimited Plus entitlement rules.
struct WatchlistLimitPolicyTests {
    @Test("Free users can add until they reach three shows")
    func freeTierAllowsUpToThree() {
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 0, isUnlimited: false)
        )
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 2, isUnlimited: false)
        )
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 3, isUnlimited: false) == false
        )
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 5, isUnlimited: false) == false
        )
    }

    @Test("Unlimited users can add regardless of current count")
    func unlimitedIgnoresCount() {
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 3, isUnlimited: true)
        )
        #expect(
            WatchlistLimitPolicy.canAddShow(currentCount: 50, isUnlimited: true)
        )
    }
}
