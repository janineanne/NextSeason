//
//  CompatibilityIndexRefreshService.swift
//  NextSeason
//

import Foundation
import os

/// Opportunistic on-device refresh of the TVDB↔TVMaze compatibility index.
///
/// Never blocks Search or launch. Failures leave the existing writable database
/// untouched aside from whatever partial writes already committed — the bundled
/// baseline remains a recovery path via `CompatibilityIndexDatabase`.
actor CompatibilityIndexRefreshService {
    /// Roughly weekly refreshes are enough for search filtering freshness.
    static let refreshInterval: TimeInterval = 7 * 24 * 60 * 60

    /// Cap per opportunity so a large `/updates/shows` window cannot burst.
    static let maxShowDetailFetchesPerRefresh = 75

    /// Delay between TVMaze calls during refresh (stay under ≥20 / 10s).
    static let requestPause: Duration = .milliseconds(400)

    private let database: CompatibilityIndexDatabase
    private let tvMaze: any TVMazeService
    private let now: @Sendable () -> Date
    private var isRunning = false

    init(
        database: CompatibilityIndexDatabase,
        tvMaze: any TVMazeService,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.database = database
        self.tvMaze = tvMaze
        self.now = now
    }

    /// Starts a refresh when due. Safe to call from foreground activation.
    func refreshIfNeeded() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        do {
            let metadata = try await database.metadata()
            if let lastSync = metadata.lastSuccessfulSyncAt,
                now().timeIntervalSince(lastSync) < Self.refreshInterval
            {
                return
            }

            AppDiagnosticsLogger.logger(for: .network)
                .notice("compatibility_index_refresh_start")
            AppDiagnosticsLogger.breadcrumb("compatibility_index_refresh")

            try await refreshTail(fromHighestID: metadata.highestTVMazeID)
            try await refreshUpdatedShows(since: metadata.lastSuccessfulSyncAt)
            try await database.setLastSuccessfulSyncAt(now())

            AppDiagnosticsLogger.logger(for: .network)
                .notice("compatibility_index_refresh_complete")
        } catch {
            // Non-fatal: keep serving the existing map.
            AppDiagnosticsLogger.logger(for: .network)
                .error(
                    "compatibility_index_refresh_failed error=\(error.localizedDescription, privacy: .public)"
                )
            AppDiagnosticsLogger.breadcrumb("compatibility_index_refresh_failed")
        }
    }

    /// Walks TVMaze show-index pages from the local high-water mark to the end.
    private func refreshTail(fromHighestID highestID: Int) async throws {
        var page = max(highestID, 0) / 250
        var highest = highestID
        var emptyPages = 0

        while true {
            let shows: [ShowIndexEntryData]
            do {
                shows = try await tvMaze.showsIndex(page: page)
            } catch TVMazeError.notFound {
                break
            }

            if shows.isEmpty {
                emptyPages += 1
                // Defensive: avoid spinning if the API returns empty pages forever.
                if emptyPages >= 3 { break }
            } else {
                emptyPages = 0
                for entry in shows {
                    if entry.id > highest { highest = entry.id }
                    try await database.applyMapping(
                        tvMazeID: entry.id,
                        tvdbID: entry.externals?.thetvdb
                    )
                }
                try await database.setHighestTVMazeID(highest)
            }

            page += 1
            try await Task.sleep(for: Self.requestPause)
            try Task.checkCancellation()
        }
    }

    /// Refreshes mappings for shows TVMaze reports as updated since the last sync.
    private func refreshUpdatedShows(since lastSync: Date?) async throws {
        let period: TVMazeUpdatePeriod
        if let lastSync {
            period = TVMazeUpdatePeriod.covering(since: lastSync, at: now())
        } else {
            // First on-device sync after install: prefer a bounded window.
            period = .week
        }

        let updates = try await tvMaze.updatedShows(since: period)
        guard !updates.isEmpty else { return }

        // Prefer newer changes first; cap work per opportunity.
        let orderedIDs = updates.keys.sorted(by: >)
        var fetched = 0
        for showID in orderedIDs {
            guard fetched < Self.maxShowDetailFetchesPerRefresh else { break }
            do {
                let entry = try await tvMaze.showIndexEntry(id: showID)
                try await database.applyMapping(
                    tvMazeID: entry.id,
                    tvdbID: entry.externals?.thetvdb
                )
                fetched += 1
            } catch TVMazeError.notFound {
                // Show removed from TVMaze — drop any local mapping.
                try await database.removeMappings(forTVMazeID: showID)
                fetched += 1
            }
            try await Task.sleep(for: Self.requestPause)
            try Task.checkCancellation()
        }
    }
}
