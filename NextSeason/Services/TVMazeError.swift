//
//  TVMazeError.swift
//  NextSeason
//

import Foundation

/// Errors surfaced by `TVMazeService`. `errorDescription` provides user-facing copy.
nonisolated enum TVMazeError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case network(URLError)
    case decoding(Error)
    case notFound
    case rateLimited
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL, .invalidResponse:
            "Something went wrong. Please try again."
        case .network:
            "Couldn't reach TVMaze. Check your connection and try again."
        case .decoding:
            "We couldn't read the data from TVMaze."
        case .notFound:
            "That show couldn't be found."
        case .rateLimited:
            "Too many requests right now. Please wait a moment and try again."
        case .server:
            "TVMaze is having trouble right now. Please try again later."
        }
    }
}
