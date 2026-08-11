# Search compatibility architecture

## User

I’d like to discuss a possible architecture for improving search compatibility between TheTVDB and TVMaze before we implement it.

Background

TheTVDB gives much better search coverage than TVMaze, but many shows returned by TheTVDB do not exist in TVMaze. Currently this means users can tap a search result only to discover that the app cannot open or track it.

I do not want to perform a TVMaze lookup for every search result, since that would generate many additional network requests, slow searches, and waste battery.

Proposed Idea

Investigate whether we can maintain a local compatibility database that maps TheTVDB IDs to TVMaze IDs.

The idea is:

* Use TVMaze’s paginated show index as the authoritative source.
* Extract only the information needed to determine whether a TVDB show exists in TVMaze.
* Build a local database (SQLite, SwiftData, JSON, or another efficient format) containing the mapping.
* During a TVDB search, filter the returned results using this local mapping before presenting them to the user.
* Only display shows that NextSeason can actually track.

The goal is for every displayed search result to be actionable.

Things I’d like you to investigate

1. Approximately how many shows currently exist in TVMaze?
2. How large would a database containing only:
    * TVDB ID
    * TVMaze ID
        be?
3. Would SQLite be the best format, or would another format be preferable?
4. Should this database be generated automatically as part of the build process, or maintained some other way?
5. How expensive would it be to update when a new version of the app is released?
6. Are there API limitations or licensing issues that make this approach impractical?
7. Are there better alternatives that provide the same user experience without requiring per-result TVMaze lookups?

Important

Please do not implement anything yet.

First evaluate this design, point out any problems, and propose improvements if you see them.

If you think there is a significantly better architecture, I’d like to hear it before we commit to this approach.

## Assistant

I'll evaluate this against TVMaze's show index, your current search/resolution flow, and API/licensing constraints—no implementation.

Next I'll sample TVMaze's index endpoints for a real show-count estimate, and read how your search currently resolves TVDB hits to TVMaze.

TVMaze blocked the sandboxed requests; retrying with full network access and sampling the show index for size and `externals.thetvdb` coverage.

Retrying the TVMaze size probe with approval, and pulling public catalog hints from the site/sitemap.

Page 300 exists (~75k IDs). I'll probe higher index pages and sample `externals.thetvdb` coverage for size estimates.

**Verdict:** a local TVDB↔TVMaze compatibility map is practical and well-aligned with TVMaze’s own “build a local cache” guidance. Size and regen cost are small. The main risks are false negatives, pagination thinning, and staleness—not disk or API volume.

Your current search path already does the expensive thing you want to avoid: after each TheTVDB page, `SearchViewModel` prefetches a TVMaze lookup for every hit. A local map replaces that storm with an offline filter, then one validated lookup on open/track.

---

### 1. How many shows are in TVMaze?

Approximate **~90,000** shows as of this check.

Evidence:
- Show index last valid page is **374** (IDs **93500–93502**); page **375** is 404.
- Max show ID ≈ **93,502**.
- Pages are ID-sliced (250 IDs/page) and often slightly under-full due to deletions (~240–245 shows/page in samples).

TVMaze does not expose a total count; `/updates/shows` is the authoritative inventory (too large for the fetch tool here, but the index end is clear).

---

### 2. How large would a TVDB ID + TVMaze ID database be?

Only shows with `externals.thetvdb` can be mapped. Sample coverage:

| Sample | With TheTVDB ID |
|---|---|
| Early catalog (page 0) | ~99.6% |
| Mid (page 300) | ~69% |
| Late (page 370) | ~65% |

Reasonable planning range: **~50k–70k mapped pairs**.

| Format | Rough size |
|---|---|
| Packed binary (`UInt32` + `UInt32`) | **~400–550 KB** |
| CSV / text | **~0.5–0.8 MB** |
| SQLite with index | **~0.7–1.5 MB** |
| Verbose JSON | larger; avoid |

This is tiny next to app icons/assets. Storage is not the blocker.

---

### 3. SQLite vs other formats?

**SQLite is fine, but not clearly best** for a read-only, ship-once lookup table.

Prefer (in order):
1. **Compact binary** — sorted by TVDB ID, binary search (or two parallel arrays). Simplest, fastest, smallest, no extra stack.
2. **SQLite** — if you want ad‑hoc queries, tooling, or future columns. Overkill for one join key.
3. **JSON** — easy to generate/debug; worse size and parse cost. OK for prototypes only.
4. **SwiftData** — poor fit. It’s for mutable user persistence, not a static catalog asset.

Membership-only structures (bloom/roaring) can shrink further, but then you still need a live lookup to get the TVMaze ID for stars/watchlist. Given the full map is already sub‑megabyte, store the pairs.

---

### 4. Build-time generation vs other maintenance?

**Do not rebuild on every local Xcode build.** Prefer:

1. **CI job** (weekly + on release tag) that walks `/shows?page=` and emits the asset.
2. **Commit the artifact** (or attach it to the release), with a generation timestamp/version.
3. Optional later: **OTA refresh** of the same file so catalog freshness isn’t tied to App Store cadence.

TVMaze designed the index for exactly this: start from `floor(lastCachedID / 250)` and walk to 404. Index responses are cached up to 24 hours.

---

### 5. Update cost per app release?

Low.

- Full rebuild: **~375 page requests**.
- Rate limit: **≥20 calls / 10s / IP** → roughly a few minutes with polite pacing.
- Incremental: usually only the last few pages + any shows whose `externals` changed (harder; full rebuild is cheap enough).
- App binary delta: typically **&lt;1–2 MB**.

Operational cost is CI time and review lag of a stale map—not API spend.

---

### 6. API / licensing practicality?

**TVMaze — generally supportive of this approach**
- Docs explicitly suggest using `/shows?page=` to build a local cache.
- License: **CC BY-SA** — commercial use allowed with attribution (you already attribute).
- ShareAlike can matter if you redistribute a substantial derived database; it does **not** force your app code to be CC BY-SA. Keep the mapping as a clearly attributed data asset. (Not legal advice—worth a quick license pass before shipping.)
- Rate limits are manageable for offline generation; avoid scraping from every device.

**TheTVDB — not a blocker for this design**
- You’re deriving the map from **TVMaze**, not redistributing TheTVDB’s catalog.
- Client-side filtering of TheTVDB search hits is normal API use.
- Their ToS restrict redistributing *their* data; don’t ship a TheTVDB dump.

**Practical API caveat:** many TVMaze shows have **no** `thetvdb` external (especially newer/niche). Your app already uses **IMDb fallback** for that gap. A pure TVDB→TVMaze map will **under-count** trackable shows unless you also keep IMDb fallback (or add an IMDb→TVMaze index).

---

### 7. Better alternatives (same UX goal)?

| Approach | Pros | Cons |
|---|---|---|
| **A. Local ID map (your idea)** | Zero per-result lookups; actionable list; tiny | Stale between updates; false negatives if externals missing |
| **B. Filter after current prefetch** | No new infra; uses today’s lookups | Still N requests/page; battery/rate-limit cost remains |
| **C. Map + single validate-on-open** | Best reliability | One request on tap (acceptable) |
| **D. Hosted mapping CDN** | Fresh without App Store | Needs hosting/ops |
| **E. Grow on-device cache of resolves/misses** | Learns over time | Cold start still bad; doesn’t fix first search |
| **F. TVMaze-primary search** | Always trackable | Loses TheTVDB coverage (your original reason for switching) |

There isn’t a free lunch that keeps TheTVDB coverage **and** zero network **and** perfect freshness. The local map is the best coverage/cost tradeoff.

---

## Design problems to fix before committing

1. **Pagination thinning**
   A TheTVDB page of 10 may collapse to 2–3 trackable rows. Search should **keep fetching TheTVDB pages until it can fill a useful actionable page** (or exhaust results), not just filter the first page and look empty.

2. **False negatives from missing externals**
   Keep IMDb fallback for rows absent from the map, *or* accept that some trackable shows stay hidden. I’d keep a narrow fallback rather than hide them forever.

3. **Staleness**
   New TVMaze shows / newly linked TVDB IDs won’t appear until the next map. Mitigate with: generation date, live lookup on open, optional OTA refresh, and caching of successful resolves.

4. **Don’t treat the map as source of truth for detail**
   Use it only for “is this trackable / what’s the TVMaze id?” Then fetch seasons/status from TVMaze as you do today.

5. **Current prefetch is the status quo cost**
   You’re already paying ~10 lookups per search page (page size is 10). The map’s value is eliminating that, not inventing a new UX goal.

---

## Recommended architecture (refined)

Ship a **read-only compatibility index**, not a second catalog:

```text
CI (weekly / release)
  → walk TVMaze /shows?page=
  → extract (tvdbID → tvMazeID) where externals.thetvdb != null
  → emit compact binary (+ attribution/version metadata)

App search
  → TheTVDB search pages
  → filter/join via local map
  → auto-advance TheTVDB offset until enough actionable rows
  → on open/track: one TVMaze show(id:) (or lookup) to validate + load seasons
  → optional: if not in map but imdbID present, try IMDb lookup once
```

**Format:** packed binary (or SQLite if you prefer familiarity).
**Not SwiftData. Not per-build scraping.**
**OTA later** if release cadence makes staleness annoying.

That preserves your goal—**every displayed result is actionable**—without per-result lookup storms, without changing the TVMaze-backed watchlist/detail architecture, and without impractical size or regen cost.

---

