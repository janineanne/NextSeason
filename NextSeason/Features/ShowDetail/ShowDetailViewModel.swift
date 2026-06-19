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

    init(
        show: Show,
        service: any TVMazeService = TVMazeClient(),
        repository: any WatchlistRepository,
        notifications: NotificationService = NotificationService()
    ) {
        self.initialShow = show
        self.service = service
        self.repository = repository
        self.notifications = notifications
    }

    /// Best available show data: the fully-loaded show once fetched, else the
    /// lighter version passed from search.
    var displayShow: Show { fullShow ?? initialShow }

    /// Next-season status, available only once seasons have been loaded.
    var nextSeasonStatus: NextSeasonStatus? {
        fullShow.map { NextSeasonCalculator.status(for: $0) }
    }

    /// Loads full show details (seasons + next episode) needed to derive status.
    func load() async {
        loadState = .loading
        do {
            fullShow = try await service.show(id: initialShow.id)
            loadState = .loaded
            isTracked = try await repository.contains(showID: initialShow.id)
        } catch is CancellationError {
            return
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func toggleWatchlist() async {
        guard let show = fullShow, loadState == .loaded, !isUpdatingWatchlist else { return }
        isUpdatingWatchlist = true
        defer { isUpdatingWatchlist = false }

        do {
            if isTracked {
                try await repository.remove(showID: show.id)
                isTracked = false
            } else {
                try await repository.add(show)
                isTracked = true
                if await notifications.needsAuthorizationPrompt() {
                    shouldPromptForNotifications = true
                } else {
                    await notifications.requestAuthorizationIfNeeded()
                    if await notifications.isDenied() {
                        shouldShowNotificationsDeniedAlert = true
                    }
                }
            }
        } catch {
            loadState = .failed(error.localizedDescription)
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
