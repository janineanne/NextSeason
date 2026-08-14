//
//  ShowIndexEntryData.swift
//  NextSeason
//

import Foundation

/// TVMaze show payload from `/shows?page=` (and `/shows/:id` for refresh).
///
/// Id + externals drive the TheTVDB mapping; name and medium poster are stored
/// so Search can overlay TVMaze display fields without a live show fetch.
nonisolated struct ShowIndexEntryData: Codable, Sendable, Equatable {
    let id: Int
    let name: String?
    let image: ImageData?
    let externals: ShowExternalsData?

    init(
        id: Int,
        name: String? = nil,
        image: ImageData? = nil,
        externals: ShowExternalsData? = nil
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.externals = externals
    }

    // We intentionally store only the medium poster URL.
    // Search results never display original-resolution artwork, so
    // storing larger URLs would increase database size with no benefit.
    var posterMediumURL: URL? {
        image?.medium.flatMap(URL.init(string:))
    }
}

/// External ids attached to a TVMaze show (show ID mapping uses `thetvdb`).
nonisolated struct ShowExternalsData: Codable, Sendable, Equatable {
    let thetvdb: Int?
}
