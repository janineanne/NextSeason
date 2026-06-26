//
//  Array+GenreDisplay.swift
//  NextSeason
//

import Foundation

extension Array where Element == String {
    /// Middle-dot-separated genre line for captions. Non-breaking spaces keep each
    /// `·` with the preceding genre so wrapped lines end with a dot instead of
    /// starting with one.
    nonisolated var genreDisplayLine: String {
        enumerated().map { index, genre in
            index < count - 1 ? "\(genre)\u{00A0}·" : genre
        }
        .joined(separator: " ")
    }
}
