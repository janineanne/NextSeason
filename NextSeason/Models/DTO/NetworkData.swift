//
//  NetworkData.swift
//  NextSeason
//

import Foundation

/// A TVMaze `network` or `webChannel`. Only the name is needed by the app.
nonisolated struct NetworkData: Codable, Sendable {
    let id: Int?
    let name: String?
}
