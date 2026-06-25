//
//  ShowDetailViewModel.swift
//  NextSeason
//

import Foundation

@Observable
@MainActor
final class ShowDetailViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    /// Header data carried over from search for instant display.
    let initialShow: Show
    private(set) var fullShow: Show?
    private(set) var loadState: LoadState = .loading
    private(set) var isTracked = false
    private(set) var isUpdatingWatchlist = false
    private(set) var shouldPromptForNotifications = false
    private(set) var shouldShowNotificationsDeniedAlert = false

    private let service: any TVMazeService
    private let repository: any WatchlistRepository
    private let notifications: NotificationService
    private let analytics: any AnalyticsTracking

    init(
        show: Show,
        service: any TVMazeService = TVMazeClient(),
        repository: any WatchlistRepository,
        notifications: NotificationService,
        analytics: any AnalyticsTracking = AnalyticsService(),
        initialIsTracked: Bool = false
    ) {
        self.initialShow = show
        self.service = service
        self.repository = repository
        self.notifications = notifications
        self.analytics = analytics
        self.isTracked = initialIsTracked
    }

    /// Best available show data: the fully-loaded show once fetched, else the
    /// lighter version passed from search.
    var displayShow: Show { fullShow ?? initialShow }

    /// Next-season status, available only once seasons have been loaded.
    var nextSeasonStatus: NextSeasonStatus? {
        fullShow.map { NextSeasonCalculator.status(for: $0) }
    }

    /// Loads full show details (seasons + next episode) and tracked status.
    /// Tracked status is fetched in parallel with the network request so the
    /// toolbar reflects search-row changes without waiting on TVMaze.
    func load() async {
        loadState = .loading
        async let trackedRefresh: Void = refreshTrackedState()

        do {
            fullShow = try await service.show(id: initialShow.id)
            loadState = .loaded
            await trackedRefresh
        } catch is CancellationError {
            return
        } catch {
            loadState = .failed(error.localizedDescription)
            analytics.trackNonFatalError(error, context: "show_detail_load")
            await trackedRefresh
        }
    }

    /// Re-reads tracked status from the repository so the Track control reflects
    /// changes made elsewhere (e.g. the show was removed on the Watchlist tab)
    /// when this screen reappears. Skipped mid-toggle to avoid clobbering an
    /// in-flight optimistic update.
    func refreshTrackedState() async {
        guard !isUpdatingWatchlist else { return }
        if let tracked = try? await repository.contains(showID: initialShow.id) {
            isTracked = tracked
        }
    }

    func trackedShow() async -> TrackedShow? {
        try? await repository.all().first { $0.id == initialShow.id }
    }

    func applyTrackedState(_ tracked: Bool) {
        isTracked = tracked
    }

    func addToWatchlist() async {
        guard !isUpdatingWatchlist else { return }
        let show = fullShow ?? initialShow
        isUpdatingWatchlist = true
        defer { isUpdatingWatchlist = false }

        do {
            try await repository.add(show)
            isTracked = true
            analytics.track(.watchlistAdded(source: .detail, showID: show.id))
            if await notifications.needsAuthorizationPrompt() {
                shouldPromptForNotifications = true
            } else {
                await notifications.requestAuthorizationIfNeeded()
                if await notifications.isDenied() {
                    shouldShowNotificationsDeniedAlert = true
                }
            }
        } catch {
            analytics.trackNonFatalError(error, context: "watchlist_add_detail")
            if fullShow != nil {
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    func dismissNotificationPrompt() {
        shouldPromptForNotifications = false
        notifications.deferAuthorizationPrompt()
    }

    func confirmNotificationPrompt() async {
        shouldPromptForNotifications = false
        await notifications.requestAuthorizationIfNeeded()
        if await notifications.isDenied() {
            shouldShowNotificationsDeniedAlert = true
        }
    }

    func dismissNotificationsDeniedAlert() {
        shouldShowNotificationsDeniedAlert = false
    }

    func openNotificationSettings() {
        notifications.openNotificationSettings()
    }
}
