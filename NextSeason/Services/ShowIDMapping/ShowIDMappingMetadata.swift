//
//  ShowIDMappingMetadata.swift
//  NextSeason
//

import Foundation

/// Cursor for a partially drained `/updates/shows` pass (newest-first).
///
/// Remaining work is every update strictly older than this point in
/// `(updatedAt desc, showID desc)` order.
nonisolated struct ShowIDMappingResumeCursor: Equatable, Sendable {
    let updatedAt: Date
    let showID: Int
}

/// Sync / generation metadata stored alongside TVDB↔TVMaze mappings.
nonisolated struct ShowIDMappingMetadata: Equatable, Sendable {
    /// On-disk schema version for the show ID mapping SQLite file.
    var schemaVersion: Int
    /// When the bundled (or fully regenerated) snapshot was produced (UTC).
    var generatedAt: Date?
    /// Highest TVMaze show id represented in the local mapping.
    var highestTVMazeID: Int
    /// Upper watermark of the last fully completed updates sync.
    var lastSuccessfulSyncAt: Date?
    /// Fixed start time of the in-progress sync. Updates after this are deferred
    /// until the next sync so a multi-pass drain cannot skip mid-flight changes.
    var syncHorizonAt: Date?
    /// When set, an updates pass was capped mid-way and should resume next opportunity.
    var updatesResumeCursor: ShowIDMappingResumeCursor?

    /// True while a sync was started but has not yet committed its horizon.
    var hasInProgressSync: Bool {
        syncHorizonAt != nil || updatesResumeCursor != nil
    }

    static let currentSchemaVersion = 2
}
