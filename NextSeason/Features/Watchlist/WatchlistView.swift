//
//  WatchlistView.swift
//  NextSeason
//

import SwiftUI

struct WatchlistView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistRefreshService) private var refreshService
    @State private var viewModel: WatchlistViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView("Loading watchlist…")
                }
            }
            .navigationTitle("Watchlist")
            .navigationDestination(for: TrackedShow.self) { tracked in
                ShowDetailView(show: Show(tracked: tracked))
            }
            .task {
                if viewModel == nil {
                    viewModel = WatchlistViewModel(
                        repository: repository,
                        refreshService: refreshService
                    )
                }
                await viewModel?.load()
            }
            .refreshable {
                await viewModel?.refreshFromNetwork()
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: WatchlistViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading watchlist…")
                .controlSize(.large)
        case .loaded(let shows) where shows.isEmpty:
            ContentUnavailableView(
                "No Tracked Shows",
                systemImage: "star",
                description: Text("Search for a show and tap Track to monitor its next season.")
            )
        case .loaded(let shows):
            List {
                ForEach(shows) { tracked in
                    NavigationLink(value: tracked) {
                        WatchlistRow(tracked: tracked)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let showID = shows[index].id
                        Task { await viewModel.remove(showID: showID) }
                    }
                }
            }
            .listStyle(.plain)
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    WatchlistView()
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
}
#endif
