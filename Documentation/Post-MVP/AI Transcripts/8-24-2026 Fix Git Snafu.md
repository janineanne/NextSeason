# Aptabase integration restoration

## User

Please restore the Aptabase analytics integration that was accidentally lost from the current NextSeason source tree.

The implementation previously existed around August 14–15, 2026, but appears to have been lost during later branch/history cleanup. The current project still contains the Aptabase app key in Secrets.xcconfig, but the Aptabase SDK, initialization, Info.plist configuration, and actual event delivery code are no longer present.

A known-good version of the Aptabase implementation still exists in the repository’s Git objects. In particular, inspect Git object/commit:

f921e4f

Use that implementation as a reference only. Do not reset the repository to it, cherry-pick it wholesale, apply an old stash wholesale, or overwrite current files with their historical versions. The project has changed substantially since then.

Your task is to restore only the Aptabase-specific functionality into the current codebase while preserving all newer work.

Required behavior

Restore the Aptabase Swift Package dependency to the NextSeason app target.

Restore the Aptabase configuration needed to obtain the app key from the existing build setting:

APTABASE_APP_KEY

The key currently exists in Secrets.xcconfig. Do not hard-code the key into Swift source.

Restore the corresponding Info.plist/configuration plumbing used by the previous implementation, including the AptabaseAppKey entry if that remains the appropriate mechanism in the current project.

Restore Aptabase initialization during application startup, following the previous implementation in f921e4f unless the current architecture requires a small adaptation.

Restore actual event delivery from AnalyticsService to Aptabase.

The previous implementation included behavior equivalent to:

import Aptabase

initialization through:

AptabaseClient.shared.initialize(appKey: key)

and event transmission through:

AptabaseClient.shared.trackEvent(...)

Use the exact Aptabase API appropriate to the package version you restore rather than blindly copying those calls if the API has changed.

Preserve the current analytics architecture

Do not replace or redesign AnalyticsService.

The current service already performs useful local analytics behavior:

* updating AnalyticsCountersStore
* logging analytics events through os.Logger

Those behaviors must remain intact.

A call such as:

analyticsService.track(...)

should continue to perform the existing local counter/logging behavior and also send the appropriate production analytics event to Aptabase.

Do not remove, consolidate, rename, or otherwise alter existing diagnostic logging merely because Aptabase is being restored.

Event privacy / whitelist

Restore the privacy-preserving event/property restrictions from the previous Aptabase implementation.

Aptabase should receive only the deliberately approved production analytics events and properties. Do not start forwarding arbitrary diagnostic data, error messages, search queries, show names, TVDB/TVMaze identifiers, watchlist contents, or other potentially identifying/user-generated data.

The intended search analytics include the previously approved information such as:

* search_performed
* query length
* result count
* whether a result was selected
* whether the selected show was already on the watchlist

Use the known-good implementation in f921e4f to recover the exact event/property mapping and whitelist we had already established.

Also preserve any current analytics events that were deliberately added after that implementation, but do not automatically expose them to Aptabase unless they fit the existing privacy policy and approved production analytics design.

If there is ambiguity about whether a current event belongs in Aptabase, leave it local rather than expanding telemetry.

Build configurations

Make sure Aptabase works in normal device builds and TestFlight/Release builds.

Do not accidentally restrict initialization or event transmission to DEBUG.

Tests and UI tests should not send real Aptabase analytics. Preserve or restore the existing safeguards for test execution.

If the Aptabase app key is absent or malformed, the app should fail gracefully:

* do not crash
* log an appropriate diagnostic message
* leave local analytics/counters working

Tests

Recover and adapt the Aptabase-related tests from f921e4f where they still make sense.

Add or update tests sufficient to verify at least:

* Aptabase configuration can be resolved from the app configuration.
* Missing configuration does not crash the app.
* Existing local analytics counters/logging behavior is preserved.
* Only approved Aptabase events/properties are eligible for transmission.
* Test execution does not transmit production analytics.

Do not introduce unnecessary test-only architecture or broad refactoring just to make these tests possible.

Package/project files

Restore the Aptabase package reference and target dependency cleanly in the Xcode project.

Restore/update Package.resolved as appropriate.

Do not modify unrelated package dependencies.

Scope discipline

This should be a narrowly scoped restoration.

Do not:

* reformat unrelated files
* change whitespace unnecessarily
* refactor unrelated analytics code
* modify search behavior
* modify the existing diagnostics system
* alter UI
* change naming or architecture unless required for the restoration
* touch unrelated files merely because their historical versions differ from the current branch

Preserve current formatting and whitespace wherever possible so the resulting diff contains only meaningful changes.

Verification

After implementing the restoration:

