# Watchlist export feature

## User

Please add a feature to offer watchlist export before destructive recovery. Once recovery reaches the point where NextSeason is proposing to delete/reset the local store, giving the user a last chance to export whatever can still be read is exactly the right behavior. I’d make it something like “Export Watchlist” / “Reset Without Exporting” / “Cancel.” The important wrinkle is that recovery may have been triggered because the store is damaged, so export needs to be explicitly best-effort: failure to export shouldn’t prevent the reset, and the UI shouldn’t imply that the exported data is necessarily complete. If the store is so damaged that nothing can be recovered, skip or disable the export option with an appropriate explanation.

## Assistant

I'll start by reading the Swift skills and locating the existing recovery and watchlist-export flows so we can add a best-effort export step before a destructive reset.

The existing recovery screen and watchlist export look like the right place to hook this in. Next I’ll read those files and the recent roadmap discussion so the new flow matches how recovery already works.

I'll read the recovery UI, launch-state machine, and existing export path next so we can add a last-chance export without implying the data is complete.

Recovery currently offers only Reset / Cancel, so I need to see how the store is opened and how export reads shows before I can add a best-effort last-chance export.

Recovery can be triggered by a damaged store, so export will be a separate best-effort read: copy the store, try SwiftData, fall back to SQLite, and never block reset if that fails.

I'll add a recovery reader that copies the store first, then tries SwiftData and falls back to SQLite so a failed export can never block reset.

I'll distinguish “store unreadable” from “opened but no shows,” then wire that into the recovery confirmation so export is skipped only when nothing can be recovered.

Next I’ll update the recovery screen so the reset confirmation offers Export Watchlist, Reset Without Exporting, and Cancel, with export disabled when nothing can be read.

The SQLite fallback missed Core Data’s `Z`-prefixed column names, so I’m updating name matching and tightening the corrupt-snapshot test.

Before a destructive reset, recovery now offers a last-chance, best-effort watchlist export — and reset still works if that export fails or the store is unreadable.

**Skills used:** `swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`, `swift-testing-pro`

When **Reset Local Data** is available (a persistence-open failure, not a generic crash loop), the confirmation is:

- **Export Watchlist** / **Reset Without Exporting** / **Cancel** — if any show data can still be read
- **Reset Local Data** / **Cancel** — if nothing could be recovered, with copy that the store is too damaged (or that no shows could be recovered)

Export is explicitly incomplete-by-design:

- The store is copied first so recovery never writes the original files
- SwiftData is tried for full rows; SQLite fills in remaining name/ID rows if a snapshot is corrupt or SwiftData cannot open the file
- Failed rows are skipped instead of failing the whole export
- A failed CSV write still leaves **Reset Local Data** available
- Canceling the share sheet does **not** reset; the user can still reset afterward
- Crash-loop recovery is unchanged (no destructive reset, so no export)

**What to test**

1. Preview **Initial failure** on `PersistenceRecoveryView` — after probe, the description mentions a possible incomplete export. **Reset Local Data** should show the three-button confirmation.
2. Preview **Store too damaged to export** — export is omitted and the copy explains why.
3. Preview **Crash loop** — still Export Diagnostics + Try Again only.
4. On a device/simulator with a real watchlist, if you can force persistence recovery: export should produce a CSV, sharing/canceling should not wipe the store, and **Reset Without Exporting** should still reset.
5. If export preparation fails, the follow-up alert should still offer reset.

I can mark **Persistence Recovery** complete on the App Store Readiness roadmap if you want that updated too.

## User

Yes please

## Assistant

I'll mark Persistence Recovery complete on the App Store Readiness roadmap and check that the heading and requirement still match the work we just shipped.

**Persistence Recovery** is now marked **(Complete)** in the App Store Readiness roadmap, matching the other finished sections. The export-before-reset requirement stays listed under it as part of the completed work.

## User

Please add comments to any changed files to bring them up to the level of commenting we've been using.

## Assistant

I'll compare the changed files with nearby well-commented ones and add comments so the new recovery-export code matches that style.

I’ll match the existing style: file- and type-level docs, plus comments on non-obvious recovery, SQLite, and test-helper logic.

The new recovery-export files are the ones that need comments; I’ll document the non-obvious probe, SQLite fallback, and test-helper paths to match the rest of the project.

Comments are now in place on the recovery-export files, at the same level as the rest of the persistence and export code: why the store is copied first, why SwiftData and SQLite are merged, why export can fail without blocking reset, and what the test helpers are isolating.

**Files updated**
- `WatchlistRecoveryExportReader.swift` — copy/merge strategy, read-only SQLite, column discovery, incomplete rows
- `PersistenceRecoveryExportPreparation.swift` — one-shot probe, empty vs unreadable, dismiss-after-failure
- `PersistenceRecoveryView.swift` — injected probe for previews, confirmation buttons, unique export URL, reset after a failed share
- `WatchlistExportBuilder.swift` / `WatchlistExportFile.swift` — recovery overload and `sheet(item:)` identity
- `AccessibilityID.swift` — new recovery control IDs
- Both new test files — store seeding, snapshot corruption, and the forced prepare-failure setup

No behavior changes — comments only.

## User

Please fix this problem found by ChatGPT:

* High — Reset can bypass an in-progress recovery probe and incorrectly omit Export Watchlist. In PersistenceRecoveryExportPreparation.probeIfNeeded(), didProbe is set to true before await loadShows() completes. Meanwhile, PersistenceRecoveryView automatically starts a probe from .task, and tapping Reset Local Data calls probeIfNeeded() again before presenting the confirmation (PersistenceRecoveryView.swift:244–249). If the automatic probe is still running, the second call sees didProbe == true, returns immediately, and presents the reset alert while availability is still .probing. The alert therefore takes the non-export path and its default confirmation text says the store is “too damaged to export,” even though the original probe may finish a moment later and find recoverable shows. The user could then reset and lose exactly the last-chance export this branch is intended to provide. (PersistenceRecoveryExportPreparation.swift:63–69; PersistenceRecoveryView.swift:205–224, 244–249)
    I’d fix this by memoizing the probe task, rather than just recording that probing has started. Every probeIfNeeded() caller should await the same in-flight task, so presentResetConfirmation() cannot return until recoverability is actually known. I’d also add a concurrency test: start a deliberately suspended loadShows, call probeIfNeeded() a second time, verify the second call does not finish until the loader is released, and then verify both callers see .available.

## Assistant

The probe currently marks itself done before the read finishes, so Reset can show the “too damaged” path while a real export is still possible. I’ll make every caller await the same in-flight probe and add a test for that.

`didProbe` is set before the read finishes, so a Reset tap can treat an in-flight probe as finished. I’ll memoize the probe `Task` so every caller waits for the same result, and add a test that proves the second call stays pending until the loader is released.

Reset no longer treats an in-flight probe as finished. `probeIfNeeded()` now memoizes one `Task` and every caller — including **Reset Local Data** — awaits that same task until recoverability is known.

That stops the confirmation from opening while availability is still `.probing` and incorrectly saying the store is too damaged to export.

A new test starts a gated `loadShows`, calls `probeIfNeeded()` a second time, checks that the second call stays pending and does not start another read, then releases the loader and verifies both callers see `.available`. All seven preparation tests passed.

**Skills used:** `swift-concurrency-pro`, `swift-testing-pro`

