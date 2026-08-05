//
//  WatchlistViewModel.swift
//  NextSeason
//

import Foundation
import SwiftUI

/// Loads, filters, and sections the local watchlist, and keeps list animations
/// in sync with undoable removals via `WatchlistPendingRemoval`.
@Observable
@MainActor
final class WatchlistViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .loaded
    /// Rows rendered by the list. Kept separate from `state` so `ForEach` can
    /// diff removals and animate instead of replacing the whole list.
    private(set) var shows: [TrackedShow] = []

    /// User-entered text from the watchlist search bar. Filtering is local; the
    /// full `shows` list stays intact so removals still animate correctly.
    var searchText = ""

    /// `shows` narrowed to the current search query. Matching is
    /// case- and diacritic-insensitive on the show name.
    var filteredShows: [TrackedShow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return shows }
        return shows.filter { $0.name.localizedStandardContains(query) }
    }

    /// Non-empty status sections for the current filter, in display order.
    /// Empty sections are omitted. Coming Soon sorts by premiere date (soonest
    /// first); every other section sorts alphabetically by show name.
    var filteredSectionGroups: [WatchlistSectionGroup] {
        Self.sectionGroups(from: filteredShows)
    }

    static func sectionGroups(from shows: [TrackedShow]) -> [WatchlistSectionGroup] {
        var buckets: [WatchlistSection: [TrackedShow]] = [:]
        for show in shows {
            let section = WatchlistSection.section(for: show.nextSeason)
            buckets[section, default: []].append(show)
        }

        return WatchlistSection.allCases.compactMap { section in
            guard var sectionShows = buckets[section], !sectionShows.isEmpty else {
                return nil
            }
            if section == .comingSoon {
                sectionShows.sort(by: Self.comingSoonSort)
            } else {
                sectionShows.sort(by: Self.alphabeticalSort)
            }
            return WatchlistSectionGroup(section: section, shows: sectionShows)
        }
    }

    private static func comingSoonSort(_ lhs: TrackedShow, _ rhs: TrackedShow) -> Bool {
        switch (lhs.nextSeason, rhs.nextSeason) {
        case let (.scheduled(_, leftDate), .scheduled(_, rightDate)):
            if leftDate != rightDate { return leftDate < rightDate }
            return alphabeticalSort(lhs, rhs)
        default:
            return alphabeticalSort(lhs, rhs)
        }
    }

    private static func alphabeticalSort(_ lhs: TrackedShow, _ rhs: TrackedShow) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    var pendingRemoval: TrackedShow? { removalCoordinator.pendingRemoval }

    private let repository: any WatchlistRepository
    private let refreshService: WatchlistRefreshService?
    private let removalCoordinator: WatchlistPendingRemoval
    private let analytics: any AnalyticsTracking

    private var reloadGeneration = 0

    init(
        repository: any WatchlistRepository,
        refreshService: WatchlistRefreshService? = nil,
        removalCoordinator: WatchlistPendingRemoval,
        analytics: any AnalyticsTracking
    ) {
        self.repository = repository
        self.refreshService = refreshService
        self.removalCoordinator = removalCoordinator
        self.analytics = analytics
    }

    /// Re-reads the watchlist from persistence without flashing the loading
    /// spinner, so `.task(id:)` cancellations cannot strand the list in
    /// `.loading` when the reload token bumps in quick succession.
    /// Concurrent reloads keep only the newest result so a slower older fetch
    /// cannot overwrite fresher data.
    func reload() async {
        reloadGeneration += 1
        let generation = reloadGeneration
        do {
            let fetched = try await repository.all()
            guard generation == reloadGeneration else { return }
            shows = fetched
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard generation == reloadGeneration else { return }
            state = .failed(error.localizedDescription)
            analytics.trackNonFatalError(error, context: "watchlist_reload")
        }
    }

    /// Commits any pending removal, force-refreshes tracked shows, then reloads.
    func refreshFromNetwork() async {
        await removalCoordinator.commitPendingRemovalIfNeeded()
        // Pull-to-refresh is interactive — update rows silently; don't alert.
        await refreshService?.refreshAll(force: true, deliverNotifications: false)
        await reload()
    }

    /// Starts the undo window for removing `tracked`. The row stays visible
    /// until the removal is committed or the user confirms with OK. On commit
    /// (including when a later pending removal replaces this one), the row is
    /// removed from the displayed list.
    func requestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect,
        source: WatchlistActionSource = .watchlist
    ) {
        let showID = tracked.id
        removalCoordinator.requestRemoval(
            tracked,
            anchor: anchor,
            source: source
        ) { [weak self] in
            self?.removeShowAnimated(showID: showID)
        }
    }

    func undoPendingRemoval() {
        removalCoordinator.undoRemoval()
    }

    /// Commits a pending removal and animates the row away when persistence
    /// confirms it; otherwise reloads so the list matches the repository.
    func commitPendingRemovalIfNeeded(onCommitted: (() -> Void)? = nil) async {
        let removedID = removalCoordinator.pendingRemoval?.id
        await removalCoordinator.commitPendingRemovalIfNeeded(onCommitted: onCommitted)
        if let removedID, await showWasRemoved(showID: removedID) {
            removeShowAnimated(showID: removedID)
        } else {
            await reload()
        }
    }

    /// Removes a row from the displayed list. Wrap in `withAnimation` at the call
    /// site so SwiftUI can run the standard list removal animation.
    func removeShow(showID: Int) {
        guard let index = shows.firstIndex(where: { $0.id == showID }) else { return }
        shows.remove(at: index)
        state = .loaded
    }

    func removeShowAnimated(showID: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            removeShow(showID: showID)
        }
    }

    /// Reacts when a pending removal ID clears. If persistence dropped the show
    /// (commit), animates the row away; an undo leaves the list unchanged.
    func handlePendingRemovalIDChange(from oldID: Int?, to newID: Int?) async {
        guard let oldID, newID == nil else { return }
        guard await showWasRemoved(showID: oldID) else { return }
        removeShowAnimated(showID: oldID)
    }

    private func showWasRemoved(showID: Int) async -> Bool {
        do {
            return try await repository.contains(showID: showID) == false
        } catch {
            return false
        }
    }

    func isPendingRemoval(_ tracked: TrackedShow) -> Bool {
        pendingRemoval?.id == tracked.id
    }
}
