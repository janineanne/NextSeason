# AppCompositionRoot change

## User

Are we displaying any posters directly from TVDB data?

## Assistant

I'll search how posters are loaded and whether any of those URLs come straight from TheTVDB.

Yes — **search result rows** do. Watchlist and show detail do not.

Search hits stay on TheTVDB until the user opens or tracks a show. `ShowRowLabel` loads `result.posterURL` with `AsyncImage`, and that URL comes from TheTVDB’s `image_url`, falling back to `thumbnail`:

```19:21:NextSeason/Models/Mapping/TheTVDBSearchResultData+Domain.swift
        let poster =
            imageURL.flatMap(URL.init(string:))
            ?? thumbnail.flatMap(URL.init(string:))
```

Watchlist rows and show detail use TVMaze’s `posterMediumURL` instead. Those URLs are mapped from TVMaze’s `image.medium` when a show is resolved, saved, or refreshed.

## User

We can't use image data from TVDB;  they don't transfer the rights to users of their API the way TVMaze does.  Plus it would be bad to display the poster from two different sources;  they might have different images.  How hard will it be to always use the poster from TVMaze?

## Assistant

I'll trace how search currently shows posters versus when TVMaze data is fetched, so we can judge how hard it is to use TVMaze artwork everywhere.

Not hard to **stop** using TheTVDB artwork. The work is getting TVMaze posters onto **search rows** without bringing back the per-hit prefetch you just removed.

Watchlist and show detail already use TVMaze’s `posterMediumURL`. The only TVDB images on screen are search-result posters (`image_url`, then `thumbnail`).

**Cheap and legal (small change):** drop those fields and show the existing placeholder on search. No extra network. Rows stay text-only until the user opens or tracks a show, at which point detail/watchlist already have the TVMaze poster.

**Using TVMaze posters on the search list** is the real cost, because search currently has a TVMaze **id** from the local index, not a show payload. Three ways:

1. **Prefetch `GET /shows/:id` for each visible row** (~10 per page). Straightforward, but it is the old N-request storm. TVMaze’s ~20 calls / 10s limit and the 1-hour HTTP cache help a bit, and already-tracked shows could reuse the watchlist URL immediately. Still the option you moved away from.

2. **Fill posters in the background after the list appears.** Same API cost, better perceived speed (placeholder first). Still competes with a tap into detail.

3. **Store `image.medium` in the compatibility SQLite.** Best fit for the current design. The generator already walks `GET /shows?page=`, and those payloads include poster URLs — they just are not saved. Schema + generator + refresh + a local lookup on search. Zero extra TVMaze calls at search time. Posters can be up to a week stale, which is fine for thumbnails.

I would not prefetch. If search must show a poster, put the TVMaze URL in the index; otherwise keep the placeholder. Either way, stop decoding TheTVDB `image_url` / `thumbnail`.

## User

I've noticed that for foreign films TheTVDB uses titles in the native language while TVMaze has translated titles.  That means that the search results show a different titled than the show detail or watchlist.  I'd like to amend the above plan to also add the show title to the database, so we can use TVMaze's title everywhere.  Does that sound reasonable?

## Assistant

I’ll check how search titles are sourced today and what the compatibility database already stores, so we can judge adding TVMaze titles alongside posters.

Yes. Title belongs in the same snapshot as the poster.

Search is the only screen still showing TheTVDB copy. Watchlist and detail already use TVMaze’s `name`. Putting **TVMaze `name` and `image.medium`** on each mapping row lets search overlay those fields locally, with no extra TVMaze calls and no TheTVDB artwork.

The generator already walks `GET /shows?page=`, which includes both fields. Incremental refresh can write them on the same `applyMapping` path once `showIndexEntry` keeps `name` and `image`.

A few things to plan for:

