//
//  NextSeasonModelContainer.swift
//  NextSeason
//

import Foundation
import SwiftData

/// Shared `ModelContainer` construction for production, UI tests, and
/// persistence tests.
///
/// Always opens `NextSeasonSchemaV1` with `NextSeasonMigrationPlan`.
/// Production must keep SwiftData's default store URL so existing
/// Application Support `default.store` files remain the store that is opened.
enum NextSeasonModelContainer {
    static func make(configuration: ModelConfiguration = ModelConfiguration()) throws
        -> ModelContainer
    {
        let schema = Schema(versionedSchema: NextSeasonSchemaV1.self)
        return try ModelContainer(
            for: schema,
            migrationPlan: NextSeasonMigrationPlan.self,
            configurations: configuration
        )
    }
}
