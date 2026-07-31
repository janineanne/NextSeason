//
//  BackgroundRefreshConfiguration.swift
//  NextSeason
//

import Foundation

/// Controls background watchlist refresh cadence.
///
/// Production uses a ~12h `BGAppRefreshTask` interval.
enum BackgroundRefreshConfiguration {
    static let refreshInterval: TimeInterval = 12 * 60 * 60
}
