//
//  PersistenceRecoveryExportPreparation.swift
//  NextSeason
//

import Foundation
import os

/// Whether recovery can offer a last-chance watchlist export.
enum RecoveryExportAvailability: Equatable, Sendable {
    /// Probe has not finished.
    case probing
    /// At least one show identity could still be read.
    case available(showCount: Int)
    /// Nothing usable could be recovered, or the store could not be read.
    case unavailable(RecoveryExportUnavailability)
}

/// Why export is not offered before a destructive reset.
enum RecoveryExportUnavailability: Equatable, Sendable {
    /// The store files could not be opened or contained no show table.
    case storeUnreadable
    /// The store opened but no show rows could be decoded.
    case noRecoverableShows
}

/// Best-effort recovery export: probe the damaged store, then build a CSV
/// from whatever rows could still be read.
///
/// Probe and prepare failures never disable reset. A successful probe with
/// zero shows skips the export action rather than offering an empty file.
/// Concurrent `probeIfNeeded()` callers join one in-flight read so Reset
/// cannot present while recoverability is still unknown.
@Observable
@MainActor
final class PersistenceRecoveryExportPreparation {
    /// Result of the last probe. Starts as `probing` until `probeIfNeeded` finishes.
    private(set) var availability: RecoveryExportAvailability = .probing
    /// Shows recovered by the last successful probe. Empty when unavailable.
    private(set) var recoveredShows: [TrackedShow] = []
    /// True while a CSV is being written.
    private(set) var isPreparing = false
    /// User-facing prepare failure; cleared when a later prepare succeeds.
    private(set) var exportErrorMessage: String?

    /// True when the confirmation should include **Export Watchlist**.
    var canExport: Bool {
        if case .available = availability { return true }
        return false
    }

    /// Shared in-flight (or completed) probe. Later callers await this instead
    /// of treating “started” as “finished,” so Reset cannot present while
    /// availability is still `.probing`.
    private var probeTask: Task<Void, Never>?
    /// Production reads the on-disk store; tests inject a stubbed result.
    private let loadShows: @MainActor () async -> WatchlistRecoveryExportRead

    /// `loadShows` is injectable so tests can stub recoverability without
    /// touching the production store.
    init(
        loadShows: @escaping @MainActor () async -> WatchlistRecoveryExportRead = {
            await WatchlistRecoveryExportReader.loadShows()
        }
    ) {
        self.loadShows = loadShows
    }

    /// Reads the store once per recovery presentation. Concurrent callers
    /// join the same in-flight task and do not return until availability
    /// is known. Completed probes are reused so the store is not re-read.
    func probeIfNeeded() async {
        if let probeTask {
            await probeTask.value
            return
        }

        let task = Task { @MainActor in
            await self.performProbe()
        }
        probeTask = task
        await task.value
    }

    /// Applies `loadShows()` to `availability`. Isolated so overlapping
    /// `probeIfNeeded()` calls share one read.
    private func performProbe() async {
        let read = await loadShows()
        recoveredShows = read.shows
        // Distinguish "opened but empty" from "could not read at all" so the
        // confirmation can explain why Export Watchlist is omitted.
        if read.shows.isEmpty {
            availability =
                read.storeWasReadable
                ? .unavailable(.noRecoverableShows)
                : .unavailable(.storeUnreadable)
            AppDiagnosticsLogger.breadcrumb("recovery_watchlist_export_probe_unavailable")
        } else {
            availability = .available(showCount: read.shows.count)
            AppDiagnosticsLogger.breadcrumb("recovery_watchlist_export_probe_available")
        }
        AppDiagnosticsLogger.persistBreadcrumbsNow()
    }

    /// Writes a CSV from `recoveredShows`. Returns `nil` when export is not
    /// available or the write fails. Failure sets `exportErrorMessage` but
    /// leaves `canExport` unchanged so reset remains available.
    func prepareFile(
        showIDMapping: any ShowIDMapping,
        directory: URL? = nil
    ) async -> WatchlistExportFile? {
        guard canExport, isPreparing == false else { return nil }
        isPreparing = true
        defer { isPreparing = false }

        do {
            let file = try await WatchlistExportBuilder.makeFile(
                shows: recoveredShows,
                showIDMapping: showIDMapping,
                directory: directory
            )
            exportErrorMessage = nil
            AppDiagnosticsLogger.breadcrumb("recovery_watchlist_export_succeeded")
            AppDiagnosticsLogger.persistBreadcrumbsNow()
            return file
        } catch {
            exportErrorMessage = String(
                localized: "Couldn't export the watchlist. You can still reset local data."
            )
            AppDiagnosticsLogger.breadcrumb("recovery_watchlist_export_failed")
            AppDiagnosticsLogger.persistBreadcrumbsNow()
            AppDiagnosticsLogger.logger(for: .persistence).error(
                "recovery_watchlist_export_failed error=\(String(describing: error), privacy: .public)"
            )
            return nil
        }
    }

    /// Clears a prepare failure so the user can reset or try export again.
    func dismissExportError() {
        exportErrorMessage = nil
    }
}
