//
//  ExportWatchlistSection.swift
//  NextSeason
//

import SwiftUI

/// About-sheet action that shares the full watchlist as a CSV file.
///
/// Available to every user; not gated on NextSeason Plus.
struct ExportWatchlistSection: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.showIDMapping) private var showIDMapping

    @State private var exportFile: WatchlistExportFile?
    @State private var exportErrorMessage: String?

    var body: some View {
        Section {
            if let exportFile {
                ShareLink(
                    item: exportFile,
                    preview: SharePreview(exportFile.url.lastPathComponent)
                ) {
                    Label("Export Watchlist", systemImage: "square.and.arrow.up")
                }
                .accessibilityHint(hintText)
                .accessibilityIdentifier(AccessibilityID.App.exportWatchlist)
            } else {
                Button("Export Watchlist", systemImage: "square.and.arrow.up", action: retryExport)
                    .disabled(exportErrorMessage == nil)
                    .accessibilityHint(hintText)
                    .accessibilityIdentifier(AccessibilityID.App.exportWatchlist)
            }
        } footer: {
            Text(
                "Exports every show on your watchlist as a CSV file you can open in Numbers or Excel."
            )
        }
        .task {
            await prepareExport()
        }
        .alert(
            "Couldn't Export Watchlist",
            isPresented: errorAlertPresented
        ) {
            Button("OK", role: .cancel) {
                exportErrorMessage = nil
            }
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private var hintText: String {
        String(localized: "Shares your watchlist as a CSV file.")
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private func retryExport() {
        Task { await prepareExport() }
    }

    private func prepareExport() async {
        do {
            exportFile = try await WatchlistExportBuilder.makeFile(
                repository: repository,
                showIDMapping: showIDMapping
            )
            exportErrorMessage = nil
        } catch {
            exportFile = nil
            exportErrorMessage = String(
                localized: "Couldn't read your watchlist. Please try again."
            )
        }
    }
}

#if DEBUG
    #Preview {
        List {
            ExportWatchlistSection()
        }
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
        .environment(\.showIDMapping, InMemoryShowIDMapping(map: [:]))
    }
#endif
