//
//  SearchLoadMoreFooterView.swift
//  NextSeason
//

import SwiftUI

/// Pagination control at the bottom of TheTVDB search results.
///
/// Replaces the old TVMaze "top 10 only" footer: TheTVDB search is offset-
/// paginated (`limit=10`), so guests can keep loading matches instead of being
/// steered to an external site.
struct SearchLoadMoreFooterView: View {
    /// True while the next TheTVDB page is in flight; disables the button.
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.tight) {
                if isLoading {
                    ProgressView()
                }
                Text(isLoading ? "Loading…" : "Load More Results")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isLoading)
        .padding(.vertical, AppSpacing.row)
        .accessibilityIdentifier(AccessibilityID.Search.loadMoreButton)
    }
}

#if DEBUG
    #Preview {
        VStack {
            SearchLoadMoreFooterView(isLoading: false) {}
            SearchLoadMoreFooterView(isLoading: true) {}
        }
        .padding()
        .appScreenBackground()
    }
#endif
