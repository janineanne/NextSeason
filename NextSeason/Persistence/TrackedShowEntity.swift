//
//  TrackedShowEntity.swift
//  NextSeason
//

import Foundation
import SwiftData

@Model
final class TrackedShowEntity {
    @Attribute(.unique) var tvMazeID: Int
    var name: String
    var posterMediumURL: URL?
    var summaryHTML: String?
    var tvMazeURL: URL?
    var statusRaw: String
    var nextSeasonSnapshot: Data
    var sourceUpdatedAt: Date
    var lastCheckedAt: Date
    var lastNotifiedSignature: String?
    var pendingChangeSignature: String?
    var isStale: Bool
    var dateAdded: Date

    init(tracked: TrackedShow) throws {
        self.tvMazeID = tracked.id
        self.name = tracked.name
        self.posterMediumURL = tracked.posterMediumURL
        self.summaryHTML = tracked.summaryHTML
        self.tvMazeURL = tracked.tvMazeURL
        self.statusRaw = tracked.status.persistenceRawValue
        self.nextSeasonSnapshot = try JSONEncoder().encode(tracked.nextSeason)
        self.sourceUpdatedAt = tracked.sourceUpdatedAt
        self.lastCheckedAt = tracked.lastCheckedAt
        self.lastNotifiedSignature = tracked.lastNotifiedSignature
        self.pendingChangeSignature = tracked.pendingChangeSignature
        self.isStale = tracked.isStale
        self.dateAdded = tracked.dateAdded
    }

    func apply(_ tracked: TrackedShow) throws {
        name = tracked.name
        posterMediumURL = tracked.posterMediumURL
        summaryHTML = tracked.summaryHTML
        tvMazeURL = tracked.tvMazeURL
        statusRaw = tracked.status.persistenceRawValue
        nextSeasonSnapshot = try JSONEncoder().encode(tracked.nextSeason)
        sourceUpdatedAt = tracked.sourceUpdatedAt
        lastCheckedAt = tracked.lastCheckedAt
        lastNotifiedSignature = tracked.lastNotifiedSignature
        pendingChangeSignature = tracked.pendingChangeSignature
        isStale = tracked.isStale
    }

    func toDomain() throws -> TrackedShow {
        let nextSeason = try JSONDecoder().decode(NextSeasonStatus.self, from: nextSeasonSnapshot)
        return TrackedShow(
            id: tvMazeID,
            name: name,
            posterMediumURL: posterMediumURL,
            summaryHTML: summaryHTML,
            tvMazeURL: tvMazeURL,
            status: ShowStatus(rawValue: statusRaw),
            nextSeason: nextSeason,
            sourceUpdatedAt: sourceUpdatedAt,
            lastCheckedAt: lastCheckedAt,
            lastNotifiedSignature: lastNotifiedSignature,
            pendingChangeSignature: pendingChangeSignature,
            isStale: isStale,
            dateAdded: dateAdded
        )
    }
}
