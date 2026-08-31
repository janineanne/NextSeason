//
//  WatchlistExportPreparation.swift
//  NextSeason
//

import Foundation

/// Prepares a shareable watchlist CSV and tracks in-progress / error state.
///
/// Export stays available after a failure is dismissed; only an in-flight
/// prepare disables the About-sheet action.
@Observable
@MainActor
final class WatchlistExportPreparation {
    /// Cached CSV ready for ShareLink; nil until the first successful prepare
    /// or after a failed prepare clears it.
    private(set) var exportFile: WatchlistExportFile?
    /// User-facing prepare failure; cleared by `dismissError()` without blocking retry.
    private(set) var errorMessage: String?
    /// True while `prepare` is in flight; concurrent prepares are ignored.
    private(set) var isPreparing = false

    /// True while a prepare is running — the only reason to disable export.
    var isExportControlDisabled: Bool { isPreparing }

    func dismissError() {
        errorMessage = nil
    }

    /// Builds (or rebuilds) `exportFile` from the on-device watchlist.
    ///
    /// On failure, sets `errorMessage` and clears `exportFile` so the About
    /// sheet can show a retry button. Pass `directory` in tests for isolation.
    func prepare(
        repository: any WatchlistRepository,
        showIDMapping: any ShowIDMapping,
        directory: URL? = nil
    ) async {
        guard !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        do {
            exportFile = try await WatchlistExportBuilder.makeFile(
                repository: repository,
                showIDMapping: showIDMapping,
                directory: directory
            )
            errorMessage = nil
        } catch {
            exportFile = nil
            errorMessage = String(
                localized: "Couldn't read your watchlist. Please try again."
            )
        }
    }
}
