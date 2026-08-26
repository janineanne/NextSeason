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

    func purchase(productID: String) async throws -> PurchaseOutcome {
        guard products.contains(where: { $0.productID == productID }) else {
            throw PurchaseError.productUnavailable
        }
        if purchaseOutcome == .success, let id = StoreProductID(rawValue: productID) {
            switch id {
            case .plusAnnual, .plusLifetime:
                isStoreEntitled = true
            case .tipTrailer, .tipPilot, .tipHitShow:
                break
            }
        }
        return purchaseOutcome
    }

    func hasActivePlusEntitlement() async -> Bool {
        isStoreEntitled
    }

    func restorePurchases() async throws {
        if let restoreError { throw restoreError }
    }

    func observeTransactionUpdates(_ onChange: @escaping @MainActor () async -> Void) {
        // Stub entitlements change only through `purchase`; nothing to observe.
        _ = onChange
    }

    func stopObservingTransactionUpdates() {}
}
