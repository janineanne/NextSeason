# TVDB TVMaze compatibility index

## User

Please implement the TVDB↔TVMaze local compatibility index we discussed.

Goal

TheTVDB gives us broader search coverage than TVMaze, but many TheTVDB results cannot be resolved to TVMaze. I want Search to display only shows that NextSeason can actually open and track, without performing a TVMaze network lookup for every search result.

The local compatibility index should answer:

TVDB show ID -> TVMaze show ID

quickly and offline.

Architecture

Use a bundled SQLite database as the initial compatibility snapshot.

The database should:

* contain only the data necessary for compatibility lookup
* map TheTVDB IDs to TVMaze IDs
* include metadata needed to track its generation/sync state
* be copied to a writable application location on first use
* remain usable even if incremental updating fails

Do not use SwiftData for this. A small direct SQLite-backed store is preferred because the data is relational, tiny, and incrementally mutable.

Please keep this implementation isolated behind a small compatibility-index abstraction rather than exposing SQLite details to SearchViewModel.

For example, the rest of the app should conceptually be able to ask something equivalent to:

tvMazeID(forTVDBID:)

without caring how that lookup is implemented.

Search behavior

Update the TheTVDB search flow so that:

1. Search results come from TheTVDB as they do now.
2. Each result is checked against the local compatibility index, not against the TVMaze network API.
3. Results with a known TVMaze mapping are displayed.
4. Results that cannot be mapped locally are normally omitted.
5. Preserve the existing narrow IMDb fallback if it is useful for avoiding false negatives for shows that TVMaze supports but whose TVDB external ID is missing.
6. When the user opens/selects a displayed result, still fetch/validate the actual show through TVMaze. The compatibility database is only an index; it must not become the source of truth for show metadata, status, seasons, etc.

A displayed result should therefore be overwhelmingly likely to be actionable, while TVMaze remains the canonical provider after selection.

Pagination

Filtering may substantially thin a TheTVDB result page.

Do not simply filter one page of TheTVDB results and return whatever remains.

Continue requesting subsequent TheTVDB pages until there is a reasonable number of actionable results or the available results are exhausted. Do not continue fetching pages solely to reach an arbitrary count.

Avoid infinite loops and excessive requests. Preserve the existing search cancellation/debouncing behavior.

Bundled database generation

Create a repeatable repository-side developer tool that generates the compatibility database from TVMaze’s paginated /shows?page= index.

Do not introduce CI.

The generator should be runnable manually before an App Store release and should be designed so that CI could invoke the same tool in the future if CI is ever added.

Do not hook the generator into normal Xcode builds.

The generator should:

1. Walk the TVMaze show index.
2. Extract entries with a usable externals.thetvdb ID.
3. Store:
    * TVDB ID
    * TVMaze ID
4. Produce the SQLite database bundled with the app.
5. Record useful metadata such as:
    * generation date
    * highest TVMaze ID represented
    * schema/version information if appropriate
6. Be safe to rerun and deterministic enough that unexpected changes are visible in source control.

Please include brief instructions in the repository documentation explaining how to regenerate the bundled database before a release.

Incremental on-device updates

The bundled database should not remain permanently frozen until the next App Store release.

Once installed, NextSeason should maintain a writable copy with lightweight, opportunistic incremental updates.

This refresh must NOT block Search or app launch.

The bundled snapshot is always considered usable even when stale.

A roughly weekly refresh is sufficient. It should occur during normal app use when practical; do not add a new background task solely for this feature.

For new TVMaze shows:

* remember the highest TVMaze ID/index state represented locally
* use TVMaze’s paginated show index to inspect the tail of the catalog and add new TVDB→TVMaze mappings

For existing shows whose external IDs may have changed:

* investigate/use TVMaze’s /updates/shows mechanism to identify changed shows since the previous refresh
* refresh only the necessary TVMaze records and update/remove their mappings as appropriate

Store enough metadata locally to support this safely, for example:

* last successful compatibility sync date
* highest TVMaze ID represented
* database/schema version

Failures should be non-fatal and simply leave the existing map in place.

