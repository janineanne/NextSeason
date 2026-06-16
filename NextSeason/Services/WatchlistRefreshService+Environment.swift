//
//  WatchlistRefreshService+Environment.swift
//  NextSeason
//

import SwiftUI

private struct WatchlistRefreshServiceKey: EnvironmentKey {
    @MainActor static let defaultValue: WatchlistRefreshService? = nil
}

extension EnvironmentValues {
    @MainActor var watchlistRefreshService: WatchlistRefreshService? {
        get { self[WatchlistRefreshServiceKey.self] }
        set { self[WatchlistRefreshServiceKey.self] = newValue }
    }
}
