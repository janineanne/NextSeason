//
//  InMemoryCompatibilityIndex.swift
//  NextSeason
//

import Foundation

/// Mutable in-memory compatibility map for unit tests and UI-test stubs.
actor InMemoryCompatibilityIndex: TVDBTVMazeCompatibilityIndex {
    private var map: [Int: Int]
    private(set) var metadata: CompatibilityIndexMetadata

    init(
        map: [Int: Int] = [:],
        metadata: CompatibilityIndexMetadata = CompatibilityIndexMetadata(
            schemaVersion: CompatibilityIndexMetadata.currentSchemaVersion,
            generatedAt: nil,
            highestTVMazeID: 0,
            lastSuccessfulSyncAt: nil,
            syncHorizonAt: nil,
            updatesResumeCursor: nil
        )
    ) {
        self.map = map
        self.metadata = metadata
    }

    func tvMazeID(forTVDBID id: Int) async -> Int? {
        map[id]
    }

    /// Inserts or replaces a mapping and bumps `highestTVMazeID` when needed.
    func upsert(tvdbID: Int, tvMazeID: Int) {
        map[tvdbID] = tvMazeID
        if tvMazeID > metadata.highestTVMazeID {
            metadata.highestTVMazeID = tvMazeID
        }
    }

    func removeMapping(forTVDBID tvdbID: Int) {
        map.removeValue(forKey: tvdbID)
    }

    func removeMappings(forTVMazeID tvMazeID: Int) {
        map = map.filter { $0.value != tvMazeID }
    }

    /// Same clear-then-upsert semantics as `CompatibilityIndexDatabase.applyMapping`.
    func applyMapping(tvMazeID: Int, tvdbID: Int?) {
        removeMappings(forTVMazeID: tvMazeID)
        if let tvdbID, tvdbID > 0 {
            upsert(tvdbID: tvdbID, tvMazeID: tvMazeID)
        }
    }

    func setLastSuccessfulSyncAt(_ date: Date) {
        metadata.lastSuccessfulSyncAt = date
    }

    func setHighestTVMazeID(_ value: Int) {
        metadata.highestTVMazeID = value
    }

    /// Snapshot of the full map for test assertions.
    func allMappings() -> [Int: Int] {
        map
    }
}
