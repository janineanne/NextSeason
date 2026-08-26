//
//  PurchaseService.swift
//  NextSeason
//

import Foundation

/// Observable purchasing and Plus entitlement state for the SwiftUI environment.
///
/// Unlimited watchlist access comes from an active annual subscription, a
/// lifetime purchase, or one-time beta grandfathering. Tips never grant Plus.
@Observable
@MainActor
final class PurchaseService {
    private(set) var isStoreEntitled = false
    private(set) var annualProduct: StoreProduct?
    private(set) var lifetimeProduct: StoreProduct?
    private(set) var tipProducts: [StoreProduct] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var lastErrorMessage: String?
    private(set) var thankYouMessage: String?

    private let store: any PurchaseStoreClient
    private let entitlementStore: PlusEntitlementStore
    private var didStart = false

    /// True when StoreKit Plus is active or the user was grandfathered.
    var isUnlimitedWatchlist: Bool {
        isStoreEntitled || entitlementStore.isGrandfathered
    }

    var isGrandfathered: Bool {
        entitlementStore.isGrandfathered
    }

    init(
        store: any PurchaseStoreClient,
        entitlementStore: PlusEntitlementStore = PlusEntitlementStore(),
        initialStoreEntitled: Bool = false
    ) {
        self.store = store
        self.entitlementStore = entitlementStore
        self.isStoreEntitled = initialStoreEntitled
    }

    /// Production StoreKit-backed service.
    convenience init() {
        self.init(store: StoreKitPurchaseStoreClient())
    }

    /// Loads products, applies one-time grandfathering, and starts listening
    /// for StoreKit transaction updates.
    func start(watchlistCount: Int) async {
        entitlementStore.evaluateGrandfatheringIfNeeded(
            watchlistCount: watchlistCount,
            freeLimit: WatchlistLimitPolicy.freeShowLimit
        )
        await refreshEntitlements()

        if !didStart {
            didStart = true
            store.observeTransactionUpdates { [weak self] in
                await self?.refreshEntitlements()
            }
        }
        await loadProducts()
    }

    func canAddToWatchlist(currentCount: Int) -> Bool {
        WatchlistLimitPolicy.canAddShow(
            currentCount: currentCount,
            isUnlimited: isUnlimitedWatchlist
        )
    }

    func loadProducts() async {
        isLoadingProducts = true
        lastErrorMessage = nil
        defer { isLoadingProducts = false }

        do {
            let products = try await store.loadProducts(ids: StoreProductID.allIDs)
            annualProduct = products.first { $0.kind == .plusAnnual }
            lifetimeProduct = products.first { $0.kind == .plusLifetime }
            tipProducts =
                products
                .filter { $0.kind == .tip }
                .sorted { lhs, rhs in
                    tipSortIndex(lhs.productID) < tipSortIndex(rhs.productID)
                }
            if annualProduct == nil && lifetimeProduct == nil {
                AppDiagnosticsLogger.breadcrumb("purchase_products_empty")
            }
        } catch is CancellationError {
            return
        } catch {
            lastErrorMessage = String(
                localized: "Couldn't load purchase options. Please try again."
            )
            AppDiagnosticsLogger.breadcrumb("purchase_products_load_failed")
        }
    }

    func purchase(_ product: StoreProduct) async -> PurchaseOutcome {
        guard !isPurchasing else { return .pending }
        isPurchasing = true
        lastErrorMessage = nil
        thankYouMessage = nil
        defer { isPurchasing = false }

        do {
            let outcome = try await store.purchase(productID: product.productID)
            switch outcome {
            case .success:
                await refreshEntitlements()
                if product.kind == .tip {
                    thankYouMessage = String(localized: "Thank you for supporting NextSeason.")
                }
            case .cancelled, .pending:
                break
            case .failed(let message):
                lastErrorMessage = message
            }
            return outcome
        } catch is CancellationError {
            return .cancelled
        } catch {
            let message = error.localizedDescription
            lastErrorMessage = message
            return .failed(message)
        }
    }

    func restorePurchases() async -> PurchaseOutcome {
        guard !isPurchasing else { return .pending }
        isPurchasing = true
        lastErrorMessage = nil
        defer { isPurchasing = false }

        do {
            try await store.restorePurchases()
            await refreshEntitlements()
            return .success
        } catch is CancellationError {
            return .cancelled
        } catch {
            let message = String(
                localized: "Couldn't restore purchases. Please try again."
            )
            lastErrorMessage = message
            return .failed(message)
        }
    }

    func refreshEntitlements() async {
        isStoreEntitled = await store.hasActivePlusEntitlement()
    }

    func clearMessages() {
        lastErrorMessage = nil
        thankYouMessage = nil
    }

    private func tipSortIndex(_ productID: String) -> Int {
        switch StoreProductID(rawValue: productID) {
        case .tipTrailer: 0
        case .tipPilot: 1
        case .tipHitShow: 2
        default: 99
        }
    }
}

extension PurchaseService {
    /// Tests, previews, and UI tests. Does not contact StoreKit.
    static func stub(
        isStoreEntitled: Bool = false,
        userDefaults: UserDefaults? = nil,
        products: [StoreProduct] = StoreProductID.allCases.map { StoreProduct($0) },
        purchaseOutcome: PurchaseOutcome = .success
    ) -> PurchaseService {
        let defaults: UserDefaults
        if let userDefaults {
            defaults = userDefaults
        } else {
            let suiteName = "PurchaseService.stub.\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: suiteName) ?? .standard
            defaults.removePersistentDomain(forName: suiteName)
        }
        return PurchaseService(
            store: StubPurchaseStoreClient(
                products: products,
                isStoreEntitled: isStoreEntitled,
                purchaseOutcome: purchaseOutcome
            ),
            entitlementStore: PlusEntitlementStore(userDefaults: defaults),
            initialStoreEntitled: isStoreEntitled
        )
    }

    /// Preview catalog with fallback prices; not entitled.
    static var preview: PurchaseService {
        stub()
    }
}
