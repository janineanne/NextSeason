# Database renaming plan

## User

We're going to make some changes that came out of my code review of the search changes, discussed with ChatGPT.

The first one:

I'd like to rename CompatibilityIndexDatabase to ShowIDMappingDatabase.  That means renaming lots of other things which have the words compatability and/or index in them.  Please give me a list of the new and old names before you do any actual work.

## Assistant

I’ll scan the codebase for `CompatibilityIndexDatabase` and related compatibility/index names so I can give you a complete old → new list before changing anything.

I’ll pull the remaining identifiers (types, files, folders, properties, and resource names) so the rename list is complete and consistent.

Proposed rule: **`CompatibilityIndex` → `ShowIDMapping`**. That drops both “compatibility” and “index” from this feature’s names. No files will be changed until you approve this list.

### Types

| Old | New |
|---|---|
| `CompatibilityIndexDatabase` | `ShowIDMappingDatabase` |
| `TVDBTVMazeCompatibilityIndex` | `TVDBTVMazeShowIDMapping` |
| `InMemoryCompatibilityIndex` | `InMemoryShowIDMapping` |
| `CompatibilityIndexRefreshService` | `ShowIDMappingRefreshService` |
| `CompatibilityIndexMetadata` | `ShowIDMappingMetadata` |
| `CompatibilityIndexUpdatesResumeCursor` | `ShowIDMappingUpdatesResumeCursor` |
| `CompatibilityIndexError` | `ShowIDMappingError` |
| `CompatibilityIndexDatabaseTests` | `ShowIDMappingDatabaseTests` |
| `CompatibilityIndexRefreshServiceTests` | `ShowIDMappingRefreshServiceTests` |

### Properties, methods, parameters

| Old | New |
|---|---|
| `compatibilityIndex` | `showIDMapping` |
| `compatibilityIndexRefresh` | `showIDMappingRefresh` |
| `refreshCompatibilityIndexIfNeeded()` | `refreshShowIDMappingIfNeeded()` |
| `onForegroundCompatibilityRefresh` | `onForegroundShowIDMappingRefresh` |
| `compatibleIndex(...)` (test helper) | `showIDMapping(...)` |
| `index:` (test helper parameter) | `mapping:` |
| `// MARK: - Compatibility filtering` | `// MARK: - Show ID mapping` |

### Files and folders

| Old | New |
|---|---|
| `Services/Compatibility/` | `Services/ShowIDMapping/` |
| `Resources/Compatibility/` | `Resources/ShowIDMapping/` |
| `CompatibilityIndexDatabase.swift` | `ShowIDMappingDatabase.swift` |
| `TVDBTVMazeCompatibilityIndex.swift` | `TVDBTVMazeShowIDMapping.swift` |
| `InMemoryCompatibilityIndex.swift` | `InMemoryShowIDMapping.swift` |
| `CompatibilityIndexRefreshService.swift` | `ShowIDMappingRefreshService.swift` |
| `CompatibilityIndexMetadata.swift` | `ShowIDMappingMetadata.swift` |
| `CompatibilityIndexDatabaseTests.swift` | `ShowIDMappingDatabaseTests.swift` |
| `CompatibilityIndexRefreshServiceTests.swift` | `ShowIDMappingRefreshServiceTests.swift` |
| `generate-tvdb-tvmaze-compatibility-db.py` | `generate-tvdb-tvmaze-show-id-mapping-db.py` |

### On-disk / bundled names

| Old | New |
|---|---|
| `tvdb_tvmaze_compatibility.sqlite` | `tvdb_tvmaze_show_id_mapping.sqlite` |
| `tvdb_tvmaze_compatibility` (resource name) | `tvdb_tvmaze_show_id_mapping` |
| Application Support folder `Compatibility/` | `ShowIDMapping/` |
| Bundle subdirectories `Compatibility` / `Resources/Compatibility` | `ShowIDMapping` / `Resources/ShowIDMapping` |

### Diagnostics / script strings

| Old | New |
|---|---|
| `compatibility_index_refresh*` log/breadcrumb names | `show_id_mapping_refresh*` |
| User-Agent `NextSeason/compatibility-db-generator` | `NextSeason/show-id-mapping-db-generator` |

Live comments and docs that still say “compatibility index” (`AGENTS.md`, `Scripts/README.md`, `ATTRIBUTION.md`, Search comments) would be updated to “show ID mapping” in the same pass.

