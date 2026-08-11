# TVMaze-derived compatibility index

`tvdb_tvmaze_compatibility.sqlite` maps TheTVDB series ids to TVMaze show ids.

## Source and license

This artifact is **derived from [TVMaze](https://www.tvmaze.com/) public API data**
(`GET /shows?page=`), specifically each show’s `externals.thetvdb` value when present.

TVMaze data is licensed under [CC BY-SA](https://creativecommons.org/licenses/by-sa/3.0/).
NextSeason already attributes TVMaze in the app UI; this file is an additional
derived data asset and must retain that attribution.

This is **not** a TheTVDB catalog dump. Do not ship TheTVDB’s database.

## Purpose

Offline filtering for Search so the UI only lists shows NextSeason can open and
track via TVMaze. The index is not the source of truth for titles, seasons, or
status — TVMaze remains canonical after the user selects a result.

## Regenerating

From the repository root (manual, pre-release — not part of normal Xcode builds):

```bash
./Scripts/generate-tvdb-tvmaze-compatibility-db.py
```

See `Scripts/README.md` for details. Commit the updated SQLite file so the change
is visible in source control.
