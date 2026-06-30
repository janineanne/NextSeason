//
//  BackgroundRefreshConfiguration.swift
//  NextSeason
//

import Foundation

/// Controls background watchlist refresh cadence.
///
/// Production uses a ~12h `BGAppRefreshTask` interval. For Scenario D soak testing,
/// set `forceAcceleratedForSoakTest` to `true` (or pass `-AcceleratedBackgroundRefresh`
/// once) to request refresh every 10 minutes. Revert before App Store release.
enum BackgroundRefreshConfiguration {
    static let launchFlag = "-AcceleratedBackgroundRefresh"
    private static let defaultsKey = "BackgroundRefreshConfiguration.accelerated"

    /// Flip to `true` only while running Scenario D soak tests.
    static let forceAcceleratedForSoakTest = false

    static let productionRefreshInterval: TimeInterval = 12 * 60 * 60
    static let acceleratedRefreshInterval: TimeInterval = 10 * 60

    static var isAccelerated: Bool {
        forceAcceleratedForSoakTest
            || UserDefaults.standard.bool(forKey: defaultsKey)
            || ProcessInfo.processInfo.arguments.contains(launchFlag)
    }

    static var refreshInterval: TimeInterval {
        isAccelerated ? acceleratedRefreshInterval : productionRefreshInterval
    }

    /// Persists accelerated mode so background relaunches keep the short interval.
    static func persistAcceleratedModeIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains(launchFlag) else { return }
        UserDefaults.standard.set(true, forKey: defaultsKey)
    }

    static func clearPersistedAcceleratedMode() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
