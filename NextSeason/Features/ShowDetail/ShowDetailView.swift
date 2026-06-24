//
//  ShowDetailView.swift
//  NextSeason
//

import SwiftUI

/// Show detail: artwork, metadata, the derived next-season status, and a
/// formatted summary.
struct ShowDetailView: View {
    @Environment(\.watchlistUndoRemoval) private var undoRemoval

    @State private var viewModel: ShowDetailViewModel

    private let onWatchlistChanged: () -> Void

    init(
        show: Show,
        service: any TVMazeService = TVMazeClient(),
        repository: any WatchlistRepository,
        notifications: NotificationService,
        isTracked: Bool = false,
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: ShowDetailViewModel(
                show: show,
                service: service,
                repository: repository,
                notifications: notifications,
                initialIsTracked: isTracked
            )
        )
        self.onWatchlistChanged = onWatchlistChanged
    }

    var body: some View {
        detailContent(viewModel: viewModel)
            .task(id: viewModel.initialShow.id) {
                await viewModel.load()
            }
            .onAppear {
                // Reconcile tracked state on reappear (e.g. returning to this screen
                // after the show was removed on the Watchlist tab).
                Task { await viewModel.refreshTrackedState() }
            }
            .onChange(of: undoRemoval?.pendingRemoval?.id) { oldValue, newValue in
                guard oldValue == viewModel.initialShow.id, newValue == nil else { return }
                Task { await viewModel.refreshTrackedState() }
            }
    }

    private func detailContent(viewModel: ShowDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(viewModel: viewModel)
                nextSeasonSection(viewModel: viewModel)
                aboutSection(viewModel: viewModel)
            }
            .padding()
        }
        .tvmazeAttributionInset()
        .navigationTitle(viewModel.displayShow.name)
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Notifications Are Off", isPresented: notificationsDeniedBinding(viewModel: viewModel)) {
            Button("Not Now", role: .cancel) {
                viewModel.dismissNotificationsDeniedAlert()
            }
            Button("Open Settings") {
                viewModel.openNotificationSettings()
                viewModel.dismissNotificationsDeniedAlert()
            }
        } message: {
            Text("Enable notifications in Settings to get alerts when this show's next season status changes.")
        }
    }

    private func notificationsDeniedBinding(viewModel: ShowDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.shouldShowNotificationsDeniedAlert },
            set: { isPresented in
                if !isPresented { viewModel.dismissNotificationsDeniedAlert() }
            }
        )
    }

    private func notificationPromptBinding(viewModel: ShowDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.shouldPromptForNotifications },
            set: { isPresented in
                if !isPresented { viewModel.dismissNotificationPrompt() }
            }
        )
    }

    private func header(viewModel: ShowDetailViewModel) -> some View {
        HStack(alignment: .top, spacing: 16) {
            poster(viewModel: viewModel)
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.displayShow.name)
                    .font(.title2.bold())
                Text(viewModel.displayShow.status.displayLabel)
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
            Spacer(minLength: 8)
            ShowRowTrackButton(
                showID: viewModel.displayShow.id,
                showName: viewModel.displayShow.name,
                isTracked: viewModel.isTracked,
                isUpdating: viewModel.isUpdatingWatchlist,
                trackButtonIdentifier: AccessibilityID.ShowDetail.trackButton
            ) { anchor in
                Task { await handleTrackButtonTap(viewModel: viewModel, anchor: anchor) }
            }
        }
    }

    private func handleTrackButtonTap(viewModel: ShowDetailViewModel, anchor: CGRect) async {
        if undoRemoval?.pendingRemoval?.id == viewModel.initialShow.id {
            undoRemoval?.undoRemoval()
            await viewModel.refreshTrackedState()
            return
        }

        if viewModel.isTracked {
            guard let undoRemoval, let tracked = await viewModel.trackedShow() else { return }
            undoRemoval.requestRemoval(
                tracked,
                anchor: anchor,
                onCommitted: onWatchlistChanged
            )
            viewModel.applyTrackedState(false)
        } else {
            await viewModel.addToWatchlist()
            onWatchlistChanged()
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
}

#if DEBUG
#Preview("With summary") {
    NavigationStack {
        ShowDetailView(
            show: .preview,
            service: PreviewTVMazeService(stub: .preview),
            repository: InMemoryWatchlistRepository(),
            notifications: NotificationService()
        )
    }
}

#Preview("Missing summary") {
    NavigationStack {
        ShowDetailView(
            show: .previewMissingSummary,
            service: PreviewTVMazeService(stub: .previewMissingSummary),
            repository: InMemoryWatchlistRepository(),
            notifications: NotificationService()
        )
    }
}
#endif