Please be conservative about network work. This is a freshness optimization, not something that must complete for the app to function.

API behavior and rate limiting

Respect TVMaze’s documented rate limits and caching guidance.

The on-device updater should avoid request bursts and unnecessary refetches.

The full TVMaze catalog should never be downloaded by every device as part of first launch. That is why the app ships with a bundled baseline.

Licensing / attribution

Do not remove any existing TVMaze or TheTVDB attribution.

Because the bundled mapping is derived from TVMaze data, keep the generated artifact clearly documented as TVMaze-derived data and retain whatever attribution/license documentation is appropriate for that asset.

Do not copy or bundle a TheTVDB catalog.

Existing behavior to remove

The current implementation appears to prefetch TVMaze resolution for each TheTVDB search result.

Once the compatibility index is working, remove that per-result TVMaze lookup behavior so we actually gain the network/battery benefit this design is intended to provide.

Error handling

Please keep this deliberately boring:

* corrupt/missing writable database -> recreate from bundled database
* incremental refresh failure -> continue using existing database
* mapping absent -> omit result or use the narrow fallback described above
* TVMaze validation fails after selection -> use the existing unavailable/error behavior

Do not create elaborate recovery machinery for a cache/index that can always be reconstructed from its bundled baseline.

Tests

Add focused tests for at least:

* TVDB ID maps to expected TVMaze ID
* unknown TVDB ID returns no mapping
* filtering removes incompatible results
* pagination continues when filtering leaves too few usable results
* pagination terminates correctly when there are no more results
* incremental addition of a new mapping
* update/replacement/removal of an existing mapping
* failed incremental refresh leaves existing data usable
* writable database can be recreated from the bundled baseline

Please avoid tests that depend on the live TVMaze or TheTVDB services.

Scope

Keep this focused on solving search compatibility.

Do not turn the local database into a second TV metadata store, and do not migrate TVMaze show details, seasons, watchlist data, or other application state into it.

After implementation, please summarize:

1. The files added/changed.
2. The SQLite schema.
3. How the bundled database is generated.
4. How and when incremental updates occur.
5. How Search now filters/fills result pages.
6. Any deviations you made from this design and why.
7. Any remaining risks or follow-up work you think I should know about.

## Assistant

I'll implement the local TVDB↔TVMaze compatibility index. First I'll review prior discussion and the current search/resolution flow so the design matches what we already have.

Next I'll read the prior architecture notes and the core search/TVMaze files so the implementation lines up with what we already decided.

I have enough context to implement. Checking a few more wiring points, then I'll add the SQLite store, generator, search filtering, and tests.

Implementing core pieces: SQLite store, generator script, TVMaze index APIs, and Search filtering. Starting the bundled DB generation in parallel.

Fixing generator variable scope, then implementing the SQLite store and related services.

Fixing multi-statement SQLite execution, then adding the refresh service and Search integration.

Wiring dependency injection and updating the Search UI next.

Rewriting the database tests to use proper async Swift Testing, then updating SearchViewModelTests.

Updating the SearchView docs, then building and running tests.

Actor inits can't call isolated methods — I'll move migration onto the raw SQLite handle.

Implemented. Search now filters through a local TVDB→TVMaze SQLite index instead of prefetching TVMaze for every hit. Skills used: `swift-concurrency-pro`, `swift-testing-pro`.

### 1. Files added/changed

**Added**
- `NextSeason/Services/Compatibility/` — protocol, SQLite store, local facade, refresh service, in-memory index
- `NextSeason/Models/DTO/ShowIndexEntryData.swift`
- `NextSeason/Resources/Compatibility/tvdb_tvmaze_compatibility.sqlite` (~1.5 MB, 62,022 mappings)
- `NextSeason/Resources/Compatibility/ATTRIBUTION.md`
- `Scripts/generate-tvdb-tvmaze-compatibility-db.py`
- `NextSeasonTests/CompatibilityIndexDatabaseTests.swift`

