//
//  LocalCompatibilityIndex.swift
//  NextSeason
//

import Foundation

/// Production facade over the writable SQLite compatibility database.
///
/// Copies the bundled snapshot into Application Support on first use. If the
/// writable file is missing or corrupt, it is recreated from the bundle.
actor LocalCompatibilityIndex: TVDBTVMazeCompatibilityIndex {
    private let database: CompatibilityIndexDatabase

    var store: CompatibilityIndexDatabase { database }

    init(database: CompatibilityIndexDatabase) {
        self.database = database
    }

    /// Opens (or recreates) the on-device writable index from the app bundle.
    static func makeDefault(bundle: Bundle = .main) throws -> LocalCompatibilityIndex {
        let writableURL = try CompatibilityIndexDatabase.defaultWritableURL()
        let bundledURL = CompatibilityIndexDatabase.bundledDatabaseURL(bundle: bundle)
        do {
            let database = try CompatibilityIndexDatabase(
                fileURL: writableURL,
                bundledURL: bundledURL
            )
            return LocalCompatibilityIndex(database: database)
        } catch {
            // Corrupt / unreadable writable copy → replace from bundled baseline.
            try CompatibilityIndexDatabase.prepareWritableDatabase(
                at: writableURL,
                bundledURL: bundledURL,
                forceReplace: true
            )
            let database = try CompatibilityIndexDatabase(
                fileURL: writableURL,
                bundledURL: bundledURL
            )
            return LocalCompatibilityIndex(database: database)
        }
    }

    func tvMazeID(forTVDBID id: Int) async -> Int? {
        await database.tvMazeID(forTVDBID: id)
    }

    func recreateFromBundledBaseline() async throws {
        try await database.recreateFromBundledBaseline()
    }
}
