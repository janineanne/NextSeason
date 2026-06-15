//
//  NextEpisode.swift
//  NextSeason
//

import Foundation

/// The show's next scheduled episode, when one exists. `season` indicates which
/// season that upcoming episode belongs to — a useful signal for detecting a new
/// season that doesn't yet have its own dated season row.
nonisolated struct NextEpisode: Sendable, Hashable {
    let season: Int?
    let airdate: Date?
}
