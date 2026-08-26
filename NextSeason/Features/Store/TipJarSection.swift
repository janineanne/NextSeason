//
//  TipJarSection.swift
//  NextSeason
//

import SwiftUI

/// Optional consumable tips. Shown to free and Plus users; never unlocks features.
struct TipJarSection: View {
    @Environment(PurchaseService.self) private var purchases

    var body: some View {
        Section {
            ForEach(displayedTips) { product in
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
        } header: {
            Text("Support NextSeason")
        } footer: {
            Text(
                "Tips are optional and do not unlock features. Thank you for helping keep NextSeason going."
            )
        }
    }

    private var displayedTips: [StoreProduct] {
        if purchases.tipProducts.isEmpty {
            return [
                StoreProduct(.tipTrailer),
                StoreProduct(.tipPilot),
                StoreProduct(.tipHitShow),
            ]
        }
        return purchases.tipProducts
    }

    private func tipIdentifier(for productID: String) -> String {
        switch StoreProductID(rawValue: productID) {
        case .tipTrailer: AccessibilityID.Store.tipTrailer
        case .tipPilot: AccessibilityID.Store.tipPilot
        case .tipHitShow: AccessibilityID.Store.tipHitShow
        default: productID
        }
    }
}
