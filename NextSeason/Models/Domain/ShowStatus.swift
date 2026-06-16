//
//  ShowStatus.swift
//  NextSeason
//

import Foundation

/// A show's production status. TVMaze's set is treated as open-ended: any
/// unrecognized value is preserved in `.unknown` rather than dropped.
nonisolated enum ShowStatus: Sendable, Hashable {
    case running
    case ended
    case toBeDetermined
    case inDevelopment
    case unknown(String)

    init(rawValue: String?) {
        switch rawValue {
        case "Running": self = .running
        case "Ended": self = .ended
        case "To Be Determined": self = .toBeDetermined
        case "In Development": self = .inDevelopment
        case let other?: self = .unknown(other)
        case nil: self = .unknown("Unknown")
        }
    }

    var displayLabel: String {
        switch self {
        case .running: "Ongoing series"
        case .ended: "Ended"
        case .toBeDetermined: "To Be Determined"
        case .inDevelopment: "In Development"
        case .unknown(let value): value
        }
    }
}
