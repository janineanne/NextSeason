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
    #if DEBUG
    @State private var isSchedulingTestNotification = false
    #endif

    init(
        navigationPath: Binding<NavigationPath>,
        tvMaze: any TVMazeService = TVMazeClient(),
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
            .navigationTitle("Watchlist")
            .navigationDestination(for: TrackedShow.self) { tracked in
                ShowDetailView(
                    show: Show(tracked: tracked),
                    service: tvMaze,
                    repository: repository,
                    notifications: notificationService,
                    isTracked: true,
                    onWatchlistChanged: onWatchlistChanged
                )
            }
            .task(id: watchlistReloadToken) {
                guard let undoRemoval else { return }
                if viewModel == nil {
                    viewModel = WatchlistViewModel(
                        repository: repository,
                        refreshService: refreshService,
                        undoRemoval: undoRemoval
                    )
                }
                await viewModel?.reload()
                notificationsDenied = await notificationService.isDenied()
            }
            .onAppear {
                Task { await viewModel?.reload() }
            }
            .onDisappear {
                Task { await viewModel?.commitPendingRemovalIfNeeded(onCommitted: onWatchlistChanged) }
            }
            .refreshable {
                await viewModel?.refreshFromNetwork()
                notificationsDenied = await notificationService.isDenied()
            }
            .onChange(of: undoRemoval?.pendingRemoval?.id) { _, _ in
                Task { await viewModel?.reload() }
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: WatchlistViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading watchlist…")
                .controlSize(.large)
        case .loaded(let shows):
            // The List is kept mounted even when empty (empty state is an overlay)
            // so removing the last row doesn't tear the List down mid-animation,
            // which crashes UICollectionView with "invalid number of items".
            List {
                if notificationsDenied {
                    NotificationsDisabledBanner {
                        notificationService.openNotificationSettings()
                    }
                }
                ForEach(shows) { tracked in
                    HStack(spacing: 8) {
                        NavigationLink(value: tracked) {
                            ShowRowLabel(tracked: tracked)
                        }
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
                                    onCommitted: onWatchlistChanged
                                )
                            }
                        }
                    }
                }
                #if DEBUG
                debugSection(for: shows)
                #endif
            }
            .listStyle(.plain)
            .tvmazeAttributionInset()
            .overlay {
                if shows.isEmpty, viewModel.pendingRemoval == nil {
                    emptyState
                }
            }
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

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tracked Shows", systemImage: "star")
        } description: {
            Text("Search for a show and tap Track to monitor its next season.")
        } actions: {
            Button("Find a Show") {
                onFindShow()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Watchlist.emptyState)
    }

    #if DEBUG
    @ViewBuilder
    private func debugSection(for shows: [TrackedShow]) -> some View {
        // Keep a constant row count regardless of `shows` so removing the last
        // tracked show doesn't change this section's structure during the
        // ForEach deletion animation (which crashes UICollectionView).
        Section {
            Button("Send Test Notification") {
                if let show = shows.first {
                    Task { await sendTestNotification(for: show) }
                }
            }
            .disabled(shows.isEmpty || isSchedulingTestNotification)
            Text(testNotificationInstructions(for: shows))
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Debug")
        }
    }

    private static let testNotificationDelaySeconds = 5

    private func testNotificationInstructions(for shows: [TrackedShow]) -> String {
        guard let show = shows.first else {
            return "Track a show to send a test notification."
        }
        if isSchedulingTestNotification {
            return "Scheduling…"
        }
        return "Uses “\(show.name)”. Arrives in \(Self.testNotificationDelaySeconds) seconds — background or quit the app, then tap the notification. Notifications must already be allowed in Settings."
    }

    private func sendTestNotification(for tracked: TrackedShow) async {
        guard !isSchedulingTestNotification else { return }
        isSchedulingTestNotification = true

        await notificationService.deliverAfterDelay(
            SeasonNotificationContent(
                showID: tracked.id,
                showName: tracked.name,
                status: tracked.nextSeason
            ),
            requestIdentifier: "debug-\(UUID().uuidString)",
            delay: TimeInterval(Self.testNotificationDelaySeconds)
        )

        isSchedulingTestNotification = false
    }
    #endif
}

#if DEBUG
#Preview {
    @Previewable @State var path = NavigationPath()
    let repository = InMemoryWatchlistRepository()
    WatchlistView(navigationPath: $path, tvMaze: TVMazeClient())
        .environment(\.watchlistRepository, repository)
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(repository: repository))
}
#endif