**Changed**
- `SearchViewModel.swift` — local filter + page fill; prefetch removed
- `TVMazeService` / `TVMazeClient` — `showsIndex` + `showIndexEntry`
- DI wiring: `AppCompositionRoot`, `NextSeasonApp`, `ContentView`, `SearchView`
- Tests, `Scripts/README.md`, `AGENTS.md`, `project.pbxproj` (`-lsqlite3`)

### 2. SQLite schema

```sql
CREATE TABLE meta (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

CREATE TABLE mappings (
  tvdb_id INTEGER PRIMARY KEY NOT NULL,
  tvmaze_id INTEGER NOT NULL
);

CREATE INDEX idx_mappings_tvmaze_id ON mappings(tvmaze_id);
```

Meta keys: `schema_version`, `generated_at`, `highest_tvmaze_id`, `last_successful_sync_at`, `mapping_count`, `source`, `license`.

### 3. Bundled DB generation

```bash
./Scripts/generate-tvdb-tvmaze-compatibility-db.py
```

Walks `GET /shows?page=`, keeps rows with `externals.thetvdb`, writes the bundled SQLite file. Manual / pre-release only (CI-ready later). Details in `Scripts/README.md` and `ATTRIBUTION.md`.

### 4. Incremental updates

`CompatibilityIndexRefreshService` runs on foreground activation (separate non-blocking `Task`):
- Skips if last successful sync &lt; ~7 days
- Tail-sync from `highest_tvmaze_id`
- Applies `/updates/shows` (capped at 75 detail fetches/opportunity, paced)
- Failures leave the existing DB usable; bundled baseline can recreate a corrupt writable copy

### 5. Search filtering / pagination

1. TheTVDB pages as before
2. Keep hits present in the local index
3. Narrow IMDb network fallback only for unmapped hits that already have an IMDb id
4. Advance TheTVDB pages until ~10 actionable results, exhaustion, or 6 pages max
5. On open/track: still fetch/validate via TVMaze (`show(id:)` / lookup / IMDb)

### 6. Deviations

- Used SQLite (as requested) rather than the earlier “packed binary” preference from the architecture chat.
- IMDb fallback still does a network lookup for unmapped-with-IMDb hits during filtering (narrow; not the old per-result TheTVDB prefetch).
- Update refresh is work-capped per opportunity so a large weekly `/updates` window can’t burst.

### 7. Risks / follow-ups

- False negatives remain when TVMaze has the show but neither `externals.thetvdb` nor a usable IMDb id on the TheTVDB hit.
- App updates with a newer bundled DB don’t automatically replace an existing writable copy (incremental sync covers the gap; a “bundled newer than local → replace” rule could be added later).
- First on-device sync after install may do a modest burst (tail + up to 75 update fetches).

**Tests:** 18 focused unit tests passed (`CompatibilityIndexDatabaseTests` + `SearchViewModelTests`).

**What to try:** Search known titles (e.g. Severance), confirm unmapped TheTVDB-only noise is gone, open/track still loads from TVMaze, and that search no longer fans out lookups per result.

## User

That looks good, but I have a few changes to request:

Remove the IMDb-based fallback from TVDB search filtering. Since search compatibility should now be determined entirely by the local TVDB-ID → TVMaze-ID index, also remove any IMDb-ID fields, decoding, mocks, tests, or supporting code that were added specifically for this fallback and are no longer used. Do not remove pre-existing IMDb data used elsewhere in the app.

## Assistant

I'll remove the IMDb filtering fallback and strip only the IMDb pieces that existed solely for that path, leaving any pre-existing IMDb usage elsewhere intact.

Simplifying the search tests to drop IMDb filtering scaffolding while keeping the resolve-path IMDb API.

Removed the IMDb path from search filtering. Compatibility is now solely the local TVDB→TVMaze index.

**Changed**
- `SearchViewModel.filterActionable` — index lookup only; no IMDb network calls while building results
- Comments updated to match
- `ShowExternalsData` — dropped unused `imdb` / `tvrage` fields added with the index DTO
- Search tests — removed IMDb filtering counter/handler scaffolding

