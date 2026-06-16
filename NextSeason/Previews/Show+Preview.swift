//
//  Show+Preview.swift
//  NextSeason
//
//  Sample data for SwiftUI previews only.
//

#if DEBUG
import Foundation

extension Show {
    static let preview = Show(
        id: 44933,
        name: "Severance",
        summaryPlainText: "Mark leads a team whose memories are surgically divided between work and personal lives.",
        posterMediumURL: nil,
        posterOriginalURL: nil,
        status: .running,
        premiered: TVMazeDate.dateOnly("2022-02-18"),
        ended: nil,
        network: "Apple TV",
        genres: ["Drama", "Science-Fiction", "Mystery"],
        averageRuntime: 49,
        seasons: [
            Season(id: 1, number: 1, premiereDate: TVMazeDate.dateOnly("2022-02-18"), endDate: TVMazeDate.dateOnly("2022-04-08"), episodeOrder: 9),
            Season(id: 2, number: 2, premiereDate: TVMazeDate.dateOnly("2025-01-17"), endDate: TVMazeDate.dateOnly("2025-03-21"), episodeOrder: 10),
            Season(id: 3, number: 3, premiereDate: nil, endDate: nil, episodeOrder: nil)
        ],
        updatedAt: .now
    )

    static let previewList: [Show] = [
        .preview,
        Show(
            id: 82,
            name: "Game of Thrones",
            summaryPlainText: "Noble families vie for control of the Iron Throne.",
            posterMediumURL: nil,
            posterOriginalURL: nil,
            status: .ended,
            premiered: TVMazeDate.dateOnly("2011-04-17"),
            ended: TVMazeDate.dateOnly("2019-05-19"),
            network: "HBO",
            genres: ["Drama", "Adventure", "Fantasy"],
            averageRuntime: 60,
            seasons: [],
            updatedAt: .now
        )
    ]
}
#endif
