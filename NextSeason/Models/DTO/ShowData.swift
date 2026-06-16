//
//  ShowData.swift
//  NextSeason
//

import Foundation

/// Mirrors a TVMaze show object (`/shows/:id` and the `show` field of a search
/// result). Only the fields NextSeason uses are decoded; unknown keys are ignored.
nonisolated struct ShowData: Codable, Sendable {
    let id: Int
    let name: String
    let url: String?
    let status: String?
    let premiered: String?
    let ended: String?
    let summary: String?
    let image: ImageData?
    let network: NetworkData?
    let webChannel: NetworkData?
    let genres: [String]?
    let averageRuntime: Int?
    let updated: Int?
    let embedded: EmbeddedData?

    enum CodingKeys: String, CodingKey {
        case id, name, url, status, premiered, ended, summary, image
        case network, webChannel, genres, averageRuntime, updated
        case embedded = "_embedded"
    }
}
