//
//  Show.swift
//  NextSeason
//

import Foundation

/// The app-facing show model. API quirks (HTML summaries, raw date strings,
/// open-ended status) are already resolved here so views never see DTO types.
nonisolated struct Show: Identifiable, Sendable, Hashable {
    let id: Int
    let name: String
    let summaryPlainText: String?
    let posterMediumURL: URL?
    let posterOriginalURL: URL?
    let status: ShowStatus
    let premiered: Date?
    let ended: Date?
    let network: String?
    let genres: [String]
    let averageRuntime: Int?
    let seasons: [Season]
    let updatedAt: Date
}
