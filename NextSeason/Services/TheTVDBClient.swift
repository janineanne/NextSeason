//
//  TheTVDBClient.swift
//  NextSeason
//

import Foundation
import os

/// Live `TheTVDBService` backed by TheTVDB API v4.
///
/// An `actor` so login-token caching, networking, and JSON decoding stay off the
/// main actor. Auth flow:
/// 1. `POST /login` with the project API key → JWT (valid ~1 month).
/// 2. Subsequent calls send `Authorization: Bearer <token>`.
/// 3. On HTTP 401, clear the cached token, re-login once, and retry.
///
/// Search uses `limit` / `offset` pagination (`TheTVDBConfiguration.pageSize`).
/// TheTVDB's `links.next` URLs are occasionally malformed (duplicate `?`), so
/// page advancement is computed from `offset` + result count rather than by
/// following those URLs.
actor TheTVDBClient: TheTVDBService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let apiKey: String
    private let baseURL: URL
    private let pageSize: Int
    private let maxRetries = 1
    /// Cached JWT from the last successful login; cleared on 401.
    private var bearerToken: String?

    init(
        session: URLSession = .shared,
        apiKey: String = TheTVDBConfiguration.apiKey,
        baseURL: URL = TheTVDBConfiguration.baseURL,
        pageSize: Int = TheTVDBConfiguration.pageSize
    ) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.pageSize = pageSize
    }

    /// `GET /search?query=&type=series&limit=&offset=`
    ///
    /// Restricted to `type=series` so movies / people / companies never appear
    /// in guest search. Empty query short-circuits without hitting the network.
    func searchSeries(matching query: String, offset: Int) async throws -> TheTVDBSearchPage {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return TheTVDBSearchPage(results: [], hasMore: false)
        }

        AppDiagnosticsLogger.logger(for: .network)
            .notice(
                "tvdb_search_start query_length=\(trimmed.count, privacy: .public) offset=\(offset, privacy: .public)"
            )
        AppDiagnosticsLogger.breadcrumb("network_tvdb_search")
        let searchStarted = Date.now

        var components = URLComponents(
            url: baseURL.appending(path: "search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "type", value: "series"),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "offset", value: String(max(offset, 0))),
        ]

        let response: TheTVDBListResponseData<TheTVDBSearchResultData> = try await authorizedGet(
            components
        )
        // Drop hits that lack a parseable series id / name rather than failing
        // the whole page — TheTVDB occasionally returns sparse records.
        let results = (response.data ?? []).compactMap { $0.toDomain() }
        let hasMore = Self.hasMorePages(
            fetchedCount: results.count,
            offset: max(offset, 0),
            pageSize: pageSize,
            links: response.links
        )

        let elapsedMs = Int(Date.now.timeIntervalSince(searchStarted) * 1000)
        AppDiagnosticsLogger.logger(for: .network)
            .notice(
                "tvdb_search_complete result_count=\(results.count, privacy: .public) has_more=\(hasMore, privacy: .public) duration_ms=\(elapsedMs, privacy: .public)"
            )
        return TheTVDBSearchPage(results: results, hasMore: hasMore)
    }

    /// Prefer `links.total_items` or a present `links.next`; otherwise treat a
    /// full page as evidence that another page may exist.
    private static func hasMorePages(
        fetchedCount: Int,
        offset: Int,
        pageSize: Int,
        links: TheTVDBLinksData?
    ) -> Bool {
        if let total = links?.totalItems {
            return offset + fetchedCount < total
        }
        if links?.next != nil {
            return true
        }
        return fetchedCount >= pageSize
    }

    private func authorizedGet<T: Decodable>(_ components: URLComponents?) async throws -> T {
        try await authorizedGet(components, allowTokenRefresh: true)
    }

    /// Attaches the cached Bearer token. On 401 with refresh still allowed,
    /// clears the token and retries once after a fresh login.
    private func authorizedGet<T: Decodable>(
        _ components: URLComponents?,
        allowTokenRefresh: Bool
    ) async throws -> T {
        let token = try await validToken()
        guard let url = components?.url else { throw TheTVDBError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            return try await perform(request, attempt: 0)
        } catch TheTVDBError.unauthorized where allowTokenRefresh {
            // Token expired or revoked — clear and retry once with a fresh login.
            bearerToken = nil
            return try await authorizedGet(components, allowTokenRefresh: false)
        }
    }

    private func validToken() async throws -> String {
        if let bearerToken { return bearerToken }
        let token = try await login()
        bearerToken = token
        return token
    }

    /// `POST /login` with `{ "apikey": ... }`. Project keys do not send a PIN;
    /// including an empty PIN field can cause TheTVDB to reject the request.
    private func login() async throws -> String {
        AppDiagnosticsLogger.breadcrumb("network_tvdb_login")
        let url = baseURL.appending(path: "login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["apikey": apiKey]
        )

        let response: TheTVDBLoginResponseData = try await perform(request, attempt: 0)
        guard let token = response.data?.token, !token.isEmpty else {
            throw TheTVDBError.invalidResponse
        }
        return token
    }

    /// Single request with one retry on HTTP 429 after a short backoff
    /// (same policy as `TVMazeClient`).
    private func perform<T: Decodable>(_ request: URLRequest, attempt: Int) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            throw TheTVDBError.network(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TheTVDBError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw TheTVDBError.decoding(error)
            }
        case 401:
            throw TheTVDBError.unauthorized
        case 429:
            guard attempt < maxRetries else { throw TheTVDBError.rateLimited }
            try await Task.sleep(for: .seconds(2))
            return try await perform(request, attempt: attempt + 1)
        default:
            throw TheTVDBError.server(statusCode: http.statusCode)
        }
    }
}
