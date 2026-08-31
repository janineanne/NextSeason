# Crash-loop prevention strategy

## User

Please implement Crash-Loop Prevention

- Detect repeated launch failures where practical.
- Offer a safe recovery path rather than repeatedly crashing.
- Preserve useful diagnostics for troubleshooting.
- Verify that recovery does not create a new launch loop.

## Assistant

I'll start by reading the Swift skills and the existing persistence-recovery work so crash-loop prevention fits the current launch path.

Persistence recovery already avoids `fatalError` on store failure. I'll look at the crash-loop notes and launch diagnostics next so the new path can detect repeats without looping.

Crash-loop prevention will sit on the existing launch recovery path: count consecutive unexpected exits, skip store open after a repeat, and only retry composition after an explicit user action so recovery itself cannot loop.

Crash-loop prevention is in place on the existing launch recovery path. After two consecutive unexpected exits, NextSeason skips opening the watchlist store and shows a safe screen instead of trying to launch again.

**How it works**
- Each launch records whether the previous session ended unexpectedly (no background, no recovery UI).
- **Two** consecutive detections count as a loop — enough to be “repeated” without trapping a single force-quit or OS kill.
- On a loop, bootstrap **does not** create `ModelContainer` (that open is a common crash site). You get **NextSeason Closed Repeatedly** with Export Diagnostics, **Try Again** (no data loss), and **Reset Local Data** (still confirmed).
- Try Again and Reset both bypass the skip, so recovery cannot immediately loop back into “skip composition.”
- The consecutive count stays until the main UI is actually on screen. A successful retry that then crashes still returns to the safe screen on the next cold start.

**Diagnostics**
Exported reports now include consecutive unexpected launches, whether composition was skipped, and the `Repeated launch failure` error. The Diagnostics screen shows the consecutive-launch count as well.

**What to test**
1. Normal launch still opens Search and Watchlist.
2. Preview **Crash loop** on `PersistenceRecoveryView` — copy should not claim the watchlist failed to open, and Try Again should sit next to Reset.
3. After a real recovery, confirm Export still includes launch breadcrumbs and the consecutive-launch line.
4. VoiceOver: Export, Try Again, and Reset should be separate actions; Reset still requires confirmation.

Relevant tests: 23 passed (`LaunchFailureTrackerTests`, `AppLaunchStateTests`, `AnalyticsDiagnosticsReportTests`, `PersistentStoreResetTests`).

Skills used: `swiftui-pro`, `swiftdata-pro`, `swift-testing-pro`, `swift-concurrency-pro`.

## User

Please revise the crash-loop prevention implementation based on a detailed code review.

The overall architecture is good, so do not redesign the feature from scratch. Keep LaunchFailureTracker, the persistent session-active approach, the threshold of two consecutive unexpected launch failures, the existing persistence recovery flow, and the existing diagnostics support.

Please address the following issues comprehensively.

1. Do not mark a launch healthy merely because AppRootView appeared

Currently AppRootView calls:

.task {
    guard !UITestingConfiguration.isEnabled else { return }
    LaunchFailureTracker().noteHealthyLaunch()
}

This clears the consecutive unexpected-launch count too early.

Initial foreground/startup work begins at roughly the same time, including work such as:

await refreshService.refreshAllIfNeeded()
await onForegroundShowIDMappingRefresh()

A repeatable crash in this startup-adjacent work could therefore happen after noteHealthyLaunch() has reset the counter. On the next launch the count would start again at one, potentially allowing the app to crash indefinitely without ever reaching the crash-loop threshold.

Required change

Define a more meaningful launch stabilization point.

The app should not call noteHealthyLaunch() simply because the first SwiftUI view appeared. It should only clear the crash-loop state after the app has demonstrated that it can remain running beyond immediate startup.

Use a simple, robust solution appropriate for this app. A short cancellable stabilization period after the main UI becomes active is acceptable and may be preferable to coupling crash-loop tracking to every individual startup task.

Requirements:

* Immediate/repeatable startup crashes must accumulate toward the crash-loop threshold.
* Once the app has remained operational through the stabilization point, clear the consecutive unexpected-launch state.
* Do not make launch health depend on successful network requests or other operations that can legitimately fail.
* Do not make normal launch noticeably slower.
* Do not block the UI while waiting for stabilization.
* Preserve the existing UI-testing behavior.
* Keep the lifecycle logic explicit and testable rather than burying arbitrary timing behavior directly in a SwiftUI view if a small abstraction would make the intent clearer.
* Ensure any stabilization task is correctly cancelled/handled as the scene lifecycle changes so that backgrounding during startup does not accidentally count as either a healthy launch or a crash.

