//
//  AppLaunchStateTests.swift
//  NextSeasonTests
//

import Foundation
import Synchronization
import Testing

@testable import NextSeason

/// Bootstrap and recovery flows for composition failures, persistence reset, and
/// crash-loop skip. Uses injectable `makeRoot` throws and `LaunchFailureTracker` stubs.
@MainActor
struct AppLaunchStateTests {
    @Test("Bootstrap presents recovery when composition fails")
    func bootstrapPresentsRecoveryOnFailure() {
        let tracker = makeTracker()
        let state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "container failed") },
            failureTracker: tracker
        )

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery after composition failure")
            return
        }
        #expect(context.kind == .persistenceFailure)
        #expect(context.allowsPersistenceReset)
        #expect(context.allowsRetry == false)
        #expect(String(describing: context.error).contains("container failed"))
        #expect(context.resetError == nil)
        #expect(context.didResetStore == false)
        #expect(context.originalError == nil)
        let report = context.diagnosticsReport()
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("container failed"))
        #expect(report.contains("Persistence reset failure:") == false)
        #expect(report.contains("Local watchlist store reset: succeeded") == false)
        #expect(report.contains("Notifications enabled: Unavailable"))
        #expect(report.contains("Notifications enabled: false") == false)
        #expect(report.contains("Notifications enabled: true") == false)
        #expect(report.contains("Crash-loop recovery: not presented"))
    }

    @Test("Reset failure stays in recovery and is included in diagnostics")
    func resetFailureStaysInRecovery() throws {
        let tracker = makeTracker()
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "container failed") },
            failureTracker: tracker
        )

        state.resetLocalData(
            removeStore: { throw StubLaunchError(message: "disk full") },
            clearNotifications: {},
            makeRoot: { throw StubLaunchError(message: "should not retry") },
            failureTracker: tracker
        )

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery after a failed reset")
            return
        }
        #expect(context.kind == .persistenceFailure)
        #expect(context.allowsPersistenceReset)
        #expect(context.didResetStore == false)
        #expect(String(describing: context.error).contains("container failed"))
        let resetError = try #require(context.resetError)
        #expect(String(describing: resetError).contains("disk full"))
        let report = context.diagnosticsReport()
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("container failed"))
        #expect(report.contains("Persistence reset failure:"))
        #expect(report.contains("disk full"))
        #expect(report.contains("Local watchlist store reset: succeeded") == false)
    }

    @Test("Successful store removal with another open failure stays in recovery")
    func resetThenStillFailingStaysInRecovery() throws {
        let tracker = makeTracker()
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "first") },
            failureTracker: tracker
        )

        state.resetLocalData(
            removeStore: {},
            clearNotifications: {},
            makeRoot: { throw StubLaunchError(message: "second") },
            failureTracker: tracker
        )

        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery when the store still will not open")
            return
        }
        #expect(context.kind == .persistenceFailureAfterReset)
        #expect(context.didResetStore)
        #expect(context.allowsPersistenceReset == false)
        #expect(context.allowsRetry)
        #expect(context.resetError == nil)
        #expect(String(describing: context.error).contains("second"))
        let originalError = try #require(context.originalError)
        #expect(String(describing: originalError).contains("first"))
        let report = context.diagnosticsReport()
        #expect(report.contains("Original persistence failure:"))
        #expect(report.contains("first"))
        #expect(report.contains("Persistence failure:"))
        #expect(report.contains("second"))
        #expect(report.contains("Local watchlist store reset: succeeded"))
        #expect(report.contains("Persistence reset failure:") == false)
    }

    @Test("Reset runs store removal and notification clearing before retrying composition")
    func resetOrchestratesRemovalThenNotificationsThenComposition() {
        let tracker = makeTracker()
        var steps: [String] = []
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "first") },
            failureTracker: tracker
        )

        state.resetLocalData(
            removeStore: { steps.append("removeStore") },
            clearNotifications: { steps.append("clearNotifications") },
            makeRoot: {
                steps.append("makeRoot")
                throw StubLaunchError(message: "second")
            },
            failureTracker: tracker
        )

        #expect(steps == ["removeStore", "clearNotifications", "makeRoot"])
        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery when composition still fails")
            return
        }
        #expect(context.didResetStore)
    }

    @Test("Crash-loop recovery skips composition and preserves diagnostics")
    func crashLoopSkipsCompositionAndExportsDiagnostics() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        var composed = false

        let state = AppLaunchState.bootstrap(
            makeRoot: {
                composed = true
                throw StubLaunchError(message: "should not run")
            },
            failureTracker: tracker
        )

        #expect(composed == false)
        guard case .recovery(let context) = state else {
            Issue.record("Expected crash-loop recovery")
            return
        }
        #expect(context.kind == .crashLoop)
        #expect(context.allowsRetry)
        #expect(context.allowsPersistenceReset == false)
        #expect(
            context.consecutiveLaunchFailures >= LaunchFailureTracker.consecutiveFailureThreshold)
        #expect(String(describing: context.error).contains("Repeated launch failure"))
        let report = context.diagnosticsReport()
        #expect(report.contains("Repeated launch failure"))
        #expect(report.contains("Consecutive unexpected launches:"))
        #expect(report.contains("Crash-loop recovery: composition skipped"))
    }

    @Test("Crash-loop recovery does not permit a destructive persistence reset")
    func crashLoopDoesNotPermitPersistenceReset() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        var removed = false
        var composed = false
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "should not run") },
            failureTracker: tracker
        )

        state.resetLocalData(
            removeStore: { removed = true },
            clearNotifications: {},
            makeRoot: {
                composed = true
                throw StubLaunchError(message: "should not compose")
            },
            failureTracker: tracker
        )

        #expect(removed == false)
        #expect(composed == false)
        guard case .recovery(let context) = state else {
            Issue.record("Expected to remain in crash-loop recovery")
            return
        }
        #expect(context.kind == .crashLoop)
        #expect(context.allowsPersistenceReset == false)
    }

    @Test("User retry after a crash loop attempts composition")
    func crashLoopRetryAttemptsComposition() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        var composed = false
        var state = AppLaunchState.bootstrap(
            makeRoot: {
                Issue.record("Initial crash-loop bootstrap should not compose")
                throw StubLaunchError(message: "should not run")
            },
            failureTracker: tracker
        )

        state.retryLaunch(
            makeRoot: {
                composed = true
                throw StubLaunchError(message: "still failing")
            },
            failureTracker: tracker
        )

        #expect(composed)
        guard case .recovery(let context) = state else {
            Issue.record("Expected recovery when retry composition fails")
            return
        }
        #expect(context.kind == .persistenceFailure)
        #expect(context.allowsPersistenceReset)
        #expect(context.allowsRetry == false)
        #expect(String(describing: context.error).contains("still failing"))
    }

    @Test("Persistence failure after a crash-loop retry permits reset")
    func persistenceFailureAfterCrashLoopRetryPermitsReset() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "should not run") },
            failureTracker: tracker
        )
        state.retryLaunch(
            makeRoot: { throw StubLaunchError(message: "container failed") },
            failureTracker: tracker
        )
        var removed = false
        var composed = false

        state.resetLocalData(
            removeStore: { removed = true },
            clearNotifications: {},
            makeRoot: {
                composed = true
                throw StubLaunchError(message: "after reset")
            },
            failureTracker: tracker
        )

        #expect(removed)
        #expect(composed)
        guard case .recovery(let context) = state else {
            Issue.record("Expected persistence recovery after reset")
            return
        }
        #expect(context.kind == .persistenceFailureAfterReset)
        #expect(context.didResetStore)
        #expect(String(describing: context.error).contains("after reset"))
    }

    @Test("Try Again does not record another process launch")
    func retryDoesNotRecordANewProcessLaunch() {
        let clock = MutableClock(date: Date(timeIntervalSince1970: 1_000))
        let defaults = makeDefaults()
        let tracker = LaunchFailureTracker(
            defaults: defaults,
            now: { clock.date },
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: true
        )
        seedCrashLoop(tracker)
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "should not run") },
            failureTracker: tracker
        )
        let startedAt = AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
            .currentLaunchStartedAt
        let countBeforeRetry = tracker.consecutiveUnexpectedLaunchCount
        clock.date = Date(timeIntervalSince1970: 2_000)

        state.retryLaunch(
            makeRoot: { throw StubLaunchError(message: "still failing") },
            failureTracker: tracker
        )

        let startedAfterRetry = AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
            .currentLaunchStartedAt
        #expect(startedAfterRetry == startedAt)
        #expect(tracker.consecutiveUnexpectedLaunchCount == countBeforeRetry)
    }

    @Test("Reset Local Data does not record another process launch")
    func resetDoesNotRecordANewProcessLaunch() {
        let clock = MutableClock(date: Date(timeIntervalSince1970: 1_000))
        let defaults = makeDefaults()
        let tracker = LaunchFailureTracker(
            defaults: defaults,
            now: { clock.date },
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: true
        )
        var state = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "container failed") },
            failureTracker: tracker
        )
        let startedAt = AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
            .currentLaunchStartedAt
        clock.date = Date(timeIntervalSince1970: 2_000)

        state.resetLocalData(
            removeStore: {},
            clearNotifications: {},
            makeRoot: { throw StubLaunchError(message: "second") },
            failureTracker: tracker
        )

        let startedAfterReset = AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
            .currentLaunchStartedAt
        #expect(startedAfterReset == startedAt)
    }

    @Test("A later launch after crash-loop recovery still skips until marked healthy")
    func crashLoopRecoveryDoesNotAutoRetryOnNextLaunch() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        _ = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "should not run") },
            failureTracker: tracker
        )
        var composedOnRelaunch = false

        let relaunch = AppLaunchState.bootstrap(
            makeRoot: {
                composedOnRelaunch = true
                throw StubLaunchError(message: "should still skip")
            },
            failureTracker: tracker
        )

        #expect(composedOnRelaunch == false)
        guard case .recovery(let context) = relaunch else {
            Issue.record("Expected to remain in crash-loop recovery")
            return
        }
        #expect(context.kind == .crashLoop)
    }

    @Test("Marking the launch healthy allows the next launch to compose")
    func healthyLaunchAfterCrashLoopAllowsComposition() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        _ = AppLaunchState.bootstrap(
            makeRoot: { throw StubLaunchError(message: "should not run") },
            failureTracker: tracker
        )
        tracker.noteHealthyLaunch()
        var composed = false

        _ = AppLaunchState.bootstrap(
            makeRoot: {
                composed = true
                throw StubLaunchError(message: "compose ran")
            },
            failureTracker: tracker
        )

        #expect(composed)
    }

    /// Isolated `UserDefaults` suite cleared before each tracker/bootstrap test.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppLaunchStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Tracker wired to isolated defaults with unexpected-termination counting enabled.
    private func makeTracker() -> LaunchFailureTracker {
        LaunchFailureTracker(
            defaults: makeDefaults(),
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: true
        )
    }

    /// Leaves session-active so the next bootstrap is the second consecutive
    /// unexpected launch (the skip threshold).
    private func seedCrashLoop(_ tracker: LaunchFailureTracker) {
        _ = tracker.beginLaunchAttempt()
        _ = tracker.beginLaunchAttempt()
    }
}

/// Mutable test clock so retry/reset can advance time without recording a new process launch.
private final class MutableClock: Sendable {
    private let storage: Mutex<Date>

    var date: Date {
        get { storage.withLock { $0 } }
        set { storage.withLock { $0 = newValue } }
    }

    init(date: Date) {
        storage = Mutex(date)
    }
}

/// Deterministic composition/reset error with a stable string description for diagnostics.
private struct StubLaunchError: Error, LocalizedError, CustomStringConvertible {
    let message: String
    var description: String { message }
    var errorDescription: String? { message }
}
