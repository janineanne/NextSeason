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

    @Test("Initial entitlement resolution stays loading until StoreKit answers")
    func initialEntitlementStaysLoadingWhileStoreKitIsSuspended() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: true)
        store.delayEntitlementResolution = true
        let purchases = makePurchases(store: store)

        #expect(purchases.storeEntitlement == .loading)
        #expect(purchases.hasResolvedStoreEntitlement == false)

        let startTask = Task { await purchases.start(watchlistCount: 0) }
        await waitUntilEntitlementIsHeld(store)

        #expect(purchases.storeEntitlement == .loading)
        #expect(purchases.isStoreEntitled == false)
        #expect(purchases.isUnlimitedWatchlist == false)

        store.releaseEntitlementResolution()
        await startTask.value
        #expect(purchases.isStoreEntitled)
    }

    @Test("Existing Plus entitlement is not treated as free while StoreKit is still resolving")
    func delayedPlusEntitlementIsNotClassifiedAsFree() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: true)
        store.delayEntitlementResolution = true
        let purchases = makePurchases(store: store)

        let startTask = Task { await purchases.start(watchlistCount: 0) }
        await waitUntilEntitlementIsHeld(store)

        var decided: Bool?
        let addTask = Task { () -> Bool in
            let value = await purchases.canAddToWatchlist(currentCount: 3)
            decided = value
            return value
        }
        for _ in 0..<50 { await Task.yield() }

        #expect(purchases.storeEntitlement == .loading)
        #expect(decided == nil)

        store.releaseEntitlementResolution()
        await startTask.value
        #expect(await addTask.value)
        #expect(decided == true)
        #expect(purchases.isStoreEntitled)
        #expect(purchases.isUnlimitedWatchlist)
    }

    @Test("Free user is classified as free only after delayed entitlement resolution")
    func delayedFreeEntitlementUsesFreeTierRules() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: false)
        store.delayEntitlementResolution = true
        let purchases = makePurchases(store: store)

        let startTask = Task { await purchases.start(watchlistCount: 0) }
        await waitUntilEntitlementIsHeld(store)

        var decided: Bool?
        let addTask = Task { () -> Bool in
            let value = await purchases.canAddToWatchlist(currentCount: 3)
            decided = value
            return value
        }
        for _ in 0..<50 { await Task.yield() }

        #expect(purchases.storeEntitlement == .loading)
        #expect(decided == nil)

        store.releaseEntitlementResolution()
        await startTask.value
        #expect(await addTask.value == false)
        #expect(purchases.isStoreEntitled == false)
        #expect(await purchases.canAddToWatchlist(currentCount: 2))
    }

    @Test("StoreKit product loading failure records an error and leaves purchase buttons empty")
    func productLoadingFailureLeavesCatalogEmpty() async {
        let store = StubPurchaseStoreClient()
        store.loadError = StubStoreError.loadFailed
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))

        await purchases.start(watchlistCount: 0)

        #expect(purchases.hasCompletedProductLoad)
        #expect(purchases.lastErrorMessage != nil)
        #expect(purchases.annualProduct == nil)
        #expect(purchases.lifetimeProduct == nil)
        #expect(purchases.tipProducts.isEmpty)
        #expect(purchases.hasResolvedStoreEntitlement)

        store.loadError = nil
        await purchases.loadProducts()
        #expect(purchases.lastErrorMessage == nil)
        #expect(purchases.annualProduct != nil)
        #expect(purchases.tipProducts.count == 3)
    }

    @Test("Partial catalog keeps loaded Plus products when tips are missing")
    func partialCatalogPlusWithoutTips() async {
        let store = StubPurchaseStoreClient(
            products: [StoreProduct(.plusAnnual), StoreProduct(.plusLifetime)]
        )
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        #expect(purchases.annualProduct != nil)
        #expect(purchases.lifetimeProduct != nil)
        #expect(purchases.tipProducts.isEmpty)
        #expect(purchases.hasCompletedProductLoad)
        #expect(purchases.lastErrorMessage == nil)
    }

    @Test("Partial catalog keeps loaded tips when Plus products are missing")
    func partialCatalogTipsWithoutPlus() async {
        let store = StubPurchaseStoreClient(
            products: [
                StoreProduct(.tipTrailer), StoreProduct(.tipPilot), StoreProduct(.tipHitShow),
            ]
        )
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        #expect(purchases.annualProduct == nil)
        #expect(purchases.lifetimeProduct == nil)
        #expect(purchases.tipProducts.count == 3)
        #expect(purchases.hasCompletedProductLoad)
    }

    @Test("Restore Purchases can activate an existing Plus entitlement")
    func restorePurchasesActivatesEntitlement() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: false)
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)
        #expect(purchases.isStoreEntitled == false)

        store.isStoreEntitled = true
        let outcome = await purchases.restorePurchases()

        #expect(outcome == .success)
        #expect(purchases.isStoreEntitled)
        #expect(purchases.isUnlimitedWatchlist)
    }

    @Test("Pending Plus purchase later completing through a transaction update unlocks Plus")
    func pendingPlusCompletesThroughTransactionUpdate() async throws {
        let store = StubPurchaseStoreClient(purchaseOutcome: .pending)
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        let annual = try #require(purchases.annualProduct)
        #expect(await purchases.purchase(annual) == .pending)
        #expect(purchases.isStoreEntitled == false)

        store.isStoreEntitled = true
        await store.emitVerifiedTransaction(
            StoreTransaction(id: 42, productID: StoreProductID.plusAnnual.rawValue)
        )

        #expect(purchases.isStoreEntitled)
        #expect(purchases.isUnlimitedWatchlist)
        #expect(store.finishedTransactionIDs.contains(42))
        #expect(purchases.thankYouMessage == nil)
    }

    @Test("Pending consumable tip later completing through a transaction update shows thanks")
    func pendingTipCompletesThroughTransactionUpdate() async throws {
        let store = StubPurchaseStoreClient(purchaseOutcome: .pending)
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        let tip = try #require(purchases.tipProducts.first)
        #expect(await purchases.purchase(tip) == .pending)
        #expect(purchases.thankYouMessage == nil)
        #expect(purchases.isStoreEntitled == false)

        await store.emitVerifiedTransaction(
            StoreTransaction(id: 43, productID: StoreProductID.tipTrailer.rawValue)
        )

        #expect(purchases.thankYouMessage != nil)
        #expect(purchases.isStoreEntitled == false)
        #expect(purchases.isUnlimitedWatchlist == false)
        #expect(store.finishedTransactionIDs.contains(43))
    }

    @Test(
        "A tip already acknowledged during purchase is not thanked again for the same transaction")
    func duplicateTipUpdateDoesNotShowThankYouAgain() async throws {
        let store = StubPurchaseStoreClient()
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        let tip = try #require(purchases.tipProducts.first)
        #expect(await purchases.purchase(tip) == .success)
        #expect(purchases.thankYouMessage != nil)

        purchases.clearMessages()
        let transaction = try #require(store.lastPurchasedTransaction)
        await store.emitVerifiedTransaction(transaction)

        #expect(purchases.thankYouMessage == nil)
        #expect(purchases.isStoreEntitled == false)
    }

    @Test("Start observes transaction updates before refreshing entitlements")
    func startObservesTransactionsBeforeRefreshingEntitlements() async throws {
        let store = StubPurchaseStoreClient(isStoreEntitled: true)
        store.delayEntitlementResolution = true
        let purchases = makePurchases(store: store)

        let startTask = Task { await purchases.start(watchlistCount: 0) }
        await waitUntilEntitlementIsHeld(store)

        #expect(store.observeTransactionUpdatesCallCount == 1)
        #expect(store.recordedCalls.first == .observeTransactionUpdates)
        let observeIndex = try #require(
            store.recordedCalls.firstIndex(of: .observeTransactionUpdates)
        )
        let entitlementIndex = try #require(
            store.recordedCalls.firstIndex(of: .hasActivePlusEntitlement)
        )
        #expect(observeIndex < entitlementIndex)
        #expect(purchases.storeEntitlement == .loading)

        await store.emitVerifiedTransaction(
            StoreTransaction(id: 1, productID: StoreProductID.tipTrailer.rawValue)
        )
        #expect(purchases.thankYouMessage != nil)
        #expect(store.finishedTransactionIDs.contains(1))

        store.releaseEntitlementResolution()
        await startTask.value
        #expect(purchases.isStoreEntitled)
        #expect(store.observeTransactionUpdatesCallCount == 1)
    }

    @Test("Repeated start does not install a second transaction observer")
    func repeatedStartDoesNotCreateDuplicateObservers() async {
        let store = StubPurchaseStoreClient()
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))

        await purchases.start(watchlistCount: 0)
        await purchases.start(watchlistCount: 0)

        #expect(store.observeTransactionUpdatesCallCount == 1)
        #expect(
            store.recordedCalls.filter { $0 == .observeTransactionUpdates }.count == 1
        )
    }

    @Test("Releasing PurchaseService stops transaction observation")
    func releasingPurchaseServiceStopsObservation() async {
        let store = StubPurchaseStoreClient()
        var purchases: PurchaseService? = makePurchases(
            store: store,
            initial: .resolved(isEntitled: false)
        )
        await purchases?.start(watchlistCount: 0)
        #expect(store.isObservingTransactionUpdates)
        #expect(store.stopObservingTransactionUpdatesCallCount == 0)

        purchases = nil
        await waitUntilObservationStops(store)

        #expect(store.isObservingTransactionUpdates == false)
        #expect(store.stopObservingTransactionUpdatesCallCount == 1)
    }

    @Test("Entitlement can be lost when the app becomes active")
    func entitlementLossWhileRunning() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: true)
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: true))
        await purchases.start(watchlistCount: 0)
        #expect(await purchases.canAddToWatchlist(currentCount: 5))

        store.isStoreEntitled = false
        await purchases.handleSceneBecameActive()

        #expect(purchases.isStoreEntitled == false)
        #expect(await purchases.canAddToWatchlist(currentCount: 5) == false)
        #expect(await purchases.canAddToWatchlist(currentCount: 2))
    }

    @Test("Becoming active does not start a second entitlement refresh during startup")
    func sceneActivationSkipsRefreshWhileEntitlementIsStillLoading() async {
        let store = StubPurchaseStoreClient(isStoreEntitled: true)
        store.delayEntitlementResolution = true
        let purchases = makePurchases(store: store)

        let startTask = Task { await purchases.start(watchlistCount: 0) }
        await waitUntilEntitlementIsHeld(store)
        #expect(store.entitlementWaiterCount == 1)

        await purchases.handleSceneBecameActive()

        #expect(store.entitlementWaiterCount == 1)
        #expect(purchases.storeEntitlement == .loading)
        #expect(
            store.recordedCalls.filter { $0 == .hasActivePlusEntitlement }.count == 1
        )

        store.releaseEntitlementResolution()
        await startTask.value
        #expect(purchases.isStoreEntitled)
    }

    @Test("Verified Plus purchases are incorporated before the transaction is finished")
    func processesPlusPurchaseBeforeFinish() async throws {
        let store = StubPurchaseStoreClient()
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        var entitledWhenFinished = false
        store.onFinish = {
            entitledWhenFinished = purchases.isStoreEntitled
        }

        let annual = try #require(purchases.annualProduct)
        #expect(await purchases.purchase(annual) == .success)
        #expect(entitledWhenFinished)
        #expect(store.finishedTransactionIDs.isEmpty == false)
    }

    @Test("Verified tip updates are acknowledged before the transaction is finished")
    func processesTipUpdateBeforeFinish() async {
        let store = StubPurchaseStoreClient()
        let purchases = makePurchases(store: store, initial: .resolved(isEntitled: false))
        await purchases.start(watchlistCount: 0)

        var thankedWhenFinished = false
        store.onFinish = {
            thankedWhenFinished = purchases.thankYouMessage != nil
        }

        await store.emitVerifiedTransaction(
            StoreTransaction(id: 7, productID: StoreProductID.tipPilot.rawValue)
        )

        #expect(thankedWhenFinished)
        #expect(purchases.isStoreEntitled == false)
        #expect(store.finishedTransactionIDs == [7])
    }

    private func makePurchases(
        store: StubPurchaseStoreClient,
        initial: StoreEntitlementState = .loading
    ) -> PurchaseService {
        let suiteName = "PurchaseServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return PurchaseService(
            store: store,
            entitlementStore: PlusEntitlementStore(userDefaults: defaults),
            initialStoreEntitlement: initial
        )
    }

    private func waitUntilEntitlementIsHeld(_ store: StubPurchaseStoreClient) async {
        for _ in 0..<200 {
            if store.entitlementWaiterCount > 0 { return }
            await Task.yield()
        }
        Issue.record("StoreKit entitlement resolution did not suspend")
    }

    private func waitUntilObservationStops(_ store: StubPurchaseStoreClient) async {
        for _ in 0..<200 {
            if store.stopObservingTransactionUpdatesCallCount > 0 { return }
            await Task.yield()
        }
        Issue.record("PurchaseService deinit did not stop transaction observation")
    }
}

private enum StubStoreError: Error {
    case loadFailed
}
