//
//  SwiftDataWatchlistRepository.swift
//  NextSeason
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataWatchlistRepository: WatchlistRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() async throws -> [TrackedShow] {
        let descriptor = FetchDescriptor<TrackedShowEntity>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    func contains(showID: Int) async throws -> Bool {
        var descriptor = FetchDescriptor<TrackedShowEntity>(
            predicate: #Predicate { $0.tvMazeID == showID }
        )
        descriptor.fetchLimit = 1
        return try context.fetchCount(descriptor) > 0
    }

    func add(_ show: Show) async throws {
        guard try await contains(showID: show.id) == false else { return }
        let tracked = TrackedShow(from: show)
        context.insert(try TrackedShowEntity(tracked: tracked))
        try context.save()
    }

    func remove(showID: Int) async throws {
        guard let entity = try entity(for: showID) else { return }
        context.delete(entity)
        try context.save()
    }

    func updateAfterRefresh(_ tracked: TrackedShow) async throws {
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