### Left unchanged

- **TVMaze catalog APIs:** `ShowIndexEntryData`, `showsIndex`, `showIndexEntry` — those refer to TVMaze’s `/shows?page=` index, not this mapping.
- **SQLite `CREATE INDEX idx_mappings_tvmaze_id`** — that is a database index.
- **Historical AI transcripts** under `Documentation/`.
- **`highestTVMazeID`** — “index” appears only in comments, not the name.

Two optional shortenings if you prefer them:

1. Protocol `TVDBTVMazeShowIDMapping` → `ShowIDMapping` (the TVDB↔TVMaze part is already implied).
2. `ShowIDMappingUpdatesResumeCursor` → `ShowIDMappingResumeCursor`.

If this mapping looks right, say so and I’ll do the rename.

## User

Yes, please do this, including the two optional shortenings at the end of your list.

## Assistant

I’ll apply the full rename, including `ShowIDMapping` for the protocol and `ShowIDMappingResumeCursor`. First I’ll read the Swift skills and the files that need to change.

Xcode uses synchronized folders, so I’ll rename files first, then update types and references. Checking remaining live-code mentions so nothing is missed.

I’ll rename the folders and files first, then update identifiers and comments in the live code and docs. Skills used: `swift-concurrency-pro`, `swiftui-pro`, `swift-testing-pro`.

Identifier replacements are in. Next I’ll catch remaining folder paths, the test `index:` parameter, and leftover comments.

A few leftover paths and comments still say “compatibility” or “index”; I’ll update those next, including the test helper parameter.

The rename is done, including both shortenings: the protocol is now `ShowIDMapping`, and the cursor is `ShowIDMappingResumeCursor`.

Skills used: `swift-concurrency-pro`, `swiftui-pro`, `swift-testing-pro`.

**Types**
- `ShowIDMapping` (protocol)
- `ShowIDMappingDatabase`
- `InMemoryShowIDMapping`
- `ShowIDMappingRefreshService`
- `ShowIDMappingMetadata`
- `ShowIDMappingResumeCursor`
- `ShowIDMappingError`

**Layout**
- `NextSeason/Services/ShowIDMapping/`
- `NextSeason/Resources/ShowIDMapping/tvdb_tvmaze_show_id_mapping.sqlite`
- `Scripts/generate-tvdb-tvmaze-show-id-mapping-db.py`

Call sites, comments, `AGENTS.md`, `Scripts/README.md`, and `ATTRIBUTION.md` were updated to match. Historical AI transcripts were left alone. TVMaze’s `/shows?page=` “show index” APIs (`ShowIndexEntryData`, `showsIndex`, and so on) were also left alone.

**Note:** the on-device Application Support folder is now `ShowIDMapping/` instead of `Compatibility/`. The next launch will copy the bundled database into the new location, so any locally refreshed mappings from earlier runs will not carry over.

**What to test**
- Build in Xcode (I could not run the simulator from here).
- Run `ShowIDMappingDatabaseTests`, `ShowIDMappingRefreshServiceTests`, and `SearchViewModelTests`.
- Search still filters to mapped shows, and foreground refresh still runs.

## User

Replace all uses of NSLock with Synchronization.Mutex. Since NextSeason targets iOS 18 and Swift 6, prefer Mutex over NSLock for protecting small pieces of synchronous mutable state. Use Mutex<Value> to own the protected value rather than keeping separate instance variables. Replace explicit lock()/unlock() calls with withLock. After the conversion, remove any @unchecked Sendable or nonisolated(unsafe) declarations that are no longer necessary. Keep critical sections as small as possible, and don’t hold the mutex while performing expensive work or calling external APIs.

This is intended to be a behavioral no-op. Don’t change algorithms or control flow unless required by the API differences.

## Assistant

I’ll find every `NSLock` use first, then convert each to `Mutex` while keeping the same behavior and dropping any `@unchecked Sendable` / `nonisolated(unsafe)` that the lock was covering.

I’ll convert each `NSLock` site to `Mutex` owning the protected value, use `withLock`, and drop `@unchecked Sendable` / `nonisolated(unsafe)` only where Mutex makes the type checked-Sendable. Skills used: `swift-concurrency-pro`.

All `NSLock` uses now go through `Synchronization.Mutex`. Skills used: `swift-concurrency-pro`.

