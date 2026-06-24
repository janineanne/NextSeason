//
//  SearchView.swift
//  NextSeason
//

import SwiftUI

/// Guest search: type a title, see matching shows and their status.
struct SearchView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.notificationService) private var notificationService
    @Environment(\.watchlistUndoRemoval) private var undoRemoval

    @Binding var navigationPath: NavigationPath
    private let tvMaze: any TVMazeService
    private let onWatchlistChanged: () -> Void
    @State private var viewModel: SearchViewModel
    @State private var trackedShowIDs: Set<Int> = []
    @State private var updatingShowIDs: Set<Int> = []
    @State private var shouldPromptForNotifications = false
    @State private var shouldShowNotificationsDeniedAlert = false

    init(
        navigationPath: Binding<NavigationPath>,
        tvMaze: any TVMazeService = TVMazeClient(),
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
        self.tvMaze = tvMaze
        self.onWatchlistChanged = onWatchlistChanged
        _viewModel = State(initialValue: SearchViewModel(service: tvMaze))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("NextSeason")
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(
                        show: show,
                        service: tvMaze,
                        repository: repository,
                        notifications: notificationService,
                        isTracked: trackedShowIDs.contains(show.id),
                        onWatchlistChanged: onWatchlistChanged
                    )
                }
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
                .task(id: viewModel.query) {
                    await viewModel.search()
                }
                .task {
                    await refreshTrackedShowIDs()
                }
                .onChange(of: navigationPath) {
                    // Returning from a detail screen may have changed tracking
                    // state, so refresh the controls shown in the results list.
                    Task { await refreshTrackedShowIDs() }
                }
                .onChange(of: undoRemoval?.pendingRemoval?.id) { _, _ in
                    Task { await refreshTrackedShowIDs() }
                }
                .alert("Stay in the Loop", isPresented: $shouldPromptForNotifications) {
                    Button("Not Now", role: .cancel) {
                        notificationService.deferAuthorizationPrompt()
                    }
                    Button("Enable Notifications") {
                        Task { await confirmNotificationPrompt() }
                    }
                } message: {
                    Text("NextSeason can notify you when a tracked show gets a release date or season update.")
                }
                .alert("Notifications Are Off", isPresented: $shouldShowNotificationsDeniedAlert) {
                    Button("Not Now", role: .cancel) {}
                    Button("Open Settings") {
                        notificationService.openNotificationSettings()
                    }
                } message: {
                    Text("Enable notifications in Settings to get alerts when a tracked show's next season status changes.")
                }
        }
    }

    private func refreshTrackedShowIDs() async {
        if let shows = try? await repository.all() {
            var ids = Set(shows.map(\.id))
            if let pendingID = undoRemoval?.pendingRemoval?.id {
                ids.remove(pendingID)
            }
            trackedShowIDs = ids
        }
    }

    private func handleTrackButton(for show: Show, anchor: CGRect) async {
        guard !updatingShowIDs.contains(show.id) else { return }

        if trackedShowIDs.contains(show.id) {
            guard let undoRemoval,
                  let tracked = try? await repository.all().first(where: { $0.id == show.id })
            else { return }
            undoRemoval.requestRemoval(tracked, anchor: anchor, onCommitted: onWatchlistChanged)
            trackedShowIDs.remove(show.id)
            return
        }

        updatingShowIDs.insert(show.id)
        defer { updatingShowIDs.remove(show.id) }

        do {
            try await repository.add(show)
            trackedShowIDs.insert(show.id)
            if await notificationService.needsAuthorizationPrompt() {
                shouldPromptForNotifications = true
            } else {
                await notificationService.requestAuthorizationIfNeeded()
                if await notificationService.isDenied() {
                    shouldShowNotificationsDeniedAlert = true
                }
            }
            onWatchlistChanged()
        } catch is CancellationError {
            return
        } catch {
            await refreshTrackedShowIDs()
        }
    }

    private func confirmNotificationPrompt() async {
        await notificationService.requestAuthorizationIfNeeded()
        if await notificationService.isDenied() {
            shouldShowNotificationsDeniedAlert = true
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
                HStack(spacing: 8) {
                    NavigationLink(value: show) {
                        ShowRowLabel(show: show)
                    }
                    ShowRowTrackButton(
                        showID: show.id,
                        showName: show.name,
                        isTracked: trackedShowIDs.contains(show.id),
                        isUpdating: updatingShowIDs.contains(show.id)
                    ) { anchor in
                        Task { await handleTrackButton(for: show, anchor: anchor) }
                    }
                }
            }
            .listStyle(.plain)
            .tvmazeAttributionInset()
        case .empty:
            // TVMaze's public search returns at most 10 results with no pagination,
            // so an empty result set does not mean the show is missing. Guide the
            // user toward a more specific query instead of implying it doesn't exist.
            ContentUnavailableView {
                Label("Can't Find Your Show?", systemImage: "magnifyingglass")
            } description: {
                Text("Try a more specific title instead of a single word — add a subtitle or the year (for example, “Title: Subtitle” or “Title 2019”).")
            }
            .uiTestMarker(AccessibilityID.Search.noResults, label: "Can't Find Your Show?")
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
    let repository = InMemoryWatchlistRepository()
    SearchView(navigationPath: $path)
        .environment(\.watchlistRepository, repository)
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(repository: repository))
}
