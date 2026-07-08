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
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.openAppAbout) private var openAppAbout

    @Binding var navigationPath: NavigationPath
    @Binding var profileFlowSearchQuery: String?
    private let onProfileFlowSearchSettled: (() -> Void)?
    private let onProfileFlowDetailLoaded: (() -> Void)?
    private let tvMaze: any TVMazeService
    private let analytics: any AnalyticsTracking
    private let onWatchlistChanged: () -> Void
    @State private var viewModel: SearchViewModel
    @State private var watchlistTracking = SearchWatchlistTracking()
    @State private var notificationPrompt = WatchlistNotificationPromptState()
    @State private var isScrollDismissingKeyboard = false
    @AppStorage(FirstRunPreferences.searchResultsHintDismissedKey)
    private var searchResultsHintDismissed = false

    init(
        navigationPath: Binding<NavigationPath>,
        profileFlowSearchQuery: Binding<String?> = .constant(nil),
        onProfileFlowSearchSettled: (() -> Void)? = nil,
        onProfileFlowDetailLoaded: (() -> Void)? = nil,
        tvMaze: any TVMazeService,
        analytics: any AnalyticsTracking,
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
        _profileFlowSearchQuery = profileFlowSearchQuery
        self.onProfileFlowSearchSettled = onProfileFlowSearchSettled
        self.onProfileFlowDetailLoaded = onProfileFlowDetailLoaded
        self.tvMaze = tvMaze
        self.analytics = analytics
        self.onWatchlistChanged = onWatchlistChanged
        _viewModel = State(initialValue: SearchViewModel(service: tvMaze, analytics: analytics))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appScreenBackground()
                .navigationTitle("NextSeason")
                .toolbar { aboutToolbarButton }
                .betaThemeSwitcherToolbar()
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(
                        show: show,
                        service: tvMaze,
                        repository: repository,
                        notifications: notificationService,
                        analytics: analytics,
                        isTracked: watchlistTracking.trackedShowIDs.contains(show.id),
                        onWatchlistChanged: onWatchlistChanged,
                        onProfileFlowDetailLoaded: onProfileFlowDetailLoaded
                    )
                    .onAppear {
                        analytics.track(.searchResultOpened(showID: show.id))
                    }
                }
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
                .modifier(ReturnToSearchResultsOnActivateModifier(navigationPath: $navigationPath))
                .onSubmit(of: .search) {
                    collapseSearchKeyboard(dismissSearch: dismissSearch)
                }
                .task(id: viewModel.query) {
                    await viewModel.search()
                }
                .searchProfileFlow(
                    profileFlowSearchQuery: $profileFlowSearchQuery,
                    viewModel: viewModel,
                    onProfileFlowSearchSettled: onProfileFlowSearchSettled
                )
                .task {
                    await refreshTrackedShows()
                }
                .task(id: navigationPath.count) {
                    if navigationPath.count > 0 {
                        dismissSearchResultsHintIfNeeded()
                    }
                    await refreshTrackedShows()
                }
                .task(id: undoRemoval?.pendingRemoval?.id) {
                    await refreshTrackedShows()
                }
                .watchlistNotificationPromptAlerts(
                    prompt: notificationPrompt,
                    notificationService: notificationService
                )
        }
        .scrollDismissesKeyboard(.immediately)
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

    private func refreshTrackedShows() async {
        await watchlistTracking.refresh(
            repository: repository,
            excludingPendingRemovalFrom: undoRemoval,
            analytics: analytics
        )
    }

    private var watchlistTrackingContext: SearchWatchlistTrackingContext {
        SearchWatchlistTrackingContext(
            repository: repository,
            undoRemoval: undoRemoval,
            notificationService: notificationService,
            notificationPrompt: notificationPrompt,
            analytics: analytics,
            onWatchlistChanged: onWatchlistChanged,
            onSearchResultsHintDismissed: dismissSearchResultsHintIfNeeded
        )
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
            .searchScrollKeyboardDismissGesture(
                isScrollDismissingKeyboard: $isScrollDismissingKeyboard,
                dismissSearch: dismissSearch
            )
            .tvmazeAttributionInset()
        case .results(let shows):
            List {
                ForEach(shows) { show in
                    HStack(spacing: AppSpacing.tight) {
                        NavigationLink(value: show) {
                            ShowRowLabel(show: show)
                        }
                        .buttonStyle(.plain)
                        .showDetailLinkAccessibility()
                        .accessibilityIdentifier("\(AccessibilityID.Search.result).\(show.id)")
                        ShowRowTrackButton(
                            showID: show.id,
                            showName: show.name,
                            isTracked: watchlistTracking.trackedShowIDs.contains(show.id),
                            isUpdating: watchlistTracking.updatingShowIDs.contains(show.id)
                        ) { anchor in
                            Task {
                                await watchlistTracking.handleTrackButton(
                                    for: show,
                                    anchor: anchor,
                                    context: watchlistTrackingContext
                                )
                            }
                        }
                    }
                    .appListRowSurface()
                }
                SearchResultsLimitFooterView(query: viewModel.query)
                    .listRowInsets(
                        EdgeInsets(
                            top: AppSpacing.tight,
                            leading: AppSpacing.screen,
                            bottom: AppSpacing.section,
                            trailing: AppSpacing.screen
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .appPlainListStyle()
            .scrollDismissesKeyboard(.immediately)
            .searchScrollKeyboardDismissGesture(
                isScrollDismissingKeyboard: $isScrollDismissingKeyboard,
                dismissSearch: dismissSearch
            )
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

/// When search is activated from a pushed show-detail screen, pop back to the
/// results list while leaving the query in `SearchViewModel` untouched.
private struct ReturnToSearchResultsOnActivateModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    @Binding var navigationPath: NavigationPath
    @State private var lastNavigationPathChange = Date.distantPast

    /// Ignore search activation briefly after pushing detail; the searchable
    /// chrome can flip `isSearching` during that transition.
    private static let navigationSettlingInterval: TimeInterval = 0.35

    func body(content: Content) -> some View {
        content
            .onChange(of: navigationPath) { _, _ in
                lastNavigationPathChange = Date.now
            }
            .onChange(of: isSearching) { wasSearching, searching in
                guard searching, !wasSearching, navigationPath.count > 0 else { return }
                guard Date.now.timeIntervalSince(lastNavigationPathChange) > Self.navigationSettlingInterval else {
                    return
                }
                navigationPath = NavigationPath()
            }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var path = NavigationPath()
    let repository = InMemoryWatchlistRepository()
    SearchView(
        navigationPath: $path,
        tvMaze: TVMazeClient(),
        analytics: RecordingAnalyticsService()
    )
    .environment(\.watchlistRepository, repository)
    .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(
        repository: repository,
        analytics: RecordingAnalyticsService()
    ))
}
#endif
