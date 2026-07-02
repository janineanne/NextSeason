//
//  AppDiagnosticsLogger.swift
//  NextSeason
//

import Foundation
import os

struct AppLaunchDiagnostics: Sendable, Hashable {
    let currentLaunchStartedAt: Date?
    let lastGracefulExitAt: Date?
    let previousLaunchEndedUnexpectedly: Bool
    let previousLaunchStartedAt: Date?
    let unexpectedTerminationDetectedAt: Date?
    let priorBreadcrumbs: [String]
}

/// Structured OSLog output and breadcrumb trail for intermittent crash investigation.
///
/// Logs use the app bundle ID as subsystem so Console.app and `log stream` can filter
/// with `subsystem:com.TrialByFyre.NextSeason`. Breadcrumbs are persisted across launches
/// so the next session can report the last activity before an abrupt termination.
enum AppDiagnosticsLogger: Sendable {
    private nonisolated static let diagnosticsSubsystem =
        Bundle.main.bundleIdentifier ?? "com.TrialByFyre.NextSeason"
    private nonisolated static let breadcrumbsDefaultsKey = "AppDiagnosticsLogger.breadcrumbs"
    private nonisolated static let sessionActiveDefaultsKey = "AppDiagnosticsLogger.sessionActive"
    private nonisolated static let currentLaunchStartedAtDefaultsKey = "AppDiagnosticsLogger.currentLaunchStartedAt"
    private nonisolated static let lastGracefulExitAtDefaultsKey = "AppDiagnosticsLogger.lastGracefulExitAt"
    private nonisolated static let previousUnexpectedDefaultsKey = "AppDiagnosticsLogger.previousUnexpected"
    private nonisolated static let previousUnexpectedLaunchStartedAtDefaultsKey = "AppDiagnosticsLogger.previousUnexpectedLaunchStartedAt"
    private nonisolated static let unexpectedTerminationDetectedAtDefaultsKey = "AppDiagnosticsLogger.unexpectedTerminationDetectedAt"
    private nonisolated static let previousUnexpectedBreadcrumbsDefaultsKey = "AppDiagnosticsLogger.previousUnexpectedBreadcrumbs"
    private nonisolated static let maxBreadcrumbs = 50
    private nonisolated static let breadcrumbStore = BreadcrumbStore()

    enum Category: String, Sendable {
        case lifecycle
        case scene
        case persistence
        case network
        case tasks
        case cache
    }

    nonisolated static func logger(for category: Category) -> Logger {
        Logger(subsystem: diagnosticsSubsystem, category: category.rawValue)
    }

    // MARK: - Session lifecycle

    /// Call once during app initialization before other work runs.
    nonisolated static func recordAppLaunch() {
        let defaults = UserDefaults.standard
        let now = Date.now
        let hadActiveSession = defaults.bool(forKey: sessionActiveDefaultsKey)
        let priorLaunchStartedAt = defaults.object(forKey: currentLaunchStartedAtDefaultsKey) as? Date
        let priorBreadcrumbs = loadPersistedBreadcrumbs()

        defaults.set(now, forKey: currentLaunchStartedAtDefaultsKey)
        defaults.set(true, forKey: sessionActiveDefaultsKey)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let launchLogger = logger(for: .lifecycle)
        launchLogger.notice("app_launch version=\(version, privacy: .public) build=\(build, privacy: .public)")

        if hadActiveSession {
            defaults.set(true, forKey: previousUnexpectedDefaultsKey)
            defaults.set(now, forKey: unexpectedTerminationDetectedAtDefaultsKey)
            if let priorLaunchStartedAt {
                defaults.set(priorLaunchStartedAt, forKey: previousUnexpectedLaunchStartedAtDefaultsKey)
            }
            defaults.set(Array(priorBreadcrumbs.suffix(10)), forKey: previousUnexpectedBreadcrumbsDefaultsKey)

            let summary = priorBreadcrumbs.suffix(10).joined(separator: " | ")
            launchLogger.fault(
                "possible_abrupt_termination prior_breadcrumbs=\(summary, privacy: .public)"
            )
            breadcrumb("recovery_after_unexpected_termination")
        } else {
            defaults.set(false, forKey: previousUnexpectedDefaultsKey)
            defaults.removeObject(forKey: previousUnexpectedLaunchStartedAtDefaultsKey)
            defaults.removeObject(forKey: unexpectedTerminationDetectedAtDefaultsKey)
            defaults.removeObject(forKey: previousUnexpectedBreadcrumbsDefaultsKey)
            breadcrumb("app_launch")
        }
    }

    /// Marks a graceful background transition so the next launch is not flagged as abrupt.
    nonisolated static func recordEnterBackground() {
        let now = Date.now
        persistBreadcrumbs()
        UserDefaults.standard.set(false, forKey: sessionActiveDefaultsKey)
        UserDefaults.standard.set(now, forKey: lastGracefulExitAtDefaultsKey)
        logger(for: .scene).notice("enter_background")
        breadcrumb("enter_background")
    }

