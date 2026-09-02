# TVMaze Research

Phase 3 research input for NextSeason. Documents the relevant parts of the
TVMaze public API and — most importantly — how to **derive next-season
information**, which the API does not expose as a single field.

Source: <https://www.tvmaze.com/api>. These findings were verified against live API responses on 2026-06-14 and subsequently validated during implementation of the MVP.

---

## 1. API basics

- **Root URL:** `https://api.tvmaze.com`
- **Format:** JSON (HAL/HATEOAS conventions: `_links`, `_embedded`).
- **Auth:** None required for the public API.
- **HTTPS:** Default for all endpoints and image CDN links.
- **Licensing:** CC BY-SA. We must credit TVMaze as the source (e.g. a link
  back using the `url` fields). This is an App-Store-visible requirement.

### Constraints that affect our design

| Constraint     | Detail                                                                                  | Impact on NextSeason                                                                 |
| -------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Rate limit     | "At least 20 calls / 10s per IP." HTTP `429` when exceeded.                              | Handle `429` with a short back-off + retry. Throttle background polling. Dynamic update windows and change gating keep API usage well below published rate limits.             |
| Edge caching   | All output cached 60 min by their load balancers.                                        | Don't expect sub-hour freshness. 12h polling is well within tolerance.               |
| User-Agent     | Strongly recommended to set a unique UA.                                                 | Set `User-Agent: NextSeason/<version>` on every request (contact info may be added later). |
| Connections    | Don't leave >1 idle connection open.                                                     | Use a single shared `URLSession`; let it manage connection reuse.                   |
| Attribution    | CC BY-SA requires crediting TVMaze.                                                      | Show a "Data by TVMaze" credit + link in the UI.                                     |

---

## 2. Endpoints we will use

### Search

| Purpose            | Endpoint                                              | Notes                                                              |
| ------------------ | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Search shows       | `GET /search/shows?q=:query`                         | Returns `[{ score, show }]`, best matches first. Fuzziness 2. Fuzzy matching works well. Relevance ordering is generally good. Returns approximately 10 matches with no pagination or mechanism to retrieve additional results.     |
| Show + seasons     | `GET /shows/:id?embed[]=seasons&embed[]=nextepisode` | Single call gives everything needed for next-season derivation.   |

### Search endpoint limitations

During MVP development, it became clear that GET /search/shows is limited to approximately 10 results, with no support for pagination or requesting additional matches.

For common or ambiguous searches, relevant shows may therefore be omitted entirely, even when they exist in the TVMaze database.

This limitation is acceptable for the MVP but is not considered sufficient for a production App Store release. Eliminating this limitation (either through an additional data source or an alternative search strategy) is tracked in the Product Evolution Roadmap.

### Watchlist Refresh & Notifications

| Purpose              | Endpoint                          | Notes                                                                       |
| -------------------- | --------------------------------- | -------------------------------------------------------------------------- |
| Refresh saved show   | `GET /shows/:id?embed[]=seasons`  | Re-fetch per tracked show during background poll.                          |
| Detect stale shows   | `GET /updates/shows?since=day`    | Map of `showId -> lastUpdatedEpoch`; skip shows that haven't changed.      |

> Note: there is no `previoussearch`/batch endpoint. Each saved show is refreshed
> individually, which is why `/updates/shows` matters for polling efficiency.

---

## 3. Relevant fields

### 3.1 Search result wrapper (`/search/shows`)

```json
[
  { "score": 0.897, "show": { /* full Show object, see below */ } }
]
```

- Array ordered by `score` (relevance), highest first.
- Each `show` is the **full** Show object (same shape as `/shows/:id`).

### 3.2 Show object (fields we care about)

