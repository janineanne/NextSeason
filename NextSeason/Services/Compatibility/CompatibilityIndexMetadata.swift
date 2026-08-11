//
//  CompatibilityIndexMetadata.swift
//  NextSeason
//

import Foundation

/// Sync / generation metadata stored alongside TVDB↔TVMaze mappings.
nonisolated struct CompatibilityIndexMetadata: Equatable, Sendable {
    /// On-disk schema version for the compatibility SQLite file.
    var schemaVersion: Int
    /// When the bundled (or fully regenerated) snapshot was produced (UTC).
    var generatedAt: Date?
    /// Highest TVMaze show id represented in the local index.
    var highestTVMazeID: Int
    /// Last time an on-device incremental refresh completed successfully.
    var lastSuccessfulSyncAt: Date?

    static let currentSchemaVersion = 1
}