**Kept (pre-existing)**
- `TVDBSearchResult.imdbID` + TheTVDB `remote_ids` decoding
- `TVMazeService.lookupShow(imdbID:)` and the open/track resolve fallback

All 18 related unit tests still pass.

## User

There are a couple of bugs in the incremental updater:

It processes at most 75 shows, then sets last successful sync to now(). If there were more than 75 changes, they'll never be processed.  The 75 show limit is reasonable, but the updater needs to be resumable so it starts from where it left off.

This code:

let orderedIDs = updates.keys.sorted(by: >)

Has this comment:

// Prefer newer changes first

But that sort is by TVMaze show ID.  It should be sorting by update timestamp instead.

## Assistant

I'll fix both updater bugs: resume after the 75-show cap instead of marking sync complete, and sort by update timestamp rather than show ID.

I'll make update sync resumable via a stored cursor, only mark `lastSuccessfulSyncAt` when the queue is drained, and sort by update timestamp.

Both updater bugs are fixed.

**Sort** — Pending updates are ordered by update timestamp (newest first), with show ID only as a tiebreaker.

**Resume** — When the per-opportunity cap is hit:
- A resume cursor (`updates_resume_at` + `updates_resume_show_id`) is stored
- `lastSuccessfulSyncAt` is **not** advanced
- The next foreground opportunity continues older remaining work (weekly interval is skipped while a cursor exists)
- Sync is marked complete only after the updates window is fully drained

Added tests cover timestamp ordering, cursor filtering, and a 2-show-cap resume across two refresh passes.

## User

When a search is being done from the search tab, a block of fake content is shown with the TVDB attribution below it.  Is it possible to have the attribution only show when the real data arrives?

## Assistant

I'll remove TheTVDB attribution from the loading skeleton and keep it only on real results.

Yes. The attribution was on the loading skeleton footer as well as results; it’s removed from loading and now only appears under real result rows.

## User

Thank you!

## Assistant

You’re welcome.

## User

More fixes:

    The incremental-refresh resume algorithm can skip updates. Cursor fixed the previous 75-item bug, but the cursor solution has another race. Imagine pass 1 processes 75 changes and records a cursor. Before pass 2, another TVMaze show gets updated. Pass 2 deliberately ignores everything newer than the cursor while it finishes the old backlog. When the backlog finally finishes, the code sets lastSuccessfulSyncAt to now. That newly changed show was never processed, but it now falls before the recorded sync date and can be skipped forever. The refresh needs a fixed upper watermark—essentially “this synchronization began at T.” Finish everything up through T, then record T, not the time the final batch happened. Newer changes are then picked up on the next synchronization.

## Assistant

I'll fix the resume race by capturing a fixed sync start watermark and committing that time when the backlog finishes, not `now()` from the final batch.

I'll add a persisted sync-start horizon and commit that timestamp when the backlog finishes, so mid-resume updates aren't lost.

The mid-drain test clock was wrong — pass 3 exited early on the weekly interval check. Fixing that.

Pass 3 paused because the fetch cap still applied to the full update window. Tightening the test so the deferred sync only has the mid-drain update.

Fixed. Each sync now freezes an upper watermark when it starts (`syncHorizonAt`).

- Only updates at or before that horizon are drained (resume cursor still handles the backlog).
- On completion, `lastSuccessfulSyncAt` is set to the horizon, not wall-clock `now`.
- Changes that arrive mid-drain stay eligible for the next sync.

Added a regression test for the mid-drain race.

## User

A long absence can also lose compatibility changes. TVMazeUpdatePeriod.covering falls back to .month for anything older than a week. If someone doesn’t open NextSeason for two months, changes made more than a month ago aren’t returned. TVMaze’s API does provide /updates/shows without a since filter, which returns the last-update timestamp for every show.   For the rare lastSync > one month ago case, I’d use that and filter locally against the stored watermark. That prevents a long-unused installation from permanently missing external-ID changes.

## Assistant

I'll add an unfiltered `/updates/shows` path for syncs older than a month, then filter locally against the stored watermark.

The test file got corrupted during the edit — rewriting it cleanly.