```json
{
  "id": 44933,
  "name": "Severance",
  "type": "Scripted",
  "language": "English",
  "genres": ["Drama", "Science-Fiction", "Mystery"],
  "status": "Running",
  "premiered": "2022-02-18",
  "ended": null,
  "averageRuntime": 49,
  "officialSite": "https://tv.apple.com/show/severance/...",
  "network": null,
  "webChannel": { "id": 310, "name": "Apple TV", "country": null },
  "image": {
    "medium": "https://static.tvmaze.com/uploads/images/medium_portrait/548/1371406.jpg",
    "original": "https://static.tvmaze.com/uploads/images/original_untouched/548/1371406.jpg"
  },
  "summary": "<p>Mark Scout leads a team at Lumon Industries...</p>",
  "updated": 1780897121,
  "_links": {
    "self": { "href": "https://api.tvmaze.com/shows/44933" },
    "previousepisode": { "href": "...", "name": "Cold Harbor" }
  }
}
```

Field notes:

- **`status`** — the most important enum. Observed values: `Running`, `Ended`,
  `To Be Determined`. TVMaze also documents `In Development`. Treat the set as
  open: decode unknown values into an `.unknown` case rather than failing.
- **`ended`** — ISO date or `null`. Non-null does **not** always mean
  permanently over (revivals happen), but combined with `status == "Ended"` it is
  our strongest "no next season" signal.
- **`network`** vs **`webChannel`** — exactly one is usually populated. Either may
  carry the human-readable platform name.
- **`image`** — `null` when no artwork exists. Use `medium` for lists, `original`
  for detail. Image URLs are immutable and safe to cache indefinitely.
- **`summary`** — contains HTML tags (`<p>`, `<b>`); must be stripped/rendered.
- **`updated`** — Unix epoch seconds; bumped when the show or any child changes.
  This is the key to efficient polling (see §5).
- **`_links.previousepisode` / `_links.nextepisode`** — present only when such an
  episode exists. `nextepisode` existing means an episode is scheduled.

### 3.3 Season object (`embed[]=seasons` or `/shows/:id/seasons`)

Seasons are returned **ascending by `number`**.

```json
{
  "id": 183341,
  "number": 3,
  "name": "",
  "episodeOrder": null,
  "premiereDate": null,
  "endDate": null,
  "webChannel": { "id": 310, "name": "Apple TV" },
  "image": null,
  "summary": null
}
```

Field notes:

- **`number`** — season number (Int).
- **`premiereDate` / `endDate`** — ISO date or `null`.
- **`episodeOrder`** — planned episode count, or `null` when not yet known.
- A **future/announced season** typically appears as an entry where
  `premiereDate`, `endDate`, and `episodeOrder` are all `null` (verified:
  Severance season 3). This is the primary "a next season exists but isn't
  scheduled yet" signal.

### 3.4 Embedded `nextepisode`

```json
{
  "id": 3643680,
  "season": 2026,
  "number": 115,
  "name": "Ep. #9799",
  "airdate": "2026-06-15",
  "airstamp": "2026-06-15T17:30:00+00:00"
}
```

- Present only when the show has a scheduled upcoming episode.
- `season` tells which season the upcoming episode belongs to. If it is greater
  than the latest **aired** season number, a new season is imminent/airing.
- `airstamp` is a full timezone-aware timestamp; prefer it over `airdate`.

---

## 4. Deriving "next season status"

There is **no single TVMaze field** that says "the next season premieres on X."
We compute a derived status from `status` + the `seasons` list + `nextepisode`.

Algorithm (pure function over the decoded DTOs):

1. Sort seasons ascending by `number`.
2. `latestAired` = season with the highest `number` whose `premiereDate` is
   non-null and `<= today`.
3. Look for a **candidate next season**: the lowest-numbered season with
   `number > latestAired.number` (or, if nothing has aired, the first season).
4. Classify:

| Derived status                         | Condition                                                                                              |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `airing(season)`                       | Latest aired season hasn't ended, or `nextepisode` for a new season has an `airdate` on or before today. |
| `scheduled(season, date)`              | Candidate next season has a future `premiereDate`, or `nextepisode` has a future `airdate`.              |
| `announcedUndated(season)`             | Candidate next season exists but `premiereDate == null`, or `nextepisode` points at a new season with no `airdate`. |
| `returningNoSeasonYet`                 | `status` is `Running`/`To Be Determined`/`In Development` but no candidate next season row exists yet. |
| `ended`                                | `status == "Ended"` and no future/undated candidate season exists.                                    |
| `unknown`                              | Data insufficient or `status` unrecognized.                                                            |

