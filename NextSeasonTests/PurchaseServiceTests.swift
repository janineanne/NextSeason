//
//  PurchaseServiceTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

@MainActor
struct PurchaseServiceTests {
    @Test("Start applies grandfathering and loads stub products")
    func startGrandfathersAndLoadsProducts() async {
        let suiteName = "PurchaseServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let purchases = PurchaseService.stub(userDefaults: defaults)
        await purchases.start(watchlistCount: 5)

        #expect(purchases.isGrandfathered)
        #expect(purchases.isUnlimitedWatchlist)
        #expect(purchases.annualProduct != nil)
        #expect(purchases.lifetimeProduct != nil)
        #expect(purchases.tipProducts.count == 3)
    }

    @Test("Purchasing annual Plus unlocks the unlimited watchlist")
    func purchasingAnnualUnlocksPlus() async throws {
        let purchases = PurchaseService.stub()
        await purchases.start(watchlistCount: 0)
        #expect(purchases.isUnlimitedWatchlist == false)

        let annual = try #require(purchases.annualProduct)
        let outcome = await purchases.purchase(annual)

        #expect(outcome == .success)
        #expect(purchases.isStoreEntitled)
        #expect(purchases.isUnlimitedWatchlist)
    }

    @Test("Tips succeed without granting Plus")
    func tipsDoNotGrantPlus() async throws {
        let purchases = PurchaseService.stub()
        await purchases.start(watchlistCount: 0)
        let tip = try #require(purchases.tipProducts.first)

        let outcome = await purchases.purchase(tip)

        #expect(outcome == .success)
        #expect(purchases.isStoreEntitled == false)
        #expect(purchases.isUnlimitedWatchlist == false)
        #expect(purchases.thankYouMessage != nil)
    }

    @Test("Product IDs match the agreed catalog")
    func productIDsMatchCatalog() {
        #expect(StoreProductID.plusAnnual.rawValue == "com.TrialByFyre.NextSeason.plus.annual")
        #expect(StoreProductID.plusLifetime.rawValue == "com.TrialByFyre.NextSeason.plus.lifetime")
        #expect(StoreProductID.tipTrailer.rawValue == "com.TrialByFyre.NextSeason.tip.small")
        #expect(StoreProductID.tipPilot.rawValue == "com.TrialByFyre.NextSeason.tip.medium")
        #expect(StoreProductID.tipHitShow.rawValue == "com.TrialByFyre.NextSeason.tip.large")
    }
}
