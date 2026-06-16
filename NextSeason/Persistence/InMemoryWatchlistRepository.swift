//
//  InMemoryWatchlistRepository.swift
//  NextSeason
//

import Foundation

/// Test and preview double for `WatchlistRepository`.
@MainActor
final class InMemoryWatchlistRepository: WatchlistRepository {
    private var shows: [Int: TrackedShow] = [:]

    func all() async throws -> [TrackedShow] {
        shows.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    func contains(showID: Int) async throws -> Bool {
        shows[showID] != nil
    }

    func add(_ show: Show) async throws {
        guard shows[show.id] == nil else { return }
        let tracked = TrackedShow(from: show)
        shows[show.id] = tracked
    }

    func remove(showID: Int) async throws {
        shows.removeValue(forKey: showID)
    }

    func updateAfterRefresh(_ tracked: TrackedShow) async throws {
        shows[tracked.id] = tracked
    }
}
