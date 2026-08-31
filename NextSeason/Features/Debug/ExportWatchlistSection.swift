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

    @State private var preparation = WatchlistExportPreparation()

    var body: some View {
        Section {
            if let exportFile = preparation.exportFile {
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
                    .disabled(preparation.isExportControlDisabled)
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
                preparation.dismissError()
            }
        } message: {
            Text(preparation.errorMessage ?? "")
        }
    }

    private var hintText: String {
        String(localized: "Shares your watchlist as a CSV file.")
    }

    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { preparation.errorMessage != nil },
            set: { if !$0 { preparation.dismissError() } }
        )
    }

    private func retryExport() {
        Task { await prepareExport() }
    }

    private func prepareExport() async {
        await preparation.prepare(
            repository: repository,
            showIDMapping: showIDMapping
        )
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
