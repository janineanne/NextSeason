//
//  ReviewPromptStoreTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct ReviewPromptStoreTests {
    @Test("Delivery and request are scoped to the marketing version")
    func deliveryAndRequestAreVersionScoped() {
        let defaults = makeDefaults()
        let store = ReviewPromptStore(defaults: defaults, marketingVersion: "1.0")

        #expect(store.isEligibleToRequest == false)
        #expect(store.markNotificationDelivered())
        #expect(store.markNotificationDelivered() == false)
        #expect(store.isEligibleToRequest)
        #expect(store.deliveredVersion == "1.0")

        store.markRequested()
        #expect(store.isEligibleToRequest == false)
        #expect(store.requestedVersion == "1.0")

        let nextVersion = ReviewPromptStore(defaults: defaults, marketingVersion: "1.1")
        #expect(nextVersion.isEligibleToRequest == false)
        #expect(nextVersion.markNotificationDelivered())
        #expect(nextVersion.isEligibleToRequest)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ReviewPromptStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
