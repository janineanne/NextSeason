//
//  AppAboutPresentationModifier.swift
//  NextSeason
//

import SwiftUI

/// Presents About (always) and Diagnostics (Debug / TestFlight only).
///
/// About is the Restore Purchases and tip-jar surface, so it ships in
/// production. The footer and sheets are omitted during UI tests so layout
/// and existing XCUITests stay stable.
@MainActor
struct AppAboutPresentationModifier: ViewModifier {
    @Environment(PurchaseService.self) private var purchases
    @State private var activeSheet: AppInfoSheet?
    @State private var betaBuildAvailability = BetaBuildAvailability.shared

    func body(content: Content) -> some View {
        if UITestingConfiguration.isEnabled {
            content
        } else {
            content
                .environment(\.openAppAbout) {
                    activeSheet = .about
                }
                .environment(\.presentPlusStore) {
                    activeSheet = .plusStore
                }
                .environment(\.openDiagnostics) {
                    guard betaBuildAvailability.isAvailable else { return }
                    activeSheet = .diagnostics
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .about:
                        AppAboutView {
                            activeSheet = .diagnostics
                        }
                        .environment(purchases)
                    case .diagnostics:
                        DiagnosticsView()
                    case .plusStore:
                        PlusStoreView()
                            .environment(purchases)
                    }
                }
                .task {
                    await betaBuildAvailability.refresh()
                }
        }
    }
}

private enum AppInfoSheet: Identifiable {
    case about
    case diagnostics
    case plusStore

    var id: String {
        switch self {
        case .about:
            return "about"
        case .diagnostics:
            return "diagnostics"
        case .plusStore:
            return "plusStore"
        }
    }
}