Add focused tests for this behavior. In particular, demonstrate that the crash-loop state is not cleared merely by reaching the initial UI, but is cleared after the defined healthy/stable-launch condition.

Do not attempt to unit-test SwiftUI task scheduling itself. Extract/test the lifecycle behavior at an appropriate boundary.

2. Do not offer destructive persistence reset merely because a crash loop was detected

The crash-loop guard currently routes into PersistenceRecoveryView, where Reset Local Data can be offered even though composition was intentionally skipped and SwiftData has not failed to open.

A generic early-launch crash is not evidence that the persistence store is corrupt.

For a crash-loop-triggered recovery state, the initial choices should be limited to appropriate non-destructive actions such as:

* Export Diagnostics
* Try Again

Do not offer Reset Local Data solely because repeated unexpected launch failures were detected.

When the user chooses Try Again, actually retry normal composition while bypassing the crash-loop guard for that explicit attempt.

If that composition attempt then fails in the existing persistence-opening path, transition into the normal persistence-recovery state. At that point it is appropriate to offer Reset Local Data, because persistence has actually been implicated.

Please model this distinction cleanly in the recovery state rather than relying on fragile view-level special cases.

Add/update tests proving that:

* generic crash-loop recovery does not expose/permit the destructive persistence reset;
* Try Again really attempts composition;
* if that retry produces a persistence-opening failure, the resulting recovery state permits the existing persistence reset flow;
* existing persistence recovery behavior continues to work.

3. Separate a real process launch from an in-process composition retry

Currently retryLaunch() and resetLocalData() call back through bootstrap(...), and bootstrap() calls:

failureTracker.beginLaunchAttempt()

As a result, pressing Try Again can be recorded diagnostically as another app launch even though the process never relaunched.

Refactor this so the lifecycle semantics are accurate.

There should be a clear distinction between:

1. beginning an actual application/process launch, including updating launch diagnostics and crash-loop tracking; and
2. attempting/retrying construction of AppCompositionRoot inside an already-running process.

A private helper such as attemptComposition(...) is reasonable if it fits the existing design.

Requirements:

* beginLaunchAttempt() should run once for the actual process launch, not every time composition is retried.
* Try Again should bypass the crash-loop guard and retry composition without pretending another process launch occurred.
* Reset Local Data should reset the persistence store and retry composition without recording a fictitious process launch.
* Keep diagnostic timestamps/breadcrumbs semantically accurate.
* Avoid unnecessary duplication among bootstrap, retry, and reset paths.

Update tests accordingly.

4. Do not let crash-loop state from an old build unnecessarily block a newly installed update

The persistent consecutive-failure count currently survives an application update.

That can produce this sequence:

1. Build A has a repeatable early-launch crash.
2. The crash-loop threshold is reached.
3. The user installs Build B containing a fix.
4. Build B still immediately enters crash-loop recovery because Build A’s failure state persisted.

Track enough build identity alongside the crash-loop state to recognize this situation.

On the first launch of a different app build, allow the new build a normal launch attempt rather than immediately blocking it because of the previous build’s crash-loop count.

Please use an appropriate stable build identifier already available from the bundle (prefer the build number where appropriate) rather than inventing application-level version infrastructure.

Requirements:

* Do not weaken crash-loop protection for repeated failures within the same build.
* A newly installed build should receive a fresh opportunity to launch normally.
* Keep the behavior deterministic and unit-testable.
* Do not overengineer migration of these small UserDefaults values.

Add tests covering same-build and changed-build behavior.

5. Tighten breadcrumbs/comments while touching this code

Review the documentation/comments on LaunchFailureTracker so they accurately describe the distinction between:

* launch attempt;
* safe recovery path;
* stable/healthy launch.

In particular, don’t describe noteReachedSafePath() as something the normal main-app path does if that is no longer true.

Also inspect this ordering:

persistBreadcrumbs()
breadcrumb("safe_recovery_path_reached")

If the intention is for safe_recovery_path_reached to survive an immediate subsequent termination, record the breadcrumb before persisting it.

Apply the same reasoning to nearby diagnostic breadcrumb persistence, but do not turn this task into a broad unrelated diagnostics refactor.

Testing and scope

Preserve the good test coverage already added for LaunchFailureTracker, including:

* one unexpected termination does not trip the guard;
* repeated unexpected launches do;
* composition is skipped after the threshold;
* explicit retry bypasses the guard;
* reset/recovery behavior;
* reaching recovery does not itself continue incrementing the failure count;
* a genuinely healthy launch clears the state;
* graceful backgrounding does not count as an unexpected launch;
* diagnostics include useful crash-loop information.

Update these tests as necessary for the corrected lifecycle semantics and add the new cases described above.

Run the complete relevant unit-test suite after making the changes.

