//
//  TheTVDBSearchResultData.swift
//  NextSeason
//

import Foundation

/// Envelope for TheTVDB list endpoints (`data` + optional pagination `links`).
///
/// Search returns this shape; other list endpoints share the same wrapper, so
/// the generic keeps decoding reusable if we ever expand beyond search.
nonisolated struct TheTVDBListResponseData<Item: Decodable & Sendable>: Decodable, Sendable {
    let data: [Item]?
    let links: TheTVDBLinksData?
}

/// Pagination metadata from TheTVDB search.
///
/// `next` is informational only — TheTVDB sometimes emits malformed URLs with a
/// duplicated `?`, so callers advance via `offset` arithmetic instead of
/// following `next` literally. `total_items` is the preferred `hasMore` signal
/// when present.
nonisolated struct TheTVDBLinksData: Decodable, Sendable {
    let next: String?
    let totalItems: Int?
    let pageSize: Int?

    enum CodingKeys: String, CodingKey {
        case next
        case totalItems = "total_items"
        case pageSize = "page_size"
    }
}

/// Login response body (`POST /login`).
nonisolated struct TheTVDBLoginResponseData: Decodable, Sendable {
    let data: TheTVDBLoginTokenData?
}

nonisolated struct TheTVDBLoginTokenData: Decodable, Sendable {
    let token: String
}

/// Mirrors a TheTVDB `/search` hit. Only fields NextSeason uses are decoded;
/// unknown keys (translations, overviews, remote ids, etc.) are ignored.
///
/// `tvdb_id` arrives as a string in JSON even though it is numeric.
nonisolated struct TheTVDBSearchResultData: Codable, Sendable {
    let tvdbID: String?
    let name: String?
    let year: String?
    let network: String?
    let status: String?
    let imageURL: String?
    let thumbnail: String?

    enum CodingKeys: String, CodingKey {
        case tvdbID = "tvdb_id"
        case name, year, network, status, thumbnail
        case imageURL = "image_url"
    }
}
