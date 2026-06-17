//
//  SearchView.swift
//  NextSeason
//

import SwiftUI

/// Guest search: type a title, see matching shows and their status.
struct SearchView: View {
    @Binding var navigationPath: NavigationPath
    private let tvMaze: any TVMazeService
    @State private var viewModel: SearchViewModel

    init(navigationPath: Binding<NavigationPath>, tvMaze: any TVMazeService = TVMazeClient()) {
        _navigationPath = navigationPath
        self.tvMaze = tvMaze
        _viewModel = State(initialValue: SearchViewModel(service: tvMaze))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("NextSeason")
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(show: show, service: tvMaze)
                }
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
                .task(id: viewModel.query) {
                    await viewModel.search()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Find Your Next Season",
                systemImage: "magnifyingglass",
                description: Text("Search for a TV show to see its status and upcoming season.")
            )
            .uiTestMarker(AccessibilityID.Search.idlePrompt, label: "Find Your Next Season")
        case .loading:
            ProgressView("Searching…")
                .controlSize(.large)
        case .results(let shows):
            List(shows) { show in
                NavigationLink(value: show) {
                    ShowRow(show: show)
                }
            }
            .listStyle(.plain)
            .tvmazeAttributionInset()
        case .empty:
            ContentUnavailableView.search(text: viewModel.query)
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.search() }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    SearchView(navigationPath: $path)
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
}