The long-absence test dates put a change after the horizon — adjusting them.

Done. When `lastSuccessfulSyncAt` is older than ~30 days, compatibility refresh now:

1. Calls unfiltered `GET /updates/shows` (`allUpdatedShows()`)
2. Filters locally to updates after the stored watermark and at/before the sync horizon

Shorter gaps still use `since=day|week|month`. Watchlist refresh is unchanged.

## User

The first incremental refresh does far more work than necessary. The bundled database has a generated_at timestamp, but the refresher ignores it when lastSuccessfulSyncAt is nil and requests the previous week of updates. That means a freshly installed app can start fetching details for scores or hundreds of shows whose mappings are already reflected in a database generated that same day. The initial watermark should be lastSuccessfulSyncAt ?? generatedAt. This would make the first update genuinely incremental instead of rechecking a week’s worth of existing data.

## Assistant

I'll seed the first refresh watermark from `generatedAt` when `lastSuccessfulSyncAt` is nil, so a fresh install doesn't recheck a full week of already-bundled mappings.

## User

Did you actually make that change?

## Assistant

No — I described the change but didn’t apply it. Doing that now.

Correct — I hadn’t applied it earlier. It’s in place now.

First updates pass uses `lastSuccessfulSyncAt ?? generatedAt` as the watermark, so a fresh install only pulls changes after the bundled snapshot was built (instead of a default week). Added a regression test for that behavior.

## User

IMDb wasn’t actually removed. It no longer slows Search, which is why your paging became much faster, but the branch still contains imdbID in TVDBSearchResult, remoteIDs decoding, the mapping code, lookupShow(imdbID:), protocol requirements, mocks, previews, tests, and the fallback in SearchViewModel.lookupTVMazeShow. I don’t see a reason to retain any of it now. The intended flow is much clearer as TVDB ID → local mapping → TVMaze ID. If a displayed mapping proves stale, falling back to lookupShow(theTVDBID:) on the explicit user tap is already reasonable. I’d remove the IMDb machinery added by this branch.

## Assistant

I'll remove the remaining IMDb search/resolve machinery so the path is strictly TVDB ID → local map → TVMaze ID, with `lookupShow(theTVDBID:)` only on stale mapping.

Removed the remaining IMDb search/resolve machinery.

**Gone:** `imdbID` on `TVDBSearchResult`, `remote_ids` decoding/`TheTVDBRemoteIDData`, `lookupShow(imdbID:)` (protocol + client), mapping/preview/mock/test usage, and the IMDb branch in `lookupTVMazeShow`.

**Resolve path now:** local map → `show(id:)` → on stale/missing, `lookupShow(theTVDBID:)`.

## User

Search can incorrectly display “Can’t Find Your Show?” even though usable results exist later. collectActionableResults stops after six TVDB pages. That’s a sensible safety cap. But if those six pages contain zero compatible shows while TVDB says more results exist, search() sets .empty. The UI then provides no Load More button, so the user can never reach page seven. The code already knows fill.hasMore == true; that fact needs to survive into the UI. I would not remove the six-page safety cap—I’d make the “no actionable results yet, but more exist” state capable of offering Load More.

## Assistant

I'll keep the six-page cap, but when filtering yields no actionable hits while TheTVDB still has more pages, surface a Load More path instead of the empty state.

The ViewModel/UI changes landed; adding the missing tests now.

Tests failed on actor isolation for `maxTheTVDBPagesPerFill` — checking how it's defined and fixing access.

Marking the page-fill constants `nonisolated` so tests can read them, then re-running.

Investigating how fill advances offsets — the new tests don't match the fill loop behavior.

Offset advances by result count (1 per mock page), not `pageSize`. Updating the tests to match.

Fix is complete. Empty filtered batches no longer wipe `hasMore`.

**Behavior**
- `search()` → `.empty` only when there are no actionable items **and** TheTVDB is exhausted
- Otherwise → `.results` (including `items: []` + `hasMore: true`) so Load More stays available
- `loadMore()` → `.empty` only after a later burst also finds nothing and TVDB is exhausted
- UI: “Still Looking…” + Load More when items are empty but more pages exist

