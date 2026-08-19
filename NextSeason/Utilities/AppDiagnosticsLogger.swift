//
//  AppDiagnosticsLogger.swift
//  NextSeason
//

import Foundation
import Synchronization
import os

/// Snapshot of launch and abrupt-termination signals for diagnostics export.
///
/// `previousLaunchEndedUnexpectedly` is true when the prior session never called
/// `recordEnterBackground` or `noteReachedSafePath` (still marked active at
/// next `recordAppLaunch`).
struct AppLaunchDiagnostics: Sendable, Hashable {
    let currentLaunchStartedAt: Date?
    let lastGracefulExitAt: Date?
    let previousLaunchEndedUnexpectedly: Bool
    let previousLaunchStartedAt: Date?
    let unexpectedTerminationDetectedAt: Date?
    let priorBreadcrumbs: [String]
    let consecutiveUnexpectedLaunchCount: Int
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
    private nonisolated static let currentLaunchStartedAtDefaultsKey =
        "AppDiagnosticsLogger.currentLaunchStartedAt"
    private nonisolated static let lastGracefulExitAtDefaultsKey =
        "AppDiagnosticsLogger.lastGracefulExitAt"
    private nonisolated static let previousUnexpectedDefaultsKey =
        "AppDiagnosticsLogger.previousUnexpected"
    private nonisolated static let previousUnexpectedLaunchStartedAtDefaultsKey =
        "AppDiagnosticsLogger.previousUnexpectedLaunchStartedAt"
    private nonisolated static let unexpectedTerminationDetectedAtDefaultsKey =
        "AppDiagnosticsLogger.unexpectedTerminationDetectedAt"
    private nonisolated static let previousUnexpectedBreadcrumbsDefaultsKey =
        "AppDiagnosticsLogger.previousUnexpectedBreadcrumbs"
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

    /// Call once at the start of a process launch, before composition.
    nonisolated static func recordAppLaunch(
        defaults: UserDefaults = .standard,
        now: Date = Date.now
    ) {
        let hadActiveSession = defaults.bool(forKey: sessionActiveDefaultsKey)
        let priorLaunchStartedAt =
            defaults.object(forKey: currentLaunchStartedAtDefaultsKey) as? Date
        let priorBreadcrumbs = loadPersistedBreadcrumbs()

        defaults.set(now, forKey: currentLaunchStartedAtDefaultsKey)
        defaults.set(true, forKey: sessionActiveDefaultsKey)

        let version =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let launchLogger = logger(for: .lifecycle)
        launchLogger.notice(
            "app_launch version=\(version, privacy: .public) build=\(build, privacy: .public)")

        // Still-active session flag means the last run never reached
        // `recordEnterBackground` or `noteReachedSafePath` — treat as a
        // possible abrupt termination.
        if hadActiveSession {
            defaults.set(true, forKey: previousUnexpectedDefaultsKey)
            defaults.set(now, forKey: unexpectedTerminationDetectedAtDefaultsKey)
            if let priorLaunchStartedAt {
                defaults.set(
                    priorLaunchStartedAt, forKey: previousUnexpectedLaunchStartedAtDefaultsKey)
            }
            defaults.set(
                Array(priorBreadcrumbs.suffix(10)), forKey: previousUnexpectedBreadcrumbsDefaultsKey
            )

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
    nonisolated static func recordEnterBackground(
        defaults: UserDefaults = .standard,
        now: Date = Date.now
    ) {
        logger(for: .scene).notice("enter_background")
        breadcrumb("enter_background")
        persistBreadcrumbs()
        defaults.set(false, forKey: sessionActiveDefaultsKey)
        defaults.set(now, forKey: lastGracefulExitAtDefaultsKey)
    }

    /// Clears the in-progress session flag after the recovery UI is showing
    /// so killing this process is not counted as another launch crash.
    /// Does not clear consecutive-failure state.
    nonisolated static func noteReachedSafePath(defaults: UserDefaults = .standard) {
        breadcrumb("safe_recovery_path_reached")
        persistBreadcrumbs()
        defaults.set(false, forKey: sessionActiveDefaultsKey)
    }

    /// Marks that this process is running a usable session again (composition
    /// succeeded after recovery). Does not record a new process launch.
    nonisolated static func noteSessionActive(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: sessionActiveDefaultsKey)
    }

    /// Reads persisted launch markers set by `recordAppLaunch` / `recordEnterBackground`.
    nonisolated static func launchDiagnostics(defaults: UserDefaults = .standard)
        -> AppLaunchDiagnostics
    {
        return AppLaunchDiagnostics(
            currentLaunchStartedAt: defaults.object(forKey: currentLaunchStartedAtDefaultsKey)
                as? Date,
            lastGracefulExitAt: defaults.object(forKey: lastGracefulExitAtDefaultsKey) as? Date,
            previousLaunchEndedUnexpectedly: defaults.bool(forKey: previousUnexpectedDefaultsKey),
            previousLaunchStartedAt: defaults.object(
                forKey: previousUnexpectedLaunchStartedAtDefaultsKey) as? Date,
            unexpectedTerminationDetectedAt: defaults.object(
                forKey: unexpectedTerminationDetectedAtDefaultsKey) as? Date,
            priorBreadcrumbs: defaults.stringArray(forKey: previousUnexpectedBreadcrumbsDefaultsKey)
                ?? [],
            consecutiveUnexpectedLaunchCount: defaults.integer(
                forKey: LaunchFailureTracker.consecutiveCountDefaultsKey)
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
    nonisolated static func logProfileFlowTiming(
        flow: String, durationMs: Int, phase: String? = nil
    ) {
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

    /// Logs a startup `ModelContainer` failure before the recovery UI is shown.
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
        UserDefaults.standard.set(
            breadcrumbStore.snapshot(limit: maxBreadcrumbs), forKey: breadcrumbsDefaultsKey)
    }

    nonisolated private static func loadPersistedBreadcrumbs() -> [String] {
        UserDefaults.standard.stringArray(forKey: breadcrumbsDefaultsKey) ?? []
    }
}

// MARK: - Breadcrumb store

/// Thread-safe breadcrumb buffer. Marked `nonisolated` so diagnostics can record
/// from any isolation under the app's default MainActor isolation; `Mutex`
/// protects the array.
private nonisolated final class BreadcrumbStore: Sendable {
    private let entries = Mutex<[String]>([])

    func append(_ entry: String, limit: Int) {
        entries.withLock { entries in
            entries.append(entry)
            if entries.count > limit {
                entries.removeFirst(entries.count - limit)
            }
        }
    }

    func snapshot(limit: Int) -> [String] {
        entries.withLock { Array($0.suffix(limit)) }
    }
}
