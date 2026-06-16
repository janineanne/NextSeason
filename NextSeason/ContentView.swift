//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// The app's root view: Search and Watchlist tabs (Slice 2).
struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
}