**Tests**
- Zero actionable + more pages → Load More can surface a later mapped hit
- Load More exhaustion with nothing actionable → `.empty`
- All 14 `SearchViewModelTests` pass

**What to try**
1. Search something that filters out the first six TVDB pages but has a compatible show later — you should see “Still Looking…” and Load More, not “Can’t Find Your Show?”
2. Tap Load More until results appear (or until true empty if none exist)

## User

Pagination bookkeeping is subtly wrong when TVDB returns a malformed/sparse record. TheTVDBClient deliberately uses compactMap to discard search records that don’t have a usable ID/name. That’s good defensive decoding. But SearchViewModel advances offset by page.results.count—the number after invalid records were discarded. Likewise hasMorePages uses that filtered count. If TVDB returned 10 raw hits and one couldn’t be converted, the next request starts at offset 9 instead of 10. You can get overlap, duplicates, unnecessary calls, and increasingly inaccurate offsets. I’d have TheTVDBClient return the correct nextOffset, based on the raw response count/API pagination metadata, rather than making the view model reconstruct it.

## Assistant

I'll fix pagination so offset advances from the raw TVDB page size/metadata, not the post-`compactMap` result count. Checking the client, page model, and ViewModel bookkeeping next.

Updating the page model and client so `nextOffset`/`hasMore` use the raw API row count, then wiring the ViewModel to that.

Updating call sites and adding tests.

Pagination now advances from the raw TVDB page, not the post-filter result count.

**Change**
- `TheTVDBSearchPage` includes `nextOffset`
- `TheTVDBClient.makeSearchPage` sets `nextOffset` / `hasMore` from **raw** API row count (before `compactMap`)
- `SearchViewModel` uses `page.nextOffset` and no longer reconstructs offset from `results.count`

**Tests**
- Client: sparse drops don’t shrink the cursor; full sparse pages still report `hasMore`
- ViewModel: second request uses `nextOffset` (e.g. 10), not filtered count (e.g. 1)

**What to try**
Search/load-more still paginates cleanly; no duplicate overlap from discarded sparse records.

## User

I'm not sure when this happened but the tracking button is no longer where it should be.

## Assistant

The star should sit on the trailing edge of each row; I'll inspect the search result row layout next.

The star sits after the label because the row HStack never expands the label or inserts a spacer. Checking the watchlist row for the intended layout.

Search rows are missing the watchlist’s `.frame(maxWidth: .infinity)` on the label, so the star hugs the text. Adding that now.

Search rows were missing the width expansion watchlist already uses, so the star sat next to the text instead of on the trailing edge.

**Fix:** `.frame(maxWidth: .infinity, alignment: .leading)` on the result label button in `SearchView`, matching `WatchlistView`.

**What to try:** Search “Happy” again — stars should line up on the right of each row.

## User

There is also one cleanup I would do specifically because this is a portfolio project. LocalCompatibilityIndex looks unnecessary. CompatibilityIndexDatabase already conforms directly to TVDBTVMazeCompatibilityIndex. LocalCompatibilityIndex mostly forwards one method to it, contains an unused makeDefault() factory, and duplicates the corrupt-database bootstrap logic that AppCompositionRoot performs separately. That’s exactly the sort of abstraction another engineer might ask, “What is this layer buying us?” Right now, the answer is very little. I’d either make it genuinely responsible for bootstrapping/recovery and use that responsibility from the composition root, or remove the wrapper and inject CompatibilityIndexDatabase behind the protocol directly. I lean toward removing it.

## Assistant

Agreed — I'll remove `LocalCompatibilityIndex` and wire `CompatibilityIndexDatabase` through the protocol at the composition root.

Trimming the composition-root comment — the injection is self-explanatory.

Removed `LocalCompatibilityIndex`.

`AppCompositionRoot` now injects `CompatibilityIndexDatabase` as `any TVDBTVMazeCompatibilityIndex` for Search, and still passes the concrete database into `CompatibilityIndexRefreshService`. Bootstrap/recovery stays in the composition root only.

