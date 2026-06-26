//
//  AnalyticsDiagnosticsReport.swift
//  NextSeason
//

import Foundation

enum AppVersionInfo {
    static var marketingVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    static var buildNumber: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
    }

    static var displayString: String {
        "\(marketingVersion) (\(buildNumber))"
    }
}

enum AnalyticsDiagnosticsReport {
    static func formatted(
        counters: AnalyticsCounters,
        notificationsEnabled: Bool,
        currentTheme: String
    ) -> String {
        """
        NextSeason Diagnostics

        Version: \(AppVersionInfo.displayString)

        App launches: \(counters.appLaunches)
        Searches: \(counters.searchesPerformed)
        Successful searches: \(counters.successfulSearches)
        No-result searches: \(counters.noResultSearches)
        Example searches: \(counters.exampleSearchesUsed)
        Show detail views: \(counters.showDetailViews)
        Watchlist adds: \(counters.watchlistAdditions)
        Watchlist removals: \(counters.watchlistRemovals)
        Notification permission requests: \(counters.notificationPermissionRequests)
        Notification permission grants: \(counters.notificationPermissionGrants)
        Notification reminders scheduled: \(counters.notificationRemindersScheduled)
        Theme selections: \(counters.themeSelections)
        Actor name taps: \(counters.actorNameTaps)
        Notifications enabled: \(notificationsEnabled)
        Current theme: \(currentTheme)
        """
    }
}
