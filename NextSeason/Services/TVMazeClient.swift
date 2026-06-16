//
//  TVMazeClient.swift
//  NextSeason
//

import Foundation

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
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
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

    func searchShows(matching query: String) async throws -> [Show] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: baseURL.appending(path: "search/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        let results: [ShowSearchResultData] = try await get(components)
        return results.map { $0.show.toDomain() }
    }

    func show(id: Int, bypassCache: Bool = false) async throws -> Show {
        var components = URLComponents(url: baseURL.appending(path: "shows/\(id)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "embed[]", value: "seasons"),
            URLQueryItem(name: "embed[]", value: "nextepisode")
        ]
        let data: ShowData = try await get(components, bypassCache: bypassCache)
        return data.toDomain()
    }

    func updatedShows(since period: TVMazeUpdatePeriod) async throws -> [Int: Date] {
        var components = URLComponents(url: baseURL.appending(path: "updates/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "since", value: period.rawValue)]
        let epochs: [String: TimeInterval] = try await get(components, bypassCache: true)
        var result: [Int: Date] = [:]
        result.reserveCapacity(epochs.count)
        for (key, epoch) in epochs {
            guard let id = Int(key) else { continue }
            result[id] = Date(timeIntervalSince1970: epoch)
        }
        return result
    }

    private func get<T: Decodable>(_ components: URLComponents?, bypassCache: Bool = false) async throws -> T {
        guard let url = components?.url else { throw TVMazeError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if bypassCache {
            request.cachePolicy = .reloadIgnoringLocalCacheData
        }
        return try await perform(request, attempt: 0)
    }

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
