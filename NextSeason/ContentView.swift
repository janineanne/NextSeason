//
//  ContentView.swift
//  NextSeason
//

import SwiftUI

/// The app's root view: Search and Watchlist tabs (Slice 2).
struct ContentView: View {
    @Environment(\.watchlistRepository) private var repository
    @Environment(\.analytics) private var analytics
    @Environment(\.appThemeColors) private var themeColors

    @Bindable var coordinator: AppNavigationCoordinator

    private let tvMaze: any TVMazeService

    init(coordinator: AppNavigationCoordinator, tvMaze: any TVMazeService = TVMazeClient()) {
        _coordinator = Bindable(coordinator)
        self.tvMaze = tvMaze
    }

    var body: some View {
        TabView(selection: tabSelection) {
            SearchView(
                navigationPath: $coordinator.searchPath,
                profileFlowSearchQuery: $coordinator.profileFlowSearchQuery,
                onProfileFlowSearchSettled: { coordinator.notifyProfileFlowSearchSettled() },
                onProfileFlowDetailLoaded: { coordinator.notifyProfileFlowDetailLoaded() },
                tvMaze: tvMaze,
                analytics: analytics,
                onWatchlistChanged: { coordinator.notifyWatchlistDataChanged() }
            )
                .accessibilityIdentifier(AccessibilityID.Tab.search)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(AppNavigationCoordinator.Tab.search)

            WatchlistView(
                navigationPath: $coordinator.watchlistPath,
                tvMaze: tvMaze,
                watchlistReloadToken: coordinator.watchlistReloadToken,
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
        .tint(themeColors.controlTint)
        .appScreenBackground()
        .background {
            TabBarReselectHandler(tabIndex: AppNavigationCoordinator.Tab.search.tabBarIndex) {
                coordinator.popSearchToRoot()
            }
        }
        .modifier(BetaDiagnosticsPresentationModifier())
        .onChange(of: coordinator.selectedTab) { _, tab in
            if tab == .watchlist {
                coordinator.notifyWatchlistDataChanged()
            }
        }
        .task {
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

    /// Any user-driven switch to Search returns to the search root; programmatic
    /// navigation (e.g. notification deep links) sets `selectedTab` directly.
    private var tabSelection: Binding<AppNavigationCoordinator.Tab> {
        Binding(
            get: { coordinator.selectedTab },
            set: { newTab in
                if newTab == .search {
                    coordinator.popSearchToRoot()
                }
                coordinator.selectedTab = newTab
            }
        )
    }
}

/// Presents beta diagnostics only in DEBUG or TestFlight builds.
@MainActor
private struct BetaDiagnosticsPresentationModifier: ViewModifier {
    @State private var activeSheet: BetaDiagnosticsSheet?
    @State private var betaBuildAvailability = BetaBuildAvailability.shared

    func body(content: Content) -> some View {
        if betaBuildAvailability.isAvailable {
            content
                .environment(\.openAppAbout) {
                    guard !UITestingConfiguration.isEnabled else { return }
                    activeSheet = .about
                }
                .environment(\.openDiagnostics) {
                    guard !UITestingConfiguration.isEnabled else { return }
                    activeSheet = .diagnostics
                }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .about:
                        AppAboutView {
                            activeSheet = .diagnostics
                        }
                    case .diagnostics:
                        DiagnosticsView()
                    }
                }
                .task {
                    await betaBuildAvailability.refresh()
                }
        } else {
            content
                .task {
                    await betaBuildAvailability.refresh()
                }
        }
    }
}

private enum BetaDiagnosticsSheet: Identifiable {
    case about
    case diagnostics

    var id: String {
        switch self {
        case .about:
            return "about"
        case .diagnostics:
            return "diagnostics"
        }
    }
}

#Preview {
    ContentView(coordinator: AppNavigationCoordinator())
        .environment(\.watchlistRepository, InMemoryWatchlistRepository())
        .environment(\.watchlistUndoRemoval, WatchlistUndoRemoval(repository: InMemoryWatchlistRepository()))
        .appThemePreview()
}
