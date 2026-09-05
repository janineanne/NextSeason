//
//  WatchlistLoadedPresentation.swift
//  NextSeason
//

import Foundation

/// Loaded-watchlist chrome: banner, empty/no-results overlay, spacer, attribution.
///
/// Derived from watchlist rows plus view-owned notification state so
/// `WatchlistView` can render named cases instead of combining those flags.
nonisolated struct WatchlistLoadedPresentation: Equatable, Sendable {
    enum Overlay: Equatable {
        case none
        case emptyWatchlist
        case noSearchResults
    }

    let showsNotificationBanner: Bool
    /// 1pt list row so the large title still has scroll backing when no
    /// banner or show rows are present.
    let showsTitlePreservingSpacer: Bool
    let showsAttribution: Bool
    let overlay: Overlay

    init(
        hasShows: Bool,
        hasVisibleRows: Bool,
        hasPendingRemoval: Bool,
        showsNotificationBanner: Bool
    ) {
        self.showsNotificationBanner = showsNotificationBanner
        showsTitlePreservingSpacer = !hasVisibleRows && !showsNotificationBanner
        showsAttribution = hasVisibleRows

        if !hasShows && !hasPendingRemoval {
            overlay = .emptyWatchlist
        } else if !hasVisibleRows {
            overlay = .noSearchResults
        } else {
            overlay = .none
        }
    }
}

@MainActor
extension WatchlistLoadedPresentation {
    init(viewModel: WatchlistViewModel, showsNotificationBanner: Bool) {
        self.init(
            hasShows: !viewModel.shows.isEmpty,
            hasVisibleRows: !viewModel.filteredShows.isEmpty,
            hasPendingRemoval: viewModel.pendingRemoval != nil,
            showsNotificationBanner: showsNotificationBanner
        )
    }
}
