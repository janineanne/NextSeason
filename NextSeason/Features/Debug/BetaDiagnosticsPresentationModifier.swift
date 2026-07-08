//
//  BetaDiagnosticsPresentationModifier.swift
//  NextSeason
//

import SwiftUI

/// Presents beta diagnostics only in DEBUG or TestFlight builds.
@MainActor
struct BetaDiagnosticsPresentationModifier: ViewModifier {
    @State private var activeSheet: BetaDiagnosticsSheet?
    @State private var betaBuildAvailability = BetaBuildAvailability.shared

    func body(content: Content) -> some View {
        if betaBuildAvailability.isAvailable {
            content
                .environment(\.openAppAbout) {
                    guard !UITestingConfiguration.isEnabled else { return }
                    activeSheet = .about
                }
                .environment(\.openDiagnostics) {
                    guard !UITestingConfiguration.isEnabled else { return }
                    activeSheet = .diagnostics
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .about:
                        AppAboutView {
                            activeSheet = .diagnostics
                        }
                    case .diagnostics:
                        DiagnosticsView()
                    }
                }
                .task {
                    await betaBuildAvailability.refresh()
                }
        } else {
            content
                .task {
                    await betaBuildAvailability.refresh()
                }
        }
    }
}

private enum BetaDiagnosticsSheet: Identifiable {
    case about
    case diagnostics

    var id: String {
        switch self {
        case .about:
            return "about"
        case .diagnostics:
            return "diagnostics"
        }
    }
}
