//
//  PlusStoreView.swift
//  NextSeason
//

import SwiftUI

/// Paywall / upgrade sheet: annual subscription, lifetime purchase, and restore.
struct PlusStoreView: View {
    @Environment(PurchaseService.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.screen + 10) {
                    header
                    purchaseButtons
                    restoreButton
                    legalFooter
                }
                .padding(AppSpacing.screen)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .appScreenBackground()
            .navigationTitle("NextSeason Plus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .disabled(purchases.isPurchasing)
            .overlay {
                if purchases.isPurchasing || purchases.isLoadingProducts {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .alert(
                "Couldn't Complete Purchase",
                isPresented: errorAlertPresented
            ) {
                Button("OK", role: .cancel) {
                    purchases.clearMessages()
                }
            } message: {
                Text(purchases.lastErrorMessage ?? "")
            }
            .task {
                if purchases.annualProduct == nil && purchases.lifetimeProduct == nil {
                    await purchases.loadProducts()
                }
            }
            .onChange(of: purchases.isUnlimitedWatchlist) { _, isUnlimited in
                if isUnlimited {
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.screen) {
            Text("Track every show you care about:")
                .font(.title2.bold())
                .appAccentText()
            Text(
                "The free watchlist holds \(WatchlistLimitPolicy.freeShowLimit) shows. With NextSeason Plus you can track unlimited shows, starting with the shows already on your list."
            )
            .font(.body)
            .appSecondaryText()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var purchaseButtons: some View {
        VStack(spacing: AppSpacing.row) {
            if let annual = purchases.annualProduct {
                purchaseButton(
                    title: String(localized: "Annual"),
                    subtitle: String(
                        localized: "\(annual.displayPrice) per year"
                    ),
                    identifier: AccessibilityID.Store.plusAnnual
                ) {
                    await purchase(annual)
                }
            }

            if let lifetime = purchases.lifetimeProduct {
                purchaseButton(
                    title: String(localized: "Lifetime"),
                    subtitle: lifetime.displayPrice,
                    identifier: AccessibilityID.Store.plusLifetime
                ) {
                    await purchase(lifetime)
                }
            }

            if purchases.annualProduct == nil && purchases.lifetimeProduct == nil
                && !purchases.isLoadingProducts
            {
                ContentUnavailableView {
                    Label("Purchase Options Unavailable", systemImage: "cart")
                } description: {
                    Text("NextSeason couldn't load purchase options right now.")
                } actions: {
                    Button("Try Again") {
                        Task { await purchases.loadProducts() }
                    }
                }
            }
        }
    }

    private var restoreButton: some View {
        Button {
            Task { _ = await purchases.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(AccessibilityID.Store.restore)
        .padding(.top, AppSpacing.tight)
    }

    private var legalFooter: some View {
        VStack(alignment: .leading, spacing: AppSpacing.row) {
            Text(subscriptionDisclosure)
                .font(.footnote)
                .appSecondaryText()

            HStack(spacing: AppSpacing.screen) {
                if let terms = StoreLegalLinks.termsOfUse {
                    Link("Terms of Use", destination: terms)
                }
                if let privacy = StoreLegalLinks.privacyPolicy {
                    Link("Privacy Policy", destination: privacy)
                }
            }
            .font(.footnote)
        }
        .padding(.top, AppSpacing.tight)
    }

    private var subscriptionDisclosure: String {
        String(
            localized:
                "NextSeason Plus Annual is an auto-renewing subscription. Payment is charged to your Apple ID account at confirmation of purchase. The subscription renews automatically unless you cancel at least 24 hours before the end of the current period. You can manage or cancel any time. The Lifetime membership is a one-time purchase that permanently unlocks an unlimited watchlist."
        )
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { purchases.lastErrorMessage != nil },
            set: { if !$0 { purchases.clearMessages() } }
        )
    }

    private func purchaseButton(
        title: String,
        subtitle: String,
        identifier: String,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.tiny)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private func purchase(_ product: StoreProduct) async {
        let outcome = await purchases.purchase(product)
        if outcome == .success {
            dismiss()
        }
    }
}

#if DEBUG
    #Preview {
        PlusStoreView()
            .environment(PurchaseService.preview)
    }
#endif
