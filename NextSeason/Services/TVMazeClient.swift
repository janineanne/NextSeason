//
//  TVMazeClient.swift
//  NextSeason
//

import Foundation
import os

/// Live `TVMazeService` backed by the public TVMaze REST API.
///
/// An `actor` so networking and JSON decoding run off the main actor. Requests
/// carry a descriptive User-Agent (per TVMaze guidance) and retry once on a
/// 429 rate-limit response.
actor TVMazeClient: TVMazeService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let userAgent: String
    private let baseURL = URL(string: "https://api.tvmaze.com")!
    private let maxRetries = 1

    init(session: URLSession = TVMazeClient.makeCachingSession()) {
        self.session = session
        let version =
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? "1.0"
        self.userAgent = "NextSeason/\(version)"
    }

    /// A session with a dedicated, modestly-sized cache. TVMaze sends
    /// `Cache-Control: public, max-age=3600`, so honoring the protocol cache lets
    /// repeat lookups (e.g. revisiting a show) skip the network for up to an hour.
    /// Isolated from `URLCache.shared` so its sizing is intentional and tunable.
    private static func makeCachingSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }

    /// `GET /search/shows?q=` — empty / whitespace query short-circuits to `[]`.
    func searchShows(matching query: String) async throws -> [Show] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        AppDiagnosticsLogger.logger(for: .network)
            .notice("search_start query_length=\(trimmed.count, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("network_search")
        let searchStarted = Date.now

        var components = URLComponents(
            url: baseURL.appending(path: "search/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        let results: [ShowSearchResultData] = try await get(components)
        let shows = results.map { $0.show.toDomain() }

        let elapsedMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
        AppDiagnosticsLogger.logger(for: .network)
            .notice(
                "search_complete result_count=\(shows.count, privacy: .public) duration_ms=\(elapsedMs, privacy: .public)"
            )
        return shows
    }

    /// `GET /lookup/shows?thetvdb=` — bridges a TheTVDB search hit to TVMaze.
    ///
    /// TVMaze responds with HTTP 301 to the canonical `/shows/:id` URL;
    /// `URLSession` follows the redirect and we decode the final show body.
    /// Used when Search's local show ID mapping is missing or stale.
    func lookupShow(theTVDBID: Int) async throws -> Show {
        AppDiagnosticsLogger.logger(for: .network)
            .notice("lookup_thetvdb_start tvdb_id=\(theTVDBID, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("network_lookup_thetvdb:\(theTVDBID)")
        var components = URLComponents(
            url: baseURL.appending(path: "lookup/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "thetvdb", value: String(theTVDBID))]
        let data: ShowData = try await get(components)
        return data.toDomain()
    }

    /// `GET /shows/:id` with embedded seasons + next episode for status calculation.
    /// Pass `bypassCache: true` for refresh paths that must not reuse a stale hour-old body.
    func show(id: Int, bypassCache: Bool = false) async throws -> Show {
        AppDiagnosticsLogger.logger(for: .network)
            .notice(
                "show_detail_start show_id=\(id, privacy: .public) bypass_cache=\(bypassCache, privacy: .public)"
            )
        AppDiagnosticsLogger.breadcrumb("network_show_detail:\(id)")
        let detailStarted = Date.now

        var components = URLComponents(
            url: baseURL.appending(path: "shows/\(id)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "embed[]", value: "seasons"),
            URLQueryItem(name: "embed[]", value: "nextepisode"),
        ]
        let data: ShowData = try await get(components, bypassCache: bypassCache)
        let show = data.toDomain()

        let elapsedMs = Int(Date.now.timeIntervalSince(detailStarted) * 1000)
        AppDiagnosticsLogger.logger(for: .network)
            .notice(
                "show_detail_complete show_id=\(id, privacy: .public) duration_ms=\(elapsedMs, privacy: .public)"
            )
        return show
    }

    /// `GET /updates/shows?since=` — JSON object of show-ID strings → Unix epochs.
    /// Always bypasses cache so background refresh sees the latest change map.
    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
        AppDiagnosticsLogger.logger(for: .network)
            .notice("updates_start period=\(period.rawValue, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("network_updates")
        var components = URLComponents(
            url: baseURL.appending(path: "updates/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "since", value: period.rawValue)]
        return try await decodeUpdatedShows(components)
    }

    /// `GET /updates/shows` with no `since` filter — last-update time for every show.
    /// Used after long absences that exceed TVMaze's `since=month` window.
    func allUpdatedShows() async throws -> [Int: Date] {
        AppDiagnosticsLogger.logger(for: .network)
            .notice("updates_start period=all")
        AppDiagnosticsLogger.breadcrumb("network_updates_all")
        let components = URLComponents(
            url: baseURL.appending(path: "updates/shows"), resolvingAgainstBaseURL: false)
        return try await decodeUpdatedShows(components)
    }

    private func decodeUpdatedShows(_ components: URLComponents?) async throws -> [Int: Date] {
        let epochs: [String: TimeInterval] = try await get(components, bypassCache: true)
        var result: [Int: Date] = [:]
        result.reserveCapacity(epochs.count)
        for (key, epoch) in epochs {
            guard let id = Int(key) else { continue }
            result[id] = Date(timeIntervalSince1970: epoch)
        }
        AppDiagnosticsLogger.logger(for: .network)
            .notice("updates_complete changed_count=\(result.count, privacy: .public)")
        return result
    }

    /// `GET /shows?page=` — paginated catalog used to build/refresh the
    /// TheTVDB↔TVMaze show ID mapping. Index pages are cached up to 24h by
    /// TVMaze; we still send a normal UA and honor 429 back-off via `perform`.
    func showsIndex(page: Int) async throws -> [ShowIndexEntryData] {
        AppDiagnosticsLogger.logger(for: .network)
            .notice("shows_index_start page=\(page, privacy: .public)")
        AppDiagnosticsLogger.breadcrumb("network_shows_index:\(page)")
        var components = URLComponents(
            url: baseURL.appending(path: "shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "page", value: String(page))]
        return try await get(components)
    }

    /// `GET /shows/:id` decoded as id, name, image, and externals for mapping refresh.
    func showIndexEntry(id: Int) async throws -> ShowIndexEntryData {
        AppDiagnosticsLogger.logger(for: .network)
            .notice("show_index_entry_start show_id=\(id, privacy: .public)")
        let components = URLComponents(
            url: baseURL.appending(path: "shows/\(id)"), resolvingAgainstBaseURL: false)
        return try await get(components, bypassCache: true)
    }

    /// Builds the request with TVMaze’s preferred User-Agent and optional cache bypass.
    private func get<T: Decodable>(_ components: URLComponents?, bypassCache: Bool = false)
        async throws -> T
    {
        guard let url = components?.url else { throw TVMazeError.invalidURL }
        if bypassCache {
            AppDiagnosticsLogger.logger(for: .cache).notice(
                "request_bypass_cache path=\(url.path, privacy: .public)")
        }
        var request = URLRequest(url: url)
        // TVMaze asks clients to identify themselves; helps them contact us on issues.
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if bypassCache {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        return try await perform(request, attempt: 0)
    }

    /// Single request with one retry on HTTP 429 after a short backoff.
    private func perform<T: Decodable>(_ request: URLRequest, attempt: Int) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw TVMazeError.network(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TVMazeError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw TVMazeError.decoding(error)
            }
        case 404:
            throw TVMazeError.notFound
        case 429:
            guard attempt < maxRetries else { throw TVMazeError.rateLimited }
            try await Task.sleep(for: .seconds(2))
            return try await perform(request, attempt: attempt + 1)
        default:
            throw TVMazeError.server(statusCode: http.statusCode)
        }
    }
}
