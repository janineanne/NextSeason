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
    @MainActor
    static func formatted(
        counters: AnalyticsCounters,
        notificationsEnabled: Bool,
        currentTheme: String,
        recentBreadcrumbs: [String] = AppDiagnosticsLogger.recentBreadcrumbs(),
        persistedBreadcrumbs: [String] = AppDiagnosticsLogger.persistedBreadcrumbsForExport(),
        launchDiagnostics: AppLaunchDiagnostics = AppDiagnosticsLogger.launchDiagnostics(),
        betaRefreshDiagnostics: BetaRefreshDiagnostics? = nil
    ) -> String {
        let breadcrumbLines = recentBreadcrumbs.isEmpty
            ? "  (none this session)"
            : recentBreadcrumbs.map { "  \($0)" }.joined(separator: "\n")
        let priorLines = persistedBreadcrumbs.isEmpty
            ? "  (none persisted)"
            : persistedBreadcrumbs.suffix(10).map { "  \($0)" }.joined(separator: "\n")
        let previousLaunchStatus = launchDiagnostics.previousLaunchEndedUnexpectedly
            ? "Ended unexpectedly"
            : "Clean or not detected"
        let currentLaunchStarted = launchDiagnostics.currentLaunchStartedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Unknown"
        let previousLaunchStarted = launchDiagnostics.previousLaunchStartedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Unknown"
        let detectedAt = launchDiagnostics.unexpectedTerminationDetectedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Not applicable"
        let lastGracefulExit = launchDiagnostics.lastGracefulExitAt
            .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Never recorded"
        let unexpectedBreadcrumbLines = launchDiagnostics.priorBreadcrumbs.isEmpty
            ? "  (none captured)"
            : launchDiagnostics.priorBreadcrumbs.map { "  \($0)" }.joined(separator: "\n")

        var betaSection = ""
        if BetaBuildConfiguration.isAvailable, let betaRefreshDiagnostics {
            let lastBackgroundRefresh = betaRefreshDiagnostics.lastBackgroundRefreshAt
                .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Never"
            let nextRefresh = betaRefreshDiagnostics.nextScheduledRefreshAt
                .map { $0.formatted(date: .abbreviated, time: .standard) } ?? "Not scheduled yet"
            betaSection = """

            Beta validation:
            Last background refresh: \(lastBackgroundRefresh)
            Next refresh window: \(nextRefresh)
            Last background fetch result: \(betaRefreshDiagnostics.lastBackgroundFetchResult)
            Last background notification decision: \(betaRefreshDiagnostics.lastBackgroundNotificationDecision)
            """
            if let lastForegroundRefresh = betaRefreshDiagnostics.lastForegroundRefreshAt?
                .formatted(date: .abbreviated, time: .standard) {
                betaSection += """

            Last foreground refresh: \(lastForegroundRefresh)
            Last foreground fetch result: \(betaRefreshDiagnostics.lastForegroundFetchResult)
            Last foreground notification decision: \(betaRefreshDiagnostics.lastForegroundNotificationDecision)
            """
            }
            if let simulated = betaRefreshDiagnostics.lastSimulatedScenarioSummary {
                betaSection += "\nLast simulation: \(simulated)"
            }
        }

        return """
        NextSeason Diagnostics

        Version: \(AppVersionInfo.displayString)
        \(betaSection)

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
        Notifications enabled: \(notificationsEnabled)
        Current theme: \(currentTheme)

        Recent breadcrumbs (this session):
        \(breadcrumbLines)

        Persisted breadcrumbs (prior session, if any):
        \(priorLines)

        Launch diagnostics:
        Previous launch status: \(previousLaunchStatus)
        Current launch started: \(currentLaunchStarted)
        Previous unexpected launch started: \(previousLaunchStarted)
        Unexpected termination detected: \(detectedAt)
        Last graceful background/exit: \(lastGracefulExit)

        Breadcrumbs from previous unexpected launch:
        \(unexpectedBreadcrumbLines)
        """
    }
}
