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
/// Before a destructive reset, recovery offers a best-effort watchlist
/// export when any show data can still be read. After a successful reset
/// that still cannot initialize storage, the copy no longer implies the
/// original watchlist can be preserved.
struct PersistenceRecoveryView: View {
    /// Which recovery copy and actions to show (`RecoveryKind`).
    let context: AppLaunchState.RecoveryContext
    /// Confirmed destructive reset of the on-disk watchlist store.
    let onResetLocalData: () -> Void
    /// Non-destructive composition retry in this already-running process.
    let onRetryLaunch: () -> Void

    /// Destructive-reset confirmation; buttons depend on export recoverability.
    @State private var isConfirmingReset = false
    /// Best-effort probe/prepare; injected in previews so they never open the real store.
    @State private var exportPreparation: PersistenceRecoveryExportPreparation
    /// Set after a successful prepare so `sheet(item:)` can present the CSV.
    @State private var shareFile: WatchlistExportFile?

    /// `exportPreparation` is injectable so previews and tests can stub
    /// recoverability without touching the on-device watchlist store.
    init(
        context: AppLaunchState.RecoveryContext,
        onResetLocalData: @escaping () -> Void,
        onRetryLaunch: @escaping () -> Void,
        exportPreparation: PersistenceRecoveryExportPreparation =
            PersistenceRecoveryExportPreparation()
    ) {
        self.context = context
        self.onResetLocalData = onResetLocalData
        self.onRetryLaunch = onRetryLaunch
        _exportPreparation = State(initialValue: exportPreparation)
    }

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
        .task {
            // Crash-loop recovery does not offer reset, so it does not probe.
            guard context.allowsPersistenceReset else { return }
            await exportPreparation.probeIfNeeded()
        }
        .alert("Reset Local Data?", isPresented: $isConfirmingReset) {
            // Export is omitted (not just disabled) when nothing could be read.
            if exportPreparation.canExport {
                Button("Export Watchlist", action: startRecoveryExport)
                    .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.exportWatchlist)
                Button("Reset Without Exporting", role: .destructive, action: confirmReset)
                    .accessibilityIdentifier(
                        AccessibilityID.PersistenceRecovery.resetWithoutExporting)
            } else {
                Button("Reset Local Data", role: .destructive, action: confirmReset)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(confirmationMessage)
        }
        // Prepare failure must not trap the user: reset stays available here.
        .alert(
            "Couldn't Export Watchlist",
            isPresented: exportFailedAlertPresented
        ) {
            Button("Reset Local Data", role: .destructive, action: confirmReset)
            Button("Cancel", role: .cancel) {
                exportPreparation.dismissExportError()
            }
        } message: {
            Text(exportFailedMessage)
        }
        .sheet(item: $shareFile) { file in
            RecoveryWatchlistExportSheet(file: file, onReset: confirmReset)
        }
    }

    /// Title keyed off `RecoveryKind` (crash loop vs store-open vs post-reset).
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

    /// Body copy for the current kind. Reset failures append generic follow-up
    /// text; technical `localizedDescription` stays in diagnostics export only.
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
        var text = base
        // Append export availability only when reset is actually offered.
        if context.allowsPersistenceReset {
            text += "\n\n\(recoveryExportDescription)"
        }
        guard context.resetError != nil else { return text }
        return text + "\n\n\(genericResetFailureText)"
    }

    /// Last-chance export copy for the recovery screen. Does not claim the
    /// exported file is complete when data can still be read.
    private var recoveryExportDescription: String {
        switch exportPreparation.availability {
        case .probing:
            String(localized: "Checking whether any watchlist data can still be exported…")
        case .available:
            String(
                localized:
                    "You can try to export whatever watchlist data can still be read before resetting. The exported file may be incomplete."
            )
        case .unavailable(.storeUnreadable):
            String(
                localized:
                    "The local store is too damaged to export any watchlist data."
            )
        case .unavailable(.noRecoverableShows):
            String(
                localized:
                    "No watchlist shows could be recovered for export."
            )
        }
    }

    private var genericResetFailureText: String {
        String(
            localized:
                "NextSeason couldn't reset its local data. You can export diagnostics for troubleshooting and try again."
        )
    }

    /// Confirmation text for the three-button export/reset alert, or the
    /// two-button reset-only alert when nothing could be recovered.
    private var confirmationMessage: String {
        if exportPreparation.canExport {
            String(
                localized:
                    "This permanently deletes your saved watchlist and scheduled reminders on this device. You can try to export whatever can still be read first. The exported file may be incomplete. This cannot be undone."
            )
        } else {
            switch exportPreparation.availability {
            case .unavailable(.noRecoverableShows):
                String(
                    localized:
                        "This permanently deletes your saved watchlist and scheduled reminders on this device. No watchlist shows could be recovered for export. You can search for shows and add them again afterward. This cannot be undone."
                )
            default:
                String(
                    localized:
                        "This permanently deletes your saved watchlist and scheduled reminders on this device. The local store is too damaged to export any watchlist data. You can search for shows and add them again afterward. This cannot be undone."
                )
            }
        }
    }

    /// Follow-up after a failed prepare; still invites the user to reset.
    private var exportFailedMessage: String {
        exportPreparation.exportErrorMessage
            ?? String(
                localized: "Couldn't export the watchlist. You can still reset local data."
            )
    }

    /// Shown only when prepare failed and the share sheet is not up, so a
    /// successful export is not covered by the failure alert.
    private var exportFailedAlertPresented: Binding<Bool> {
        Binding(
            get: { exportPreparation.exportErrorMessage != nil && shareFile == nil },
            set: { if !$0 { exportPreparation.dismissExportError() } }
        )
    }

    /// Waits for the probe so the confirmation buttons match recoverability.
    private func presentResetConfirmation() {
        Task {
            await exportPreparation.probeIfNeeded()
            isConfirmingReset = true
        }
    }

    /// Prepares a CSV in a unique temp folder so a later retry gets a new URL
    /// for `sheet(item:)`. A nil result leaves reset available via the failure alert.
    private func startRecoveryExport() {
        Task {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "recovery-watchlist-export-\(UUID().uuidString)",
                    isDirectory: true
                )
            let file = await exportPreparation.prepareFile(
                showIDMapping: recoveryShowIDMapping(),
                directory: directory
            )
            if let file {
                shareFile = file
            }
        }
    }

    /// Dismisses the export sheet (if any) and performs the destructive reset.
    private func confirmReset() {
        shareFile = nil
        onResetLocalData()
    }

    /// Mapping is independent of the watchlist store. A mapping-open failure
    /// still allows export; TVDB IDs are simply omitted.
    private func recoveryShowIDMapping() -> any ShowIDMapping {
        do {
            return try ShowIDMappingDatabase.openDefault()
        } catch {
            return InMemoryShowIDMapping(map: [:])
        }
    }
}

