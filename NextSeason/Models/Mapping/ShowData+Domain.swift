//
//  ShowData+Domain.swift
//  NextSeason
//
//  Maps network DTOs into clean domain models. Kept separate so the API shape
//  and the app's model can evolve independently.
//

import Foundation

extension ShowData {
    nonisolated func toDomain() -> Show {
        Show(
            id: id,
            name: name,
            summaryPlainText: summary?.strippingHTMLTags,
            posterMediumURL: image?.medium.flatMap(URL.init(string:)),
            posterOriginalURL: image?.original.flatMap(URL.init(string:)),
            status: ShowStatus(rawValue: status),
            premiered: TVMazeDate.dateOnly(premiered),
            ended: TVMazeDate.dateOnly(ended),
            network: network?.name ?? webChannel?.name,
            genres: genres ?? [],
            averageRuntime: averageRuntime,
            seasons: (embedded?.seasons ?? []).map { $0.toDomain() },
            updatedAt: updated.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? .distantPast
        )
    }
}

extension SeasonData {
    nonisolated func toDomain() -> Season {
        Season(
            id: id,
            number: number,
            premiereDate: TVMazeDate.dateOnly(premiereDate),
            endDate: TVMazeDate.dateOnly(endDate),
            episodeOrder: episodeOrder
        )
    }
}
