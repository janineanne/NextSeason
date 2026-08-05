//
//  WatchlistRepository.swift
//  NextSeason
//

import Foundation

/// Persistence boundary for saved shows. View models depend on this protocol, not
/// on SwiftData directly (PD-007).
///
/// Production: `SwiftDataWatchlistRepository`. UI tests / previews:
/// `InMemoryWatchlistRepository`.
@MainActor
protocol WatchlistRepository: AnyObject {
    /// All tracked shows, newest `dateAdded` first.
    func all() async throws -> [TrackedShow]
    func trackedShow(showID: Int) async throws -> TrackedShow?
    /// Lightweight ID set for star state / empty-watchlist checks.
    func trackedShowIDs() async throws -> Set<Int>
    func contains(showID: Int) async throws -> Bool
    /// Idempotent insert from a fully loaded `Show`.
    func add(_ show: Show) async throws
    /// No-op when the ID is not present.
    func remove(showID: Int) async throws
    /// Writes refresh / notification-debounce fields onto an existing row.
    func updateAfterRefresh(_ tracked: TrackedShow) async throws
}
