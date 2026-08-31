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
    private(set) var exportFile: WatchlistExportFile?
    private(set) var errorMessage: String?
    private(set) var isPreparing = false

    /// True while a prepare is running — the only reason to disable export.
    var isExportControlDisabled: Bool { isPreparing }

    func dismissError() {
        errorMessage = nil
    }

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
