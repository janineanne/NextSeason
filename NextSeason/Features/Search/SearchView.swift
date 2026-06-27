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
    @Environment(\.analytics) private var analytics
    @Environment(\.dismissSearch) private var dismissSearch

    @Binding var navigationPath: NavigationPath
    @Binding var profileFlowSearchQuery: String?
    private let tvMaze: any TVMazeService
    private let onWatchlistChanged: () -> Void
    @State private var viewModel: SearchViewModel
    @State private var trackedShowIDs: Set<Int> = []
    @State private var updatingShowIDs: Set<Int> = []
    @State private var shouldPromptForNotifications = false
    @State private var shouldShowNotificationsDeniedAlert = false
    @State private var isScrollDismissingKeyboard = false
    @AppStorage(FirstRunPreferences.searchResultsHintDismissedKey)
    private var searchResultsHintDismissed = false

    init(
        navigationPath: Binding<NavigationPath>,
        profileFlowSearchQuery: Binding<String?> = .constant(nil),
        tvMaze: any TVMazeService = TVMazeClient(),
        analytics: any AnalyticsTracking = AnalyticsService(),
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
        _profileFlowSearchQuery = profileFlowSearchQuery
        self.tvMaze = tvMaze
        self.onWatchlistChanged = onWatchlistChanged
        _viewModel = State(initialValue: SearchViewModel(service: tvMaze, analytics: analytics))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appScreenBackground()
                .navigationTitle("NextSeason")
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(
                        show: show,
                        service: tvMaze,
                        repository: repository,
                        notifications: notificationService,
                        analytics: analytics,
                        isTracked: trackedShowIDs.contains(show.id),
                        onWatchlistChanged: onWatchlistChanged
                    )
                    .onAppear {
                        analytics.track(.searchResultOpened(showID: show.id))
                    }
                }
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
                .onSubmit(of: .search) {
                    collapseSearchKeyboard()
                }
                .task(id: viewModel.query) {
                    await viewModel.search()
                }
                .onChange(of: profileFlowSearchQuery) { _, query in
                    guard let query, !query.isEmpty else { return }
                    viewModel.query = query
                    profileFlowSearchQuery = nil
                }
                .task {
                    await refreshTrackedShowIDs()
                }
                .onChange(of: navigationPath) {
                    if navigationPath.count > 0 {
                        dismissSearchResultsHintIfNeeded()
                    }
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
                    Text(FirstRunCopy.notificationPromptMessage)
                }
                .alert("Notifications Are Off", isPresented: $shouldShowNotificationsDeniedAlert) {
                    Button("Not Now", role: .cancel) {}
                    Button("Open Settings") {
                        notificationService.openNotificationSettings()
                    }
                } message: {
                    Text(FirstRunCopy.notificationsDeniedMessage)
                }
        }
        .scrollDismissesKeyboard(.immediately)
        .appNavigationChrome()
    }

    /// Dismisses the keyboard but keeps the query visible in the search field.
    private func collapseSearchKeyboard() {
        dismissSearch()
        // `isPresented = false` collapses searchable and clears the visible query;
        // resign first responder ends editing while the nav-bar search text stays put.
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Nav-bar `.searchable` often ignores `scrollDismissesKeyboard`; drag is a reliable fallback.
    private func scrollDismissesSearchKeyboardGesture() -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                guard !isScrollDismissingKeyboard else { return }
                guard abs(value.translation.height) > 4 else { return }
                isScrollDismissingKeyboard = true
                collapseSearchKeyboard()
            }
            .onEnded { _ in
                isScrollDismissingKeyboard = false
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
            undoRemoval.requestRemoval(
                tracked,
                anchor: anchor,
                source: .search,
                onCommitted: onWatchlistChanged
            )
            trackedShowIDs.remove(show.id)
            return
        }

        updatingShowIDs.insert(show.id)
        defer { updatingShowIDs.remove(show.id) }

        do {
            try await repository.add(show)
            trackedShowIDs.insert(show.id)
            analytics.track(.watchlistAdded(source: .search, showID: show.id))
            dismissSearchResultsHintIfNeeded()
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
            analytics.trackNonFatalError(error, context: "watchlist_add_search")
            await refreshTrackedShowIDs()
        }
    }

    private func confirmNotificationPrompt() async {
        await notificationService.requestAuthorizationIfNeeded()
        if await notificationService.isDenied() {
            shouldShowNotificationsDeniedAlert = true
        }
    }

    private func dismissSearchResultsHintIfNeeded() {
        guard !searchResultsHintDismissed else { return }
        searchResultsHintDismissed = true
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label("Find Your Next Season", systemImage: "magnifyingglass")
                    .appPrimaryText()
            } description: {
                Text(FirstRunCopy.searchIdleDescription)
                    .appSecondaryText()
            } actions: {
                Button(FirstRunCopy.tryExampleButtonTitle) {
                    analytics.track(.exampleSearchUsed)
                    viewModel.query = FirstRunCopy.exampleSearchQuery
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityID.Search.tryExampleButton)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.Search.idlePrompt)
        case .loading:
            List {
                ForEach(0..<3, id: \.self) { _ in
                    ShowRowSkeleton()
                }
                .appListRowSurface()
            }
            .appPlainListStyle()
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(scrollDismissesSearchKeyboardGesture())
            .tvmazeAttributionInset()
        case .results(let shows):
            List(shows) { show in
                HStack(spacing: AppSpacing.tight) {
                    NavigationLink(value: show) {
                        ShowRowLabel(show: show)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("\(AccessibilityID.Search.result).\(show.id)")
                    ShowRowTrackButton(
                        showID: show.id,
                        showName: show.name,
                        isTracked: trackedShowIDs.contains(show.id),
                        isUpdating: updatingShowIDs.contains(show.id)
                    ) { anchor in
                        Task { await handleTrackButton(for: show, anchor: anchor) }
                    }
                }
                .appListRowSurface()
            }
            .appPlainListStyle()
            .scrollDismissesKeyboard(.immediately)
            .simultaneousGesture(scrollDismissesSearchKeyboardGesture())
            .searchResultsHintInset(isVisible: !searchResultsHintDismissed)
            .tvmazeAttributionInset()
        case .empty:
            // TVMaze's public search returns at most 10 results with no pagination,
            // so an empty result set does not mean the show is missing. Guide the
            // user toward a more specific query instead of implying it doesn't exist.
            ContentUnavailableView {
                Label("Can't Find Your Show?", systemImage: "magnifyingglass")
                    .appPrimaryText()
            } description: {
                Text("Try a more specific title instead of a single word — add a subtitle or the year (for example, “Title: Subtitle” or “Title 2019”).")
                    .appSecondaryText()
            }
            .uiTestMarker(AccessibilityID.Search.noResults, label: "Can't Find Your Show?")
        case .failed(let message):
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
                    .appPrimaryText()
            } description: {
                Text(message)
                    .appSecondaryText()
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
