//
//  AnalyticsDiagnosticsReport.swift
//  NextSeason
//

import Foundation

/// Marketing / build strings shown at the top of shareable diagnostics reports.
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

/// Builds the plain-text diagnostics export shown on the Diagnostics screen and
/// via Share / Copy. Fields are oriented toward TestFlight triage:
///
/// - **Usage counters:** cumulative local tallies (see `AnalyticsCounters`).
/// - **Recent breadcrumbs:** in-memory trail for the current process (what the user
///   did just before filing a report).
/// - **Persisted breadcrumbs:** last session's trail (survives relaunch when the
///   prior process wrote them before exit).
/// - **Launch diagnostics:** whether the previous run looked like an unexpected
///   termination, when the current / prior launches started, last graceful
///   background, and breadcrumbs captured from that unexpected launch — enough
///   to correlate a crash-like exit with the last known app steps.
/// - **Beta validation:** last foreground/background refresh outcomes and
///   simulated-scenario summaries when beta tooling is available.
enum AnalyticsDiagnosticsReport {
    @MainActor
    static func formatted(
        counters: AnalyticsCounters,
        notificationsEnabled: Bool,
        recentBreadcrumbs: [String] = AppDiagnosticsLogger.recentBreadcrumbs(),
        persistedBreadcrumbs: [String] = AppDiagnosticsLogger.persistedBreadcrumbsForExport(),
        launchDiagnostics: AppLaunchDiagnostics = AppDiagnosticsLogger.launchDiagnostics(),
        betaRefreshDiagnostics: BetaRefreshDiagnostics? = nil
    ) -> String {
        let breadcrumbLines =
            recentBreadcrumbs.isEmpty
            ? String(localized: "  (none this session)")
            : recentBreadcrumbs.map { "  \($0)" }.joined(separator: "\n")
        let priorLines =
            persistedBreadcrumbs.isEmpty
            ? String(localized: "  (none persisted)")
            // Cap export size; full ring stays available in-app if needed.
            : persistedBreadcrumbs.suffix(10).map { "  \($0)" }.joined(separator: "\n")
        let previousLaunchStatus =
            launchDiagnostics.previousLaunchEndedUnexpectedly
            ? String(localized: "Ended unexpectedly")
            : String(localized: "Clean or not detected")
        let currentLaunchStarted =
            launchDiagnostics.currentLaunchStartedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) }
            ?? String(localized: "Unknown")
        let previousLaunchStarted =
            launchDiagnostics.previousLaunchStartedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) }
            ?? String(localized: "Unknown")
        let detectedAt =
            launchDiagnostics.unexpectedTerminationDetectedAt
            .map { $0.formatted(date: .abbreviated, time: .standard) }
            ?? String(localized: "Not applicable")
        let lastGracefulExit =
            launchDiagnostics.lastGracefulExitAt
            .map { $0.formatted(date: .abbreviated, time: .standard) }
            ?? String(localized: "Never recorded")
        let unexpectedBreadcrumbLines =
            launchDiagnostics.priorBreadcrumbs.isEmpty
            ? String(localized: "  (none captured)")
            : launchDiagnostics.priorBreadcrumbs.map { "  \($0)" }.joined(separator: "\n")

        var betaSection = ""
        if BetaBuildConfiguration.isAvailable, let betaRefreshDiagnostics {
            let lastBackgroundRefresh =
                betaRefreshDiagnostics.lastBackgroundRefreshAt
                .map { $0.formatted(date: .abbreviated, time: .standard) }
                ?? String(localized: "Never")
            let nextRefresh =
                betaRefreshDiagnostics.nextScheduledRefreshAt
                .map { $0.formatted(date: .abbreviated, time: .standard) }
                ?? String(localized: "Not scheduled yet")
            betaSection = """

                Beta validation:
                Last background refresh: \(lastBackgroundRefresh)
                Next refresh window: \(nextRefresh)
                Last background fetch result: \(betaRefreshDiagnostics.lastBackgroundFetchResult)
                Last background notification decision: \(betaRefreshDiagnostics.lastBackgroundNotificationDecision)
                """
            if let lastForegroundRefresh = betaRefreshDiagnostics.lastForegroundRefreshAt?
                .formatted(date: .abbreviated, time: .standard)
            {
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
            \(String(localized: "NextSeason Diagnostics"))

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
            Notifications enabled: \(notificationsEnabled)

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
