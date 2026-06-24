//
//  WatchlistUndoRemoval+Environment.swift
//  NextSeason
//

import SwiftUI

private struct WatchlistUndoRemovalKey: EnvironmentKey {
    @MainActor static let defaultValue: WatchlistUndoRemoval? = nil
}

extension EnvironmentValues {
    @MainActor var watchlistUndoRemoval: WatchlistUndoRemoval? {
        get { self[WatchlistUndoRemovalKey.self] }
        set { self[WatchlistUndoRemovalKey.self] = newValue }
    }
}
