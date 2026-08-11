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
///
/// Update passes are newest-first and **resumable**: when the per-opportunity
/// fetch cap is hit, a cursor is stored and `lastSuccessfulSyncAt` is left
/// unchanged so the next foreground opportunity continues the remaining work.
actor CompatibilityIndexRefreshService {
    /// Roughly weekly refreshes are enough for search filtering freshness.
    static let refreshInterval: TimeInterval = 7 * 24 * 60 * 60

    /// Cap per opportunity so a large `/updates/shows` window cannot burst.
    static let defaultMaxShowDetailFetchesPerRefresh = 75

    /// Delay between TVMaze calls during refresh (stay under ≥20 / 10s).
    static let defaultRequestPause: Duration = .milliseconds(400)

    private let database: CompatibilityIndexDatabase
    private let tvMaze: any TVMazeService
    private let now: @Sendable () -> Date
    private let maxShowDetailFetchesPerRefresh: Int
    private let requestPause: Duration
    private var isRunning = false

    init(
        database: CompatibilityIndexDatabase,
        tvMaze: any TVMazeService,
        now: @escaping @Sendable () -> Date = { Date() },
        maxShowDetailFetchesPerRefresh: Int = CompatibilityIndexRefreshService
            .defaultMaxShowDetailFetchesPerRefresh,
        requestPause: Duration = CompatibilityIndexRefreshService.defaultRequestPause
    ) {
        self.database = database
        self.tvMaze = tvMaze
        self.now = now
        self.maxShowDetailFetchesPerRefresh = maxShowDetailFetchesPerRefresh
        self.requestPause = requestPause
    }

    /// Starts a refresh when due, or continues a capped updates pass.
    /// Safe to call from foreground activation.
    func refreshIfNeeded() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        do {
            let metadata = try await database.metadata()
            let hasResumeCursor = metadata.updatesResumeCursor != nil
            if !hasResumeCursor,
                let lastSync = metadata.lastSuccessfulSyncAt,
                now().timeIntervalSince(lastSync) < Self.refreshInterval
            {
                return
            }

            AppDiagnosticsLogger.logger(for: .network)
                .notice("compatibility_index_refresh_start")
            AppDiagnosticsLogger.breadcrumb("compatibility_index_refresh")

            try await refreshTail(fromHighestID: metadata.highestTVMazeID)
            let updatesFinished = try await refreshUpdatedShows(
                since: metadata.lastSuccessfulSyncAt,
                resumeCursor: metadata.updatesResumeCursor
            )
            if updatesFinished {
                try await database.clearUpdatesResumeCursor()
                try await database.setLastSuccessfulSyncAt(now())
                AppDiagnosticsLogger.logger(for: .network)
                    .notice("compatibility_index_refresh_complete")
            } else {
                AppDiagnosticsLogger.logger(for: .network)
                    .notice("compatibility_index_refresh_paused")
                AppDiagnosticsLogger.breadcrumb("compatibility_index_refresh_paused")
            }
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
            try await Task.sleep(for: requestPause)
            try Task.checkCancellation()
        }
    }

    /// Refreshes mappings for shows TVMaze reports as updated since the last sync.
    ///
    /// - Returns: `true` when the updates window is fully drained; `false` when
    ///   work remains and a resume cursor was persisted.
    private func refreshUpdatedShows(
        since lastSync: Date?,
        resumeCursor: CompatibilityIndexUpdatesResumeCursor?
    ) async throws -> Bool {
        let period: TVMazeUpdatePeriod
        if let lastSync {
            period = TVMazeUpdatePeriod.covering(since: lastSync, at: now())
        } else {
            // First on-device sync after install: prefer a bounded window.
            period = .week
        }

        let updates = try await tvMaze.updatedShows(since: period)
        let pending = Self.pendingUpdates(from: updates, resumeCursor: resumeCursor)
        guard !pending.isEmpty else { return true }

        var fetched = 0
        var lastProcessed: CompatibilityIndexUpdatesResumeCursor?
        for item in pending {
            guard fetched < maxShowDetailFetchesPerRefresh else { break }
            do {
                let entry = try await tvMaze.showIndexEntry(id: item.showID)
                try await database.applyMapping(
                    tvMazeID: entry.id,
                    tvdbID: entry.externals?.thetvdb
                )
            } catch TVMazeError.notFound {
                // Show removed from TVMaze — drop any local mapping.
                try await database.removeMappings(forTVMazeID: item.showID)
            }
            lastProcessed = item
            fetched += 1
            try await Task.sleep(for: requestPause)
            try Task.checkCancellation()
        }

        let remaining = pending.count - fetched
        if remaining > 0, let lastProcessed {
            // Pause: keep lastSuccessfulSyncAt unchanged and resume older work next time.
            try await database.setUpdatesResumeCursor(lastProcessed)
            return false
        }

        return true
    }

    /// Newest-first ordering by update timestamp, then show id for stability.
    /// When resuming, keeps only entries strictly older than the stored cursor.
    nonisolated static func pendingUpdates(
        from updates: [Int: Date],
        resumeCursor: CompatibilityIndexUpdatesResumeCursor?
    ) -> [CompatibilityIndexUpdatesResumeCursor] {
        let items = updates.map {
            CompatibilityIndexUpdatesResumeCursor(updatedAt: $0.value, showID: $0.key)
        }
        let filtered: [CompatibilityIndexUpdatesResumeCursor]
        if let resumeCursor {
            filtered = items.filter { Self.isOlderThanCursor($0, resumeCursor) }
        } else {
            filtered = items
        }
        return filtered.sorted { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }
            return lhs.showID > rhs.showID
        }
    }

    nonisolated private static func isOlderThanCursor(
        _ item: CompatibilityIndexUpdatesResumeCursor,
        _ cursor: CompatibilityIndexUpdatesResumeCursor
    ) -> Bool {
        if item.updatedAt != cursor.updatedAt {
            return item.updatedAt < cursor.updatedAt
        }
        return item.showID < cursor.showID
    }
}
