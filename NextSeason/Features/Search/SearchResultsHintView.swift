//
//  SearchResultsHintView.swift
//  NextSeason
//

import SwiftUI

/// One-time guidance shown below the first search results list.
struct SearchResultsHintView: View {
    @Environment(\.appThemeColors) private var themeColors

    var body: some View {
        Text(FirstRunCopy.searchResultsHint)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .appSecondaryText()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.tight)
            .background(themeColors.background)
            .accessibilityIdentifier(AccessibilityID.Search.resultsHint)
    }
}

extension View {
    /// Pins first-run search guidance above the TVMaze attribution strip.
    func searchResultsHintInset(isVisible: Bool) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            if isVisible {
                SearchResultsHintView()
            }
        }
    }
}

#if DEBUG
#Preview {
    SearchResultsHintView()
        .appScreenBackground()
        .appThemePreview()
}
#endif
