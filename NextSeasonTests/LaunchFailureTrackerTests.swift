//
//  LaunchFailureTrackerTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

/// Crash-loop threshold, build rollover, graceful background, stabilization, and
/// debugger-attached DEBUG overrides for `LaunchFailureTracker`.
@MainActor
struct LaunchFailureTrackerTests {
    @Test("A clean first launch does not skip composition")
    func firstLaunchDoesNotSkip() {
        let tracker = makeTracker()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 0)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("A single unexpected relaunch does not skip composition")
    func oneUnexpectedLaunchDoesNotSkip() {
        let tracker = makeTracker()
        _ = tracker.beginLaunchAttempt()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 1)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("Two consecutive unexpected relaunches skip composition")
    func twoUnexpectedLaunchesSkipComposition() {
        let tracker = makeTracker()
        _ = tracker.beginLaunchAttempt()
        _ = tracker.beginLaunchAttempt()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 2)
        #expect(result.shouldSkipComposition)
    }

    @Test("Reaching a safe path does not increment the count on the next launch")
    func safePathDoesNotIncrementOnNextLaunch() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        let looping = tracker.beginLaunchAttempt()
        #expect(looping.shouldSkipComposition)
        let countAtRecovery = looping.consecutiveUnexpectedLaunchCount
        tracker.noteReachedSafePath()

        let next = tracker.beginLaunchAttempt()

        #expect(next.consecutiveUnexpectedLaunchCount == countAtRecovery)
        #expect(next.shouldSkipComposition)
    }

    @Test("A healthy launch clears the guard so the next launch can compose")
    func healthyLaunchClearsGuard() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition)
        tracker.noteReachedSafePath()
        tracker.noteHealthyLaunch()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 0)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("A graceful background does not count as an unexpected launch")
    func gracefulBackgroundDoesNotIncrement() {
        let defaults = makeDefaults()
        let tracker = LaunchFailureTracker(
            defaults: defaults,
            countsPreviousUnexpectedTermination: true
        )
        _ = tracker.beginLaunchAttempt()
        AppDiagnosticsLogger.recordEnterBackground(defaults: defaults)

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 0)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("Successful composition after recovery makes a later crash count as unexpected")
    func compositionSucceededRestoresSessionActive() {
        let tracker = makeTracker()
        _ = tracker.beginLaunchAttempt()
        tracker.noteReachedSafePath()
        tracker.noteCompositionSucceeded()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 1)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("Repeated failures within the same build still trip the guard")
    func sameBuildStillProtects() {
        let defaults = makeDefaults()
        let tracker = LaunchFailureTracker(
            defaults: defaults,
            buildIdentifier: "1",
            countsPreviousUnexpectedTermination: true
        )
        seedCrashLoop(tracker)

        let result = tracker.beginLaunchAttempt()

        #expect(result.shouldSkipComposition)
        #expect(result.consecutiveUnexpectedLaunchCount == 2)
    }

    @Test("A newly installed build starts at zero and only counts its own unexpected terminations")
    func newBuildStartsAtZeroThenCountsItsOwnFailures() {
        let defaults = makeDefaults()
        let buildA = LaunchFailureTracker(
            defaults: defaults,
            buildIdentifier: "100",
            countsPreviousUnexpectedTermination: true
        )
        seedCrashLoop(buildA)
        let looping = buildA.beginLaunchAttempt()
        #expect(looping.shouldSkipComposition)
        #expect(looping.consecutiveUnexpectedLaunchCount == 2)

        let buildB = LaunchFailureTracker(
            defaults: defaults,
            buildIdentifier: "101",
            countsPreviousUnexpectedTermination: true
        )
        let firstLaunch = buildB.beginLaunchAttempt()
        let diagnostics = AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
        #expect(diagnostics.previousLaunchEndedUnexpectedly)
        #expect(firstLaunch.consecutiveUnexpectedLaunchCount == 0)
        #expect(firstLaunch.shouldSkipComposition == false)

        let secondLaunch = buildB.beginLaunchAttempt()
        #expect(secondLaunch.consecutiveUnexpectedLaunchCount == 1)
        #expect(secondLaunch.shouldSkipComposition == false)

        let thirdLaunch = buildB.beginLaunchAttempt()
        #expect(thirdLaunch.consecutiveUnexpectedLaunchCount == 2)
        #expect(thirdLaunch.shouldSkipComposition)
    }

    @Test("Stabilization does not mark a launch healthy when the wait is cancelled")
    func cancelledStabilizationDoesNotMarkHealthy() async {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition)
        let countBefore = tracker.consecutiveUnexpectedLaunchCount

        await LaunchStabilization.waitUntilStable(
            tracker: tracker,
            sleep: { _ in throw CancellationError() }
        )

        #expect(tracker.consecutiveUnexpectedLaunchCount == countBefore)
    }

    @Test("Crash-loop detection does not clear the consecutive-failure count")
    func crashLoopDetectionDoesNotClearTheCount() {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition)

        #expect(
            tracker.consecutiveUnexpectedLaunchCount
                >= LaunchFailureTracker.consecutiveFailureThreshold
        )
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition)
    }

    @Test("Completed stabilization clears the crash-loop count")
    func completedStabilizationMarksHealthy() async {
        let tracker = makeTracker()
        seedCrashLoop(tracker)
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition)
        var slept: Duration?

        await LaunchStabilization.waitUntilStable(
            tracker: tracker,
            sleep: { duration in slept = duration }
        )

        #expect(slept == LaunchStabilization.duration)
        #expect(tracker.consecutiveUnexpectedLaunchCount == 0)
        #expect(tracker.beginLaunchAttempt().shouldSkipComposition == false)
    }

    @Test("A debugger-attached DEBUG launch does not count an unexpected termination")
    func debuggerAttachedWithoutOverrideDoesNotCount() {
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: true,
                arguments: [],
                isDebugBuild: true
            ) == false
        )

        let defaults = makeDefaults()
        let tracker = LaunchFailureTracker(
            defaults: defaults,
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: false
        )
        _ = tracker.beginLaunchAttempt()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 0)
        #expect(result.shouldSkipComposition == false)
        #expect(
            AppDiagnosticsLogger.launchDiagnostics(defaults: defaults)
                .previousLaunchEndedUnexpectedly
        )
    }

    @Test("A debugger-attached DEBUG launch counts when the override is present")
    func debuggerAttachedWithOverrideCounts() {
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: true,
                arguments: [LaunchFailureTracker.enableCrashLoopDetectionArgument],
                isDebugBuild: true
            )
        )

        let tracker = LaunchFailureTracker(
            defaults: makeDefaults(),
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: true
        )
        _ = tracker.beginLaunchAttempt()

        let result = tracker.beginLaunchAttempt()

        #expect(result.consecutiveUnexpectedLaunchCount == 1)
        #expect(result.shouldSkipComposition == false)
    }

    @Test("A DEBUG launch without a debugger counts unexpected terminations")
    func debuggerNotAttachedCounts() {
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: false,
                arguments: [],
                isDebugBuild: true
            )
        )
    }

    @Test("Release builds count unexpected terminations even if a debugger is attached")
    func releaseBuildAlwaysCounts() {
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: true,
                arguments: [],
                isDebugBuild: false
            )
        )
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: true,
                arguments: [LaunchFailureTracker.enableCrashLoopDetectionArgument],
                isDebugBuild: false
            )
        )
        #expect(
            LaunchFailureTracker.shouldCountPreviousUnexpectedTermination(
                isDebuggerAttached: false,
                arguments: [],
                isDebugBuild: false
            )
        )
    }

    /// Isolated `UserDefaults` suite cleared before each launch-attempt sequence.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "LaunchFailureTrackerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Tracker with unexpected-termination counting enabled (production-like default).
    private func makeTracker() -> LaunchFailureTracker {
        LaunchFailureTracker(
            defaults: makeDefaults(),
            buildIdentifier: "test-build",
            countsPreviousUnexpectedTermination: true
        )
    }

    /// Leaves session-active so the next `beginLaunchAttempt` is the second
    /// consecutive unexpected launch (the skip threshold).
    private func seedCrashLoop(_ tracker: LaunchFailureTracker) {
        _ = tracker.beginLaunchAttempt()
        _ = tracker.beginLaunchAttempt()
    }
}
