# TVMaze Research — NextSeason

Phase 2 deliverable. Last updated: June 13, 2026.

API reference: [TVMaze API](https://www.tvmaze.com/api)

---

## Summary and recommendation

**TVMaze is a viable data source for NextSeason.** The public REST API exposes show search, show-level status, per-season premiere dates, and an updates feed — enough to power v0.1 guest search and future status-change notifications.

**Recommendation:** Proceed to Phase 3 (Architecture) using TVMaze as the sole data provider. No third-party dependencies required.

**Caveats:**

- TVMaze data is community-maintained; premiere dates can be announced before episodes are scheduled, or vice versa.
- API responses are cached up to 60 minutes — not real-time.
- iOS cannot guarantee 12-hour background polling without a backend; use `BGAppRefreshTask` as a supplement, not the sole mechanism.

---

## Endpoints we will use

| Purpose | Endpoint | Used in |
|---|---|---|
| Search shows | `GET /search/shows?q={query}` | v0.1 guest search |
| Show details | `GET /shows/{id}` | v0.1 show detail, future polling |
| Season list | `GET /shows/{id}/seasons` | v0.1 next-season derivation, future polling |
| Next episode (optional) | `GET /shows/{id}?embed=nextepisode` | v0.1 supplement when current season is airing |
| Show updates | `GET /updates/shows?since=day` | Future efficient polling |

**Not needed for NextSeason:**

- `/schedule`, `/schedule/full` — country/date episode listings, not show-specific next-season status
- `/shows/{id}/episodes` — full episode list is heavier than needed; seasons + optional nextepisode suffice
- `/singlesearch/shows` — returns one ambiguous result; regular search with user disambiguation is safer

### v0.1 API call pattern

1. **Search:** `GET /search/shows?q=severance` → user picks from results (each result includes full show object)
2. **Detail:** `GET /shows/{id}/seasons` → derive next-season status
3. **Optional:** `GET /shows/{id}?embed=nextepisode` → if current season is actively airing

Minimum: **2 calls per show detail view** (search is 1 call; detail needs seasons).

---

## Show status values

TVMaze exposes a `status` field on every show. Documented values:

| Status | Meaning |
|---|---|
| **Running** | Episodes are currently airing, or will air again in the future |
| **Ended** | No more episodes will air |
| **In Development** | New show in development; pilot has not yet aired |
| **To Be Determined** | Uncertain whether new episodes will ever air |

Source: [TVMaze FAQ — Show Status](https://www.tvmaze.com/faq/13/shows)

### Other relevant show-level fields

| Field | Type | Notes |
|---|---|---|
| `premiered` | date string or null | Show's first premiere |
| `ended` | date string or null | Set when show has ended |
| `updated` | unix timestamp | Last time show or any child record changed — useful change signal |
| `_links.nextepisode` | link or absent | Present only when an upcoming episode is scheduled |
| `_links.previousepisode` | link | Most recently aired episode |

---

## Season fields

`GET /shows/{id}/seasons` returns seasons in ascending order.

| Field | Type | Notes |
|---|---|---|
| `number` | integer | Season number; **0 = specials** (exclude from next-season logic) |
| `name` | string | Optional season title |
| `episodeOrder` | integer or null | Planned episode count; null for future unannounced seasons |
| `premiereDate` | date string or null | ISO date; null when not yet announced |
| `endDate` | date string or null | null for ongoing or future seasons |
| `summary` | HTML string or null | Often null for future seasons |

---

## Deriving next-season status

NextSeason needs a single user-facing answer per show. Derive it from show status + season list.

### Decision flow

1. If `status == "Ended"` → **No next season** (show is over)
2. If `status == "To Be Determined"` → **Uncertain** (may or may not return)
3. If `status == "In Development"` → **Not yet premiered** (show the show itself, not a "next season")
4. If `status == "Running"`:
   - Exclude season 0 (specials)
   - Find the **latest season** (highest `number`)
   - If that season has no `endDate` and/or has a scheduled `nextepisode` → current season is airing; show next episode info
   - If that season has `endDate` in the past (fully aired):
     - Look for a season with `number == latest + 1`
     - If it exists with `premiereDate` → **Next season N premieres {date}**
     - If it exists without `premiereDate` → **Season N confirmed, premiere date TBA**
     - If no future season row exists → **No next season announced yet** (but show is still Running)

### User-facing status labels (proposed)

| Derived state | Example label |
|---|---|
| Ended | "Ended — no further seasons" |
| Uncertain (TBD) | "Status uncertain" |
| In Development | "In development — not yet premiered" |
| Next season with date | "Season 3 premieres June 21, 2026" |
| Next season without date | "Season 3 confirmed — premiere date TBA" |
| Current season airing | "Season 3 now airing — next episode June 21, 2026" |
| Running, no next season listed | "No next season announced" |

Exact copy and edge-case handling belong in Phase 3 / implementation.

---

## Example shows

Probed live from `api.tvmaze.com` on June 13, 2026.

### Severance (id 44933) — between seasons, future season confirmed, no date

```
status: "Running"
_links.nextepisode: absent
```

Seasons (relevant):

| Season | premiereDate | endDate |
|---|---|---|
| 1 | 2022-02-18 | 2022-04-08 |
| 2 | 2025-01-17 | 2025-03-21 |
| 3 | null | null |

**Derived:** Season 3 confirmed, premiere date TBA.

This is the most important pattern for NextSeason: TVMaze creates a future season row before a premiere date is known. The `nextepisode` embed is absent because no episodes are scheduled yet.

### House of the Dragon (id 44778) — next season has premiere date

```
status: "Running"
_links.nextepisode: present (S3E1 "TBA", airdate 2026-06-21)
```

Seasons (relevant):

| Season | premiereDate | endDate |
|---|---|---|
| 2 | 2024-06-16 | 2024-08-04 |
| 3 | 2026-06-21 | 2026-08-09 |
| 4 | null | null |

**Derived:** Season 3 premieres June 21, 2026. (Season 4 also listed with no dates — ignore; season 3 is the active next target.)

`embed=nextepisode` confirms `airdate: "2026-06-21"` — consistent with season premiereDate.

### Game of Thrones (id 82) — show ended

```
status: "Ended"
ended: "2019-05-19"
```

**Derived:** Ended — no further seasons.

---

## Change detection for notifications

When saved shows are implemented, store a **snapshot** of the derived next-season status per show. Notify the user when any meaningful field changes.

### Fields to snapshot

| Field | Source |
|---|---|
| `show.status` | `/shows/{id}` |
| `show.ended` | `/shows/{id}` |
| Target season `number` | Derived from `/shows/{id}/seasons` |
| Target season `premiereDate` | `/shows/{id}/seasons` |
| Target season `endDate` | `/shows/{id}/seasons` |
| `nextepisode.airdate` | `/shows/{id}?embed=nextepisode` (if present) |
| `show.updated` | `/shows/{id}` — cheap change indicator |

### Changes that should trigger a notification

- No date → premiere date announced
- Premiere date changed
- New future season row appears
- Show status changes (e.g. Running → Ended, In Development → Running)
- Next episode scheduled when none existed before

### Changes that should NOT trigger a notification

- Rating changes
- Image or summary updates
- Episode-level changes unrelated to next-season status (e.g. cast updates)
- `show.updated` changed but derived next-season status is identical

---

## Polling and updates endpoint strategy

ProductSpec targets ~12-hour polling for saved shows. TVMaze provides an efficient optimization:

### `GET /updates/shows`

Returns a map of `{showId: unixTimestamp}` for all shows updated within a time window.

```
GET /updates/shows?since=day    # last 24 hours
GET /updates/shows?since=week   # last 7 days
GET /updates/shows?since=month  # last 30 days
```

A show is marked updated when any direct or indirect child changes (episodes, seasons, images, etc.).

### Recommended polling flow (no backend)

1. On app launch: refresh all saved shows (reliable)
2. On `BGAppRefreshTask` (best-effort, ~12h target):
   - Fetch `/updates/shows?since=day`
   - Intersect with saved show IDs
   - Re-fetch only shows that appear in the updates list
   - Compare snapshots; fire local notification on diff
3. Accept that iOS may not run background refresh on a fixed schedule

### Polling cost estimate

If a user saves 20 shows and 3 updated in the last day:

- 1 call to `/updates/shows?since=day`
- 3 calls to `/shows/{id}/seasons`
- Total: 4 calls (well within rate limits)

If polling all 20 shows naively: 20 calls every cycle.

---

## Rate limits, caching, and licensing

### Rate limits

- Minimum 20 calls per 10 seconds per IP
- HTTP 429 if exceeded — back off and retry
- Set a descriptive `User-Agent` header (recommended by TVMaze)

### Caching

- API responses cached up to **60 minutes** on TVMaze load balancers
- `/updates/shows` and `/shows?page=N` (index) cached up to 24 hours
- NextSeason should also cache locally to reduce redundant calls

### Licensing

- CC BY-SA — free to use with attribution
- **Must credit TVMaze** with a link in the app (e.g. settings/about screen)
- ShareAlike applies to our data usage, not our app code

---

## iOS background and notification constraints

Research based on [Apple Background Tasks documentation](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app) and WWDC25 session "Finish tasks in the background."

### Background refresh (`BGAppRefreshTask`)

- **Discretionary** — iOS decides when to run based on app usage, battery, network
- Requesting `earliestBeginDate` of 12 hours does **not** guarantee execution at 12 hours
- ~30 seconds max execution time
- **Stops entirely** if user force-quits the app from the app switcher, until user relaunches
- Frequently used apps get more frequent scheduling

**Implication:** 12-hour polling is a target, not a guarantee. Foreground refresh on app open is the reliable fallback.

### Notifications (`UNUserNotificationCenter`)

- Local notifications do **not** require a server or APNs
- User must grant notification permission — prompt after user saves their first show, not on launch
- No special App Store restrictions for this notification pattern
- Notifications should describe the change: e.g. "Severance — Season 3 premiere date announced: Jan 17, 2027"

### Silent push (not planned for MVP)

- `content-available: 1` push from a server would enable more reliable background wake
- Requires backend infrastructure — **out of scope** for initial releases
- Rate-limited to ~3 per hour by Apple

### Auth for saved shows

- v0.1 requires no authentication
- For saved watchlists: **Sign in with Apple** is the likely choice (native iOS, privacy-friendly, no password management)
- Detailed auth architecture deferred to Phase 3
- Watchlist could work locally without auth initially; account needed only for cross-device sync (if ever)

---

## Limitations and risks

| Risk | Impact | Mitigation |
|---|---|---|
| TVMaze data lag | New premiere dates may take up to 60 min to appear in API | Accept; document in UI that data may not be instant |
| Incomplete season rows | Future season may not exist until announced | Show "No next season announced" for Running shows |
| `To Be Determined` ambiguity | TVMaze itself is unsure | Show honest "status uncertain" label |
| iOS background unreliability | Notifications may be delayed beyond 12 hours | Foreground refresh on launch; set user expectations |
| Rate limiting with large watchlists | Many saved shows = many API calls if naively polled | Use `/updates/shows` filter |
| Show name disambiguation | Multiple shows share names (e.g. "The Office") | Always use `/search/shows`, never `/singlesearch` |
| CC BY-SA attribution | Legal requirement | Add TVMaze credit in app settings |

---

## Open items for Phase 3 (Architecture)

These are research-informed inputs, not decisions:

- Define `NextSeasonStatus` value type and season-selection algorithm in code
- Design `TVMazeClient` (search, show, seasons, updates)
- SwiftData model: saved show + status snapshot + last-checked timestamp
- `BGAppRefreshTask` registration and refresh coordinator
- When and how to request notification permission
- Local caching strategy and TTL
- TVMaze attribution placement in UI
- Whether watchlist works locally before Sign in with Apple is added

---

## Phase 2 open questions — resolved

| Question | Answer |
|---|---|
| What next-season fields does TVMaze expose? | Show `status`, `ended`, `updated`; season `number`, `premiereDate`, `endDate`, `episodeOrder`; optional `nextepisode.airdate` via embed. See [Deriving next-season status](#deriving-next-season-status). |
| How reliable are premiere dates vs. status strings? | Premiere dates are present when known and generally match episode airdates. Status strings are coarse (4 values). Future seasons can exist with null dates before premiere is announced. Data is community-sourced and may lag reality by up to 60 minutes. |
| What iOS constraints apply to background polling? | `BGAppRefreshTask` is discretionary, ~30s max, stops on force-quit. Local notifications via `UNUserNotificationCenter` need no server. 12-hour polling is a target, not a guarantee. See [iOS background and notification constraints](#ios-background-and-notification-constraints). |
| Minimum auth for saved shows? | None for v0.1. Sign in with Apple is the likely choice when accounts are added. Local-only watchlist possible without auth. |
