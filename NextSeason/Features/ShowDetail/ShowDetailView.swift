//
//  ShowDetailView.swift
//  NextSeason
//

import SwiftUI

/// Show detail: artwork, metadata, the derived next-season status, and a
/// formatted summary.
struct ShowDetailView: View {
    @Environment(\.watchlistRepository) private var repository
    @State private var viewModel: ShowDetailViewModel?

    private let show: Show
    private let service: any TVMazeService
    private let previewRepository: (any WatchlistRepository)?

    init(
        show: Show,
        service: any TVMazeService = TVMazeClient(),
        repository: (any WatchlistRepository)? = nil
    ) {
        self.show = show
        self.service = service
        self.previewRepository = repository
    }

    var body: some View {
        Group {
            if let viewModel {
                detailContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .task(id: show.id) {
            if viewModel?.initialShow.id != show.id {
                let vm = ShowDetailViewModel(
                    show: show,
                    service: service,
                    repository: previewRepository ?? repository
                )
                viewModel = vm
                await vm.load()
            }
        }
    }

    private func detailContent(viewModel: ShowDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(viewModel: viewModel)
                nextSeasonSection(viewModel: viewModel)
                aboutSection(viewModel: viewModel)
                attribution
            }
            .padding()
        }
        .navigationTitle(viewModel.displayShow.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { watchlistToolbarItem(viewModel: viewModel) }
        .alert("Stay in the Loop", isPresented: notificationPromptBinding(viewModel: viewModel)) {
            Button("Not Now", role: .cancel) {
                viewModel.dismissNotificationPrompt()
            }
            Button("Enable Notifications") {
                Task { await viewModel.confirmNotificationPrompt() }
            }
        } message: {
            Text("NextSeason can notify you when a tracked show gets a release date or season update.")
        }
    }

    private func notificationPromptBinding(viewModel: ShowDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.shouldPromptForNotifications },
            set: { isPresented in
                if !isPresented { viewModel.dismissNotificationPrompt() }
            }
        )
    }

    @ToolbarContentBuilder
    private func watchlistToolbarItem(viewModel: ShowDetailViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await viewModel.toggleWatchlist() }
            } label: {
                if viewModel.isUpdatingWatchlist {
                    ProgressView()
                } else {
                    Label(
                        viewModel.isTracked ? "Tracking" : "Track",
                        systemImage: viewModel.isTracked ? "star.fill" : "star"
                    )
                }
            }
            .disabled(viewModel.loadState != .loaded || viewModel.isUpdatingWatchlist)
            .accessibilityHint("Adds or removes this show from your watchlist")
        }
    }

    private func header(viewModel: ShowDetailViewModel) -> some View {
        HStack(alignment: .top, spacing: 16) {
            poster(viewModel: viewModel)
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayShow.name)
                    .font(.title2.bold())
                Label(viewModel.displayShow.status.displayLabel, systemImage: "tv")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let network = viewModel.displayShow.network {
                    Text(network)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !viewModel.displayShow.genres.isEmpty {
                    Text(viewModel.displayShow.genres.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func poster(viewModel: ShowDetailViewModel) -> some View {
        AsyncImage(url: viewModel.displayShow.posterMediumURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty, .failure:
                Rectangle()
                    .fill(.quaternary)
                    .overlay { Image(systemName: "tv").foregroundStyle(.secondary) }
            @unknown default:
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: 100, height: 150)
        .clipShape(.rect(cornerRadius: 10))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func nextSeasonSection(viewModel: ShowDetailViewModel) -> some View {
        GroupBox("Next Season") {
            switch viewModel.loadState {
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Checking next season…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .loaded:
                if let status = viewModel.nextSeasonStatus {
                    Text(status.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func aboutSection(viewModel: ShowDetailViewModel) -> some View {
        let html = viewModel.displayShow.summaryHTML
        let hasSummary = SummaryFormatter.hasDisplayableContent(html)
        if hasSummary || viewModel.displayShow.tvMazeURL != nil {
            VStack(alignment: .leading, spacing: 8) {
                if let html, hasSummary {
                    Text("About")
                        .font(.headline)
                    Text(SummaryFormatter.attributedString(from: html))
                        .font(.body)
                }
                if let url = viewModel.displayShow.tvMazeURL {
                    Link(destination: url) {
                        Label("View on TVMaze", systemImage: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attribution: some View {
        Text("Data provided by TVMaze")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)
    }
}

#if DEBUG
#Preview("With summary") {
    NavigationStack {
        ShowDetailView(
            show: .preview,
            service: PreviewTVMazeService(stub: .preview),
            repository: InMemoryWatchlistRepository()
        )
    }
}

#Preview("Missing summary") {
    NavigationStack {
        ShowDetailView(
            show: .previewMissingSummary,
            service: PreviewTVMazeService(stub: .previewMissingSummary),
            repository: InMemoryWatchlistRepository()
        )
    }
}
#endif