Also make sure the new source and test files, including LaunchFailureTracker.swift and LaunchFailureTrackerTests.swift, are included in the project/repository and not accidentally left as untracked files.

Constraints

* Do not change unrelated application behavior.
* Do not redesign the existing persistence recovery system unnecessarily.
* Do not add third-party dependencies.
* Do not add production analytics for crash reporting.
* Do not make network success part of the definition of a healthy launch.
* Do not weaken the existing user-data protections around persistence reset.
* Prefer small, explicit types/state over booleans whose meaning depends on context.
* Maintain the project’s existing concurrency style and Swift formatting conventions.
* Keep the implementation portfolio-quality: clear naming, explicit lifecycle semantics, useful focused tests, and no speculative abstraction beyond what this feature needs.

When finished, summarize:

1. the lifecycle definition now used for a healthy launch;
2. how crash-loop recovery differs from persistence-failure recovery;
3. how in-process retry differs from an actual process launch;
4. how build changes affect the persisted crash-loop state;
5. tests added or changed;
6. all files modified or added;
7. test results.

## Assistant

I'll keep the current crash-loop architecture and tighten the five review items: healthy-launch timing, reset availability, in-process retry vs process launch, build identity, and breadcrumb accuracy.

I'll keep the same tracker and recovery flow, then fix healthy-launch timing, hide reset until persistence actually fails, stop treating retries as new launches, and reset crash-loop state across builds.

The new tracker files were still untracked; I'll add them to the repo so they stay with the rest of this work.

Crash-loop prevention now uses a clearer lifecycle: a launch is healthy only after a 2-second active wait, reset is offered only after a real persistence failure, and in-process retries are no longer treated as new process launches.

**Skills used:** `swiftui-pro`, `swift-testing-pro`, `swift-concurrency-pro`

### 1. Healthy-launch definition
The main UI becoming visible is not enough. `LaunchStabilization` waits **2 seconds** after `scenePhase == .active`, then calls `noteHealthyLaunch()`. The wait is cancelled when leaving `.active`, so backgrounding during startup is neither a healthy launch nor a crash (`recordEnterBackground` still marks a graceful exit). Network success is not part of the definition, and the UI is not blocked.

### 2. Crash-loop vs persistence recovery
`RecoveryKind` makes the distinction explicit:

- **`.crashLoop`** — Export Diagnostics and Try Again only. No Reset Local Data.
- **`.persistenceFailure`** — existing persistence recovery, including Reset Local Data.
- **`.persistenceFailureAfterReset`** — store already wiped; Try Again, no second reset.

Try Again after a crash loop actually attempts composition. If that throw is a persistence-open failure, the state becomes `.persistenceFailure` and Reset is then allowed. `resetLocalData()` is a no-op unless `allowsPersistenceReset` is true.

### 3. Process launch vs in-process retry
`beginLaunchAttempt()` runs only from `bootstrap()` (once per process). `retryLaunch()` and `resetLocalData()` call private `attemptComposition()`, which does not record a launch or consult the crash-loop skip. Successful composition calls `noteCompositionSucceeded()` so a later crash still counts toward the streak.

### 4. Build changes
The tracker stores `CFBundleVersion` beside the consecutive-failure count. On the first launch of a different build, the count is cleared so the new build can launch normally. Repeated failures **within the same build** still trip the guard.

### 5. Tests added or changed
Updated `LaunchFailureTrackerTests` and `AppLaunchStateTests` for the new lifecycle, plus:

- stabilization cancelled vs completed
- crash-loop recovery does not permit reset
- Try Again attempts composition and, on persistence failure, then permits reset
- Try Again / Reset do not record a new process launch
- same-build vs new-build behavior

### 6. Files
**Added (now staged):** `NextSeason/App/LaunchFailureTracker.swift`, `NextSeasonTests/LaunchFailureTrackerTests.swift`

**Modified:** `AppLaunchState.swift`, `PersistenceRecoveryView.swift`, `NextSeasonApp.swift`, `AppDiagnosticsLogger.swift`, `AppCompositionRoot.swift`, `AnalyticsDiagnosticsReport.swift`, `DiagnosticsView.swift`, `AppLaunchStateTests.swift`, `AnalyticsCountersTests.swift`

### 7. Test results
**32 tests in 4 suites passed** (`LaunchFailureTrackerTests`, `AppLaunchStateTests`, `AnalyticsDiagnosticsReportTests`, `PersistentStoreResetTests`).

**What to test in the UI:** Preview **Crash loop** should show Export and Try Again only (no Reset). After Try Again, if the store still will not open, Reset should appear as in the existing persistence flow.

## User

Please make one final focused correction to the crash-loop prevention implementation. Do not redesign the feature; the current architecture is good.

Fix new-build crash-loop counting

