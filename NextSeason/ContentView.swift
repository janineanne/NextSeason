//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// Root tab shell: Search and Watchlist, wired to `AppNavigationCoordinator` for
/// tab selection, navigation paths, watchlist reload tokens, and notification deep links.
struct ContentView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.watchlistPendingRemoval) private var removalCoordinator
    @Environment(\.analytics) private var analytics
    @Bindable var coordinator: AppNavigationCoordinator

    private let tvMaze: any TVMazeService

    init(coordinator: AppNavigationCoordinator, tvMaze: any TVMazeService) {
        _coordinator = Bindable(coordinator)
        self.tvMaze = tvMaze
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            SearchView(
                navigationPath: $coordinator.searchPath,
                tvMaze: tvMaze,
                analytics: analytics,
                onWatchlistChanged: { coordinator.notifyWatchlistDataChanged() }
            )
            // Instruments / ProfileFlow automation is wired here—not inside
            // `SearchView` or `ShowDetailView`—so feature screens stay unaware
            // of profiling. The runner (`ProfileFlowRunner`) drives tabs, paths,
            // and repository work through `AppNavigationCoordinator`; it still
            // needs two async completion signals that only the Search tab can
            // observe:
            //
            // 1. Search settled — debounced `.task(id: query)` finishes and
            //    `SearchViewModel.state` becomes `.results`, `.empty`, or `.failed`.
            // 2. Detail loaded — a pushed `ShowDetailView` finishes its load task.
            //
            // Those signals travel through SwiftUI environment keys (see
            // `AutomationEnvironment`) so `ShowDetailView` inherits the detail
            // callback without taking a profiling parameter. Guards inside the
            // consumers (`ProfileFlowConfiguration.isEnabled`) keep normal
            // launches from bumping coordinator tokens even though the hooks
            // are always installed.
            .environment(
                \.automationSearchQuery,
                $coordinator.automationSearchQuery
            )
            .environment(\.onAutomationSearchSettled) {
                coordinator.notifyAutomationSearchSettled()
            }
            .environment(\.onAutomationDetailLoaded) {
                coordinator.notifyAutomationDetailLoaded()
            }
            .accessibilityIdentifier(AccessibilityID.Tab.search)
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(AppNavigationCoordinator.Tab.search)

            WatchlistView(
                navigationPath: $coordinator.watchlistPath,
                tvMaze: tvMaze,
                watchlistReloadToken: coordinator.watchlistReloadToken,
                pendingDetailToken: coordinator.pendingWatchlistDetail?.id,
                onApplyPendingDetail: {
                    coordinator.applyPendingWatchlistDetail()
                },
                onFindShow: {
                    coordinator.showSearchRoot()
                },
                onWatchlistChanged: {
                    coordinator.notifyWatchlistDataChanged()
                }
            )
            .accessibilityIdentifier(AccessibilityID.Tab.watchlist)
            .tabItem {
                Label("Watchlist", systemImage: "star")
            }
            .tag(AppNavigationCoordinator.Tab.watchlist)
        }
        .appScreenBackground()
        .background {
            TabBarReselectHandler(tabIndex: AppNavigationCoordinator.Tab.search.tabBarIndex) {
                coordinator.popSearchToRoot()
            }
        }
        .modifier(BetaDiagnosticsPresentationModifier())
        .onChange(of: coordinator.selectedTab) { oldTab, tab in
            if tab == .search, oldTab != .search {
                coordinator.popSearchToRoot()
            }
            // Commit deferred removals when leaving the Watchlist tab — not when
            // pushing Show Detail (NavigationStack onDisappear would false-trigger).
            if oldTab == .watchlist, tab != .watchlist {
                Task {
                    AppDiagnosticsLogger.logTaskStart("watchlist_commit_on_leave_tab")
                    await removalCoordinator?.commitPendingRemovalIfNeeded()
                    AppDiagnosticsLogger.logTaskComplete("watchlist_commit_on_leave_tab")
                }
            }
            if tab == .watchlist {
                coordinator.notifyWatchlistDataChanged()
            }
        }
        .task {
            if !UITestingConfiguration.isEnabled {
                // Attach the exact coordinator SwiftUI observes so notification taps
                // route into this view's navigation state; this also flushes any
                // launch-time tap that NotificationRouting buffered before attach.
                NotificationRouting.setCoordinator(coordinator)
            }
            await coordinator.resolveInitialTab(repository: repository)
            await coordinator.resolvePendingNavigation(
                repository: repository,
                tvMaze: tvMaze,
                analytics: analytics
            )
        }
        .onChange(of: coordinator.pendingShowID) { _, showID in
            guard showID != nil else { return }
            Task {
                await coordinator.resolvePendingNavigation(
                    repository: repository,
                    tvMaze: tvMaze,
                    analytics: analytics
                )
            }
        }
    }
}

#if DEBUG
    #Preview {
        let repository = InMemoryWatchlistRepository()
        ContentView(coordinator: AppNavigationCoordinator(), tvMaze: TVMazeClient())
            .environment(\.watchlistRepository, repository)
            .environment(
                \.watchlistPendingRemoval,
                WatchlistPendingRemoval(
                    repository: repository,
                    analytics: RecordingAnalyticsService()
                ))
    }
#endif
