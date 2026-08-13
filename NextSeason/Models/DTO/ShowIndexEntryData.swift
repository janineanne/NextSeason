//
//  ShowIndexEntryData.swift
//  NextSeason
//

import Foundation

/// Minimal TVMaze show payload from `/shows?page=` (and `/shows/:id` for refresh).
///
/// Only id + externals are needed for the show ID mapping.
nonisolated struct ShowIndexEntryData: Codable, Sendable, Equatable {
    let id: Int
    let externals: ShowExternalsData?
}

/// External ids attached to a TVMaze show (show ID mapping uses `thetvdb`).
nonisolated struct ShowExternalsData: Codable, Sendable, Equatable {
    let thetvdb: Int?
}
