//
//  WatchlistRefreshService+Environment.swift
//  NextSeason
//

import SwiftUI

private struct WatchlistRefreshServiceKey: EnvironmentKey {
    @MainActor static let defaultValue: WatchlistRefreshService? = nil
}

extension EnvironmentValues {
    /// Background / pull-to-refresh pipeline for tracked shows; optional in previews.
    @MainActor var watchlistRefreshService: WatchlistRefreshService? {
        get { self[WatchlistRefreshServiceKey.self] }
        set { self[WatchlistRefreshServiceKey.self] = newValue }
    }
}
