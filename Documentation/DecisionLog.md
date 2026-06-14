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
