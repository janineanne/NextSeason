//
//  ShowSearchResultData.swift
//  NextSeason
//

import Foundation

/// One entry from `/search/shows`: a relevance score plus the full show object.
nonisolated struct ShowSearchResultData: Codable, Sendable {
    let score: Double
    let show: ShowData
}
