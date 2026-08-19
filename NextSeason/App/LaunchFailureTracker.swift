//
//  LaunchFailureTracker.swift
//  NextSeason
//

import Foundation
import os

/// Detects repeated unexpected process launches so bootstrap can skip opening
/// the watchlist store and show a safe recovery UI instead of crashing again.
///
/// Lifecycle:
/// - **Launch attempt:** `beginLaunchAttempt()` runs once per process start.
///   An unexpected launch is one where the previous session never reached
///   `recordEnterBackground` or `noteReachedSafePath`. Two consecutive
///   detections are treated as a crash loop.
/// - **Safe recovery path:** `noteReachedSafePath()` after the recovery UI is
///   showing, so force-quitting recovery is not counted as another launch
///   crash. Does not clear the consecutive-failure count.
/// - **Composition succeeded:** `noteCompositionSucceeded()` after
///   `AppCompositionRoot` is created in this already-running process, so a
///   later crash is attributed to this session.
/// - **Stable/healthy launch:** `noteHealthyLaunch()` only after the main UI
///   has stayed `.active` through `LaunchStabilization.duration`. Appearing
///   on screen is not enough.
///
/// A newly installed build (different `CFBundleVersion`) starts a new
/// crash-loop streak at zero. An unexpected termination left by the
/// previous build is still recorded in launch diagnostics, but it does
/// not count as a failure of the new build. Repeated failures *within*
/// the same build still trip the guard.
struct LaunchFailureTracker: Sendable {
    static let consecutiveFailureThreshold = 2
    nonisolated static let consecutiveCountDefaultsKey =
        "LaunchFailureTracker.consecutiveUnexpectedLaunchCount"
    nonisolated static let lastRecordedBuildDefaultsKey =
        "LaunchFailureTracker.lastRecordedBuild"

    private let defaults: UserDefaults
    private let now: @Sendable () -> Date
    private let buildIdentifier: String

    init(
        defaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> Date = { Date.now },
        buildIdentifier: String = AppVersionInfo.buildNumber
    ) {
        self.defaults = defaults
        self.now = now
        self.buildIdentifier = buildIdentifier
    }

    var consecutiveUnexpectedLaunchCount: Int {
        defaults.integer(forKey: Self.consecutiveCountDefaultsKey)
    }

    /// Records this process launch, updates the consecutive-failure count,
    /// and reports whether composition should be skipped.
    ///
    /// Call once per process start — not when retrying composition in an
    /// already-running process.
    ///
    /// Order is intentional: launch diagnostics are recorded first (so an
    /// older build's unexpected exit is still visible), then a new build
    /// starts a zero streak without counting that older exit. Only an
    /// unexpected exit that belongs to the current build increments the
    /// consecutive-failure count.
    func beginLaunchAttempt() -> LaunchAttemptResult {
        AppDiagnosticsLogger.recordAppLaunch(defaults: defaults, now: now())
        let previousEndedUnexpectedly = AppDiagnosticsLogger.launchDiagnostics(
            defaults: defaults
        ).previousLaunchEndedUnexpectedly

        if isLaunchOfADifferentBuild {
            startFreshStreakForCurrentBuild()
        } else if previousEndedUnexpectedly {
            defaults.set(
                consecutiveUnexpectedLaunchCount + 1,
                forKey: Self.consecutiveCountDefaultsKey
            )
        }

        let count = consecutiveUnexpectedLaunchCount
        let shouldSkip = count >= Self.consecutiveFailureThreshold
        if shouldSkip {
            AppDiagnosticsLogger.logger(for: .lifecycle).fault(
                "crash_loop_detected consecutive_unexpected_launches=\(count, privacy: .public)"
            )
        }
        return LaunchAttemptResult(
            consecutiveUnexpectedLaunchCount: count,
            shouldSkipComposition: shouldSkip
        )
    }

    /// Marks that the recovery UI is on screen so force-quitting this session
    /// is not counted as another launch crash. Does not clear the
    /// consecutive-failure count.
    func noteReachedSafePath() {
        AppDiagnosticsLogger.noteReachedSafePath(defaults: defaults)
    }

    /// Marks that composition succeeded in this already-running process.
    /// A crash from here counts toward the consecutive-failure streak until
    /// the launch is marked healthy or the app backgrounds.
    func noteCompositionSucceeded() {
        AppDiagnosticsLogger.noteSessionActive(defaults: defaults)
    }

    /// Clears the consecutive-failure count after the launch has remained
    /// active through the stabilization period.
    func noteHealthyLaunch() {
        defaults.set(0, forKey: Self.consecutiveCountDefaultsKey)
        AppDiagnosticsLogger.breadcrumb("launch_marked_healthy")
        AppDiagnosticsLogger.persistBreadcrumbsNow()
    }

    private var isLaunchOfADifferentBuild: Bool {
        defaults.string(forKey: Self.lastRecordedBuildDefaultsKey) != buildIdentifier
    }

    /// Zeros the streak and records this build. Does not increment for an
    /// unexpected termination that belonged to the previous build.
    private func startFreshStreakForCurrentBuild() {
        defaults.set(0, forKey: Self.consecutiveCountDefaultsKey)
        defaults.set(buildIdentifier, forKey: Self.lastRecordedBuildDefaultsKey)
    }
}

/// Snapshot returned by `LaunchFailureTracker.beginLaunchAttempt()`.
struct LaunchAttemptResult: Sendable, Equatable {
    let consecutiveUnexpectedLaunchCount: Int
    let shouldSkipComposition: Bool
}

/// Recorded when bootstrap skips `ModelContainer` because of a crash loop.
/// Included in diagnostics export; not shown as raw text in the recovery UI.
struct RepeatedLaunchFailure: Error, CustomStringConvertible {
    let consecutiveCount: Int

    var description: String {
        "Repeated launch failure (consecutive unexpected launches: \(consecutiveCount))"
    }
}

/// Waits until the main UI has stayed active long enough to treat the launch
/// as stable. Immediate startup crashes must still accumulate toward the
/// crash-loop threshold; network success is not part of this definition.
///
/// Call from the ready UI while `scenePhase == .active`. Cancel the wait
/// when leaving `.active` so backgrounding during startup is neither a
/// healthy launch nor a crash (`recordEnterBackground` still marks a
/// graceful exit).
enum LaunchStabilization {
    /// Long enough to outlast first-frame / immediate startup crashes,
    /// short enough that a normal launch is not delayed. The UI is not blocked.
    static let duration: Duration = .seconds(2)

    static func waitUntilStable(
        tracker: LaunchFailureTracker = LaunchFailureTracker(),
        duration: Duration = LaunchStabilization.duration,
        sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) async {
        do {
            try await sleep(duration)
            guard Task.isCancelled == false else { return }
            tracker.noteHealthyLaunch()
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }
}
