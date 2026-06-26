//
//  TVMazeAttributionView.swift
//  NextSeason
//

import SwiftUI

/// Required TVMaze credit-back on screens that display their data (PD-002, PD-008).
struct TVMazeAttributionView: View {
    @Environment(\.openDiagnostics) private var openDiagnostics

    var body: some View {
        VStack(spacing: 2) {
            Text("Data provided by TVMaze")
                .font(.footnote)
                .appSecondaryText()
            if openDiagnostics != nil, !UITestingConfiguration.isEnabled {
                Text("Version \(AppVersionInfo.displayString)")
                    .font(.caption2)
                    .appSecondaryText()
                    .accessibilityHint("Long press to open diagnostics")
                    .onLongPressGesture(minimumDuration: 0.8) {
                        openDiagnostics?()
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// Pins TVMaze attribution above the tab bar or home indicator.
    func tvmazeAttributionInset() -> some View {
        modifier(TVMazeAttributionInsetModifier())
    }
}

private struct TVMazeAttributionInsetModifier: ViewModifier {
    @Environment(\.appThemeColors) private var themeColors

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            TVMazeAttributionView()
                .padding(.vertical, AppSpacing.tight)
                .background(themeColors.background)
        }
    }
}

#if DEBUG
#Preview {
    TVMazeAttributionView()
}
#endif
