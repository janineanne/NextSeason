//
//  MetricKitDiagnosticsSubscriber.swift
//  NextSeason
//

import Foundation

/// Placeholder retained so existing setup code does not need conditional compilation.
/// Crash reports for TestFlight builds should come from TestFlight / App Store Connect.
enum MetricKitDiagnosticsSubscriber {
    static func installIfNeeded() {
        AppDiagnosticsLogger.breadcrumb("launch_diagnostics_installed")
    }
}
