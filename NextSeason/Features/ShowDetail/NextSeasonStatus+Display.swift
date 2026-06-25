//
//  NextSeasonStatus+Display.swift
//  NextSeason
//

import SwiftUI

/// User-facing presentation for `NextSeasonStatus`. Kept in the feature layer so
/// the domain enum stays free of display concerns.
extension NextSeasonStatus {
    var headline: String {
        switch self {
        case .airing(let season):
            "Currently showing Season \(season)"
        case .scheduled(let season, let premiere):
            "Season \(season) premieres \(premiere.formatted(date: .abbreviated, time: .omitted))"
        case .announcedUndated(let season):
            "Season \(season) announced — date to be confirmed"
        case .returningNoSeasonYet:
            "Returning — no next season announced yet"
        case .ended:
            "Ended — no next season expected"
        case .unknown:
            "Next season status unknown"
        }
    }

    var statusSymbolName: String {
        switch self {
        case .airing:
            "play.tv"
        case .scheduled:
            "calendar"
        case .announcedUndated:
            "calendar.badge.clock"
        case .returningNoSeasonYet:
            "arrow.clockwise"
        case .ended:
            "checkmark.circle"
        case .unknown:
            "questionmark.circle"
        }
    }

    /// Tint for the status icon and headline on show detail.
    var emphasisColor: Color {
        switch self {
        case .scheduled, .airing:
            Color.accentColor
        case .announcedUndated, .returningNoSeasonYet, .unknown:
            Color.appMutedText
        case .ended:
            Color.appMutedText.opacity(0.85)
        }
    }
}
