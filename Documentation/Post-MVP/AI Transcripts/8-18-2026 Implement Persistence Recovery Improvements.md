# User-facing recovery flow

## User

Replace the startup `fatalError` with a user-facing recovery flow before release.

- Log diagnostics before attempting recovery.
- Explain the consequences before resetting local data.
- Allow the user to export diagnostics before resetting.
- Provide a clear **Reset Local Data** action when recovery is not possible.

## Assistant

I'll start by locating the startup `fatalError` and reading the SwiftUI/persistence skills so the recovery flow matches the app's existing patterns.

The startup crash is in `NextSeasonApp.swift`. Next I’ll read the recovery notes, diagnostics logger, and current app bootstrap so the new flow can log, explain, and reset without crashing.

The roadmap is specific: log first, explain data loss, let the user export diagnostics, then reset. I’ll look at existing error screens, diagnostics export, and how the store is created.

I'll replace the startup crash with a blocking recovery screen: log first, explain that reset deletes the watchlist, let the user export diagnostics, then offer **Reset Local Data**.

I'll keep notification clearing out of unit tests so they don't wipe pending alerts on the simulator.

Startup no longer crashes when the watchlist store won’t open. The app now logs the failure and shows a recovery screen so you can export diagnostics and choose to reset.

**What you’ll see**
- Title: **Couldn't Open Your Watchlist**
- Copy that reset **permanently deletes** the local watchlist and scheduled next-season reminders
- **Export Diagnostics** (Share sheet, includes the SwiftData error)
- **Reset Local Data**, with a confirmation alert before anything is deleted

After a confirmed reset, the app deletes `default.store` and sidecars, clears pending notifications, and retries launch. If reset itself fails, you stay on the same screen with the error.

Show ID mapping failures no longer take this path. Mapping already retries from the bundled database; if that still fails, Search continues with an empty in-memory map so a mapping problem can’t wipe the watchlist.

**What to test**
1. Normal launch still opens Search and Watchlist.
2. Preview `PersistenceRecoveryView` and confirm the copy, Export, and Reset confirmation.
3. On a TestFlight or debug build, if you ever hit this screen: export first, then reset, and confirm you can add shows again.
4. VoiceOver on the recovery screen — Export and Reset should be separate actions; the description should mention data loss.

## User

Please make a focused follow-up pass on the Persistence Recovery implementation. The overall architecture and approach are good; do not redesign the feature or perform unrelated cleanup/refactoring.

There are four issues to address.

1. Include reset failures in exported diagnostics

Currently AppLaunchState.RecoveryContext can contain both the original persistence initialization error and a later resetError, but diagnosticsReport() only exports the original persistence failure.

If PersistentStoreReset itself fails, diagnostics exported afterward need to contain that reset failure as well. This is particularly important because the reset failure may be the most useful information for troubleshooting at that point.

Update the diagnostics representation/report as appropriate so that:

* the original persistence initialization failure remains available;
* a persistence reset failure is also included when one has occurred;
* the full technical error information belongs in diagnostics rather than relying on what is displayed to the user.

Add tests verifying that a reset failure appears in the exported diagnostics.

2. Distinguish “reset succeeded but persistence still won’t initialize”

There is an important state distinction in the recovery flow:

1. The original SwiftData store fails to open.
2. The user chooses Reset Local Data.
3. The existing store is successfully removed.
4. Creating a fresh ModelContainer still fails.

At step 4, the user’s old watchlist has already been permanently deleted. The recovery UI should therefore not return to copy that tells the user that resetting will delete their watchlist as though it still exists.

Preserve enough recovery state to distinguish the initial persistence failure from a failure that occurs after the local store has already been successfully reset.

When the reset succeeded but persistence initialization still failed:

* clearly tell the user that the local watchlist was reset successfully but NextSeason still could not initialize its local data store;
* continue to make Export Diagnostics available;
* do not misleadingly imply that the original watchlist can still be preserved;
* provide whatever retry/recovery action is reasonable within the existing design, without creating an elaborate new recovery system.

Please keep this state model as simple as practical.

Add tests covering this distinction.

3. Add successful end-to-end recovery-state coverage if practical

The existing tests cover several failure paths well, including:

* initial bootstrap failure entering recovery;
* reset operation failure remaining in recovery;
* successful removal followed by another initialization failure remaining in recovery;
* removal of the SwiftData store and sidecars;
* ability to create a fresh ModelContainer afterward.

Please add coverage for the normal successful orchestration path if it can be done cleanly:

recovery → reset store → clear relevant notifications → recreate composition → .ready

Do not introduce protocols, abstractions, dependency-injection machinery, or production architectural changes solely to make this test possible.

If a clean test requires disproportionate production changes, leave the architecture alone and explain why the existing lower-level coverage is preferable.

4. Don’t display raw technical reset errors to the user

PersistenceRecoveryView currently incorporates resetError.localizedDescription directly into user-facing copy.

Replace this with friendly, generic recovery language. For example, the UI can explain that NextSeason couldn’t reset its local data and that the user can export diagnostics for troubleshooting and try again.

