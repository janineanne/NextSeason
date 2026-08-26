//
//  PurchaseStoreClient.swift
//  NextSeason
//

import Foundation

/// StoreKit (or a test double) behind `PurchaseService`.
@MainActor
protocol PurchaseStoreClient: AnyObject {
    func loadProducts(ids: [String]) async throws -> [StoreProduct]
    func purchase(productID: String) async throws -> PurchaseOutcome
    func hasActivePlusEntitlement() async -> Bool
    func restorePurchases() async throws
    func observeTransactionUpdates(_ onChange: @escaping @MainActor () async -> Void)
    func stopObservingTransactionUpdates()
}
