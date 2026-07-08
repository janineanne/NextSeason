//
//  WatchlistRepository.swift
//  NextSeason
//

import Foundation

/// Persistence boundary for saved shows. View models depend on this protocol, not
/// on SwiftData directly (PD-007).
@MainActor
protocol WatchlistRepository: AnyObject {
    func all() async throws -> [TrackedShow]
    func trackedShow(showID: Int) async throws -> TrackedShow?
    func trackedShowIDs() async throws -> Set<Int>
    func contains(showID: Int) async throws -> Bool
    func add(_ show: Show) async throws
    func remove(showID: Int) async throws
    func updateAfterRefresh(_ tracked: TrackedShow) async throws
}
