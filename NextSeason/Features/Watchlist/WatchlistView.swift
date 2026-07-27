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

    @Binding var navigationPath: NavigationPath
    private let tvMaze: any TVMazeService
    /// Called when the user taps "Find a Show" from the empty state, so the host
    /// can switch to the Search tab.
    private let onFindShow: () -> Void
    /// Called after a watchlist removal is persisted (not on undo).
    private let onWatchlistChanged: () -> Void
    /// Bumped when the user selects the Watchlist tab so the list reloads.
    private let watchlistReloadToken: Int
    /// Identifies a pending notification deep link so this view can push its detail
    /// once its `NavigationStack` is on screen. Changes when a new deep link arrives.
    private let pendingDetailToken: Int?
    /// Applies the pending notification deep link (see `pendingDetailToken`). The
    /// coordinator decides whether the push animates based on the tap context.
    private let onApplyPendingDetail: () -> Void
    @State private var viewModel: WatchlistViewModel?
    @State private var notificationStatus = NotificationStatusModel()
    /// True after `.task(id:)` finishes its first (or token-driven) reload, so
    /// `.onAppear` only refreshes on later tab returns — not during first load.
    @State private var hasCompletedInitialLoad = false
    /// Sections the user has collapsed. Missing IDs are treated as expanded.
    @State private var collapsedSections: Set<WatchlistSection> = []

    init(
        navigationPath: Binding<NavigationPath>,
        tvMaze: any TVMazeService,
        watchlistReloadToken: Int = 0,
        pendingDetailToken: Int? = nil,
        onApplyPendingDetail: @escaping () -> Void = {},
        onFindShow: @escaping () -> Void = {},
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
        self.tvMaze = tvMaze
        self.watchlistReloadToken = watchlistReloadToken
        self.pendingDetailToken = pendingDetailToken
        self.onApplyPendingDetail = onApplyPendingDetail
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
            .appAboutToolbarButton()
            // Theme switcher parked; see ThemeSwitcherView.swift status comment.
            // .betaThemeSwitcherToolbar()
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
                await prepareAndReload()
            }
            .onAppear {
                analytics.track(.watchlistViewed)
                // Apply a deep link that arrived while this tab was off screen; the
                // stack is now mounted so the push lands instead of being dropped.
                onApplyPendingDetail()
                // First presentation is owned by `.task(id:)`. Refresh here only
                // after that initial load has finished (tab return / reappear).
                guard hasCompletedInitialLoad else { return }
                Task { await reloadScreen() }
            }
            .onChange(of: pendingDetailToken) { _, token in
                // A deep link arrived while the watchlist is already on screen.
                guard token != nil else { return }
                onApplyPendingDetail()
            }
            .refreshNotificationStatus(notificationStatus)
            .onChange(of: undoRemoval?.pendingRemoval?.id) { oldId, newId in
                Task { await viewModel?.handlePendingRemovalIDChange(from: oldId, to: newId) }
            }
        }
    }

    /// Creates the view model on first need, then reloads list + notification status.
    private func prepareAndReload() async {
        guard let undoRemoval else { return }
        if viewModel == nil {
            viewModel = WatchlistViewModel(
                repository: repository,
                refreshService: refreshService,
                undoRemoval: undoRemoval,
                analytics: analytics
            )
        }
        await reloadScreen()
        hasCompletedInitialLoad = true
    }

    private func reloadScreen() async {
        await viewModel?.reload()
        await notificationStatus.refresh(using: notificationService)
    }

    private func enableNotificationsFromBanner() async {
        await notificationService.enableNotificationsFromSettingsEntryPoint()
        await notificationStatus.refresh(using: notificationService)
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
                if notificationStatus.showsDisabledBanner {
                    NotificationsDisabledBanner(
                        buttonTitle: notificationStatus.enablementButtonTitle
                    ) {
                        Task { await enableNotificationsFromBanner() }
                    }
                }
                // Keeps the list scroll-backed so the large navigation title renders
                // when there are no rows to show (empty watchlist or no search
                // matches, and no banner).
                if viewModel.filteredShows.isEmpty, !notificationStatus.showsDisabledBanner {
                    Color.clear
                        .frame(height: 1)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .accessibilityHidden(true)
                }
                ForEach(viewModel.filteredSectionGroups) { group in
                    WatchlistCollapsibleSection(
                        title: group.section.title,
                        shows: group.shows,
                        isExpanded: expansionBinding(for: group.section)
                    ) { tracked in
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
                                        source: .watchlist
                                    )
                                }
                            }
                        }
                    }
                }
                Section {
                } footer: {
                    TVMazeAttributionView()
                }
            }
            .animation(
                .easeInOut(duration: 0.35),
                value: viewModel.filteredShows.map { "\($0.id):\($0.nextSeason.headline)" }
            )
            .appPlainListStyle()
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Watchlist"
            )
            .refreshable {
                await viewModel.refreshFromNetwork()
                await notificationStatus.refresh(using: notificationService)
            }
            .overlay {
                if viewModel.shows.isEmpty, viewModel.pendingRemoval == nil {
                    emptyState
                } else if viewModel.filteredShows.isEmpty {
                    noSearchResults(query: viewModel.searchText)
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
                    Task { await viewModel.reload() }
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Watchlist.emptyState)
        .onAppear {
            analytics.track(.emptyWatchlistShown)
        }
    }

    private func noSearchResults(query: String) -> some View {
        ContentUnavailableView {
            Label("No Matches", systemImage: "magnifyingglass")
                .appPrimaryText()
        } description: {
            Text("No tracked shows match “\(query.trimmingCharacters(in: .whitespacesAndNewlines))”.")
                .appSecondaryText()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(AccessibilityID.Watchlist.noResults)
    }

    private func expansionBinding(for section: WatchlistSection) -> Binding<Bool> {
        Binding(
            get: { !collapsedSections.contains(section) },
            set: { isExpanded in
                if isExpanded {
                    collapsedSections.remove(section)
                } else {
                    collapsedSections.insert(section)
                }
            }
        )
    }
}

/// A status section the user can collapse.
private struct WatchlistCollapsibleSection<Row: View>: View {
    let title: String
    let shows: [TrackedShow]
    @Binding var isExpanded: Bool
    @ViewBuilder let row: (TrackedShow) -> Row

    var body: some View {
        Section(isExpanded: $isExpanded) {
            ForEach(shows) { tracked in
                row(tracked)
            }
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.tight) {
                    Text(title)
                        .font(.headline)
                        .appPrimaryText()
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Collapse section" : "Expand section")
            .accessibilityAddTraits(.isHeader)
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
