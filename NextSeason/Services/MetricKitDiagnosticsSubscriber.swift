//
//  MetricKitDiagnosticsSubscriber.swift
//  NextSeason
//

import Foundation

/// Launch-time diagnostics hook retained so composition / setup call sites stay
/// stable. Does not subscribe to MetricKit; crash reports for TestFlight builds
/// should come from TestFlight / App Store Connect. `installIfNeeded` only drops
/// a breadcrumb so launch trails show diagnostics were wired.
enum MetricKitDiagnosticsSubscriber {
    static func installIfNeeded() {
        AppDiagnosticsLogger.breadcrumb("launch_diagnostics_installed")
    }
}
