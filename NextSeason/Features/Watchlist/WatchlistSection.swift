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

    /// Stable identifier for UserDefaults. Independent of `rawValue` so inserting
    /// a new section in the middle of the enum does not remap saved collapse state.
    var persistenceID: String {
        switch self {
        case .airingNow: "airingNow"
        case .comingSoon: "comingSoon"
        case .waitingForADate: "waitingForADate"
        case .ended: "ended"
        case .unknown: "unknown"
        }
    }

    static func fromPersistenceID(_ id: String) -> WatchlistSection? {
        allCases.first { $0.persistenceID == id }
    }

    var title: String {
        switch self {
        case .airingNow:
            String(localized: "Airing Now")
        case .comingSoon:
            String(localized: "Coming Soon")
        case .waitingForADate:
            String(localized: "Waiting for a Date")
        case .ended:
            String(localized: "Ended")
        case .unknown:
            String(localized: "Unknown")
        }
    }

    /// Collapsed headers include the row count so users can see how many shows
    /// are hidden, e.g. "Ended (4)". Expanded headers stay as the section name.
    func headerTitle(showCount: Int, isExpanded: Bool) -> String {
        if isExpanded {
            title
        } else {
            String(localized: "\(title) (\(showCount))")
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