The technical error should remain available in the exported diagnostics and diagnostic logging, but filesystem/Foundation/SwiftData implementation details should not be presented directly to the user.

Constraints

Please keep this narrowly scoped.

In particular:

* Preserve the existing AppLaunchState / PersistenceRecoveryView / PersistentStoreReset separation unless a small change is genuinely necessary for the fixes above.
* Do not redesign AppCompositionRoot.
* Do not change the existing behavior that treats ShowIDMappingDatabase initialization failure as non-destructive and falls back to InMemoryShowIDMapping.
* Do not broaden what Reset Local Data deletes. It should continue to reset the watchlist persistence store and associated scheduled notifications without wiping unrelated preferences, analytics state, mapping data, or other application-support data.
* Keep the existing explicit destructive confirmation before the initial reset.
* Keep diagnostics export available before destructive recovery.
* Do not perform unrelated cleanup or formatting changes.

Run the relevant tests after making the changes. Then summarize:

1. the production changes made;
2. the tests added or changed;
3. how the UI now distinguishes an initial persistence failure from a post-reset initialization failure;
4. what diagnostic information is exported in each failure state;
5. any requested item you deliberately did not implement and why.

## Assistant

I'll keep the current architecture and make a narrow pass: include reset errors in diagnostics, distinguish post-reset init failure, cover the success path if it's clean, and replace raw reset errors in the UI.

I'll keep the same types and make four small updates: export reset errors, track a successful reset separately, use generic UI copy, and add tests for those states.

All 10 related tests passed. Summary of the follow-up pass:

### 1. Production changes
- **`RecoveryContext`** now keeps four pieces of state: the latest init error, the original init error (when a later retry failed differently), a reset-operation error, and `didResetStore`.
- **Diagnostics export** includes the current persistence failure, the original failure when present, a reset failure when present, and `Local watchlist store reset: succeeded` after a successful wipe.
- **`resetLocalData()`** records a successful store removal even if the next `ModelContainer` open still fails, instead of treating that as a fresh first-time failure.
- **Recovery UI** uses generic copy for reset failures (no `localizedDescription`). After a successful wipe it switches title, body, and primary action.

### 2. Tests added or changed
- Reset failure stays in recovery **and appears in the export** (original init error + `disk full`).
- Successful wipe + failed re-init sets `didResetStore`, preserves the original error, and exports both errors plus the reset-succeeded line.
- Reset orchestration order: `removeStore` → `clearNotifications` → `makeRoot`.
- `AnalyticsDiagnosticsReport` covers original + reset failures, and a successful-reset flag.

### 3. How the UI distinguishes the two failures
| State | Title | Copy | Action |
|---|---|---|---|
| Initial failure (and reset that didn’t complete) | **Couldn't Open Your Watchlist** | Watchlist may still exist; reset will delete it. If reset failed, a generic “couldn’t reset… export and try again” line is added. | **Reset Local Data** with the existing destructive confirmation |
| Reset succeeded, init still fails | **Couldn't Set Up Local Data** | Watchlist was reset successfully; it cannot be restored; store still won’t initialize. | **Try Again** (retries reset + init, no delete confirmation) |

Export Diagnostics stays available in both states.

### 4. What diagnostics export in each state
- **Initial failure:** `Persistence failure:` + the SwiftData/composition error.
- **Reset operation failed:** that original persistence failure **and** `Persistence reset failure:` with the full technical reset error.
- **Reset succeeded, init still fails:** `Original persistence failure:` (first error), `Persistence failure:` (new error), and `Local watchlist store reset: succeeded`.

### 5. What was not implemented
A full **recovery → `.ready`** test was not added. Reaching `.ready` requires a real `AppCompositionRoot`, which would open the on-device store and run production launch wiring (analytics, MetricKit, background refresh). That would need a test-only initializer or extra injection, which you asked not to add.

The new orchestration test covers the reset sequence (`removeStore` → `clearNotifications` → `makeRoot`). Combined with `PersistentStoreResetTests` (wipe store, open a fresh container), that covers the success path without changing `AppCompositionRoot`.

## User

Stop hardcoding notificationsEnabled: false in persistence-recovery diagnostics; represent notification status as unknown/unavailable when the app cannot obtain the real status during startup recovery, without adding async notification querying or complicating the recovery flow.

## Assistant

I'll change recovery diagnostics so notification status is shown as unknown, not hardcoded as disabled, without adding any async notification lookup.

Recovery diagnostics no longer report notifications as disabled when that status was never queried.

`AnalyticsDiagnosticsReport` now takes `notificationsEnabled: Bool?`. Known values still print `true` / `false`. `nil` prints **Unavailable**. Persistence recovery passes `nil` and stays synchronous — it does not ask the system for authorization.

The Diagnostics screen is unchanged: it still passes the real status once that has been loaded.

**What to test:** Export from the recovery screen and confirm the line is `Notifications enabled: Unavailable`, not `false`. From Diagnostics after a normal launch, the true/false value should still match notification settings.

