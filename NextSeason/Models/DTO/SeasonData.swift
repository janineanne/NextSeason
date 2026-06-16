//
//  SeasonData.swift
//  NextSeason
//

import Foundation

/// A season entry from `/shows/:id/seasons` or the `seasons` embed.
/// Dates and `episodeOrder` are null for announced-but-unscheduled seasons.
nonisolated struct SeasonData: Codable, Sendable {
    let id: Int
    let number: Int
    let premiereDate: String?
    let endDate: String?
    let episodeOrder: Int?
}