LaunchFailureTracker correctly recognizes when the app’s build identifier has changed and resets the consecutive unexpected-launch count.

However, beginLaunchAttempt() currently records the new launch and determines that the previous session ended unexpectedly, then resets the counter for the changed build, and then increments the counter based on that previous unexpected termination.

This means an unexpected termination belonging to the old build becomes failure #1 for the new build.

For example:

1. Build 100 is crash-looping and leaves its session-active marker set.
2. The user installs build 101.
3. Build 101 detects that build 100 ended unexpectedly.
4. The build-change logic resets the consecutive count.
5. The code then increments it to 1 because the previous launch ended unexpectedly.
6. If build 101 crashes on its first attempt, its second launch reaches the threshold of 2.

The intent of the build-aware reset is that a newly installed build receives a genuinely fresh opportunity to launch. Failures from an older build must not contribute to the new build’s consecutive crash-loop count.

Required behavior

On the first process launch of a different build:

* Preserve the fact that the previous session ended unexpectedly in diagnostics if that information is useful.
* Reset the crash-loop streak for the new build.
* Do not count the old build’s unexpected termination toward the new build’s consecutive-failure count.
* The new build’s first launch should therefore begin with consecutiveUnexpectedLaunchCount == 0.
* If the new build itself crashes unexpectedly, its next launch should count that as failure #1.
* Only failures belonging to the current build should accumulate toward consecutiveFailureThreshold.

Please structure the ordering/state logic so this behavior is explicit rather than depending on a reset followed by a compensating decrement or similar workaround.

Tests

Update/add focused tests proving the complete build-boundary behavior:

1. A build that has accumulated crash-loop failures reaches the normal threshold.
2. Changing to a new build causes its first launch to have:

consecutiveUnexpectedLaunchCount == 0

    even if the previous build left an active-session marker indicating unexpected termination.
3. If that new build then terminates unexpectedly, its next process launch has a count of 1.
4. A second consecutive unexpected termination in that same new build reaches the existing threshold normally.
5. Same-build behavior remains unchanged.
6. Diagnostic information about the previous unexpected termination remains accurate if appropriate.

Please tighten the existing changed-build test rather than merely asserting that the result is below the threshold. It should explicitly verify the intended zero count.

Small test cleanup

While touching these tests, review the test currently named approximately:

“Stabilization does not mark a launch healthy until the wait completes”

If it does not actually exercise LaunchStabilization or its timing behavior, either rename it so its name accurately describes what it proves or adjust it to test the stated behavior.

Do not broaden this into additional launch-lifecycle work; the existing two-second stabilization design is acceptable.

Scope

* Do not change the crash-loop threshold.
* Do not change the two-second launch stabilization period.
* Do not change the new RecoveryKind model.
* Do not change the distinction between crash-loop recovery and persistence recovery.
* Do not change the in-process composition retry design.
* Do not add dependencies.
* Do not make unrelated cleanup changes.

Run the complete relevant test suite after the change.

When finished, summarize:

1. how the build-boundary counting logic changed;
2. the tests added or modified;
3. all files changed;
4. test results.

## Assistant

I'll keep the current architecture and only fix new-build counting so an old build's unexpected exit doesn't become failure #1 for the new build.

A newly installed build now starts its crash-loop streak at zero. An unexpected exit from the previous build stays in diagnostics, but it is not counted as failure #1 for the new build.

**Skills used:** `swift-testing-pro`

### 1. Build-boundary counting
`beginLaunchAttempt()` now records launch diagnostics first, then branches explicitly:

- **Different build:** start a fresh streak at 0 and record the new build id. Do not increment, even if the previous session ended unexpectedly.
- **Same build:** increment only when that previous unexpected termination belongs to this build.

There is no reset-then-increment. Failures from an older build never contribute to the new build’s count. If build 101 crashes on its first attempt, the next launch is failure #1; a second consecutive unexpected exit still reaches the existing threshold of 2.

### 2. Tests
- Replaced the loose “below threshold” new-build test with `newBuildStartsAtZeroThenCountsItsOwnFailures`: build 100 reaches 2; build 101’s first launch is **0** with `previousLaunchEndedUnexpectedly` still true; its next launches are 1 then 2.
- Left `sameBuildStillProtects` unchanged.
- Renamed the misnamed stabilization test to **Crash-loop detection does not clear the consecutive-failure count**, which is what it actually asserts.

### 3. Files changed
- `NextSeason/App/LaunchFailureTracker.swift`
- `NextSeasonTests/LaunchFailureTrackerTests.swift`

### 4. Test results
**32 tests in 4 suites passed** (`LaunchFailureTrackerTests`, `AppLaunchStateTests`, `AnalyticsDiagnosticsReportTests`, `PersistentStoreResetTests`).