1. Build the NextSeason app target.
2. Run the relevant unit tests.
3. Search the resulting project to confirm the Aptabase package is actually linked to the app target.
4. Confirm that normal application startup initializes Aptabase in Release/TestFlight-capable builds.
5. Confirm that AnalyticsService.track(...) reaches the Aptabase transmission path for an approved event.
6. Confirm that test execution does not send production events.
7. Review the final diff for accidental unrelated changes.

Finally, summarize:

* every file changed
* what Aptabase functionality was restored in each file
* what tests were added or restored
* any deviations from the old f921e4f implementation and why
* exactly what I should do on a physical device/TestFlight build to verify that a fresh event appears in the Aptabase dashboard

Do not make a commit.

## Assistant

I'll restore Aptabase from commit `f921e4f` as a reference only, then weave just that analytics path into the current tree without resetting or overwriting newer work. First I'll inspect that commit, the current analytics architecture, and the Swift skills that apply.

Skills used: `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`, `swiftdata-pro`. Next I’ll inspect `f921e4f` and the current analytics/startup code so the restore stays surgical.

The old Aptabase work is in that stash-style commit. I’ll pull those source files next and compare them with the current analytics and app-startup code.

I have the historical mapping and the current architecture. Next I’ll restore the package, Info.plist key plumbing, and Aptabase delivery without replacing the local analytics service.

Package wiring is in place. Next I’ll restore Aptabase initialization, the event whitelist, and delivery on the current `AnalyticsService`.

I’ll update the analytics tests next: preserve local counter behavior, restore the Aptabase whitelist checks, and add coverage that tests never send production events.

I’ll resolve the Aptabase package, then build the app and run the analytics-related unit tests on the booted simulator.

Aptabase is restored on the current architecture. Local counters and `os.Logger` behavior are unchanged; approved events now also go to Aptabase in real app runs, not in tests.

**Skills used:** `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`, `swiftdata-pro`

## Files changed

| File | What was restored |
|---|---|
| `NextSeason.xcodeproj/project.pbxproj` | Aptabase 0.3.11 Swift package, linked only to the NextSeason app target |
| `NextSeason.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | Pin to Aptabase 0.3.11 (`cfd67fac…`) |
| `App-Info.plist` | `AptabaseAppKey` = `${APTABASE_APP_KEY}` (still from `Secrets.xcconfig`) |
| `NextSeason/Services/AnalyticsService.swift` | SDK init at startup, whitelist, `track()` → Aptabase, missing-key logging, test-run guard |
| `NextSeason/Services/AnalyticsCounters.swift` | Exhaustive switch for `searchResultSelected` / `searchPerformed` outcome |
| `NextSeason/Features/Search/SearchViewModel.swift` | Remote-only `outcome` on `search_performed` (results / empty / failed) |
| `NextSeason/Features/Search/SearchView.swift` | `search_result_selected` with `already_on_watchlist` when a result is opened |
| `NextSeasonTests/AnalyticsServiceTests.swift` | Config, whitelist, local preservation, no production transmission |
| `NextSeasonTests/AnalyticsCountersTests.swift` | Call sites updated for the restored `outcome` associated value |
| `NextSeasonTests/SearchViewModelTests.swift` | Immediate `search_performed` outcome tests from `f921e4f` |

## Behavior restored

`AnalyticsService.track(...)` still updates `AnalyticsCountersStore` and logs via `os.Logger`. For the three approved events it also calls Aptabase 0.3.11:

- `Aptabase.shared.initialize(appKey:)`
- `Aptabase.shared.trackEvent(_:)` / `trackEvent(_:with:)`

**Aptabase whitelist (unchanged from `f921e4f`):**

- `app_launched` — no properties
- `search_performed` — `query_length`, `result_count`, `duration_ms`, `outcome`
- `search_result_selected` — `already_on_watchlist`

Everything else stays local, including `show_id`, error `context`, watchlist contents, and search text. `outcome` is remote-only; local logs/counters still use length, count, and duration.

Initialization is **not** `#if DEBUG`. It runs whenever `AnalyticsService` is created with `isEnabled == true` (normal device, TestFlight, Release). It is skipped for `-UITesting`, XCTest/Swift Testing, and missing/unsubstituted keys (logs `aptabase_disabled missing_or_malformed_app_key`, does not crash).

## Tests added or restored

Restored from `f921e4f`: remote whitelist mapping, `search_performed` outcome cases, `search_result_selected`, local-only `watchlist_added`, SearchViewModel immediate search logging.

Added for this restore: Info.plist key presence, key resolver accept/reject, missing config does not crash, identifying events stay local, local counters still increment, `allowsAptabaseTransmission == false` under tests.

**Verification:** NextSeason Debug build succeeded; Aptabase 0.3.11 is linked into the app target; built `Info.plist` has a resolved `AptabaseAppKey`. 40 related unit tests passed.

## Deviations from `f921e4f`

