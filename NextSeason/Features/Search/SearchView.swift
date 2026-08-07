//
//  SearchView.swift
//  NextSeason
//

import SwiftUI

/// Guest search: type a title, browse matching shows, and track from the results list.
///
/// Lifecycle / refresh matrix:
/// - `.task(id: query)` drives `SearchViewModel.search()` (debounce + cancel on edit).
/// - `.task` and `.task(id: navigationPath.count)` refresh tracked IDs when the
///   screen appears or when returning from show detail.
/// - `.onChange(of: outcomeGeneration)` keeps row track-button state in sync when
///   a pending removal commits, is undone, or is cancelled.
///
/// First-run AppStorage (independent flags):
/// - `hasCompletedFirstSearch` — retires the idle "Try an Example" button once the
///   user reaches `.results` or `.empty`.
/// - `searchResultsHintDismissed` — hides the results-list inset hint after the
///   user opens a show (or after an add-to-watchlist dismisses it).
struct SearchView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.notificationService) private var notificationService
    @Environment(\.watchlistPendingRemoval) private var removalCoordinator
    @Environment(\.dismissSearch) private var dismissSearch

    @Binding var navigationPath: NavigationPath
    private let tvMaze: any TVMazeService
    private let analytics: any AnalyticsTracking
    private let onWatchlistChanged: () -> Void
    @State private var viewModel: SearchViewModel
    @State private var watchlistTracking = SearchWatchlistTracking()
    @State private var notificationPrompt = WatchlistNotificationPromptState()
    @State private var isScrollDismissingKeyboard = false
    /// Persists dismissal of the results-list first-run inset (not the idle example CTA).
    @AppStorage(FirstRunPreferences.searchResultsHintDismissedKey)
    private var searchResultsHintDismissed = false
    /// Persists completion of the idle "Try an Example" affordance.
    @AppStorage(FirstRunPreferences.hasCompletedFirstSearchKey)
    private var hasCompletedFirstSearch = false

    init(
        navigationPath: Binding<NavigationPath>,
        tvMaze: any TVMazeService,
        analytics: any AnalyticsTracking,
        onWatchlistChanged: @escaping () -> Void = {}
    ) {
        _navigationPath = navigationPath
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
                .appAboutToolbarButton()
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(
                        show: show,
                        service: tvMaze,
                        repository: repository,
                        notifications: notificationService,
                        analytics: analytics,
                        isTracked: watchlistTracking.trackedShowIDs.contains(show.id),
                        onWatchlistChanged: onWatchlistChanged
                    )
                    .onAppear {
                        analytics.track(.searchResultOpened(showID: show.id))
                        // Push-only: tab switches that re-show detail must not cancel
                        // a pending removal started on another tab.
                        removalCoordinator?.dismissPendingRemovalForNavigation()
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
                .onChange(of: viewModel.state) { _, newState in
                    markFirstSearchCompletedIfNeeded(for: newState)
                }
                .automationSearchHooks(viewModel: viewModel)
                .task {
                    await refreshTrackedShows()
                }
                .task(id: navigationPath.count) {
                    if navigationPath.count > 0 {
                        dismissSearchResultsHintIfNeeded()
                    }
                    await refreshTrackedShows()
                }
                .onChange(of: removalCoordinator?.outcomeGeneration) { _, _ in
                    guard let outcome = removalCoordinator?.lastOutcome else { return }
                    Task { await handlePendingRemovalOutcome(outcome) }
                }
                .watchlistNotificationPromptAlerts(
                    prompt: notificationPrompt,
                    notificationService: notificationService
                )
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func refreshTrackedShows() async {
        await watchlistTracking.refresh(
            repository: repository,
            excludingPendingRemovalFrom: removalCoordinator,
            analytics: analytics
        )
    }

    private func handlePendingRemovalOutcome(_ outcome: PendingRemovalOutcome) async {
        await refreshTrackedShows()
        switch outcome {
        case .committed, .replaced:
            onWatchlistChanged()
        case .undone, .cancelled, .failed:
            break
        }
    }

    private var watchlistTrackingContext: SearchWatchlistTracking.Context {
        SearchWatchlistTracking.Context(
            repository: repository,
            tvMaze: tvMaze,
            removalCoordinator: removalCoordinator,
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

    /// Once the user reaches a real search outcome, they've demonstrated they
    /// know how to search, so retire the "Try an Example" affordance for good.
    private func markFirstSearchCompletedIfNeeded(for state: SearchViewModel.State) {
        guard !hasCompletedFirstSearch else { return }
        switch state {
        case .results, .empty:
            hasCompletedFirstSearch = true
        case .idle, .loading, .failed:
            break
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label {
                    Text("Find Your Next Season")
                        .appAccentText()
                } icon: {
                    Image(systemName: "magnifyingglass")
                        .appPrimaryText()
                }
            } description: {
                Text(FirstRunCopy.searchIdleDescription)
                    .appSecondaryText()
            } actions: {
                if !hasCompletedFirstSearch {
                    Button(FirstRunCopy.tryExampleButtonTitle) {
                        analytics.track(.exampleSearchUsed)
                        viewModel.query = FirstRunCopy.exampleSearchQuery
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityID.Search.tryExampleButton)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityID.Search.idlePrompt)
        case .loading:
            List {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        ShowRowSkeleton()
                    }
                } footer: {
                    TVMazeAttributionView()
                }
            }
            .appPlainListStyle()
            .scrollDismissesKeyboard(.immediately)
            .searchScrollKeyboardDismissGesture(
                isScrollDismissingKeyboard: $isScrollDismissingKeyboard,
                dismissSearch: dismissSearch
            )
        case .results(let shows):
            List {
                Section {
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
                                isUpdating: watchlistTracking.updatingShowIDs.contains(show.id),
                                isPendingRemoval: removalCoordinator?.pendingRemoval?.id == show.id
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
                } footer: {
                    TVMazeAttributionView()
                }
            }
            .appPlainListStyle()
            .scrollDismissesKeyboard(.immediately)
            .searchScrollKeyboardDismissGesture(
                isScrollDismissingKeyboard: $isScrollDismissingKeyboard,
                dismissSearch: dismissSearch
            )
            .searchResultsHintInset(isVisible: !searchResultsHintDismissed)
        case .empty:
            // TVMaze's public search returns at most 10 results with no pagination,
            // so an empty result set does not mean the show is missing. Guide the
            // user toward a more specific query instead of implying it doesn't exist.
            ContentUnavailableView {
                Label {
                    Text("Can't Find Your Show?")
                        .appAccentText()
                } icon: {
                    Image(systemName: "magnifyingglass")
                        .appPrimaryText()
                }
            } description: {
                Text(
                    "Try a more specific title instead of a single word — add a subtitle or the year (for example, “Title: Subtitle” or “Title 2019”)."
                )
                .appSecondaryText()
            }
            .uiTestMarker(AccessibilityID.Search.noResults, label: "Can't Find Your Show?")
        case .failed(let message):
            ContentUnavailableView {
                Label {
                    Text("Something Went Wrong")
                        .appAccentText()
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .appPrimaryText()
                }
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
                guard
                    Date.now.timeIntervalSince(lastNavigationPathChange)
                        > Self.navigationSettlingInterval
                else {
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
        .environment(
            \.watchlistPendingRemoval,
            WatchlistPendingRemoval(
                repository: repository,
                analytics: RecordingAnalyticsService()
            ))
    }
#endif
