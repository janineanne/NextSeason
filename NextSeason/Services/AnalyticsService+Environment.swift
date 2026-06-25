//
//  AnalyticsService+Environment.swift
//  NextSeason
//

import SwiftUI

private struct AnalyticsServiceKey: EnvironmentKey {
    @MainActor static let defaultValue: any AnalyticsTracking = AnalyticsService()
}

extension EnvironmentValues {
    @MainActor var analytics: any AnalyticsTracking {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
