//
//  SearchResultsLimitFooterView.swift
//  NextSeason
//

import SwiftUI

/// Guidance at the bottom of search results when TVMaze's API cap may hide a match.
struct SearchResultsLimitFooterView: View {
    let query: String

    var body: some View {
        VStack(spacing: AppSpacing.tight) {
            Text(FirstRunCopy.searchResultsLimitMessage)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .appSecondaryText()
            Link(destination: tvMazeSearchURL) {
                Label("Search on TVMaze.com", systemImage: "arrow.up.right.square")
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.row)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityID.Search.resultsLimitFooter)
    }

    private var tvMazeSearchURL: URL {
        var components = URLComponents(string: "https://www.tvmaze.com/search")!
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        }
        return components.url ?? URL(string: "https://www.tvmaze.com")!
    }
}

#if DEBUG
#Preview {
    SearchResultsLimitFooterView(query: "Star Trek")
        .padding()
        .appScreenBackground()
        .appThemePreview()
}
#endif
