//
//  ShowDetailView.swift
//  NextSeason
//

import SwiftUI

/// Show detail: artwork, metadata, the derived next-season status, and a
/// formatted summary.
struct ShowDetailView: View {
    @Environment(\.watchlistUndoRemoval) private var undoRemoval
    @Environment(\.appThemeColors) private var themeColors

    @State private var viewModel: ShowDetailViewModel
    @State private var showActorNameAlert = false

    private let analytics: any AnalyticsTracking
    private let onWatchlistChanged: () -> Void

    init(
        show: Show,
        service: any TVMazeService = TVMazeClient(),
        repository: any WatchlistRepository,
        notifications: NotificationService,
        analytics: any AnalyticsTracking = AnalyticsService(),
        isTracked: Bool = false,
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            initialValue: ShowDetailViewModel(
                show: show,
                service: service,
                repository: repository,
                notifications: notifications,
                analytics: analytics,
                initialIsTracked: isTracked
            )
        )
        self.analytics = analytics
        self.onWatchlistChanged = onWatchlistChanged
    }

    var body: some View {
        detailContent(viewModel: viewModel)
            .task(id: viewModel.initialShow.id) {
                await viewModel.load()
            }
            .onAppear {
                analytics.track(.showDetailViewed(showID: viewModel.initialShow.id))
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
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                header(viewModel: viewModel)
                nextSeasonSection(viewModel: viewModel)
                aboutSection(viewModel: viewModel)
            }
            .padding(AppSpacing.screen)
        }
        .appScreenBackground()
        .scrollContentBackground(.hidden)
        .tvmazeAttributionInset()
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationChrome()
        .alert("Stay in the Loop", isPresented: notificationPromptBinding(viewModel: viewModel)) {
            Button("Not Now", role: .cancel) {
                viewModel.dismissNotificationPrompt()
            }
            Button("Enable Notifications") {
                Task { await viewModel.confirmNotificationPrompt() }
            }
        } message: {
            Text(FirstRunCopy.notificationPromptMessage)
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
            Text(FirstRunCopy.notificationsDeniedMessage)
        }
        .alert("Coming Soon", isPresented: $showActorNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(FirstRunCopy.actorDetailsPlannedMessage)
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
        HStack(alignment: .top, spacing: AppSpacing.screen) {
            poster(viewModel: viewModel)
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                Text(viewModel.displayShow.name)
                    .font(.title2.bold())
                    .appPrimaryText()
                Text(viewModel.displayShow.status.displayLabel)
                    .font(.subheadline)
                    .appSecondaryText()
                if let network = viewModel.displayShow.network {
                    Text(network)
                        .font(.subheadline)
                        .appSecondaryText()
                }
                if !viewModel.displayShow.genres.isEmpty {
                    Text(viewModel.displayShow.genres.genreDisplayLine)
                        .font(.caption)
                        .appSecondaryText()
                }
            }
            Spacer(minLength: AppSpacing.tight)
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
                source: .detail,
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
                    .overlay { Image(systemName: "tv") }
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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("Next Season")
                .font(.headline)
                .appPrimaryText()

            switch viewModel.loadState {
            case .loading:
                HStack(spacing: AppSpacing.tight) {
                    ProgressView()
                    Text("Checking next season…")
                        .appSecondaryText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .loaded:
                if let status = viewModel.nextSeasonStatus {
                    HStack(alignment: .top, spacing: AppSpacing.tight) {
                        Image(systemName: status.statusSymbolName)
                            .font(.subheadline)
                            .foregroundStyle(status.emphasisColor(in: themeColors))
                            .accessibilityHidden(true)
                        Text(status.headline)
                            .font(.body)
                            .appPrimaryText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: AppSpacing.tight) {
                    Label {
                        Text(message)
                            .appSecondaryText()
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(themeColors.warning)
                    }
                    Button("Try Again") {
                        Task { await viewModel.load() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.row)
        .appSurfaceCard()
    }

    @ViewBuilder
    private func aboutSection(viewModel: ShowDetailViewModel) -> some View {
        let html = viewModel.displayShow.summaryHTML
        let hasSummary = SummaryFormatter.hasDisplayableContent(html)
        if hasSummary || viewModel.displayShow.tvMazeURL != nil {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                if let html, hasSummary {
                    Text("About")
                        .font(.headline)
                        .appPrimaryText()
                    Text(SummaryFormatter.attributedStringWithTappableActorNames(from: html))
                        .font(.body)
                        .appSecondaryText()
                        .tint(themeColors.mutedText)
                        .environment(\.openURL, OpenURLAction { url in
                            if url.scheme == SummaryFormatter.actorNameTapScheme {
                                analytics.track(.actorNameTapped(showID: viewModel.displayShow.id))
                                showActorNameAlert = true
                                return .handled
                            }
                            return .systemAction
                        })
                }
                if let url = viewModel.displayShow.tvMazeURL {
                    Link(destination: url) {
                        Label("View on TVMaze", systemImage: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                    .padding(.top, AppSpacing.tight / 2)
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
