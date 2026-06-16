//
//  TrackedShow.swift
//  NextSeason
//

import Foundation

/// A show the user is monitoring for next-season changes. Stored on-device only.
nonisolated struct TrackedShow: Identifiable, Sendable, Hashable {
    let id: Int
    var name: String
    var posterMediumURL: URL?
    var summaryHTML: String?
    var tvMazeURL: URL?
    var status: ShowStatus
    var nextSeason: NextSeasonStatus
    var sourceUpdatedAt: Date
    var lastCheckedAt: Date
    var lastNotifiedSignature: String?
    /// When a non-date-backed change is first seen, holds its signature until a
    /// second poll confirms it (PD-008 debounce).
    var pendingChangeSignature: String?
    /// True when TVMaze no longer returns this show (merged/deleted).
    var isStale: Bool
    var dateAdded: Date

    init(
        id: Int,
        name: String,
        posterMediumURL: URL?,
        summaryHTML: String? = nil,
        tvMazeURL: URL? = nil,
        status: ShowStatus,
        nextSeason: NextSeasonStatus,
        sourceUpdatedAt: Date,
        lastCheckedAt: Date,
        lastNotifiedSignature: String? = nil,
        pendingChangeSignature: String? = nil,
        isStale: Bool = false,
        dateAdded: Date
    ) {
        self.id = id
        self.name = name
        self.posterMediumURL = posterMediumURL
        self.summaryHTML = summaryHTML
        self.tvMazeURL = tvMazeURL
        self.status = status
        self.nextSeason = nextSeason
        self.sourceUpdatedAt = sourceUpdatedAt
        self.lastCheckedAt = lastCheckedAt
        self.lastNotifiedSignature = lastNotifiedSignature
        self.pendingChangeSignature = pendingChangeSignature
        self.isStale = isStale
        self.dateAdded = dateAdded
    }

    /// Builds a tracked row from a fully-loaded show at save time.
    init(from show: Show, now: Date = .now) {
        self.init(
            id: show.id,
            name: show.name,
            posterMediumURL: show.posterMediumURL,
            summaryHTML: show.summaryHTML,
            tvMazeURL: show.tvMazeURL,
            status: show.status,
            nextSeason: NextSeasonCalculator.status(for: show, now: now),
            sourceUpdatedAt: show.updatedAt,
            lastCheckedAt: now,
            dateAdded: now
        )
    }
}

extension Show {
    /// A lightweight show for navigation from the watchlist; detail reloads full data.
    init(tracked: TrackedShow) {
        self.init(
            id: tracked.id,
            name: tracked.name,
            tvMazeURL: tracked.tvMazeURL,
            summaryHTML: tracked.summaryHTML,
            posterMediumURL: tracked.posterMediumURL,
            posterOriginalURL: nil,
            status: tracked.status,
            premiered: nil,
            ended: nil,
            network: nil,
            genres: [],
            averageRuntime: nil,
            seasons: [],
            nextEpisode: nil,
            updatedAt: tracked.sourceUpdatedAt
        )
    }
}
