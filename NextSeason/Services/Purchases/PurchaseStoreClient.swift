//
//  PurchaseStoreClient.swift
//  NextSeason
//

import Foundation

/// StoreKit (or a test double) behind `PurchaseService`.
///
/// Verified transactions are delivered to the application through `onVerified`
/// (or the observer) *before* the client finishes them, so entitlement and tip
/// acknowledgement can be applied first.
@MainActor
protocol PurchaseStoreClient: AnyObject {
    func loadProducts(ids: [String]) async throws -> [StoreProduct]
    func purchase(
        productID: String,
        onVerified: @escaping @MainActor (StoreTransaction) async -> Void
    ) async throws -> PurchaseOutcome
    func hasActivePlusEntitlement() async -> Bool
    func restorePurchases() async throws
    func observeTransactionUpdates(
        _ onVerified: @escaping @MainActor (StoreTransaction) async -> Void
    )
    func stopObservingTransactionUpdates()
}

/// StoreKit-independent snapshot of a verified transaction.
nonisolated struct StoreTransaction: Equatable, Sendable {
    let id: UInt64
    let productID: String

    var kind: StoreProductKind? {
        StoreProductID(rawValue: productID)?.kind
    }
}
