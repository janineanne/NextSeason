//
//  EmbeddedData.swift
//  NextSeason
//

import Foundation

/// The `_embedded` container returned when requesting embeds on a show.
nonisolated struct EmbeddedData: Codable, Sendable {
    let seasons: [SeasonData]?
    let nextepisode: NextEpisodeData?
}
