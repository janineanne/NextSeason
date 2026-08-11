//
//  TheTVDBError.swift
//  NextSeason
//

import Foundation

/// Errors surfaced by `TheTVDBService`. `errorDescription` provides user-facing copy.
///
/// Mirrors `TVMazeError` so Search failure UI can show a localized message
/// without branching on provider type. Auth failures (`unauthorized`) are
/// distinct because login/token refresh is TheTVDB-specific.
nonisolated enum TheTVDBError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case network(URLError)
    case decoding(Error)
    /// Login rejected or a Bearer token was refused (HTTP 401).
    case unauthorized
    case rateLimited
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL, .invalidResponse:
            String(localized: "Something went wrong. Please try again.")
        case .network:
            String(localized: "Couldn't reach TheTVDB. Check your connection and try again.")
        case .decoding:
            String(localized: "We couldn't read the data from TheTVDB.")
        case .unauthorized:
            String(localized: "TheTVDB authentication failed. Please try again later.")
        case .rateLimited:
            String(
                localized:
                    "Too many requests right now. Please wait a moment and try again."
            )
        case .server:
            String(
                localized:
                    "TheTVDB is having trouble right now. Please try again later."
            )
        }
    }
}
