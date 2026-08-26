//
//  StoreKitPurchaseStoreClient.swift
//  NextSeason
//

import Foundation
import StoreKit

/// Live StoreKit 2 client: product loading, purchase, entitlements, and restore.
@MainActor
final class StoreKitPurchaseStoreClient: PurchaseStoreClient {
    private var productsByID: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    func loadProducts(ids: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: ids)
        productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        if products.isEmpty {
            AppDiagnosticsLogger.breadcrumb("storekit_products_empty")
        }
        return products.compactMap(Self.storeProduct(from:))
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        guard let product = productsByID[productID] else {
            throw PurchaseError.productUnavailable
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .failed(
                String(localized: "The purchase could not be completed. Please try again.")
            )
        }
    }

    func hasActivePlusEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            switch StoreProductID(rawValue: transaction.productID) {
            case .plusAnnual, .plusLifetime:
                return true
            case .tipTrailer, .tipPilot, .tipHitShow, .none:
                continue
            }
        }
        return false
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    func observeTransactionUpdates(_ onChange: @escaping @MainActor () async -> Void) {
        stopObservingTransactionUpdates()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, !Task.isCancelled else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                }
                await onChange()
            }
        }
    }

    func stopObservingTransactionUpdates() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private static func storeProduct(from product: Product) -> StoreProduct? {
        guard let id = StoreProductID(rawValue: product.id) else { return nil }
        return StoreProduct(
            productID: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            kind: id.kind
        )
    }
}
