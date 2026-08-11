//
//  CompatibilityIndexMetadata.swift
//  NextSeason
//

import Foundation

/// Cursor for a partially drained `/updates/shows` pass (newest-first).
///
/// Remaining work is every update strictly older than this point in
/// `(updatedAt desc, showID desc)` order.
nonisolated struct CompatibilityIndexUpdatesResumeCursor: Equatable, Sendable {
    let updatedAt: Date
    let showID: Int
}

/// Sync / generation metadata stored alongside TVDB↔TVMaze mappings.
nonisolated struct CompatibilityIndexMetadata: Equatable, Sendable {
    /// On-disk schema version for the compatibility SQLite file.
    var schemaVersion: Int
    /// When the bundled (or fully regenerated) snapshot was produced (UTC).
    var generatedAt: Date?
    /// Highest TVMaze show id represented in the local index.
    var highestTVMazeID: Int
    /// Last time an on-device incremental refresh completed successfully end-to-end.
    var lastSuccessfulSyncAt: Date?
    /// When set, an updates pass was capped mid-way and should resume next opportunity.
    var updatesResumeCursor: CompatibilityIndexUpdatesResumeCursor?

    static let currentSchemaVersion = 1
}