Edge cases to handle in code (and to cover with tests):

- Daily/soap shows use calendar-year "seasons" (`season: 2026`) — derivation must
  not assume small sequential numbers.
- Specials / season 0 should be ignored for "next season" purposes.
- A show can flip from `Ended` back to `Running` (revival) — detected naturally
  on the next poll because `status` and `seasons` change.
- `premiereDate` strings are date-only; parse as a calendar date, not a timestamp.

---

## 5. Change detection for notifications

Goal: detect meaningful changes to tracked shows and deliver local notifications while minimizing unnecessary network requests.

Approach:

1. On save, compute and store a `NextSeasonStatus` snapshot per show.
2. Background poll (~every 12h):
   a. Call GET /updates/shows?since=<period> using the smallest update period (day, week, or month) that safely covers the elapsed time since the oldest tracked show was last checked. It returns `{ showId: epoch }`.
   b. For each tracked show whose stored source update timestamp is older than the value returned by the updates endpoint, fetch the latest show details using GET /shows/:id?embed[]=seasons.
   c. Recompute `NextSeasonStatus` and diff against the stored snapshot.
3. Emit a local notification on a meaningful delta:
   - `announcedUndated` → `scheduled` (premiere date announced)
   - `scheduled` date changed
   - any status → `airing` (new season out)
   - any status → `ended`
4. Persist notification signatures and pending-change state to prevent duplicate notifications and reduce false positives from transient API updates.

This minimizes API calls (one `/updates` call gates all per-show fetches) and
respects the rate limit.

**Implementation notes:** The completed MVP further reduces unnecessary API traffic by dynamically selecting the appropriate TVMaze update window (day, week, or month) and by confirming certain status transitions across refresh cycles before notifying the user.

---

## 6. Data reliability & service availability

The app is only as good as this data, so reliability was investigated explicitly
(web research + the TVMaze forums/API docs, 2026-06-14).

### 6.1 How the data is produced

- **100% community-sourced.** TVMaze's catalog is user-generated content;
  completeness is "as complete as the community makes it." There is no paid
  editorial team guaranteeing coverage.
- **Moderated, not a free-for-all.** Several quality safeguards exist:
  - New contributors are rate-limited and go through a **verification/probation**
    period; edits are monitored for vandalism before higher permissions are
    granted (reputation-based levels).
  - An **edit-conflict system** auto-locks attributes that get changed too often
    (e.g. episode name/number); only Trusted Contributors and above can then edit
    them. This stabilizes established facts and prevents edit wars.
  - **Re-creation of deleted invalid entries** is blocked via primary-attribute
    matching.
  - Contributors are directed to prefer **official sources** (network sites,
    press releases, on-screen credits) over aggregators like IMDB.
- TVMaze states 99%+ of edits are correct. Treat that as encouraging but not a
  guarantee for any single field.

### 6.2 Numbering rules that affect us

- Season/episode numbering follows the **network/web channel of original
  premiere** (e.g. Netflix date wins if it premiered on Netflix first).
- Shows **without official season numbering** (daily/talk/news shows) use the
  **current calendar year as the season number** — this is why we saw
  `season: 2026` on a soap. Our `NextSeasonCalculator` must not assume small
  sequential season numbers (already accounted for in §4).
- Numbering mostly aligns with TheTVDB, but known edge cases disagree
  (e.g. American Dad). Not critical for us — we care about "is there a next
  season and when," not exact episode ordering.

### 6.3 Reruns & re-broadcasts

A re-broadcast of an old season must never be mistaken for a new one. TVMaze's
data model makes this safe by construction:

- **Dates/numbering are anchored to the original premiere** (§6.2), so re-airing a
  season does not change its `premiereDate` or add a season row.
- **Reruns are not modeled at all** — there is no rerun flag and no duplicate
  episode entries; each episode carries a single (original) `airdate`.
