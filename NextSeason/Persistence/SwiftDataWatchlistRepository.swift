//
//  SwiftDataWatchlistRepository.swift
//  NextSeason
//

import Foundation
import os
import SwiftData

@MainActor
final class SwiftDataWatchlistRepository: WatchlistRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() async throws -> [TrackedShow] {
        AppDiagnosticsLogger.logger(for: .persistence).notice("watchlist_read_all start")
        AppDiagnosticsLogger.breadcrumb("watchlist_read_all")
        let descriptor = FetchDescriptor<TrackedShowEntity>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        let result = try context.fetch(descriptor).map { try $0.toDomain() }
        AppDiagnosticsLogger.logger(for: .persistence)
            .notice("watchlist_read_all complete count=\(result.count, privacy: .public)")
        return result
    }

    func contains(showID: Int) async throws -> Bool {
        var descriptor = FetchDescriptor<TrackedShowEntity>(
            predicate: #Predicate { $0.tvMazeID == showID }
        )
        descriptor.fetchLimit = 1
        return try context.fetchCount(descriptor) > 0
    }

    func add(_ show: Show) async throws {
        AppDiagnosticsLogger.logger(for: .persistence)
            .notice("watchlist_write_add show_id=\(show.id, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("watchlist_add:\(show.id)")
        guard try await contains(showID: show.id) == false else { return }
        let tracked = TrackedShow(from: show)
        context.insert(try TrackedShowEntity(tracked: tracked))
        try context.save()
    }

    func remove(showID: Int) async throws {
        AppDiagnosticsLogger.logger(for: .persistence)
            .notice("watchlist_write_remove show_id=\(showID, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("watchlist_remove:\(showID)")
        guard let entity = try entity(for: showID) else { return }
        context.delete(entity)
        try context.save()
    }

    func updateAfterRefresh(_ tracked: TrackedShow) async throws {
        AppDiagnosticsLogger.logger(for: .persistence)
            .notice("watchlist_write_refresh show_id=\(tracked.id, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("watchlist_refresh_write:\(tracked.id)")
        guard let entity = try entity(for: tracked.id) else { return }
        try entity.apply(tracked)
        try context.save()
    }

    private func entity(for showID: Int) throws -> TrackedShowEntity? {
        var descriptor = FetchDescriptor<TrackedShowEntity>(
            predicate: #Predicate { $0.tvMazeID == showID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
