//
//  ShowIDMappingDatabase.swift
//  NextSeason
//

import Foundation
import SQLite3

/// Direct SQLite store for TheTVDB → TVMaze show ID mappings.
///
/// Intentionally not SwiftData: the data is relational, tiny, and updated
/// incrementally outside the watchlist persistence stack.
actor ShowIDMappingDatabase: ShowIDMapping {
    nonisolated static let bundledResourceName = "tvdb_tvmaze_show_id_mapping"
    nonisolated static let bundledResourceExtension = "sqlite"
    nonisolated static let writableFileName = "tvdb_tvmaze_show_id_mapping.sqlite"

    /// SQLite handle; `nonisolated(unsafe)` because `OpaquePointer` is not Sendable
    /// and actor `deinit` must close it without hopping.
    nonisolated(unsafe) private var db: OpaquePointer?
    private let fileURL: URL
    private let bundledURL: URL?

    init(fileURL: URL, bundledURL: URL?) throws {
        self.fileURL = fileURL
        self.bundledURL = bundledURL
        try Self.prepareWritableDatabase(at: fileURL, bundledURL: bundledURL)
        let opened = try Self.openDatabase(at: fileURL)
        try Self.migrateIfNeeded(opened)
        db = opened
    }

    /// Opens an already-prepared database file (tests / in-memory setups).
    init(preparedFileURL: URL) throws {
        self.fileURL = preparedFileURL
        self.bundledURL = nil
        let opened = try Self.openDatabase(at: preparedFileURL)
        try Self.migrateIfNeeded(opened)
        db = opened
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    /// Protocol entry point — hops onto the actor, then uses the sync lookup.
    func record(forTVDBID id: Int) async -> ShowIDMappingRecord? {
        lookupRecord(forTVDBID: id)
    }

    func tvdbID(forTVMazeID id: Int) async -> Int? {
        lookupTVDBID(forTVMazeID: id)
    }

    /// Synchronous TheTVDB → TVMaze lookup for callers already on this actor
    /// (refresh writes, recovery). Prefer `record(forTVDBID:)` from outside.
    func lookupRecord(forTVDBID id: Int) -> ShowIDMappingRecord? {
        guard let db else { return nil }
        let sql =
            "SELECT tvmaze_id, name, poster_medium_url FROM mappings WHERE tvdb_id = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        let tvMazeID = Int(sqlite3_column_int64(statement, 0))
        let name = Self.columnText(statement, index: 1)
        let poster = Self.columnText(statement, index: 2).flatMap(URL.init(string:))
        return ShowIDMappingRecord(tvMazeID: tvMazeID, name: name, posterMediumURL: poster)
    }

    /// Synchronous TVMaze → TheTVDB lookup for callers already on this actor.
    func lookupTVDBID(forTVMazeID id: Int) -> Int? {
        guard let db else { return nil }
        let sql = "SELECT tvdb_id FROM mappings WHERE tvmaze_id = ? ORDER BY tvdb_id ASC LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int64(statement, 1, sqlite3_int64(id))
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return Int(sqlite3_column_int64(statement, 0))
    }

    /// Inserts or replaces the mapping keyed by TheTVDB id.
    /// Nil display fields keep any values already stored for this TheTVDB id.
    func upsert(
        tvdbID: Int,
        tvMazeID: Int,
        name: String? = nil,
        posterMediumURL: URL? = nil
    ) throws {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        try execute(
            """
            INSERT INTO mappings(tvdb_id, tvmaze_id, name, poster_medium_url) VALUES(?, ?, ?, ?)
            ON CONFLICT(tvdb_id) DO UPDATE SET
                tvmaze_id = excluded.tvmaze_id,
                name = COALESCE(excluded.name, mappings.name),
                poster_medium_url = COALESCE(excluded.poster_medium_url, mappings.poster_medium_url);
            """,
            bind: { statement in
                sqlite3_bind_int64(statement, 1, sqlite3_int64(tvdbID))
                sqlite3_bind_int64(statement, 2, sqlite3_int64(tvMazeID))
                Self.bindText(
                    statement,
                    index: 3,
                    (trimmedName?.isEmpty == false) ? trimmedName : nil
                )
                Self.bindText(statement, index: 4, posterMediumURL?.absoluteString)
            }
        )
    }

    /// Removes a single TheTVDB → TVMaze row.
    func removeMapping(forTVDBID tvdbID: Int) throws {
        try execute(
            "DELETE FROM mappings WHERE tvdb_id = ?;",
            bind: { statement in
                sqlite3_bind_int64(statement, 1, sqlite3_int64(tvdbID))
            }
        )
    }

    /// Removes every mapping that points at this TVMaze show (0–N TheTVDB ids).
    func removeMappings(forTVMazeID tvMazeID: Int) throws {
        try execute(
            "DELETE FROM mappings WHERE tvmaze_id = ?;",
            bind: { statement in
                sqlite3_bind_int64(statement, 1, sqlite3_int64(tvMazeID))
            }
        )
    }

    /// Reconciles one TVMaze show's external TheTVDB id into the mapping.
    ///
    /// A show can change or lose its TheTVDB external; clear prior rows for
    /// this TVMaze id, then write the current mapping when present.
    func applyMapping(
        tvMazeID: Int,
        tvdbID: Int?,
        name: String? = nil,
        posterMediumURL: URL? = nil
    ) throws {
        try removeMappings(forTVMazeID: tvMazeID)
        if let tvdbID, tvdbID > 0 {
            try upsert(
                tvdbID: tvdbID,
                tvMazeID: tvMazeID,
                name: name,
                posterMediumURL: posterMediumURL
            )
        }
    }

    /// Reads sync / generation meta keys into a single value type.
    func metadata() throws -> ShowIDMappingMetadata {
        ShowIDMappingMetadata(
            schemaVersion: Int(metaValue("schema_version") ?? "")
                ?? ShowIDMappingMetadata.currentSchemaVersion,
            generatedAt: Self.parseDate(metaValue("generated_at")),
            highestTVMazeID: Int(metaValue("highest_tvmaze_id") ?? "") ?? 0,
            lastSuccessfulSyncAt: Self.parseDate(metaValue("last_successful_sync_at")),
            syncHorizonAt: Self.parseDate(metaValue("sync_horizon_at")),
            updatesResumeCursor: updatesResumeCursor()
        )
    }

    /// High-water mark for the `/shows?page=` tail crawl.
    func setHighestTVMazeID(_ value: Int) throws {
        try setMeta(key: "highest_tvmaze_id", value: String(value))
    }

    /// Commits the upper watermark after a fully drained updates pass.
    func setLastSuccessfulSyncAt(_ date: Date) throws {
        try setMeta(key: "last_successful_sync_at", value: Self.formatDate(date))
    }

    /// Records when the bundled (or fully regenerated) snapshot was produced.
    func setGeneratedAt(_ date: Date) throws {
        try setMeta(key: "generated_at", value: Self.formatDate(date))
    }

    /// Pins the in-progress sync start so mid-flight updates are deferred.
    func setSyncHorizonAt(_ date: Date) throws {
        try setMeta(key: "sync_horizon_at", value: Self.formatDate(date))
    }

    /// Clears the in-progress horizon after a successful commit (or abort cleanup).
    func clearSyncHorizonAt() throws {
        try setMeta(key: "sync_horizon_at", value: "")
    }

    /// Persists where a rate-limited updates drain should resume next opportunity.
    func setUpdatesResumeCursor(_ cursor: ShowIDMappingResumeCursor) throws {
        try setMeta(key: "updates_resume_at", value: Self.formatDate(cursor.updatedAt))
        try setMeta(key: "updates_resume_show_id", value: String(cursor.showID))
    }

    /// Clears a partial updates drain cursor.
    func clearUpdatesResumeCursor() throws {
        try setMeta(key: "updates_resume_at", value: "")
        try setMeta(key: "updates_resume_show_id", value: "")
    }

    /// Clears in-progress sync markers after a horizon is successfully committed.
    func clearInProgressSyncState() throws {
        try clearUpdatesResumeCursor()
        try clearSyncHorizonAt()
    }

    private func updatesResumeCursor() -> ShowIDMappingResumeCursor? {
        guard let updatedAt = Self.parseDate(metaValue("updates_resume_at")),
            let showID = Int(metaValue("updates_resume_show_id") ?? "")
        else {
            return nil
        }
        return ShowIDMappingResumeCursor(updatedAt: updatedAt, showID: showID)
    }

    /// Closes the SQLite handle. Used by tests before replacing files on disk.
    func close() {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    /// Replaces the writable database from the bundled baseline after corruption.
    func recreateFromBundledBaseline() throws {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
        try Self.prepareWritableDatabase(
            at: fileURL,
            bundledURL: bundledURL,
            forceReplace: true
        )
        let opened = try Self.openDatabase(at: fileURL)
        try Self.migrateIfNeeded(opened)
        db = opened
    }

    // MARK: - File bootstrap

    /// Opens the on-device mapping database at the default Application Support
    /// location, copying the bundled baseline if needed.
    ///
    /// If the first open fails, replaces the writable file from the bundled
    /// baseline (or empty schema) and retries once. A second failure is thrown.
    nonisolated static func openDefault() throws -> ShowIDMappingDatabase {
        try open(fileURL: defaultWritableURL(), bundledURL: bundledDatabaseURL())
    }

    /// Opens a mapping database at `fileURL`, copying from `bundledURL` if needed.
    ///
    /// If the first open fails, replaces the writable file from the bundled
    /// baseline (or empty schema) and retries once. A second failure is thrown.
    nonisolated static func open(
        fileURL: URL,
        bundledURL: URL?
    ) throws -> ShowIDMappingDatabase {
        do {
            return try ShowIDMappingDatabase(
                fileURL: fileURL,
                bundledURL: bundledURL
            )
        } catch {
            try prepareWritableDatabase(
                at: fileURL,
                bundledURL: bundledURL,
                forceReplace: true
            )
            return try ShowIDMappingDatabase(
                fileURL: fileURL,
                bundledURL: bundledURL
            )
        }
    }

    /// Application Support path for the mutable on-device copy of the mapping.
    nonisolated static func defaultWritableURL(
        fileManager: FileManager = .default
    ) throws -> URL {
        let folder = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("ShowIDMapping", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(writableFileName)
    }

    /// Locates the read-only bundled baseline; tries a few resource layouts so
    /// Xcode folder references and flat copies both resolve.
    nonisolated static func bundledDatabaseURL(
        bundle: Bundle = .main
    ) -> URL? {
        bundle.url(
            forResource: bundledResourceName,
            withExtension: bundledResourceExtension,
            subdirectory: "Resources/ShowIDMapping"
        )
            ?? bundle.url(
                forResource: bundledResourceName,
                withExtension: bundledResourceExtension,
                subdirectory: "ShowIDMapping"
            )
            ?? bundle.url(
                forResource: bundledResourceName,
                withExtension: bundledResourceExtension
            )
    }

    /// Ensures a writable SQLite file exists at `fileURL`.
    ///
    /// Reuses an existing readable file, replaces a corrupt one, copies the
    /// bundled baseline when available, or creates an empty schema otherwise.
    /// `forceReplace` is the recovery path after open failures.
    nonisolated static func prepareWritableDatabase(
        at fileURL: URL,
        bundledURL: URL?,
        forceReplace: Bool = false,
        fileManager: FileManager = .default
    ) throws {
        let folder = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        if forceReplace, fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }

        if fileManager.fileExists(atPath: fileURL.path), !forceReplace {
            if isReadableDatabase(at: fileURL) {
                if bundledURL != nil {
                    let version = storedSchemaVersion(at: fileURL) ?? 0
                    if version == ShowIDMappingMetadata.currentSchemaVersion {
                        return
                    }
                    // Schema bump — replace from the bundled snapshot so Search
                    // gets TVMaze titles/posters instead of empty new columns.
                    try fileManager.removeItem(at: fileURL)
                } else {
                    return
                }
            } else {
                // Unreadable / truncated file — drop it and fall through to copy/create.
                try fileManager.removeItem(at: fileURL)
            }
        }

        guard let bundledURL else {
            try createEmptyDatabase(at: fileURL)
            return
        }

        try fileManager.copyItem(at: bundledURL, to: fileURL)
        // Ensure the Application Support copy is writable even if the bundle
        // resource was copied with restrictive permissions.
        try fileManager.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: fileURL.path
        )
    }

    /// Creates a minimal empty mapping database (schema + default meta) when no bundled
    /// baseline is available — Search simply finds no actionable hits until refresh.
    nonisolated static func createEmptyDatabase(at fileURL: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK, let db else {
            throw ShowIDMappingError.sqlite("Unable to create empty show ID mapping database")
        }
        defer { sqlite3_close(db) }
        try exec(
            db,
            """
            CREATE TABLE IF NOT EXISTS meta (
                key TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS mappings (
                tvdb_id INTEGER PRIMARY KEY NOT NULL,
                tvmaze_id INTEGER NOT NULL,
                name TEXT,
                poster_medium_url TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_mappings_tvmaze_id ON mappings(tvmaze_id);
            """
        )
        try exec(
            db,
            """
            INSERT OR REPLACE INTO meta(key, value) VALUES('schema_version', '\(ShowIDMappingMetadata.currentSchemaVersion)');
            INSERT OR REPLACE INTO meta(key, value) VALUES('generated_at', '');
            INSERT OR REPLACE INTO meta(key, value) VALUES('highest_tvmaze_id', '0');
            INSERT OR REPLACE INTO meta(key, value) VALUES('last_successful_sync_at', '');
            INSERT OR REPLACE INTO meta(key, value) VALUES('source', 'TVMaze');
            INSERT OR REPLACE INTO meta(key, value) VALUES('license', 'CC BY-SA');
            """
        )
    }

    nonisolated private static func isReadableDatabase(at fileURL: URL) -> Bool {
        var db: OpaquePointer?
        guard sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
            let db
        else {
            return false
        }
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='mappings';"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_ROW
    }

    nonisolated private static func openDatabase(at fileURL: URL) throws -> OpaquePointer {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(fileURL.path, &db, flags, nil) == SQLITE_OK, let db else {
            throw ShowIDMappingError.sqlite("Unable to open show ID mapping database")
        }
        return db
    }

    // MARK: - Internals

    /// Ensures `meta` / `mappings` exist, adds display columns on older files,
    /// and records the current schema version.
    nonisolated private static func migrateIfNeeded(_ db: OpaquePointer) throws {
        try exec(
            db,
            """
            CREATE TABLE IF NOT EXISTS meta (
                key TEXT PRIMARY KEY NOT NULL,
                value TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS mappings (
                tvdb_id INTEGER PRIMARY KEY NOT NULL,
                tvmaze_id INTEGER NOT NULL,
                name TEXT,
                poster_medium_url TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_mappings_tvmaze_id ON mappings(tvmaze_id);
            """
        )
        if !mappingsHasColumn(db, "name") {
            try exec(db, "ALTER TABLE mappings ADD COLUMN name TEXT;")
        }
        if !mappingsHasColumn(db, "poster_medium_url") {
            try exec(db, "ALTER TABLE mappings ADD COLUMN poster_medium_url TEXT;")
        }
        try writeMetaValue(
            db,
            key: "schema_version",
            value: String(ShowIDMappingMetadata.currentSchemaVersion)
        )
    }

    nonisolated private static func storedSchemaVersion(at fileURL: URL) -> Int? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
            let db
        else {
            return nil
        }
        defer { sqlite3_close(db) }
        guard let raw = readMetaValue(db, key: "schema_version") else { return nil }
        return Int(raw)
    }

    nonisolated private static func mappingsHasColumn(_ db: OpaquePointer, _ name: String) -> Bool {
        var statement: OpaquePointer?
        guard
            sqlite3_prepare_v2(db, "PRAGMA table_info(mappings);", -1, &statement, nil)
                == SQLITE_OK
        else {
            return false
        }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let cString = sqlite3_column_text(statement, 1) else { continue }
            if String(cString: cString) == name { return true }
        }
        return false
    }

    nonisolated private static func bindText(
        _ statement: OpaquePointer?,
        index: Int32,
        _ value: String?
    ) {
        guard let value else {
            sqlite3_bind_null(statement, index)
            return
        }
        sqlite3_bind_text(
            statement, index, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
    }

    nonisolated private static func columnText(_ statement: OpaquePointer?, index: Int32) -> String?
    {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        let value = String(cString: cString)
        return value.isEmpty ? nil : value
    }

    nonisolated private static func readMetaValue(_ db: OpaquePointer, key: String) -> String? {
        let sql = "SELECT value FROM meta WHERE key = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(
            statement, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        guard let cString = sqlite3_column_text(statement, 0) else { return nil }
        return String(cString: cString)
    }

    nonisolated private static func writeMetaValue(
        _ db: OpaquePointer,
        key: String,
        value: String
    ) throws {
        let sql =
            "INSERT INTO meta(key, value) VALUES(?, ?) "
            + "ON CONFLICT(key) DO UPDATE SET value = excluded.value;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ShowIDMappingError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(
            statement, 1, key, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(
            statement, 2, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw ShowIDMappingError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
    }

    private func metaValue(_ key: String) -> String? {
        guard let db else { return nil }
        return Self.readMetaValue(db, key: key)
    }

    private func setMeta(key: String, value: String) throws {
        guard let db else { throw ShowIDMappingError.sqlite("Database is closed") }
        try Self.writeMetaValue(db, key: key, value: value)
    }

    private func execute(
        _ sql: String,
        bind: ((OpaquePointer?) -> Void)? = nil
    ) throws {
        guard let db else { throw ShowIDMappingError.sqlite("Database is closed") }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw ShowIDMappingError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        bind?(statement)
        let step = sqlite3_step(statement)
        // Multi-statement scripts use exec instead; single statements end at DONE.
        guard step == SQLITE_DONE || step == SQLITE_ROW else {
            throw ShowIDMappingError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
    }

    nonisolated private static func exec(_ db: OpaquePointer, _ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let message = errorMessage.map { String(cString: $0) } ?? "SQLite error"
            sqlite3_free(errorMessage)
            throw ShowIDMappingError.sqlite(message)
        }
    }

    nonisolated private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    nonisolated private static func formatDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

/// Failures opening, preparing, or mutating the show ID mapping SQLite store.
///
/// Surfaced to launch-time recovery and tests; Search treats a missing
/// mapping as “not actionable” rather than throwing these errors.
enum ShowIDMappingError: Error, LocalizedError {
    /// Low-level SQLite prepare / step / exec failure (message from `sqlite3_errmsg`).
    case sqlite(String)
    /// Bundled baseline resource could not be located in the app bundle.
    case missingBundledDatabase

    var errorDescription: String? {
        switch self {
        case .sqlite(let message):
            return message
        case .missingBundledDatabase:
            return "Bundled show ID mapping database is missing."
        }
    }
}
