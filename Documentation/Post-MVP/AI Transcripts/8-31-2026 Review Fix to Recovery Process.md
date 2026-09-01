> From: https://chatgpt.com/c/6a9615f3-7a78-83e8-90ce-011d1fa2c862

# you asked

message time: 2026-08-31 17:02:55

Please review the changes in branch export-data

---

# chatgpt response

I’ll inspect the branch contents and diff it against the likely base branch, then review the export flow for correctness, UX, data completeness, and tests. I’ll focus on actionable findings rather than style unless something materially affects maintainability.

The branch is cleanly based on current `main`, with two commits: the implementation plus a comments-only follow-up. The scope is appropriately contained: recovery UI/preparation, a low-level reader, reuse of the existing export builder/file type, localization/accessibility IDs, and targeted tests.

The implementation has good defensive intent: it never reads destructively from the original store, falls back from SwiftData to SQLite on the copied store, and explicitly keeps reset available if export preparation fails. I’m checking the fallback assumptions now, because that’s where recovery code is most likely to give a misleading “nothing recoverable” result.

I found **one substantive issue**. Other than this, the implementation looks well thought out and the recovery-reader tests cover the important corruption/fallback cases nicely.

- **High — Reset can bypass an in-progress recovery probe and incorrectly omit Export Watchlist.** In `PersistenceRecoveryExportPreparation.probeIfNeeded()`, `didProbe` is set to `true` **before** `await loadShows()` completes. Meanwhile, `PersistenceRecoveryView` automatically starts a probe from `.task`, and tapping **Reset Local Data** calls `probeIfNeeded()` again before presenting the confirmation (`PersistenceRecoveryView.swift:244–249`). If the automatic probe is still running, the second call sees `didProbe == true`, returns immediately, and presents the reset alert while `availability` is still `.probing`. The alert therefore takes the non-export path and its default confirmation text says the store is “too damaged to export,” even though the original probe may finish a moment later and find recoverable shows. The user could then reset and lose exactly the last-chance export this branch is intended to provide. (`PersistenceRecoveryExportPreparation.swift:63–69`; `PersistenceRecoveryView.swift:205–224, 244–249`)

  I’d fix this by memoizing the **probe task**, rather than just recording that probing has started. Every `probeIfNeeded()` caller should await the same in-flight task, so `presentResetConfirmation()` cannot return until recoverability is actually known. I’d also add a concurrency test: start a deliberately suspended `loadShows`, call `probeIfNeeded()` a second time, verify the second call does **not** finish until the loader is released, and then verify both callers see `.available`.

Everything else I examined looks good: the original store is copied before attempting recovery, SQLite is opened read-only, SwiftData and SQLite results are merged with the higher-fidelity SwiftData row preferred, partial rows remain exportable, export-preparation failure leaves reset possible, and the normal watchlist export path was cleanly refactored rather than duplicated.

I also ran `git diff --check`; it reports no whitespace errors. I **couldn't run the Xcode test suite/build in this environment because the review container is Linux and doesn't have `xcodebuild`**.

So I would **fix that one race before merging**; after that, I don't see another code-review blocker.

---

# you asked

message time: 2026-08-31 17:14:06

Is this better?

---

# chatgpt response

I’ll compare this archive to the prior version and specifically verify whether the in-flight probe race is actually closed, then I’ll scan for any regressions introduced by the fix.

Yes—the actual fix matches the failure mode I identified. Because `probeTask` is created on the main actor before the first suspension and retained, overlapping callers now await the same task instead of mistaking “probe started” for “probe finished.”

Yes. This fixes the race I found.

`probeIfNeeded()` now keeps the actual in-flight `Task` and makes every subsequent caller await it. So if the automatic probe is still running when the user taps **Reset Local Data**, `presentResetConfirmation()` waits for the existing probe to finish before showing the confirmation. It can no longer incorrectly fall through to “the local store is too damaged to export” just because the probe hasn't completed yet.

The new test is also the right test: it deliberately suspends the loader, starts a second probe, verifies that the second call hasn't completed and that the loader ran only once, then releases it and confirms export becomes available.

I did another pass over the surrounding code and don't see a new issue introduced by this change. `git diff --check` is also clean.

**One housekeeping note:** in the archive you sent, these two fixes are still **uncommitted working-tree changes**:

- `PersistenceRecoveryExportPreparation.swift`
- `PersistenceRecoveryExportPreparationTests.swift`

Assuming that's intentional because you wanted the review before committing: **yes, I think this is ready to commit and merge.**