If you want a next step before implementation, I’d suggest a short spike that only measures: for a set of real queries, what fraction of TheTVDB hits are in today’s TVMaze externals map, and how many pages you’d need to fetch to fill 10 actionable rows. That number decides whether pagination-fill logic is mandatory for MVP of this feature.

## User

Yes, please go ahead with the spike.  No code changes yet, though.

Yes, please go ahead with the spike.  No code changes yet, though.

## Assistant

I'll run a measurement-only spike: build today's TVMaze TVDB→ID map, run representative TheTVDB searches, and report hit rates plus pages needed to fill 10 actionable rows—no app code changes.

Writing a temporary spike script outside the repo, then building the map and measuring search overlap.

Map build is past page 300; waiting for it to finish and run the searches.

Refining the “never filled” cases—many are catalog-limited (TheTVDB returned fewer than 10 hits), not mapping failures.

**Spike result:** a local map works, and “fill 10 actionable rows” is only sometimes the right success metric. Precise titles often have fewer than 10 TheTVDB hits total; filtering still leaves the trackable shows.

Method (measurement only, nothing written into the app repo):
- Built today’s full TVMaze index map (`/shows?page=` → 375 pages)
- Ran 24 TheTVDB series searches (`limit=10`, same as the app)
- Measured first-page overlap, pages to reach 10 mapped hits, and live lookup on unmapped samples

Artifacts are under `/tmp/nextseason-spike/` (`summary.txt`, `report.json`, `tvmaze_tvdb_map.json`).

---

### Map inventory

| Metric | Value |
|---|---|
| TVMaze shows walked | **89,038** |
| With `externals.thetvdb` | **62,022 (69.7%)** |
| Unique TVDB→TVMaze pairs | **62,022** |
| ID conflicts | **0** |

Packed binary for that map would be roughly **~500 KB**.

---

### Search overlap (24 queries)

**First-page keep rate** (mapped / TheTVDB hits on page 1):

- Mean **64%** (min **10%** Andor, max **100%**)
- Mean rows hidden on page 1: **~3.2**

**“Pages to fill 10 actionable”** needs splitting:

| Outcome | Count | Meaning |
|---|---|---|
| Filled 10 within ≤3 pages | **15/24** | Auto-advance helps |
| Never filled — catalog &lt;10 TheTVDB hits | **6/24** | Can’t show 10 anyway (Severance, Breaking Bad, AoT, Demon Slayer, Squid Game, Money Heist) |
| Never filled — enough hits, not enough mapped | **3/24** | Stranger Things (6/10), One Piece (2/10), Andor (7/18) |

Among the 15 that did fill 10:

- Median **2** pages
- Histogram: **1 page ×4**, **2 pages ×9**, **3 pages ×2**

---

### What “never fill 10” actually looks like

These would still show a usable actionable list:

| Query | Actionable after filter | TheTVDB hits |
|---|---|---|
| Severance | 2 | 4 |
| Demon Slayer | 1 | 1 |
| Money Heist | 4 | 4 |
| Squid Game | 2 | 5 |
| Breaking Bad | 5 | 9 |
| Stranger Things | 6 | 10 |
| Andor | 7 | 18 |
| One Piece | 2 | 10 |

Unmapped samples were mostly podcasts, foreign remakes, fan shorts, and loose title matches—not the primary show. Live probe of 25 unmapped IDs: **0** resolved via `/lookup?thetvdb` or IMDb. The map looks accurate for “not in TVMaze,” not stale.

---

### Design implications

1. **Pagination-fill is useful, but not mandatory for MVP.**
   It matters for broad/ambiguous queries (`Love`, `Shogun`, `Fallout`) where page 1 keep rate is ~20–40%. For precise titles, showing 1–7 actionable rows is normal and fine.

2. **First-page-only filtering can look sparse.**
   Worst cases: Andor **1/10**, Fallout/One Piece **2/10**. Auto-fetching 1–2 more TheTVDB pages (or targeting “enough rows,” not strictly 10) fixes most of that.

3. **Prefer “fill until N actionable or exhausted”** over “always 10.”
   Target something like **min(10, available_mapped)** and stop when TheTVDB has no more hits.

4. **IMDb fallback didn’t rescue the unmapped spike samples.**
   Keep it as a safety net if you want, but it isn’t required to make filtering feel correct for these queries.

5. **Filtering improves relevance** by dropping noise TheTVDB includes that TVMaze doesn’t track.

---

### Recommendation from the spike

Proceed with the local map approach. For search UX:

- Filter with the map
- Auto-advance TheTVDB pages until you have a reasonable actionable page **or** results are exhausted
- Don’t treat “always 10 rows” as a hard requirement

If you want a follow-up spike before implementation, the highest-value one would be: for each query, is the **top TheTVDB hit** (the one users expect) in the map? From the unmapped samples, it looks yes for the big titles—but confirming rank-1 keep rate would lock that down.

