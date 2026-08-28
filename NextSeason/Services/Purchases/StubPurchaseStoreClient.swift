//
//  StubPurchaseStoreClient.swift
//  NextSeason
//

import Foundation

/// In-memory StoreKit double for tests, previews, and UI tests.
@MainActor
final class StubPurchaseStoreClient: PurchaseStoreClient {
    var products: [StoreProduct]
    var isStoreEntitled: Bool
    var purchaseOutcome: PurchaseOutcome
    var restoreError: (any Error)?
    var loadError: (any Error)?

    /// When true, `hasActivePlusEntitlement()` suspends until
    /// `releaseEntitlementResolution()`.
    var delayEntitlementResolution = false

    /// Invoked after a verified transaction has been delivered to the app and
    /// immediately before the stub records it as finished.
    var onFinish: (@MainActor () -> Void)?

    private(set) var finishedTransactionIDs: [UInt64] = []
    private(set) var lastPurchasedTransaction: StoreTransaction?
    private(set) var entitlementWaiterCount = 0
    private(set) var observeTransactionUpdatesCallCount = 0
    private(set) var stopObservingTransactionUpdatesCallCount = 0
    private(set) var recordedCalls: [RecordedCall] = []

    enum RecordedCall: Equatable, Sendable {
        case observeTransactionUpdates
        case hasActivePlusEntitlement
        case stopObservingTransactionUpdates
    }

    private var nextTransactionID: UInt64 = 1
    private var entitlementWaiters: [CheckedContinuation<Void, Never>] = []
    private var transactionObserver: (@MainActor (StoreTransaction) async -> Void)?

    init(
        products: [StoreProduct] = StoreProductID.allCases.map { StoreProduct($0) },
        isStoreEntitled: Bool = false,
        purchaseOutcome: PurchaseOutcome = .success
    ) {
        self.products = products
        self.isStoreEntitled = isStoreEntitled
        self.purchaseOutcome = purchaseOutcome
    }

    func loadProducts(ids: [String]) async throws -> [StoreProduct] {
        if let loadError { throw loadError }
        let requested = Set(ids)
        return products.filter { requested.contains($0.productID) }
    }

    func purchase(
        productID: String,
        onVerified: @escaping @MainActor (StoreTransaction) async -> Void
    ) async throws -> PurchaseOutcome {
        guard products.contains(where: { $0.productID == productID }) else {
            throw PurchaseError.productUnavailable
        }
        if purchaseOutcome == .success {
            let transaction = StoreTransaction(id: nextTransactionID, productID: productID)
            nextTransactionID += 1
            lastPurchasedTransaction = transaction
            if let id = StoreProductID(rawValue: productID) {
                switch id {
                case .plusAnnual, .plusLifetime:
                    isStoreEntitled = true
                case .tipTrailer, .tipPilot, .tipHitShow:
                    break
                }
            }
            await deliverThenFinish(transaction, onVerified: onVerified)
        }
        return purchaseOutcome
    }

    func hasActivePlusEntitlement() async -> Bool {
        recordedCalls.append(.hasActivePlusEntitlement)
        if delayEntitlementResolution {
            await withCheckedContinuation { continuation in
                entitlementWaiters.append(continuation)
                entitlementWaiterCount = entitlementWaiters.count
            }
        }
        return isStoreEntitled
    }

    func restorePurchases() async throws {
        if let restoreError { throw restoreError }
    }

    func observeTransactionUpdates(
        _ onVerified: @escaping @MainActor (StoreTransaction) async -> Void
    ) {
        observeTransactionUpdatesCallCount += 1
        recordedCalls.append(.observeTransactionUpdates)
        transactionObserver = onVerified
    }

    func stopObservingTransactionUpdates() {
        stopObservingTransactionUpdatesCallCount += 1
        recordedCalls.append(.stopObservingTransactionUpdates)
        transactionObserver = nil
    }

    var isObservingTransactionUpdates: Bool {
        transactionObserver != nil
    }

    /// Completes any in-flight `hasActivePlusEntitlement()` waits.
    func releaseEntitlementResolution() {
        delayEntitlementResolution = false
        let waiters = entitlementWaiters
        entitlementWaiters.removeAll()
        entitlementWaiterCount = 0
        for waiter in waiters {
            waiter.resume()
        }
    }

    /// Delivers a later StoreKit update (Ask to Buy, restore, entitlement change).
    func emitVerifiedTransaction(_ transaction: StoreTransaction) async {
        guard let transactionObserver else { return }
        await deliverThenFinish(transaction, onVerified: transactionObserver)
    }

    private func deliverThenFinish(
        _ transaction: StoreTransaction,
        onVerified: @MainActor (StoreTransaction) async -> Void
    ) async {
        await onVerified(transaction)
        onFinish?()
        finishedTransactionIDs.append(transaction.id)
    }
}
