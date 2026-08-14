# TVMaze-derived show ID mapping

`tvdb_tvmaze_show_id_mapping.sqlite` maps TheTVDB series ids to TVMaze show ids,
plus TVMaze title and medium poster URL for Search display.

## Source and license

This artifact is **derived from [TVMaze](https://www.tvmaze.com/) public API data**
(`GET /shows?page=`), specifically each show’s `externals.thetvdb` value when
present, along with `name` and `image.medium`.

TVMaze data is licensed under [CC BY-SA](https://creativecommons.org/licenses/by-sa/3.0/).
NextSeason already attributes TVMaze in the app UI; this file is an additional
derived data asset and must retain that attribution.

This is **not** a TheTVDB catalog dump. Do not ship TheTVDB’s database.

## Purpose

Offline filtering for Search so the UI only lists shows NextSeason can open and
track via TVMaze. Search rows overlay TVMaze title and poster from this snapshot.
Live TVMaze remains canonical for detail and watchlist after the user selects a
result.

## Regenerating

From the repository root (manual, pre-release — not part of normal Xcode builds):

```bash
./Scripts/generate-tvdb-tvmaze-show-id-mapping-db.py
```

See `Scripts/README.md` for details. Commit the updated SQLite file so the change
is visible in source control.
