//
//  InMemoryShowIDMapping.swift
//  NextSeason
//

import Foundation

/// Mutable in-memory show ID map for unit tests and UI-test stubs.
actor InMemoryShowIDMapping: ShowIDMapping {
    private var records: [Int: ShowIDMappingRecord]
    private(set) var metadata: ShowIDMappingMetadata

    /// Id-only map; display fields start empty (typical UI-test stub).
    init(
        map: [Int: Int] = [:],
        metadata: ShowIDMappingMetadata = ShowIDMappingMetadata(
            schemaVersion: ShowIDMappingMetadata.currentSchemaVersion,
            generatedAt: nil,
            highestTVMazeID: 0,
            lastSuccessfulSyncAt: nil,
            syncHorizonAt: nil,
            updatesResumeCursor: nil
        )
    ) {
        self.records = map.mapValues {
            ShowIDMappingRecord(tvMazeID: $0, name: nil, posterMediumURL: nil)
        }
        self.metadata = metadata
    }

    /// Pre-seeded records including TVMaze title/poster (overlay tests).
    init(
        records: [Int: ShowIDMappingRecord],
        metadata: ShowIDMappingMetadata = ShowIDMappingMetadata(
            schemaVersion: ShowIDMappingMetadata.currentSchemaVersion,
            generatedAt: nil,
            highestTVMazeID: 0,
            lastSuccessfulSyncAt: nil,
            syncHorizonAt: nil,
            updatesResumeCursor: nil
        )
    ) {
        self.records = records
        self.metadata = metadata
    }

    func record(forTVDBID id: Int) async -> ShowIDMappingRecord? {
        records[id]
    }

    /// Inserts or replaces a mapping and bumps `highestTVMazeID` when needed.
    /// Nil display fields keep any values already stored for this TheTVDB id.
    func upsert(
        tvdbID: Int,
        tvMazeID: Int,
        name: String? = nil,
        posterMediumURL: URL? = nil
    ) {
        let existing = records[tvdbID]
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        records[tvdbID] = ShowIDMappingRecord(
            tvMazeID: tvMazeID,
            name: (trimmedName?.isEmpty == false) ? trimmedName : existing?.name,
            posterMediumURL: posterMediumURL ?? existing?.posterMediumURL
        )
        if tvMazeID > metadata.highestTVMazeID {
            metadata.highestTVMazeID = tvMazeID
        }
    }

    func removeMapping(forTVDBID tvdbID: Int) {
        records.removeValue(forKey: tvdbID)
    }

    func removeMappings(forTVMazeID tvMazeID: Int) {
        records = records.filter { $0.value.tvMazeID != tvMazeID }
    }

    /// Same clear-then-upsert semantics as `ShowIDMappingDatabase.applyMapping`.
    func applyMapping(
        tvMazeID: Int,
        tvdbID: Int?,
        name: String? = nil,
        posterMediumURL: URL? = nil
    ) {
        removeMappings(forTVMazeID: tvMazeID)
        if let tvdbID, tvdbID > 0 {
            upsert(
                tvdbID: tvdbID,
                tvMazeID: tvMazeID,
                name: name,
                posterMediumURL: posterMediumURL
            )
        }
    }

    func setLastSuccessfulSyncAt(_ date: Date) {
        metadata.lastSuccessfulSyncAt = date
    }

    func setHighestTVMazeID(_ value: Int) {
        metadata.highestTVMazeID = value
    }

    /// Snapshot of TheTVDB → TVMaze ids for test assertions.
    func allMappings() -> [Int: Int] {
        records.mapValues(\.tvMazeID)
    }
}
