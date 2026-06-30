//
//  BetaRefreshDiagnostics.swift
//  NextSeason
//

import Foundation

/// In-memory refresh and notification diagnostics for beta validation.
/// All mutating APIs no-op when `BetaBuildConfiguration.isAvailable` is false.
@MainActor
@Observable
final class BetaRefreshDiagnostics {
    private(set) var lastRefreshAt: Date?
    private(set) var lastFetchResult = "No refresh recorded yet."
    private(set) var lastNotificationDecision = "No notification decision yet."
    private(set) var nextScheduledRefreshAt: Date?
    private(set) var lastSimulatedScenarioSummary: String?

    func recordRefreshCompleted(
        at date: Date,
        fetchResult: String,
        notificationDecision: String
    ) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastRefreshAt = date
        lastFetchResult = fetchResult
        lastNotificationDecision = notificationDecision
    }

    func recordRefreshSkipped(reason: String) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastFetchResult = "Skipped: \(reason)"
    }

    func recordNextScheduledRefresh(at date: Date) {
        guard BetaBuildConfiguration.isAvailable else { return }
        nextScheduledRefreshAt = date
    }

    func recordSimulatedScenario(_ summary: String) {
        guard BetaBuildConfiguration.isAvailable else { return }
        lastSimulatedScenarioSummary = summary
        lastFetchResult = "Simulated: \(summary)"
        lastNotificationDecision = summary
    }
}