/// Share sheet after a successful best-effort recovery export. Reset remains
/// available if the user cancels sharing; the copy does not claim completeness.
private struct RecoveryWatchlistExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let file: WatchlistExportFile
    /// Destructive reset after the user has had a chance to share the CSV.
    let onReset: () -> Void

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label {
                    Text("Watchlist Export Ready")
                        .appAccentText()
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .appPrimaryText()
                }
            } description: {
                Text(
                    "This file contains whatever watchlist data could still be read. It may be incomplete."
                )
                .appSecondaryText()
            } actions: {
                ShareLink(
                    item: file,
                    preview: SharePreview(file.url.lastPathComponent)
                ) {
                    Label("Share Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.exportWatchlist)

                Button("Reset Local Data", role: .destructive, action: onReset)
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(AccessibilityID.PersistenceRecovery.resetLocalData)
            }
            .padding(.horizontal, AppSpacing.screen)
            .navigationTitle("NextSeason")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .appAccentTint()
        .appScreenBackground()
    }
}

#if DEBUG
    private struct PreviewPersistenceError: Error {}

    /// Stubbed probe result so previews never copy or open the production store.
    private func previewRecoveryExportPreparation(
        shows: [TrackedShow] = [],
        storeWasReadable: Bool = false
    ) -> PersistenceRecoveryExportPreparation {
        PersistenceRecoveryExportPreparation {
            WatchlistRecoveryExportRead(shows: shows, storeWasReadable: storeWasReadable)
        }
    }

    /// Sample row for the export-available preview only.
    private func previewRecoveredShow() -> TrackedShow {
        TrackedShow(
            id: 44933,
            name: "Severance",
            posterMediumURL: nil,
            tvMazeURL: URL(string: "https://www.tvmaze.com/shows/44933/severance"),
            status: .running,
            nextSeason: .unknown,
            sourceUpdatedAt: Date(timeIntervalSince1970: 0),
            lastCheckedAt: Date(timeIntervalSince1970: 0),
            dateAdded: Date(timeIntervalSince1970: 0)
        )
    }

    #Preview("Initial failure") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                kind: .persistenceFailure,
                error: PreviewPersistenceError()
            ),
            onResetLocalData: {},
            onRetryLaunch: {},
            exportPreparation: previewRecoveryExportPreparation(
                shows: [previewRecoveredShow()],
                storeWasReadable: true
            )
        )
    }

    #Preview("Store too damaged to export") {
        PersistenceRecoveryView(
            context: AppLaunchState.RecoveryContext(
                kind: .persistenceFailure,
                error: PreviewPersistenceError()
            ),
            onResetLocalData: {},
            onRetryLaunch: {},
            exportPreparation: previewRecoveryExportPreparation()
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
