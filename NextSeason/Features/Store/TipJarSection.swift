//
//  TipJarSection.swift
//  NextSeason
//

import SwiftUI

/// Optional consumable tips. Shown to free and Plus users; never unlocks features.
///
/// Purchase buttons are created only from products StoreKit actually loaded.
struct TipJarSection: View {
    @Environment(PurchaseService.self) private var purchases

    var body: some View {
        Section {
            if !purchases.tipProducts.isEmpty {
                ForEach(purchases.tipProducts) { product in
                    Button {
                        Task { _ = await purchases.purchase(product) }
                    } label: {
                        LabeledContent {
                            Text(product.displayPrice)
                        } label: {
                            Text(product.displayName)
                        }
                    }
                    .accessibilityIdentifier(tipIdentifier(for: product.productID))
                    .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
                    .disabled(purchases.isPurchasing)
                }
            } else if isWaitingForTips {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Loading tip options")
            } else {
                Text("NextSeason couldn't load tip options right now.")
                    .appSecondaryText()
                Button("Try Again") {
                    Task { await purchases.loadProducts() }
                }
                .disabled(purchases.isLoadingProducts || purchases.isPurchasing)
            }
        } header: {
            Text("Support NextSeason")
        } footer: {
            Text(
                "Tips are optional and do not unlock features. Thank you for helping keep NextSeason running for years to come."
            )
        }
        .task {
            if purchases.tipProducts.isEmpty {
                await purchases.loadProducts()
            }
        }
    }

    /// True while StoreKit products are loading or the first load has not finished.
    /// Distinguishes a spinner from the empty-state retry UI after a failed load.
    private var isWaitingForTips: Bool {
        purchases.isLoadingProducts || !purchases.hasCompletedProductLoad
    }

    /// Maps known tip product IDs to stable accessibility identifiers for UI tests.
    private func tipIdentifier(for productID: String) -> String {
        switch StoreProductID(rawValue: productID) {
        case .tipTrailer: AccessibilityID.Store.tipTrailer
        case .tipPilot: AccessibilityID.Store.tipPilot
        case .tipHitShow: AccessibilityID.Store.tipHitShow
        default: productID
        }
    }
}
