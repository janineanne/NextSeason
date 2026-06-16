//
//  TVMazeDate.swift
//  NextSeason
//

import Foundation

/// Parses TVMaze date-only strings ("yyyy-MM-dd"). Implemented without a shared
/// `DateFormatter` so it is safe to call from any concurrency context.
nonisolated enum TVMazeDate {
    static func dateOnly(_ string: String?) -> Date? {
        guard let string, string.count >= 10 else { return nil }
        let parts = string.prefix(10).split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar.date(from: components)
    }
}
