//
//  PersistenceRecoveryView.swift
//  NextSeason
//

import SwiftUI

/// Blocking launch screen when the watchlist store cannot be opened.
///
/// Explains that reset deletes local watchlist data, lets the user export
/// diagnostics first, and requires confirmation before **Reset Local Data**.
/// After a successful reset that still cannot initialize storage, the copy
/// no longer implies the original watchlist can be preserved.
struct PersistenceRecoveryView: View {
    let context: AppLaunchState.RecoveryContext
    let onResetLocalData: () -> Void

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

                if context.didResetStore {
                    Button("Try Again", action: onResetLocalData)
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.tryAgain)
                } else {
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
        if context.didResetStore {
            String(localized: "Couldn't Set Up Local Data")
        } else {
            String(localized: "Couldn't Open Your Watchlist")
        }
    }

    private var descriptionText: String {
        if context.didResetStore {
            var text = String(
                localized:
                    "Your local watchlist was reset successfully, but NextSeason still couldn't initialize its local data store. The previous watchlist can no longer be restored. You can export diagnostics for troubleshooting."
            )
            if context.resetError != nil {
                text += "\n\n\(genericResetFailureText)"
            }
            return text
        }

        var text = String(
            localized:
                "NextSeason couldn't read the shows saved on this device. You can export diagnostics for troubleshooting. Resetting local data permanently deletes your watchlist and any scheduled next-season reminders on this device. You can search for shows and add them again afterward."
        )
        if context.resetError != nil {
            text += "\n\n\(genericResetFailureText)"
        }
        return text
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
            context: AppLaunchState.RecoveryContext(error: PreviewPersistenceError()),
            onResetLocalData: {}
        )
    }

    #Preview("After successful reset") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                error: PreviewPersistenceError(),
                originalError: PreviewPersistenceError(),
                didResetStore: true
            ),
            onResetLocalData: {}
        )
    }
#endif
