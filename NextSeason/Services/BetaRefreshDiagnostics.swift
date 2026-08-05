//
//  BetaRefreshDiagnostics.swift
//  NextSeason
//

import Foundation

/// In-memory (and partially persisted) samples of refresh / notification outcomes
/// for beta validation UI and shareable diagnostics reports.
///
/// Background refresh timestamps and decision strings persist across launches via
/// UserDefaults so Testers can open Diagnostics after a BGAppRefresh and still see
/// what happened. Foreground samples and simulation summaries stay session-scoped.
/// All mutating APIs no-op when `BetaBuildConfiguration.isAvailable` is false.
@MainActor
@Observable
final class BetaRefreshDiagnostics {
    private static let lastBackgroundRefreshAtDefaultsKey =
        "BetaRefreshDiagnostics.lastBackgroundRefreshAt"
    private static let lastBackgroundFetchResultDefaultsKey =
        "BetaRefreshDiagnostics.lastBackgroundFetchResult"
    private static let lastBackgroundNotificationDecisionDefaultsKey =
        "BetaRefreshDiagnostics.lastBackgroundNotificationDecision"

    private(set) var lastBackgroundRefreshAt: Date?
    private(set) var lastBackgroundFetchResult = "No background refresh recorded yet."
    private(set) var lastBackgroundNotificationDecision = "No background notification decision yet."
    private(set) var lastForegroundRefreshAt: Date?
    private(set) var lastForegroundFetchResult = "No foreground refresh recorded yet."
    private(set) var lastForegroundNotificationDecision = "No foreground notification decision yet."
    private(set) var nextScheduledRefreshAt: Date?
    private(set) var lastSimulatedScenarioSummary: String?

    init() {
        guard BetaBuildConfiguration.isAvailable, !UITestingConfiguration.isEnabled else { return }
        lastBackgroundRefreshAt = Self.loadPersistedDate(forKey: Self.lastBackgroundRefreshAtDefaultsKey)
        lastBackgroundFetchResult = Self.loadPersistedString(
            forKey: Self.lastBackgroundFetchResultDefaultsKey,
            defaultValue: lastBackgroundFetchResult
        )
        lastBackgroundNotificationDecision = Self.loadPersistedString(
            forKey: Self.lastBackgroundNotificationDecisionDefaultsKey,
            defaultValue: lastBackgroundNotificationDecision
        )
    }

    func recordBackgroundRefreshCompleted(
        at date: Date,
        fetchResult: String,
        notificationDecision: String
    ) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastBackgroundRefreshAt = date
        lastBackgroundFetchResult = fetchResult
        lastBackgroundNotificationDecision = notificationDecision
        Self.persistBackgroundRefreshState(
            at: date,
            fetchResult: fetchResult,
            notificationDecision: notificationDecision
        )
    }

    func recordForegroundRefreshCompleted(
        at date: Date,
        fetchResult: String,
        notificationDecision: String
    ) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastForegroundRefreshAt = date
        lastForegroundFetchResult = fetchResult
        lastForegroundNotificationDecision = notificationDecision
    }

    /// Clears persisted background refresh state for unit tests.
    static func resetLastBackgroundRefreshForTesting() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: lastBackgroundRefreshAtDefaultsKey)
        defaults.removeObject(forKey: lastBackgroundFetchResultDefaultsKey)
        defaults.removeObject(forKey: lastBackgroundNotificationDecisionDefaultsKey)
    }

    func recordNextScheduledRefresh(at date: Date) {
        guard BetaBuildConfiguration.isAvailable else { return }
        nextScheduledRefreshAt = date
    }

    func recordSimulatedScenarioSummary(_ summary: String) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastSimulatedScenarioSummary = summary
    }

    private static func loadPersistedDate(forKey key: String) -> Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }

    private static func loadPersistedString(forKey key: String, defaultValue: String) -> String {
        UserDefaults.standard.string(forKey: key) ?? defaultValue
    }

    private static func persistBackgroundRefreshState(
        at date: Date,
        fetchResult: String,
        notificationDecision: String
    ) {
        // UI tests share the host app's defaults; skip so runs stay isolated.
        guard !UITestingConfiguration.isEnabled else { return }
        let defaults = UserDefaults.standard
        defaults.set(date, forKey: lastBackgroundRefreshAtDefaultsKey)
        defaults.set(fetchResult, forKey: lastBackgroundFetchResultDefaultsKey)
        defaults.set(notificationDecision, forKey: lastBackgroundNotificationDecisionDefaultsKey)
    }
}
