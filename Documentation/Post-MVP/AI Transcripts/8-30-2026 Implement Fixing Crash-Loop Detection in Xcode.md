# Crash-loop detection update

## User

Update the crash-loop detector so that normal development in Xcode does not cause false crash detections when I stop the app with Xcode’s Stop button.

Currently, if the app is launched from Xcode and I stop it, the next launch can interpret that abrupt termination as a crash. This pollutes the crash-loop history and can eventually trigger crash-loop recovery even though the app has not actually been crashing.

Please make the following changes:

* In DEBUG builds, detect whether the app is currently running with a debugger attached.
* When a debugger is attached, do not record/count the previous abnormal termination as a crash for crash-loop detection purposes.
* Do NOT simply disable crash-loop detection for all Simulator runs. I still want to be able to launch the app normally in the Simulator without Xcode attached and exercise the real crash-loop behavior.
* Release/TestFlight/App Store behavior must remain completely unchanged.
* Add a DEBUG-only launch argument that overrides the debugger exclusion and enables normal crash-loop detection while the debugger is attached. Use a clear name such as --enable-crash-loop-detection. This will allow intentional testing of the crash-loop recovery flow from Xcode.
* Keep the debugger-detection/override logic narrowly scoped to crash-loop detection; it should not affect other diagnostics, persistence recovery, logging, or app behavior.
* Add or update tests where practical to cover the decision logic, particularly:
    * debugger attached + no override → do not count abnormal termination
    * debugger attached + override → count normally
    * debugger not attached → count normally
    * release behavior remains unaffected

Please first inspect the existing crash-loop implementation and integrate this into its current design rather than introducing a parallel mechanism or unnecessarily restructuring the code.

Preserve the project’s existing formatting and whitespace conventions. Do not perform unrelated cleanup or refactoring.

## Assistant

I'll start by inspecting the existing crash-loop implementation and the relevant Swift skills so we can integrate debugger exclusion into the current design.

The crash-loop logic lives in `LaunchFailureTracker` and its tests. I'll read those next so the debugger exclusion can plug into the existing design.

The app uses MainActor isolation by default, so I'll match that when adding the debugger-exclusion path. Next I'll wire it into `LaunchFailureTracker` and update the tests.

The increment already happens after diagnostics are recorded, so I'll add a DEBUG-only skip there when a debugger is attached (unless the override argument is set). Existing tests will inject “count normally” so they keep working under Xcode.

The production logic is in place. I'll move the debugger helper onto the tracker type, then update the tests so they still count crashes when Xcode’s debugger is attached.

Tests passed. I'll do a Release compile next to confirm the `#else` path has no unused-parameter warnings.

I'll consolidate the DEBUG-only code so Release doesn't compile unused debugger helpers or unused parameters.

Xcode Stop is no longer counted as a crash in DEBUG when a debugger is attached. Release, TestFlight, and App Store behavior is unchanged.

The skip lives in the existing increment path in `LaunchFailureTracker.beginLaunchAttempt()`. Launch diagnostics still record the unexpected termination; only the crash-loop streak is skipped. Simulator launches without Xcode attached still use the real detector.

**Skills used:** `swift-testing-pro`, `swift-concurrency-pro`

### How it works

In DEBUG, `beginLaunchAttempt()` asks whether a debugger is attached (`P_TRACED`). If it is, the previous abnormal termination is not added to the consecutive-failure count.

To exercise the real crash-loop recovery flow from Xcode, add this launch argument:

`--enable-crash-loop-detection`

That override is DEBUG-only. It does not change diagnostics, persistence recovery, or other app behavior.

### Tests

`LaunchFailureTrackerTests` now covers:

- debugger attached + no override → do not count (diagnostics still record the termination)
- debugger attached + `--enable-crash-loop-detection` → count normally
- debugger not attached → count normally
- release-style decision (`isDebugBuild: false`) → always count

Existing crash-loop tests explicitly enable counting so they still pass when Xcode’s debugger is attached. All 16 `LaunchFailureTracker` tests and the related `AppLaunchState` tests passed. A Release compile also succeeded.

### What to test in the app

1. Run from Xcode, press Stop, run again — the crash-loop count should not rise, and recovery should not appear after two stops.
2. Install/run in the Simulator without Xcode attached and force-quit twice — crash-loop recovery should still appear.
3. Optionally add `--enable-crash-loop-detection` in the scheme and repeat step 1 — the detector should behave as if there is no debugger.

