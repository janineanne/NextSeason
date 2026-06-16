//
//  Season.swift
//  NextSeason
//

import Foundation

/// A clean, app-facing season. `premiereDate`/`endDate` are nil for an
/// announced-but-unscheduled season.
nonisolated struct Season: Identifiable, Sendable, Hashable {
    let id: Int
    let number: Int
    let premiereDate: Date?
    let endDate: Date?
    let episodeOrder: Int?
}