**Production**
- `BreadcrumbStore` and `DiagnosticsSimulatedDataProvider` own their state in `Mutex` and are checked `Sendable` (no `@unchecked Sendable` or `nonisolated(unsafe)`).
- `BackgroundRefreshCompletion` uses `Mutex(false)` for the finished flag. `setTaskCompleted` runs **after** `withLock`, so the mutex is not held across that API call. `@unchecked Sendable` stays because `BGAppRefreshTask` is not Sendable.

**Tests**
- `LookupCounter`, `OffsetRecorder`, and `SyncClock` now use `Mutex` and are checked `Sendable`.

Left unchanged, because they were not `NSLock` sites: `CallCounter`, SQLite’s `nonisolated(unsafe)` handle, and the mock TVMaze `@unchecked Sendable` types.

**What to test**
- Build in Xcode (strict concurrency).
- Run `SearchViewModelTests` and `ShowIDMappingRefreshServiceTests`.
- Diagnostics simulated-data phase advance still flips baseline ↔ updated.
- Background refresh still completes the `BGTask` once (including expiration).

## User

Please review the ShowIDMappingDatabase initialization in AppCompositionRoot. It currently contains more construction/recovery logic than the other dependencies in the composition root.

Evaluate whether that logic should be encapsulated behind a small helper such as ShowIDMappingDatabase.openDefault() (preferred over introducing a separate factory type unless a factory clearly improves the design).

The goal is to keep AppCompositionRoot focused on dependency wiring rather than database-opening details.

This should be a behavior-preserving cleanup. Do not change recovery behavior, storage locations, error handling semantics, or public APIs unless necessary. If extracting the logic makes the code less clear, leave it where it is and explain why.

## Assistant

I’ll review how `ShowIDMappingDatabase` is built in `AppCompositionRoot` and compare it with the database’s own open/recovery APIs before deciding whether a small helper is clearer.

The composition root is doing database recovery, not wiring. I’ll move that one-shot open/replace/retry into `ShowIDMappingDatabase.openDefault()` so the root just constructs the dependency. Skills used: `swift-concurrency-pro`.

Yes — that logic belonged on the database, not in the composition root. A factory type would have been extra ceremony for a single open path.

`ShowIDMappingDatabase.openDefault()` now owns the default location, bundled baseline, and the one-shot corrupt-file retry. `AppCompositionRoot` just wires it:

```54:59:NextSeason/App/AppCompositionRoot.swift
            let database = try ShowIDMappingDatabase.openDefault()
            showIDMapping = database
            showIDMappingRefresh = ShowIDMappingRefreshService(
                database: database,
                tvMaze: liveTVMaze
            )
```

Recovery, storage locations, and existing inits are unchanged. UI tests still use `InMemoryShowIDMapping`.

**What to test:** launch the app once (non-UI-test) and confirm Search still filters mapped shows. Corrupt-file recovery is the same path as before, now inside `openDefault()`.

## User

There are 3 instances of the error "Call to main actor-isolated instance method 'append(_:limit:)' in a synchronous nonisolated context" in AppDiagnosticsLogger.

## Assistant

That error is likely from Swift 6.2’s default actor isolation treating `BreadcrumbStore` as main-actor. I’ll check the logger and isolation settings, then restore a safe nonisolated `Mutex` API.

The app target defaults to MainActor isolation, so `BreadcrumbStore` became main-actor after we dropped `nonisolated`. I’ll mark the store nonisolated so `Mutex` can be used from the logger’s nonisolated APIs. Skills used: `swift-concurrency-pro`.

Those three errors were `append` plus the two `snapshot` calls. The app target uses default MainActor isolation, so `BreadcrumbStore` became main-actor when we dropped `nonisolated` during the `Mutex` conversion.

The store is now a `nonisolated` `Sendable` class. `Mutex` still protects the array, and `AppDiagnosticsLogger`’s nonisolated methods can call it from any isolation.

Rebuild and those three diagnostics should be gone.

## User

Ok, I have a few small things to fix after ChatGPT's review.

The old unfiltered-update path had:

AppDiagnosticsLogger.breadcrumb("compatibility_index_updates_unfiltered")

Instead of being updated to

AppDiagnosticsLogger.breadcrumb("show_id_mapping_updates_unfiltered")

It was dropped altogether.  Please put it back.

## Assistant

I’ll restore the breadcrumb on the long-absence unfiltered-updates path, using the renamed `show_id_mapping_updates_unfiltered` name.

