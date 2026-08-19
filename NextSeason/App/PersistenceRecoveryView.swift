//
//  PersistenceRecoveryView.swift
//  NextSeason
//

import SwiftUI

/// Blocking launch screen when the watchlist store cannot be opened or a
/// crash loop was detected.
///
/// Crash-loop recovery offers Export Diagnostics and Try Again only.
/// Persistence-open failures also offer **Reset Local Data**, with
/// confirmation, after explaining that reset deletes the local watchlist.
/// After a successful reset that still cannot initialize storage, the copy
/// no longer implies the original watchlist can be preserved.
struct PersistenceRecoveryView: View {
    let context: AppLaunchState.RecoveryContext
    let onResetLocalData: () -> Void
    let onRetryLaunch: () -> Void

    @State private var isConfirmingReset = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label {
                    Text(titleText)
                        .appAccentText()
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .appPrimaryText()
                }
            } description: {
                Text(descriptionText)
                    .appSecondaryText()
            } actions: {
                ShareLink(item: context.diagnosticsReport()) {
                    Label("Export Diagnostics", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.exportDiagnostics)

                if context.allowsRetry {
                    Button("Try Again", action: onRetryLaunch)
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.tryAgain)
                }

                if context.allowsPersistenceReset {
                    Button(
                        "Reset Local Data",
                        role: .destructive,
                        action: presentResetConfirmation
                    )
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.resetLocalData)
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.screen)
            .navigationTitle("NextSeason")
            .navigationBarTitleDisplayMode(.inline)
        }
        .appAccentTint()
        .appScreenBackground()
        .alert("Reset Local Data?", isPresented: $isConfirmingReset) {
            Button("Reset Local Data", role: .destructive, action: confirmReset)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
    }

    private var titleText: String {
        switch context.kind {
        case .persistenceFailureAfterReset:
            String(localized: "Couldn't Set Up Local Data")
        case .crashLoop:
            String(localized: "NextSeason Closed Repeatedly")
        case .persistenceFailure:
            String(localized: "Couldn't Open Your Watchlist")
        }
    }

    private var descriptionText: String {
        let base: String
        switch context.kind {
        case .persistenceFailureAfterReset:
            base = String(
                localized:
                    "Your local watchlist was reset successfully, but NextSeason still couldn't initialize its local data store. The previous watchlist can no longer be restored. You can export diagnostics for troubleshooting."
            )
        case .crashLoop:
            base = String(
                localized:
                    "NextSeason closed unexpectedly several times before it could finish launching. You can export diagnostics for troubleshooting and try launching again."
            )
        case .persistenceFailure:
            base = String(
                localized:
                    "NextSeason couldn't read the shows saved on this device. You can export diagnostics for troubleshooting. Resetting local data permanently deletes your watchlist and any scheduled next-season reminders on this device. You can search for shows and add them again afterward."
            )
        }
        guard context.resetError != nil else { return base }
        return base + "\n\n\(genericResetFailureText)"
    }

    private var genericResetFailureText: String {
        String(
            localized:
                "NextSeason couldn't reset its local data. You can export diagnostics for troubleshooting and try again."
        )
    }

    private var confirmationMessage: String {
        String(
            localized:
                "This permanently deletes your saved watchlist and scheduled reminders on this device. You can search for shows and add them again afterward. This cannot be undone."
        )
    }

    private func presentResetConfirmation() {
        isConfirmingReset = true
    }

    private func confirmReset() {
        onResetLocalData()
    }
}

#if DEBUG
    private struct PreviewPersistenceError: Error {}

    #Preview("Initial failure") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                kind: .persistenceFailure,
                error: PreviewPersistenceError()
            ),
            onResetLocalData: {},
            onRetryLaunch: {}
        )
    }

    #Preview("Crash loop") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                kind: .crashLoop,
                error: RepeatedLaunchFailure(consecutiveCount: 2),
                consecutiveLaunchFailures: 2
            ),
            onResetLocalData: {},
            onRetryLaunch: {}
        )
    }

    #Preview("After successful reset") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                kind: .persistenceFailureAfterReset,
                error: PreviewPersistenceError(),
                originalError: PreviewPersistenceError()
            ),
            onResetLocalData: {},
            onRetryLaunch: {}
        )
    }
#endif
