//
//  WatchlistPendingRemoval+Environment.swift
//  NextSeason
//

import SwiftUI

private struct WatchlistPendingRemovalKey: EnvironmentKey {
    @MainActor static let defaultValue: WatchlistPendingRemoval? = nil
}

extension EnvironmentValues {
    /// Shared undoable watchlist-removal coordinator; nil when not composed.
    @MainActor var watchlistPendingRemoval: WatchlistPendingRemoval? {
        get { self[WatchlistPendingRemovalKey.self] }
        set { self[WatchlistPendingRemovalKey.self] = newValue }
    }
}