Restored. When last sync is older than a month and refresh uses the unfiltered TVMaze updates map, it now records `show_id_mapping_updates_unfiltered` again. The `lastSync == nil` path still has no breadcrumb, matching the original.

## User

SearchViewModelTests still contains:

private final class CallCounter: @unchecked Sendable {
    var value = 0
}

That wasn’t an NSLock conversion because it never had a lock, so Cursor technically stayed within scope. But now it stands out next to the nicely converted LookupCounter and OffsetRecorder.  Please change that to a Mutex<Int> too.

## Assistant

I’ll convert `CallCounter` to a `Mutex<Int>` like the other test helpers, and switch the `value += 1` call sites to an increment that happens inside the lock. Skills used: `swift-concurrency-pro`, `swift-testing-pro`.

`CallCounter` now owns a `Mutex<Int>`, is checked `Sendable`, and increments inside `withLock`. The `#expect(...value == …)` reads are unchanged.

**What to test:** run `SearchViewModelTests`.

## User

Please add a test for

No lastSuccessfulSyncAt and no generatedAt uses allUpdatedShows().

## Assistant

I’ll add a refresh test next to the existing watermark cases: empty `lastSuccessfulSyncAt` and `generatedAt` should call `allUpdatedShows()`. Skills used: `swift-testing-pro`.

Added `missingWatermarksUseUnfilteredUpdates` in `ShowIDMappingRefreshServiceTests`. An empty database (no `lastSuccessfulSyncAt`, no `generatedAt`) now asserts that refresh:

- calls `allUpdatedShows()` rather than the filtered `updatedShows(since:)` path
- still respects the sync horizon
- records a successful sync

**What to test:** run `ShowIDMappingRefreshServiceTests`.

## User

Add focused test coverage for ShowIDMappingDatabase.openDefault() recovery behavior

Please make the smallest change necessary to make the recovery logic used by ShowIDMappingDatabase.openDefault() directly testable.

The current openDefault() resolves the real Application Support URL and bundled database URL internally, which makes its recovery behavior awkward to test without touching real app storage.

Please:

* Keep openDefault() as the public/default entry point used by AppCompositionRoot.
* Extract only the URL-dependent open/recovery logic into an internal helper that accepts a writable database URL and optional bundled database URL.
* Have openDefault() resolve the normal production URLs and delegate to that helper.
* Do not introduce a new factory type or protocol.
* Preserve the current behavior exactly: try opening the writable database first; if that fails, recreate/replace it from the bundled baseline and retry opening it.
* Add a focused test using temporary files that verifies the recovery path. The test should start with an invalid/corrupt writable database and a valid bundled baseline, call the extracted helper, and verify that the resulting database opens successfully and contains the bundled baseline data.
* If practical, also verify that an already-valid writable database opens without being unnecessarily replaced.

Keep this as a behavior-preserving testability refactor. Do not change storage locations, schema behavior, recovery policy, or AppCompositionRoot.

## Assistant

I’ll extract the URL-based open/retry into an internal helper, leave `openDefault()` as the production wrapper, and add temp-file tests for recovery and the already-valid path. Skills used: `swift-testing-pro`.

`openDefault()` still resolves the production URLs and now delegates to an internal `open(fileURL:bundledURL:)` that owns the try / replace / retry path. `AppCompositionRoot` is unchanged.

Tests in `ShowIDMappingDatabaseTests`:
- Unopenable writable file (read-only sqlite) is force-replaced from the bundled baseline and opens with that mapping.
- An already-valid writable file is left as-is and is not overwritten by the bundle.

**What to test:** run `ShowIDMappingDatabaseTests`.

## User

Test openRecoversUnopenableWritableFromBundledBaseline is failing with "Expectation failed: await database.tvMazeID(forTVDBID: 371980) == 44933"

## Assistant

The read-only file is still opening: SQLite can open a `0444` database with `READWRITE` and just treat it as read-only, so recovery never runs. I’ll switch the test to a corrupt file so the first open fails and the bundled baseline is copied in.

SQLite still opened the `0444` file, so recovery never ran and you kept the empty writable database.

The test now writes invalid bytes instead. That fails the readable-database check, so `open` deletes the file, copies the bundled baseline, and the Severance mapping is present.

**What to test:** re-run `ShowIDMappingDatabaseTests`.

