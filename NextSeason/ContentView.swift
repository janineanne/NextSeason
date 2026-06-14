//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// The app's root view. For Slice 1 it shows guest search; in Slice 2 this is the
/// natural place to introduce a `TabView` (Search + Watchlist).
struct ContentView: View {
    var body: some View {
        SearchView()
    }
}

#Preview {
    ContentView()
}
