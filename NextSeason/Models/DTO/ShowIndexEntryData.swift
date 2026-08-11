//
//  ShowIndexEntryData.swift
//  NextSeason
//

import Foundation

/// Minimal TVMaze show payload from `/shows?page=` (and `/shows/:id` for refresh).
///
/// Only id + externals are needed for the compatibility index.
nonisolated struct ShowIndexEntryData: Codable, Sendable, Equatable {
    let id: Int
    let externals: ShowExternalsData?
}

/// External ids attached to a TVMaze show.
nonisolated struct ShowExternalsData: Codable, Sendable, Equatable {
    let thetvdb: Int?
    let imdb: String?
    let tvrage: Int?
}
