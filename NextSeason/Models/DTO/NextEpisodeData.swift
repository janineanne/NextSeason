//
//  NextEpisodeData.swift
//  NextSeason
//

import Foundation

/// The `nextepisode` embed: the show's upcoming scheduled episode, if any.
/// `season` indicates which season that episode belongs to.
nonisolated struct NextEpisodeData: Codable, Sendable {
    let id: Int?
    let season: Int?
    let number: Int?
    let name: String?
    let airdate: String?
    let airstamp: String?
}
