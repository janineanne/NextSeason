//
//  TheTVDBConfiguration.swift
//  NextSeason
//

import Foundation

/// Shared TheTVDB v4 endpoints, credentials, and search page size.
///
/// Search is the only TheTVDB surface in NextSeason; show/season detail,
/// watchlist persistence, and refresh stay on TVMaze. Marked `nonisolated` so
/// actor clients (e.g. `TheTVDBClient`) can use these defaults under the app's
/// default MainActor isolation.
nonisolated enum TheTVDBConfiguration {
    /// API v4 root (`https://api4.thetvdb.com/v4`).
    static let baseURL = URL(string: "https://api4.thetvdb.com/v4")!

    /// Public site used for attribution links (not the API host).
    static let websiteURL = URL(string: "https://www.thetvdb.com")!

    /// Project API key for `POST /login`. The JWT returned by login is cached
    /// on `TheTVDBClient`; this key is never sent as a Bearer token.
    static let apiKey = [REDACTED TVDB API KEY]

    /// Results per search page. TheTVDB paginates with `limit` + `offset`
    /// (not a 1-based page index).
    static let pageSize = 10
}