    nonisolated static func launchDiagnostics() -> AppLaunchDiagnostics {
        let defaults = UserDefaults.standard
        return AppLaunchDiagnostics(
            currentLaunchStartedAt: defaults.object(forKey: currentLaunchStartedAtDefaultsKey) as? Date,
            lastGracefulExitAt: defaults.object(forKey: lastGracefulExitAtDefaultsKey) as? Date,
            previousLaunchEndedUnexpectedly: defaults.bool(forKey: previousUnexpectedDefaultsKey),
            previousLaunchStartedAt: defaults.object(forKey: previousUnexpectedLaunchStartedAtDefaultsKey) as? Date,
            unexpectedTerminationDetectedAt: defaults.object(forKey: unexpectedTerminationDetectedAtDefaultsKey) as? Date,
            priorBreadcrumbs: defaults.stringArray(forKey: previousUnexpectedBreadcrumbsDefaultsKey) ?? []
        )
    }

    // MARK: - Breadcrumbs

    /// Records a short, privacy-safe activity marker included in diagnostics export.
    nonisolated static func breadcrumb(_ message: String) {
        guard ProcessInfo.processInfo.arguments.contains("-UITesting") == false else { return }
        let entry = "\(timestamp()) \(message)"
        breadcrumbStore.append(entry, limit: maxBreadcrumbs)
        logger(for: .lifecycle).notice("breadcrumb \(message, privacy: .public)")
    }

    nonisolated static func recentBreadcrumbs(limit: Int = 20) -> [String] {
        breadcrumbStore.snapshot(limit: limit)
    }

    nonisolated static func persistedBreadcrumbsForExport() -> [String] {
        loadPersistedBreadcrumbs()
    }

    nonisolated static func persistBreadcrumbsNow() {
        persistBreadcrumbs()
    }

    // MARK: - Scene / task helpers

    nonisolated static func logScenePhase(from previous: String?, to phase: String) {
        logger(for: .scene).notice(
            "scene_phase from=\(previous ?? "nil", privacy: .public) to=\(phase, privacy: .public)"
        )
        breadcrumb("scene:\(phase)")
    }

    nonisolated static func logTaskStart(_ name: String) {
        logger(for: .tasks).notice("task_start name=\(name, privacy: .public)")
        breadcrumb("task_start:\(name)")
    }

    nonisolated static func logTaskCancel(_ name: String) {
        logger(for: .tasks).notice("task_cancel name=\(name, privacy: .public)")
        breadcrumb("task_cancel:\(name)")
    }

    nonisolated static func logTaskComplete(_ name: String) {
        logger(for: .tasks).notice("task_complete name=\(name, privacy: .public)")
        breadcrumb("task_complete:\(name)")
    }

    /// Parseable wall-clock for `-ProfileFlow` runs without Instruments attached.
    nonisolated static func logProfileFlowTiming(flow: String, durationMs: Int, phase: String? = nil) {
        if let phase {
            logger(for: .tasks).notice(
                "profile_flow_timing flow=\(flow, privacy: .public) phase=\(phase, privacy: .public) duration_ms=\(durationMs)"
            )
        } else {
            logger(for: .tasks).notice(
                "profile_flow_timing flow=\(flow, privacy: .public) duration_ms=\(durationMs)"
            )
        }
        if isProfileFlowActive {
            ProfileFlowTimingStore.append(flow: flow, durationMs: durationMs, phase: phase)
        }
    }

    private nonisolated static var isProfileFlowActive: Bool {
        if ProcessInfo.processInfo.environment["PROFILE_FLOW"] != nil { return true }
        return ProcessInfo.processInfo.arguments.contains("-ProfileFlow")
    }

    // MARK: - Persistence failures

    /// Logs a fatal startup failure before `ModelContainer` initialization aborts the process.
    nonisolated static func logModelContainerInitFailure(_ error: Error) {
        breadcrumb("model_container_init_failed")
        persistBreadcrumbsNow()
        logger(for: .persistence).fault(
            "model_container_init_failed error=\(String(describing: error), privacy: .public)"
        )
    }

    // MARK: - Private

    nonisolated private static func timestamp() -> String {
        ISO8601DateFormatter().string(from: .now)
    }

    nonisolated private static func persistBreadcrumbs() {
        UserDefaults.standard.set(breadcrumbStore.snapshot(limit: maxBreadcrumbs), forKey: breadcrumbsDefaultsKey)
    }

    nonisolated private static func loadPersistedBreadcrumbs() -> [String] {
        UserDefaults.standard.stringArray(forKey: breadcrumbsDefaultsKey) ?? []
    }
}

// MARK: - Breadcrumb store

private final class BreadcrumbStore: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var entries: [String] = []

    nonisolated func append(_ entry: String, limit: Int) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(entry)
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }

    nonisolated func snapshot(limit: Int) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(entries.suffix(limit))
    }
}
