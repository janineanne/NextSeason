//
//  WatchlistView.swift
//  NextSeason
//

import SwiftUI

struct WatchlistView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistRefreshService) private var refreshService
    @Environment(\.notificationService) private var notificationService
    @Environment(\.watchlistUndoRemoval) private var undoRemoval
    @Environment(\.analytics) private var analytics
    @Environment(\.appThemeColors) private var themeColors
    @Environment(\.openAppAbout) private var openAppAbout

    @Binding var navigationPath: NavigationPath
    private let tvMaze: any TVMazeService
    /// Called when the user taps "Find a Show" from the empty state, so the host
    /// can switch to the Search tab.
    private let onFindShow: () -> Void
    /// Called after a watchlist removal is persisted (not on undo).
    private let onWatchlistChanged: () -> Void
    /// Bumped when the user selects the Watchlist tab so the list reloads.
    private let watchlistReloadToken: Int
    @State private var viewModel: WatchlistViewModel?
    @State private var notificationsDenied = false

    init(
        navigationPath: Binding<NavigationPath>,
        tvMaze: any TVMazeService,
        watchlistReloadToken: Int = 0,
        onFindShow: @escaping () -> Void = {},
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
        self.tvMaze = tvMaze
        self.watchlistReloadToken = watchlistReloadToken
        self.onFindShow = onFindShow
        self.onWatchlistChanged = onWatchlistChanged
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView("Loading watchlist…")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appScreenBackground()
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { aboutToolbarButton }
            .betaThemeSwitcherToolbar()
            .navigationDestination(for: TrackedShow.self) { tracked in
                ShowDetailView(
                    show: Show(tracked: tracked),
                    service: tvMaze,
                    repository: repository,
                    notifications: notificationService,
                    analytics: analytics,
                    isTracked: true,
                    onWatchlistChanged: onWatchlistChanged
                )
                .onAppear {
                    analytics.track(.watchlistItemOpened(showID: tracked.id))
                }
            }
            .task(id: watchlistReloadToken) {
                guard let undoRemoval else { return }
                if viewModel == nil {
                    viewModel = WatchlistViewModel(
                        repository: repository,
                        refreshService: refreshService,
                        undoRemoval: undoRemoval,
                        analytics: analytics
                    )
                }
                await viewModel?.reload()
                notificationsDenied = await notificationService.isDenied()
            }
            .onAppear {
                analytics.track(.watchlistViewed)
                Task { await viewModel?.reload() }
            }
            .onDisappear {
                AppDiagnosticsLogger.breadcrumb("watchlist_disappear")
                Task { [viewModel] in
                    AppDiagnosticsLogger.logTaskStart("watchlist_commit_on_disappear")
                    await viewModel?.commitPendingRemovalIfNeeded()
                    AppDiagnosticsLogger.logTaskComplete("watchlist_commit_on_disappear")
                }
            }
            .refreshable {
                await viewModel?.refreshFromNetwork()
                notificationsDenied = await notificationService.isDenied()
            }
            .onChange(of: undoRemoval?.pendingRemoval?.id) { oldId, newId in
                guard let oldId, newId == nil else { return }
                Task { @MainActor in
                    guard try await repository.contains(showID: oldId) == false else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel?.removeShow(showID: oldId)
                    }
                }
            }
        }
        .appNavigationChrome()
    }

    @ToolbarContentBuilder
    private var aboutToolbarButton: some ToolbarContent {
        if let openAppAbout {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openAppAbout()
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About NextSeason")
                .accessibilityHint("Shows version and beta diagnostics")
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: WatchlistViewModel) -> some View {
        @Bindable var viewModel = viewModel

        switch viewModel.state {
        case .loading:
            ProgressView("Loading watchlist…")
                .controlSize(.large)
        case .loaded:
            // The List is kept mounted even when empty (empty state is an overlay)
            // so removing the last row doesn't tear the List down mid-animation,
            // which crashes UICollectionView with "invalid number of items".
            List {
                if notificationsDenied {
                    NotificationsDisabledBanner {
                        notificationService.openNotificationSettings()
                    }
                }
                // Keeps the list scroll-backed so the large navigation title renders
                // when the watchlist is empty (zero tracked shows, no banner).
                if viewModel.shows.isEmpty, !notificationsDenied {
                    Color.clear
                        .frame(height: 1)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .accessibilityHidden(true)
                }
                ForEach(viewModel.shows) { tracked in
                    HStack(spacing: AppSpacing.tight) {
                        NavigationLink(value: tracked) {
                            ShowRowLabel(tracked: tracked)
                        }
                        .buttonStyle(.plain)
                        .showDetailLinkAccessibility()
                        .accessibilityIdentifier("\(AccessibilityID.Watchlist.row).\(tracked.id)")

                        ShowRowTrackButton(
                            showID: tracked.id,
                            showName: tracked.name,
                            isTracked: !viewModel.isPendingRemoval(tracked),
                            isUpdating: false,
                            trackButtonIdentifier: AccessibilityID.Watchlist.trackButton
                        ) { anchor in
                            if viewModel.isPendingRemoval(tracked) {
                                viewModel.undoPendingRemoval()
                            } else {
                                viewModel.requestRemoval(
                                    tracked,
                                    anchor: anchor,
                                    source: .watchlist,
                                    onCommitted: {}
                                )
                            }
                        }
                    }
                    .appListRowSurface()
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.shows.map(\.id))
            .appPlainListStyle()
            .tvmazeAttributionInset()
            .overlay {
                if viewModel.shows.isEmpty, viewModel.pendingRemoval == nil {
                    emptyState
                }
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
                    .appPrimaryText()
            } description: {
                Text(message)
                    .appSecondaryText()
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tracked Shows", systemImage: "star")
                .appPrimaryText()
        } description: {
            Text(FirstRunCopy.watchlistEmptyDescription)
                .appSecondaryText()
        } actions: {
            Button("Find a Show") {
                onFindShow()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeColors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Watchlist.emptyState)
        .onAppear {
            analytics.track(.emptyWatchlistShown)
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var path = NavigationPath()
    let repository = InMemoryWatchlistRepository()
    WatchlistView(navigationPath: $path, tvMaze: TVMazeClient())
        .environment(\.watchlistRepository, repository)
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(
            repository: repository,
            analytics: RecordingAnalyticsService()
        ))
}
#endif