- **`nextepisode` is the next *unaired* episode by airstamp**, so a rerun (already
  past-dated) never surfaces there.

Verified (2026-06-14): *The Big Bang Theory* (ended 2019, in constant rerun)
returns `status: Ended`, **no `nextepisode`**, and a last season (12) dated
2018–2019 — i.e. zero future/undated signals.

`NextSeasonCalculator` keys only off these rerun-immune fields (season rows + their
original premiere dates + the next unaired episode), so reruns cannot produce a
false `.airing`/`.scheduled`. The sole residual risk is a contributor *mis-entering*
a rerun date as a season premiere — a data-accuracy issue covered by §6.5 and
PD-008 (debounce/confirm + dedup), not a modeling gap. Step B includes an
"ended-but-rerunning" calculator test to lock this in.

### 6.4 Timeliness — the most relevant risk for NextSeason

Our core promise depends on **how quickly** the community adds:

1. a new (often undated) season row after a renewal is announced, and
2. a concrete `premiereDate` once scheduled.

This latency is community-dependent and variable. Popular shows are typically
updated quickly; niche/foreign shows may lag. Anecdotally, TVMaze is often *ahead*
of TheTVDB for upcoming shows, but there is no guaranteed SLA on freshness. Plus
the API's own **60-minute edge cache** adds up to an hour on top.

> Implication: NextSeason should present itself as a convenient tracker, not an
> infallible oracle. Showing a "last updated" timestamp and a "Data by TVMaze"
> link (also a license requirement) sets honest expectations.

### 6.5 Data volatility → notification correctness

Because data is editable, fields can **change or be corrected after the fact**:

- A speculative/incorrect future season or placeholder date could be added, then
  fixed — which could otherwise trigger a false or premature notification.
- A show can be deleted or merged (rare), so a saved show's `/shows/:id` could
  later return `404`.

Mitigations (feed into notification design, see `MVPArchitecture.md`):

- **Debounce notifications:** prefer notifying on changes that *persist across two
  consecutive polls*, or that are backed by a concrete `premiereDate`/`airstamp`,
  rather than firing on the first transient edit. Balance against timeliness.
- **Dedup signature** (already designed) prevents repeat notifications and limits
  the blast radius of a value that flaps.
- **Handle `404`/missing show** gracefully on refresh (mark stale, don't crash).

### 6.6 Service availability

- **No official public status page and no SLA** — expected for a free API.
- Third-party monitors report **~100% uptime, ~0% error rate**, and ~110–130 ms
  average response time over the trailing 30 days. Observed availability is
  excellent.
- Maintenance is occasionally announced via their blog; the site can drop to
  **read-only** mode during maintenance — **reads (our use case) keep working**,
  only edits are paused.
- We must still code defensively: handle `429` (rate limit) with back-off, and
  treat network/`5xx` failures as transient with clear UI error states.

### 6.7 Overall assessment

TVMaze is **fit for purpose** for NextSeason: strong observed uptime, sensible
moderation, and good upcoming-season coverage, at zero cost and with no auth. The
**residual risk is data freshness/accuracy**, inherent to any crowd-sourced
catalog. We mitigate it with honest UI (timestamps, attribution), debounced
notifications, and graceful failure handling — rather than by assuming the data is
perfect.

**Contingency:** The networking layer is isolated behind the `TVMazeService` protocol (`MVPArchitecture.md` §4). If freshness proves insufficient
in practice, a second provider (TheTVDB — TV-first, very stable; or TMDB — broad,
but episode ordering can shift) could be added or swapped behind that protocol
without touching the UI. No need to build multi-source now; just preserved as an
option.

---

## 7. Open questions / risks

- **Data freshness/accuracy:** the main residual risk — see §6.4/§6.5 for the
  assessment and mitigations. Monitor real-world latency during testing.
- **Background execution limits:** iOS `BGAppRefreshTask` scheduling is
  best-effort, not guaranteed every 12h. Notifications may be delayed until the
  system grants runtime. Documented in `MVPArchitecture.md`.
- **Status enum drift:** treat `status` as open-ended; never crash on a new value.
```
