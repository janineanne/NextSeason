//
//  PlusAccountSection.swift
//  NextSeason
//

import SwiftUI

/// About-screen Plus status, upgrade CTA, and Restore Purchases.
struct PlusAccountSection: View {
    @Environment(PurchaseService.self) private var purchases
    @Binding var isShowingPlusStore: Bool

    var body: some View {
        Section {
            LabeledContent {
                Text(statusValue)
            } label: {
                Label("Watchlist", systemImage: "star")
            }

            if !purchases.isUnlimitedWatchlist {
                Button {
                    isShowingPlusStore = true
                } label: {
                    Label("Unlock NextSeason Plus", systemImage: "sparkles")
                }
                .accessibilityIdentifier(AccessibilityID.Store.plusUnlock)
            }

            Button {
                Task { _ = await purchases.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
            .accessibilityIdentifier(AccessibilityID.Store.restore)
            .disabled(purchases.isPurchasing)
        } header: {
            Text("NextSeason Plus")
        } footer: {
            Text(footerText)
        }
    }

    private var statusValue: String {
        if purchases.isStoreEntitled {
            return String(localized: "Unlimited")
        }
        if purchases.isGrandfathered {
            return String(localized: "Unlimited")
        }
        return String(
            localized: "Up to \(WatchlistLimitPolicy.freeShowLimit) shows"
        )
    }

    private var footerText: String {
        if purchases.isStoreEntitled {
            return String(localized: "You have NextSeason Plus.")
        }
        if purchases.isGrandfathered {
            return String(
                localized:
                    "Your watchlist is unlimited because you were tracking more than \(WatchlistLimitPolicy.freeShowLimit) shows before this limit was added."
            )
        }
        return String(
            localized: "NextSeason Plus removes the watchlist limit."
        )
    }
}
