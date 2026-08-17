//
//  NextSeasonMigrationPlan.swift
//  NextSeason
//

import Foundation
import SwiftData

/// Schema ladder for the user watchlist store.
///
/// V1 is the baseline that unversioned TestFlight stores are expected to
/// match by entity name and attribute hash. `stages` stays empty until a
/// V2 schema actually ships — do not add a placeholder migration.
nonisolated enum NextSeasonMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NextSeasonSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
