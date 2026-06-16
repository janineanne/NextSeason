//
//  NextSeasonStatus.swift
//  NextSeason
//

import Foundation

/// The app's answer to "is there a next season, and when?", derived by
/// `NextSeasonCalculator` from a show's status, seasons, and next episode.
nonisolated enum NextSeasonStatus: Sendable, Hashable {
    /// The most recent season is currently airing / just released.
    case airing(season: Int)
    /// A not-yet-aired season has a known future premiere date.
    case scheduled(season: Int, premiere: Date)
    /// A future season exists in the data but has no premiere date yet.
    case announcedUndated(season: Int)
    /// The show is returning but no next-season row exists yet.
    case returningNoSeasonYet
    /// The show has ended with nothing upcoming.
    case ended
    /// Not enough information to decide.
    case unknown
}
