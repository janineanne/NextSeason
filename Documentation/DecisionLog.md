# Product Decisions

## PD-001 User Accounts

Decision:
No user accounts in MVP.

Rationale:
The MVP validates demand for season notifications.
Local storage dramatically reduces complexity and allows focus on the core value proposition.

Future Revisit:
When cloud sync or multi-device support becomes necessary.

---

## PD-002 Data source: TVMaze

Decision:
Use the TVMaze public REST API.

Rationale:
Free, no auth, JSON, generous rate limit, and exposes show status + season data.
CC BY-SA license is acceptable provided we credit TVMaze in-app.

---

## PD-003 Derive next-season status (no native field)

Decision:
Compute a `NextSeasonStatus` from `status` + embedded `seasons` + `nextepisode`.

Rationale:
TVMaze has no single "next season date" field. An announced-but-unscheduled
season appears as a season row with null dates (verified: Severance S3). A pure,
testable calculator centralizes this rule for both the detail screen and future
change-detection.

---

## PD-004 Three model tiers (DTO / domain / persistence)

Decision:
Keep `Codable` DTOs, clean domain models, and SwiftData models separate.

Rationale:
Isolates API quirks (HTML summaries, open-ended status, embeds) from the UI and
tests; lets the API evolve without touching views.

---

## PD-005 Local-only notifications via BGTaskScheduler

Decision:
Future notifications use `UNUserNotificationCenter` local notifications driven by
a ~12h `BGAppRefreshTask`; no push server.

Rationale:
Consistent with the no-backend decision (PD-001). Background refresh is
best-effort on iOS — documented as a target cadence, not a guarantee.

---

## PD-006 Testing: Swift Testing + fixtures

Decision:
Use the Swift Testing framework; test the pure next-season calculator and DTO
decoding against committed real-API JSON fixtures; mock networking via a protocol.

Rationale:
Deterministic, no live network in tests, and showcases testable design for the
portfolio goal.

---

## PD-007 Persistence: SwiftData behind a repository protocol

Decision:
Use SwiftData as the persistence engine, accessed only through a
`WatchlistRepository` protocol that deals in domain types. The `@Model` class is a
private detail of the SwiftData implementation.

Rationale:
SwiftData is the native, dependency-free fit and enforces unique watchlist
entries (FR-005). The repository is justified by a present need — testability and
keeping persistence out of the view-model/service layers — not by speculative
swappability (which is merely a free side effect). Trade-off: we forgo `@Query`
live-binding in views and do explicit fetches; acceptable for an
infrequently-changing watchlist. Built in Slice 2; Slice 1 ships storage-free.

---

## PD-008 Reliability-driven notification rules

Decision:
Because TVMaze data is crowd-sourced and editable, Slice 2 notifications will
fire only on *durable* changes — a change that persists across two consecutive
polls or is backed by a concrete `premiereDate`/`airstamp` — guarded by the
`lastNotifiedSignature` dedup. Saved-show refresh handles `404` (deleted/merged)
gracefully, and `429`/`5xx` are treated as transient. The UI shows a
"last updated" timestamp and "Data by TVMaze" attribution.

Rationale:
Investigation (see `TVMazeResearch.md` §6) found excellent service uptime but an
inherent freshness/accuracy risk in any crowd-sourced catalog. A single poll can
reflect a transient or incorrect edit, which could cause a false or premature
notification. Confirming changes trades a little timeliness for trustworthiness —
the right call for an app whose value is trust. The existing `TVMazeService`
protocol preserves the option to add/swap a provider (TheTVDB, TMDB) later if
freshness proves insufficient, without building multi-source now.

---

## PD-009 Render show summaries as formatted text

Decision:
Display TVMaze summaries with their intended light formatting (paragraphs, bold,
italics) rather than as stripped plain text. Implemented in Step B via a small,
unit-tested HTML→`AttributedString` converter that keeps the app's fonts and
respects Dynamic Type / VoiceOver. The raw `summary` HTML is retained on the
domain model so formatting happens at render time.

Rationale:
The summary is the main descriptive content on the detail screen; preserving
emphasis and paragraph breaks reads far better than flattened text. A dedicated
converter (vs. `NSAttributedString`'s HTML import) avoids main-thread cost and
baked-in styling that would fight Dynamic Type, and it is pure and testable.
The summary is now rendered on the show-detail screen (Step B); the `SummaryFormatter`
also normalizes messy source whitespace (stray non-breaking/double spaces), and
plain-text stripping (`String.strippingHTMLTags`) is retained only as the
converter's fallback. No third-party dependency required.

---

## PD-010 HTTP response caching via a dedicated URLCache

Decision:
Rely on standard HTTP caching for TVMaze reads rather than a custom in-memory
cache. `TVMazeClient` uses a `URLSession` configured with its own `URLCache`
(~4 MB memory / 50 MB disk) and the default `.useProtocolCachePolicy`. TVMaze
sends `Cache-Control: public, max-age=3600` on the search and show endpoints, so
repeat lookups are served from cache for up to an hour with no network round trip.

Rationale:
A bespoke cache would re-implement the freshness windows, disk persistence, and
eviction that `URLCache` already handles correctly, while adding its own
invalidation risk. A dedicated cache (vs. `URLCache.shared`) keeps sizing
intentional and isolated, and leaves a clean per-request `cachePolicy` knob for
Slice 2 (force-revalidate on background refresh; serve cached data when offline).
Trade-off: if TVMaze ever drops its cache headers, caching silently stops — an
acceptable, documented risk for a free data source, and not worth hedging with a
custom cache.

---

## Terminology note

To resolve an overload of the term "v0.1": **MVP** = the full first release
(search + watchlist + notifications) per `MVPDefinition.md`. It is delivered in
**slices** — **Slice 1 (Guest Search)** and **Slice 2 (Save & Notify)**. The term
"v0.1" is avoided going forward. See `ProductSpec.md` → Terminology.

---

## Phase 3 development log

Date: 2026-06-14

Goal: Phase 3 architecture.

AI Tool: Cursor / Claude.

Outcome: Wrote `TVMazeResearch.md`, `Architecture.md`, and `ProductSpec.md`.
Verified TVMaze fields against live API responses.

Decision: Build Slice 1 (Guest Search) on a DTO/domain split with a pure
next-season calculator; decide SwiftData-behind-a-repository for persistence
(PD-007) and design notifications now, but build both in Slice 2.

Follow-up: Phase 4 — implement the Guest Search vertical slice (search +
detail), per `Architecture.md` §10.
