//
//  AppDiagnosticsLogger.swift
//  NextSeason
//

import Foundation
import os

nonisolated(unsafe) private let diagnosticsSubsystem =
    Bundle.main.bundleIdentifier ?? "com.TrialByFyre.NextSeason"
nonisolated(unsafe) private let breadcrumbsDefaultsKey = "AppDiagnosticsLogger.breadcrumbs"
nonisolated(unsafe) private let sessionActiveDefaultsKey = "AppDiagnosticsLogger.sessionActive"
nonisolated(unsafe) private let maxBreadcrumbs = 50
nonisolated(unsafe) private let breadcrumbStore = BreadcrumbStore()

/// Structured OSLog output and breadcrumb trail for intermittent crash investigation.
///
/// Logs use the app bundle ID as subsystem so Console.app and `log stream` can filter
/// with `subsystem:com.TrialByFyre.NextSeason`. Breadcrumbs are persisted across launches
/// so the next session can report the last activity before an abrupt termination.
enum AppDiagnosticsLogger: Sendable {
    enum Category: String, Sendable {
        case lifecycle
        case scene
        case persistence
        case network
        case tasks
        case cache
        case crash
    }

    nonisolated static func logger(for category: Category) -> Logger {
        Logger(subsystem: diagnosticsSubsystem, category: category.rawValue)
    }

    // MARK: - Session lifecycle

    /// Call once during app initialization before other work runs.
    nonisolated static func recordAppLaunch() {
        let hadActiveSession = UserDefaults.standard.bool(forKey: sessionActiveDefaultsKey)
        let priorBreadcrumbs = loadPersistedBreadcrumbs()

        UserDefaults.standard.set(true, forKey: sessionActiveDefaultsKey)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let launchLogger = logger(for: .lifecycle)
        launchLogger.notice("app_launch version=\(version, privacy: .public) build=\(build, privacy: .public)")

        if hadActiveSession {
            let summary = priorBreadcrumbs.suffix(10).joined(separator: " | ")
            launchLogger.fault(
                "possible_abrupt_termination prior_breadcrumbs=\(summary, privacy: .public)"
            )
            breadcrumb("recovery_after_abrupt_termination")
        } else {
            breadcrumb("app_launch")
        }
    }

    /// Marks a graceful background transition so the next launch is not flagged as abrupt.
    nonisolated static func recordEnterBackground() {
        persistBreadcrumbs()
        UserDefaults.standard.set(false, forKey: sessionActiveDefaultsKey)
        logger(for: .scene).notice("enter_background")
        breadcrumb("enter_background")
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

    // MARK: - Crash diagnostic formatting

    nonisolated static func logCrashDiagnosticSummary(
        exceptionType: String,
        signal: String,
        terminationReason: String?,
        crashedThread: String,
        topFrames: [String]
    ) {
        let frames = topFrames.prefix(8).joined(separator: " | ")
        logger(for: .crash).fault(
            """
            metrickit_crash exception=\(exceptionType, privacy: .public) \
            signal=\(signal, privacy: .public) \
            reason=\(terminationReason ?? "none", privacy: .public) \
            thread=\(crashedThread, privacy: .public) \
            frames=\(frames, privacy: .public)
            """
        )
        breadcrumb("metrickit_crash:\(exceptionType)")
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
