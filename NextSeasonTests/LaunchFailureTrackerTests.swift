//
//  LaunchFailureTrackerTests.swift
//  NextSeasonTests
//

import Foundation
import Testing

@testable import NextSeason

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
        let tracker = LaunchFailureTracker(defaults: defaults)
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
        let tracker = LaunchFailureTracker(defaults: defaults, buildIdentifier: "1")
        seedCrashLoop(tracker)

        let result = tracker.beginLaunchAttempt()

        #expect(result.shouldSkipComposition)
        #expect(result.consecutiveUnexpectedLaunchCount == 2)
    }

    @Test("A newly installed build starts at zero and only counts its own unexpected terminations")
    func newBuildStartsAtZeroThenCountsItsOwnFailures() {
        let defaults = makeDefaults()
        let buildA = LaunchFailureTracker(defaults: defaults, buildIdentifier: "100")
        seedCrashLoop(buildA)
        let looping = buildA.beginLaunchAttempt()
        #expect(looping.shouldSkipComposition)
        #expect(looping.consecutiveUnexpectedLaunchCount == 2)

        let buildB = LaunchFailureTracker(defaults: defaults, buildIdentifier: "101")
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

    private func makeDefaults() -> UserDefaults {
        let suiteName = "LaunchFailureTrackerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeTracker() -> LaunchFailureTracker {
        LaunchFailureTracker(defaults: makeDefaults(), buildIdentifier: "test-build")
    }

    /// Leaves session-active so the next `beginLaunchAttempt` is the second
    /// consecutive unexpected launch (the skip threshold).
    private func seedCrashLoop(_ tracker: LaunchFailureTracker) {
        _ = tracker.beginLaunchAttempt()
        _ = tracker.beginLaunchAttempt()
    }
}
