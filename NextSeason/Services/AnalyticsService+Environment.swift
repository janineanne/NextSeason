//
//  AnalyticsService+Environment.swift
//  NextSeason
//

import SwiftUI

private struct AnalyticsServiceKey: EnvironmentKey {
    @MainActor static let defaultValue: any AnalyticsTracking = UnconfiguredAnalyticsService()
}

extension EnvironmentValues {
    @MainActor var analytics: any AnalyticsTracking {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

@MainActor
private final class UnconfiguredAnalyticsService: AnalyticsTracking {
    private func fail() -> Never {
        fatalError("AnalyticsTracking was not injected. Set it on the root view.")
    }

    func track(_ event: AnalyticsEvent) { fail() }

    func countersSnapshot() -> AnalyticsCounters { fail() }

    func diagnosticsReport(
        notificationsEnabled: Bool,
        betaRefreshDiagnostics: BetaRefreshDiagnostics?
    ) -> String {
        fail()
    }
}