- Extracted `AptabaseAppKey.resolved(from:)` so config can be tested without calling the SDK.
- Log on missing/malformed key (old code returned silently).
- Explicit automated-test guard. Old tests used `AnalyticsService(isEnabled: true)`, which would have initialized the real SDK if the key was in the host bundle.
- `isAptabaseConfigured` so `trackEvent` is not called unless initialize succeeded.
- Did **not** restore the two AI-transcript markdown files or their pbxproj group entries.

## Device / TestFlight check

Use a normal run, not tests or `-UITesting`:

1. Install a device Debug, Archive, or TestFlight build.
2. Launch the app and leave it in the foreground for a few seconds (`app_launched`).
3. Search for a show and leave without opening it (`search_performed` with `outcome` `results`, `empty`, or `failed`).
4. Open a result (`search_result_selected` with `already_on_watchlist`).
5. Background the app — the SDK flushes on `didEnterBackground`.
6. In the Aptabase dashboard (US, matching `A-US-…`), confirm those three event names. Properties should be structural only; no query text, titles, or IDs.

Events can take a minute to show up. A Simulator run from Xcode (not Test) can also send events if you want a quicker check before TestFlight.

No commit was made.

## User

Please check and see if any other commits were lost, and restore them if so.

## Assistant

I’ll look for other lost work the same way we found Aptabase: compare the current tree against reflog, stashes, and dangling commits, then restore only what’s actually missing.

There are a lot of dangling commits. I’ll summarize them next and compare unique work against current `main` so we only restore what’s actually missing.

The only unique leftover from that lost stash is the two Aptabase transcripts. I’ll restore those docs into the Post-MVP transcript group; everything else in dangling history already landed later or was intentionally replaced.

I searched reflog, dangling/unreachable commits, leftover stash snapshots, `origin/post-mvp`, and unique files that exist in old Git objects but not on current `main`.

**No other feature work was lost.** Aptabase was the unique casualty of the August 14 history rewrite.

What happened: Aptabase lived in stash `f921e4f` on `tvdb-tvmaze-database-additions` (`5a27181`). That branch was rewritten into `c49eedd` (“Use name and poster image from TVDB for search”), and the stash was never reapplied. `origin/post-mvp` is fully contained in `main`; `main` is strictly ahead.

The other dangling objects are not missing features:

- Stash snapshots (`WIP on` / `index on` / `On <branch>`) whose work later landed under new SHAs — SwiftData migration, persistence recovery, app icon, notification routing, TVDB search
- An earlier duplicate of the TVDB search commit (`b149373`); current `c49eedd` already has that work plus the review transcript
- Intentional removals/renames — theme switcher, old icon sets, undo-toast types, the 10-result search footer

**Leftover from the same Aptabase stash:** the two AI transcripts were still missing. I restored them into the Post-MVP transcript group (same place as the other 8-14 files):

- `Documentation/Post-MVP/AI Transcripts/8-14-2026 Discuss and Review Aptabase Integration.md`
- `Documentation/Post-MVP/AI Transcripts/8-14-2026 Implement Aptabase Integration.md`
- matching Xcode group entries in `project.pbxproj`

No other unique Swift, tests, packages, or product behavior turned up. I did not revive abandoned theme/icon/search-limit code. No commit was made.

## User

After all that we've got some test failures:

addFromSearchStubStoresResolvedNextSeason:
Expectation failed: (tracked.nextSeason → .returningNoSeasonYet) == .airing(season: 17)

addWithSeasonsSkipsDetailFetch:
Expectation failed: (tracked.nextSeason → .returningNoSeasonYet) == .airing(season: 17)

## Assistant

I'll inspect those two watchlist tests and the add-from-search path to see why `nextSeason` is `.returningNoSeasonYet` instead of `.airing(season: 17)`.

These failures are from the calendar, not Aptabase. The fixtures end season 17 on 2026-08-23, and `repository.add` scores status with `Date.now` (today is Aug 24), so the season already looks finished. I’ll switch those tests to dates relative to today so an airing season stays airing.

Those two failures were calendar-sensitive fixtures, not the Aptabase restore.

`WatchlistTracking.add` stores status via `TrackedShow(from: show)`, which uses **`Date.now`**. The fixtures ended season 17 on **2026-08-23**. Today is **August 24**, so the calculator correctly treated that season as finished and stored `.returningNoSeasonYet`. The explicit calculator checks still passed because they used a pinned July 22 date.

I updated `WatchlistTrackingTests` so the airing season is relative to today (premiered ~120 days ago, ends ~120 days from now). `WatchlistTrackingTests` — all 4 tests — passed.

**What to test:** re-run `addFromSearchStubStoresResolvedNextSeason` and `addWithSeasonsSkipsDetailFetch`; both should expect `.airing(season: 17)` again.