- **Schema bump, then replace.** Today `migrateIfNeeded` only ensures tables exist. Adding columns on an existing writable file would leave ~62k rows with null title/poster until a show happens to appear in `/updates/shows`. Ship schema 2 in the bundled DB and replace the on-device copy when the schema does not match, the same way a corrupt file is replaced from the bundle.
- **Still a search-display cache, not canonical metadata.** Live TVMaze stays the source of truth after open/track. Rows can be up to a week stale, which is fine for a list thumbnail and title. Missing fields fall back to a placeholder (poster) or TheTVDB name (title) rather than a blank row.
- **Search still queries TheTVDB.** A user who types the native title can get a hit whose row then shows the TVMaze (usually English) name. That is the inconsistency you want to fix on the way into detail; it does not make TheTVDB search match English-only queries.
- **Size.** Two integers per row today. Adding a title string and a poster URL will grow the file (likely several MB). Still reasonable to bundle; worth checking after a regenerate.

I would look up a small record (`tvMazeID`, `name`, `posterMediumURL`) instead of stretching `ShowIDMapping` with extra one-off methods. Year, network, and status can stay TheTVDB for now; those mismatches are much less visible than title and poster.

## User

Ok, sounds good. Please implement the entire plan.

## Assistant

I'll implement the mapping-DB title and poster overlay, then wire search to use those TVMaze fields instead of TheTVDB artwork and names. First I'm reading the Swift skills and the current mapping, search, and refresh code.

I'll add TVMaze title and poster to the mapping schema, overlay those on search rows, and stop using TheTVDB artwork. Starting with the generator so the bundled database can rebuild while the Swift changes land.

Search now uses **TVMaze title and poster** from the local mapping. TheTVDB artwork is no longer decoded or shown. Skills used: `swift-concurrency-pro`, `swift-testing-pro`, `swiftui-pro`.

**What changed**
- Mapping schema is now version 2: each row stores `tvmaze_id`, `name`, and `poster_medium_url`.
- Search overlays those TVMaze fields onto each result. Title falls back to TheTVDB only if the snapshot has no name. Poster never falls back.
- Incremental refresh writes the same display fields when it updates a show.
- On launch, an older on-device database is replaced from the bundled snapshot so existing installs get titles and posters instead of empty new columns.
- Regenerated `tvdb_tvmaze_show_id_mapping.sqlite`: 62,043 mappings, all with titles, 58,513 with posters (~6.9 MB).

Watchlist and show detail were already TVMaze-only. Year, network, and status on search rows are still TheTVDB.

**What to test**
- Search a show whose TheTVDB name differs (foreign-language title) and confirm the list shows the TVMaze name and poster, matching detail/watchlist.
- Search a show with no TVMaze artwork and confirm the placeholder, not a TheTVDB image.
- Quit and relaunch once so the schema-1 on-device copy is replaced; search rows should have titles/posters immediately.
- Open and track still resolve through live TVMaze as before.

## User

<timestamp>Friday, Aug 14, 2026, 1:07 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: error
task_id: 865008
title: Regenerate bundled mapping SQLite with titles
tool_call_id: call-16a903c3-8eed-4079-944f-dcd10a887210-88
fc_a372000d-3c7e-978a-bd50-1b19ede70517_0
detail: exit_code=1
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/865008.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

The first mapping-database regenerate failed because the sandbox blocked TVMaze. The retry with network access completed successfully, and the bundled schema 2 file is in place.

## User

Have you made any test updates or additions that are needed?

## Assistant

I'll check the current tests on this branch against the mapping and search changes.

Yes. The tests for this change are already in place, and the focused suites passed (42 tests).

**Added**
- `ShowIDMappingDatabaseTests` — store title/poster, keep them on an ID-only upsert, migrate a schema 1 file, replace an older writable DB from the bundle
- `ShowIDMappingRefreshServiceTests` — refresh writes TVMaze name and poster
- `SearchViewModelTests` — search overlays TVMaze title/poster, and does not fall back to a TheTVDB image

**Updated**
- `TheTVDBClientTests` — dropped `imageURL` / `thumbnail` from DTO construction
- Mapping and refresh mocks — look up `ShowIDMappingRecord` and pass name/image on index entries

Nothing else is required for this plan unless you want extra coverage (for example decoding a TVMaze index payload with `name` and `image`).

