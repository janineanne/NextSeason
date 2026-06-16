//
//  SearchView.swift
//  NextSeason
//

import SwiftUI

/// Guest search: type a title, see matching shows and their status.
struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("NextSeason")
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
        case .loading:
            ProgressView("Searching…")
                .controlSize(.large)
        case .results(let shows):
            List(shows) { show in
                ShowRow(show: show)
            }
            .listStyle(.plain)
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
    SearchView()
}
