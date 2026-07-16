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

    /// Shared state driving the post-track notification prompt alerts, reused
    /// verbatim by the search flow via `watchlistNotificationPromptAlerts`.
    let notificationPrompt = WatchlistNotificationPromptState()

    private let service: any TVMazeService
    private let repository: any WatchlistRepository
    private let notifications: any NotificationManaging
    private let analytics: any AnalyticsTracking

    /// Notification service used by the shared prompt alerts modifier.
    var notificationService: any NotificationManaging { notifications }

    init(
        show: Show,
        service: any TVMazeService,
        repository: any WatchlistRepository,
        notifications: any NotificationManaging,
        analytics: any AnalyticsTracking,
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
        AppDiagnosticsLogger.breadcrumb("show_detail_load:\(initialShow.id)")
        async let trackedRefresh: Void = refreshTrackedState()

        do {
            fullShow = try await service.show(id: initialShow.id)
            guard !Task.isCancelled else {
                AppDiagnosticsLogger.logTaskCancel("show_detail_load")
                return
            }
            loadState = .loaded
            await trackedRefresh
        } catch is CancellationError {
            AppDiagnosticsLogger.logTaskCancel("show_detail_load")
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
        do {
            isTracked = try await repository.contains(showID: initialShow.id)
        } catch is CancellationError {
            return
        } catch {
            analytics.trackNonFatalError(error, context: "show_detail_refresh_tracked_state")
        }
    }

    func trackedShow() async -> TrackedShow? {
        try? await repository.trackedShow(showID: initialShow.id)
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
                notificationPrompt.shouldPromptForNotifications = true
            }
        } catch {
            analytics.trackNonFatalError(error, context: "watchlist_add_detail")
            if fullShow != nil {
                loadState = .failed(error.localizedDescription)
            }
        }
    }
}
