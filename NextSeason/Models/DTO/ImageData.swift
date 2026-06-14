//
//  ImageData.swift
//  NextSeason
//

import Foundation

/// TVMaze image payload (poster format for shows). Either resolution may be absent.
nonisolated struct ImageData: Codable, Sendable {
    let medium: String?
    let original: String?
}
