//
//  MetricKitDiagnosticsSubscriber.swift
//  NextSeason
//

import Foundation
import MetricKit

/// Receives MetricKit crash diagnostics on the launch after a crash and logs a
/// structured summary for Organizer / Console correlation.
enum MetricKitDiagnosticsSubscriber {
    private static var subscriber: Subscriber?

    static func installIfNeeded() {
        guard !UITestingConfiguration.isEnabled else { return }
        guard subscriber == nil else { return }
        let instance = Subscriber()
        subscriber = instance
        MXMetricManager.shared.add(instance)
        AppDiagnosticsLogger.breadcrumb("metrickit_subscriber_installed")
    }

    private struct CrashSummary: Sendable {
        let exceptionType: String
        let signal: String
        let terminationReason: String?
        let stackSummary: String
    }

    private final class Subscriber: NSObject, MXMetricManagerSubscriber {
        nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
            let summaries = payloads.flatMap { payload -> [CrashSummary] in
                payload.crashDiagnostics?.map(Self.makeSummary(from:)) ?? []
            }
            for summary in summaries {
                AppDiagnosticsLogger.logCrashDiagnosticSummary(
                    exceptionType: summary.exceptionType,
                    signal: summary.signal,
                    terminationReason: summary.terminationReason,
                    crashedThread: "metrickit",
                    topFrames: [summary.stackSummary]
                )
            }
        }

        nonisolated private static func makeSummary(from crash: MXCrashDiagnostic) -> CrashSummary {
            let json = String(data: crash.callStackTree.jsonRepresentation(), encoding: .utf8) ?? ""
            let maxLength = 500
            let stackSummary = json.count <= maxLength ? json : String(json.prefix(maxLength)) + "…"
            return CrashSummary(
                exceptionType: crash.exceptionType.map { "\($0)" } ?? "unknown",
                signal: crash.signal.map { "\($0)" } ?? "unknown",
                terminationReason: crash.terminationReason,
                stackSummary: stackSummary
            )
        }
    }
}
