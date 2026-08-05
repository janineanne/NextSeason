//
//  WatchlistSection.swift
//  NextSeason
//

import Foundation

/// Watchlist list grouping derived from each show's stored `NextSeasonStatus`.
enum WatchlistSection: Int, CaseIterable, Identifiable, Sendable {
    case airingNow
    case comingSoon
    case waitingForADate
    case ended
    case unknown

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .airingNow:
            "Airing Now"
        case .comingSoon:
            "Coming Soon"
        case .waitingForADate:
            "Waiting for a Date"
        case .ended:
            "Ended"
        case .unknown:
            "Unknown"
        }
    }

    /// Maps a stored next-season status onto the watchlist section that lists it.
    static func section(for status: NextSeasonStatus) -> WatchlistSection {
        switch status {
        case .airing:
            .airingNow
        case .scheduled:
            .comingSoon
        case .announcedUndated, .returningNoSeasonYet:
            .waitingForADate
        case .ended:
            .ended
        case .unknown:
            .unknown
        }
    }
}

/// A non-empty watchlist section ready for display.
struct WatchlistSectionGroup: Identifiable, Equatable, Sendable {
    let section: WatchlistSection
    let shows: [TrackedShow]

    var id: WatchlistSection { section }
}
