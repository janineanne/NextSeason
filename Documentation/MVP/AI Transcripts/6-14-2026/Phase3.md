# NextSeason project overview

## User

Please familiarie yourself with project NextSeason, found in /Users/janine/Documents/TbF Projects/NextSeason

## Assistant

I'll familiarize myself with the NextSeason project. Let me explore its structure.

### Tool Run Terminal Command V2

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason","globPattern":"**/*.swift"}
```

## Assistant

Let me explore the directory structure and read the key files.

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

## Assistant

The code is still the default Xcode template, so the real content is in the documentation. Let me read those.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/ProblemStatement.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/ProjectKickoff.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVPDefinition.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVPBacklog.md"}
```

## Assistant

Let me read the remaining documentation to complete my understanding.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/FunctionalRequirements.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/UserStories.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/DecisionLog.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/KickoffTranscripts/Log.md"}
```

## Assistant

Let me check the Phase transcripts and the cursor rules to round out my understanding.

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason","globPattern":".cursor/**/*"}
```

### Tool Run Terminal Command V2

## Assistant

Let me read the remaining cursor rule and the plan file to complete the picture.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/.cursor/rules/swiftui-project-style.mdc"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/.cursor/plans/phase_1_product_definition_26919850.plan.md"}
```

## Assistant

I've now reviewed the project thoroughly. Here's my understanding of **NextSeason**.

## What it is

An iOS app whose single job is: **tell the user when a new season of a TV show they care about becomes available.** It deliberately avoids being a full media tracker (no episode tracking, ratings, reviews, social features, or "where to watch").

## Current state

The project is in the **planning/pre-implementation phase**. The actual code is still the default Xcode template:
- `NextSeasonApp.swift` — standard `@main` app
- `ContentView.swift` — "Hello, world!" placeholder

All the real work so far lives in `Documentation/`, produced across kickoff phases (Phases 1–2 via ChatGPT, Phase 3 via Cursor/Claude per `KickoffTranscripts/Log.md`).

## Tech stack & conventions (from `AGENTS.md` + `.cursor/rules`)

- **iOS 26+**, **Swift 6.2+**, modern concurrency (always prefer `async/await`)
- **SwiftUI + MVVM**, shared state via `@Observable` classes
- **SwiftData** for persistence
- No UIKit, no third-party dependencies without asking
- Data source: **TVMaze API**
- Keep views small, logic in view models/services, files under 500 lines, accessibility required, prefer simplicity over cleverness

## Product plan

**MVP (v0.1) — guest search only:**
- Search shows by title (TVMaze), show artwork
- Show detail screen with next-season status: season number, premiere date when known, or a status label ("In Production", "TBA", "Ended", "No next season known")
- Clear empty/error states
- No login required

**North star (later phases):** search → save to watchlist → poll TVMaze ~every 12h → notify when next-season status changes. The full MVP backlog also lists local watchlist persistence, notification permission flow, and background refresh as P0, while accounts/cloud sync/streaming info are explicitly deferred to P2.

## Documentation map

- `ProblemStatement.md`, `MVPDefinition.md`, `MVPBacklog.md` — the "why" and scope
- `FunctionalRequirements.md` (FR-001…FR-018), `UserStories.md` (US-001…US-008) — the "what"
- `DecisionLog.md`, `KickoffTranscripts/` — decisions and AI-session history
- `ProjectKickoff.md` — the overall AI-assisted workflow (ChatGPT = PM/staff engineer, Claude/Cursor = pair programmer, Xcode = source of truth), emphasizing small vertical slices

## Notable observations

- Per the kickoff plan, Phase 1's deliverable was `Development Documentation/ProductSpec.md`, but the actual docs ended up in `Documentation/` with somewhat different filenames. The expected Phase 2/3 docs (`TVMazeResearch.md`, `Architecture.md`) **don't exist yet** — those phases are the logical next steps before coding.
- There's a portfolio/learning goal alongside the product goal: demonstrating effective AI-assisted development and engineering judgment.

I'm ready to help. A natural next step would be **Phase 2 TVMaze research** (which next-season fields the API actually exposes), then **Phase 3 architecture**, then building the first vertical slice (guest search). Want me to start on any of those, or something else?

## User

Where are you seeing a reference to "Development Documentation"?

## Assistant

The reference to "Development Documentation" comes from the Phase 1 plan file, not from the actual docs. It's in `.cursor/plans/phase_1_product_definition_26919850.plan.md`, which repeatedly points at a `Development Documentation/` folder that doesn't actually exist in the repo. For example:

```6:13:.cursor/plans/phase_1_product_definition_26919850.plan.md
todos:
  - id: write-product-spec
    content: Draft Development Documentation/ProductSpec.md with target user, problem, v0.1 scope, non-goals, and future notification preview
    status: completed
  - id: log-phase1-decision
    content: Add Phase 1 decision entry to Development Documentation/DevelopmentLog.md
    status: completed
```

And again in the deliverable and log sections:

```38:38:.cursor/plans/phase_1_product_definition_26919850.plan.md
Create [Development Documentation/ProductSpec.md](Development Documentation/ProductSpec.md) as the single source of truth for Phase 1. Structure:
```

Let me double-check it doesn't appear anywhere else in the repo.

### Tool Ripgrep Raw Search

```
{"pattern":"Development Documentation","path":"/Users/janine/Documents/TbF Projects/NextSeason","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_vrtx_01TW6rEunLjJK4CZorYDRHD2","offset":0}
```

## Assistant

Confirmed: `Development Documentation` appears in exactly **one** place in the repo — the Phase 1 plan file `.cursor/plans/phase_1_product_definition_26919850.plan.md`.

That plan was written expecting a `Development Documentation/` folder with files like `ProductSpec.md` and `DevelopmentLog.md`. In reality, the docs live in a folder named `Documentation/` with different filenames (`MVPDefinition.md`, `DecisionLog.md`, etc.). So that earlier observation in my summary traces back to a mismatch between the plan's intended structure and what actually got created — not to anything in `AGENTS.md` or the actual documentation.

## User

Oh, I didn't realize that was there.  That's out of date and I've removed it.

## Assistant

Sounds good. That clears up the only stale reference, so the docs structure is now consistently `Documentation/` with no lingering pointers to a `Development Documentation/` folder. Nothing further needed on my end — just let me know when you'd like to move forward (e.g., Phase 2 TVMaze research or the first build slice).

## User

Why are you associating TVMazeResearch.md with Phase 2?  It's listed under Phase 3 in the ProjectKickoff document.

## Assistant

You're right, and good catch. In `ProjectKickoff.md`, the document deliverables — including `TVMazeResearch.md` (along with `ProductSpec.md` and `Architecture.md`) — are all listed under **Phase 3 – Architecture**:

```141:148:Documentation/ProjectKickoff.md
## Phase 3 - Architecture

Create:

- ProductSpec.md
- Architecture.md
- TVMazeResearch.md
```

Phase 2 is just "Research" (investigate TVMaze capabilities, notification requirements, App Store constraints, data availability) — it produces no named document.

My mistaken association came from the now-deleted Phase 1 plan file, which said exact TVMaze field mapping "belong in Phase 2 (`TVMazeResearch.md`)" and even had a mermaid diagram labeling `p2[Phase2_TVMazeResearch]`. That contradicted the actual kickoff doc. Since you've removed that file, the authoritative source is `ProjectKickoff.md`, where `TVMazeResearch.md` is a **Phase 3** deliverable. Thanks for the correction.

## User

Now please execute Phase 3

## Assistant

Phase 3 produces three architecture documents (`TVMazeResearch.md`, `Architecture.md`, `ProductSpec.md`) and no code. Since `TVMazeResearch.md` must be factually accurate about the real API, I'll research TVMaze directly rather than rely on memory, then design the architecture around what the API actually exposes.

Let me set up a plan and start the API research.

### Tool Todo Write

### Tool Web Fetch

```
{"url":"https://www.tvmaze.com/api","toolCallId":"toolu_vrtx_016PpPW68kqHz4X3F86qsoc5"}
```

## Assistant

I have the full endpoint list. Now I need real JSON to document exact field shapes for next-season detection. Let me fetch a few live examples (raw JSON via curl, since the data is the key deliverable here).

### Tool Run Terminal Command V2

## Assistant

Severance is a great example: status `Running` plus a season 3 with `null` dates (announced-but-unscheduled). Let me capture two more shapes — an `Ended` show and a show with a scheduled `nextepisode`.

### Tool Run Terminal Command V2

## Assistant

Let me confirm the search-results wrapper shape and verify the other status values exist.

### Tool Run Terminal Command V2

## Assistant

I now have verified, real API data. Key findings I'll build the architecture on:

- **Search**: `/search/shows?q=` returns `[{score, show}]`; full show info per result.
- **Show**: has `status` (observed: `Running`, `Ended`, `To Be Determined`; `In Development` also exists), `premiered`, `ended`, and `_links.previousepisode` / `_links.nextepisode`.
- **Next-season signal**: TVMaze has **no direct "next season date" field**. It must be *derived* from `embed[]=seasons` (an announced-but-unscheduled season shows up with `premiereDate: null`/`episodeOrder: null`, e.g. Severance S3) combined with `status` and `embed[]=nextepisode` (`nextepisode.season` tells which season the next airing episode belongs to).
- **Change detection**: `show.updated` timestamp + `/updates/shows?since=day` let us skip unchanged shows; rate limit ~20 req/10s; cache 60 min; set a custom User-Agent.

Now I'll write the three Phase 3 documents. Let me start with the research doc.

### Tool Edit File V2

## Assistant

Now the architecture document.

### Tool Todo Write

### Tool Edit File V2

## Assistant

Now the ProductSpec, which consolidates the existing Phase 1/2 product docs into a single source of truth.

### Tool Todo Write

### Tool Edit File V2

## Assistant

Now I'll record the Phase 3 decisions in the decision log.

### Tool Edit File V2

### Tool Todo Write

## Assistant

Phase 3 is complete. Per `ProjectKickoff.md`, Phase 3 is documentation only (no code), so I created the three required Architecture deliverables plus a log entry, grounding everything in **live-verified** TVMaze data rather than assumptions.

## What I created (all in `Documentation/`)

- **`TVMazeResearch.md`** — the API facts that drive everything else: endpoints, the fields we need, rate-limit/caching/attribution constraints, and the key insight that there's **no native "next season date" field**. It documents the derivation algorithm and the polling/change-detection approach, verified against real responses (Severance, Game of Thrones, a daily soap).
- **`Architecture.md`** — layering (DTO / domain / persistence tiers), the domain model, `TVMazeClient` networking, MVVM with `@Observable`, the pure `NextSeasonCalculator`, the future SwiftData + notifications design, testing strategy, proposed file layout, and a decisions table.
- **`ProductSpec.md`** — consolidated single-source-of-truth that summarizes and cross-links the existing Phase 1/2 docs (doesn't duplicate them).
- **`DecisionLog.md`** — appended architecture decisions PD-002…PD-006 and a Phase 3 development-log entry.

## Key architectural decisions (please review — these are yours to own per the kickoff)

1. **Derive `NextSeasonStatus`** from `status` + embedded `seasons` + `nextepisode` via a pure, testable function. (An announced-but-unscheduled season shows up as a season row with `null` dates — confirmed with Severance S3.)
2. **Three model tiers** (Codable DTOs → domain models → SwiftData) to keep API quirks out of views.
3. **`TVMazeClient` as an actor behind a protocol** for safe concurrency + mockable tests.
4. **Model SwiftData + notifications now, build later** — v0.1 (guest search) ships storage-free.
5. **Local notifications + `BGTaskScheduler`** (best-effort ~12h), no backend.
6. **Swift Testing with committed JSON fixtures.**

## Open questions I flagged for your Phase 5 review

- Should v0.1 really ship with **zero persistence**, or include a minimal recents/watchlist?
- `summary` HTML: strip to plain text vs. render as `AttributedString`?
- Exact set of "meaningful change" notification triggers and copy.
- In-memory caching in `TVMazeClient` vs. relying on TVMaze's 60-min edge cache.

## What you should check

- Skim the three new docs and confirm the architecture matches your intent — especially the `NextSeasonStatus` cases and the DTO/domain split.
- Decide the open questions above (or defer them).
- These are docs only; nothing compiles or changes in the app yet. When you're ready, the natural next step is **Phase 4: the guest-search vertical slice** (search → detail), following `Architecture.md` §10.

One note: I wrote the files into `Documentation/` to match your existing docs. I did not commit anything. Want me to proceed to the Phase 4 guest-search slice next, or adjust any of these decisions first?

## User

Let's answer your questions.  First - persistence.  One of the items in Phase 3 is to determine persistence, so it's implied that there will be some.  I think using SwiftData is the best choice, with an abstraction layer so we can switch it out for something else later if it becomes necessary.  What do you think?

## Assistant

I agree on both counts, with one nuance worth surfacing before we lock it in.

## SwiftData: yes

It's the right call for this app — `@Model` + `ModelContainer` is the native, low-friction fit for a local watchlist on iOS 26, it satisfies the duplicate-prevention requirement cleanly (`@Attribute(.unique)` for `tvMazeID`, FR-005), and it aligns with `AGENTS.md`. No third-party dependency needed.

## The abstraction layer: yes, but let me justify it on *present* need, not future swapping

I want to be careful here because one of our own rules is "do not add clever abstractions just to look architectural" / "no abstraction without a present need." "We might swap it out someday" is the *weakest* reason to add a layer — that day usually never comes, and YAGNI applies.

The *strong* reason — which I fully agree with — is **testability and layering that pay off immediately**: a repository protocol lets view models depend on an interface we can mock, keeps SwiftData types out of the VM/service layers (which `Architecture.md` already commits to), and gives us deterministic watchlist tests with no live `ModelContainer`. Swappability is then a free side effect, not the justification. So: same conclusion you reached, just anchored to a need we have on day one.

## The real trade-off to decide

How "pure" the abstraction is:

- **Pure repository (deals in domain structs):** maximum decoupling and swappability — `@Model` never leaves the persistence layer. Cost: we give up SwiftData's `@Query` live-binding in views and write a bit of mapping boilerplate; the watchlist VM does explicit fetches and we drive UI updates via `@Observable`.
- **Pragmatic (keep `@Model` as the type, funnel mutations through a protocol):** more idiomatic SwiftData, keeps `@Query` live updates, less code. Cost: `@Model` leaks into VMs, so a true future swap would be harder and tests touch SwiftData.

Since you specifically want genuine swap-out capability, I'd go **pure repository**:

```swift
protocol WatchlistRepository: Sendable {
    func all() async throws -> [TrackedShow]          // TrackedShow = domain struct, not @Model
    func add(_ show: Show) async throws
    func remove(showID: Int) async throws
    func contains(showID: Int) async throws -> Bool
    func updateSnapshot(_ snapshot: NextSeasonSnapshot, forShowID id: Int) async throws
}

// Implementations:
//   SwiftDataWatchlistRepository  (wraps ModelContext + a private @Model type)
//   InMemoryWatchlistRepository   (tests / previews)
```

The `@Model` class becomes a private persistence detail inside `SwiftDataWatchlistRepository`, mapped to/from the `TrackedShow` domain struct. For an infrequently-changing watchlist, losing `@Query` is a non-issue, and we gain a trivially mockable boundary.

## One scope clarification

Phase 3's job is to *determine* the persistence strategy — which we're doing now. That's separate from *when we build it*. My recommendation stays: design it now (this decision), implement it in the **save/watchlist slice**, not the first guest-search slice, so the first slice stays minimal. If you'd rather pull a minimal watchlist into v0.1, that's a legitimate alternative — just say so.

Want me to fold this into `Architecture.md` (replace the current §7 with the repository-protocol design) and add it to the decision log as the resolution of the open question?

## User

I agree on the repository.  On the scope, I'm learning your terminology.  ChatGPT referrred to the whole MVP as version 0.1, while you're only referring to the first slice.  Now that I understand what you mean, I agree.

## Assistant

Good — that's a terminology collision worth fixing in the docs so future-you (and ChatGPT) don't get crossed up. ChatGPT used **v0.1 = the whole MVP**; I was overloading **v0.1 = the first slice**. Since "v0.1" now means two different things across our materials, I'll stop using it and switch to unambiguous language:

- **MVP** = the full first release (search + watchlist + notifications), exactly as `MVPDefinition.md` defines it.
- Delivered in **vertical slices**:
  - **Slice 1 — Guest Search** (search + detail, no persistence)
  - **Slice 2 — Save & Notify** (watchlist + notifications + background refresh)

Let me find every place my new docs used the ambiguous "v0.1" so I can replace it.

### Tool Ripgrep Raw Search

```
{"pattern":"v0\\.1","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","outputMode":"content","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_vrtx_01Eq9QKJUZyxs52PJZrTH256","offset":0}
```

## Assistant

The decision is settled (SwiftData + pure repository protocol). I'll now (1) standardize terminology across the docs, (2) replace `Architecture.md` §7 with the repository design, and (3) record both in the decision log. Starting with `ProductSpec.md`.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Now `TVMazeResearch.md`.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Now the `Architecture.md` edits — terminology plus the §7 rewrite to the repository design.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Now the §7 rewrite to the repository design:

### Tool Edit File V2

## Assistant

Let me update the layering diagram and the proposed file layout to reflect the repository, then the decisions table and open questions.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Now the decisions table and the open-questions section:

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Finally, the decision log — fix the wording and add the repository decision.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Let me verify no stray "v0.1" remains.

### Tool Ripgrep Raw Search

```
{"pattern":"v0\\.1","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_vrtx_01J6rAMm22oqfrrz4fiqPCsz","offset":0}
```

## Assistant

The only remaining `v0.1` mentions are the intentional ones in the new Terminology notes (explaining *why* the term is retired). Everything else is now standardized.

## Done — both questions resolved and folded into the docs

**Persistence (your decision, confirmed):** SwiftData behind a `WatchlistRepository` protocol.
- I rewrote `Architecture.md` §7 with the repository design: the protocol deals in a domain `TrackedShow` struct, while a private `TrackedShowEntity` `@Model` stays sealed inside `SwiftDataWatchlistRepository`. Added an `InMemoryWatchlistRepository` for tests/previews.
- I framed the justification on a **present need** (testability + the layering we already committed to), with swap-out as a free side effect — that keeps us honest against our own "no premature abstraction" rule.
- I flagged the one real **trade-off**: dealing in domain structs means giving up `@Query` live-binding in views (we do explicit fetches driven by `@Observable`). Fine for an infrequently-changing watchlist.
- Updated the layering diagram, file layout, decisions table, and open-questions section. Logged as **PD-007**.

**Terminology (your clarification):** dropped the ambiguous "v0.1" everywhere.
- New canonical vocabulary across `ProductSpec.md`, `Architecture.md`, `TVMazeResearch.md`, `DecisionLog.md`:
  - **MVP** = the full first release (search + watchlist + notifications) — what ChatGPT called "v0.1".
  - **Slice 1 — Guest Search** and **Slice 2 — Save & Notify** = the implementation increments.
- Added a **Terminology** section to `ProductSpec.md` and a terminology note to `DecisionLog.md` so the distinction is permanent and discoverable.

## Still open for you (the remaining Phase 5 questions)

- `summary` HTML — strip to plain text vs. render as `AttributedString`?
- Exact notification copy + the precise set of "meaningful change" triggers (Slice 2).
- In-memory response caching in `TVMazeClient` for Slice 1, or just rely on TVMaze's 60-min edge cache?

Want to keep going through these, or pause here? Nothing is committed yet, and no app code has changed — still docs only.

## User

Please don't change any app code without asking and receiving permission.

## Assistant

Understood, and agreed. I won't modify any app code (Swift files, project settings, assets, etc.) without first describing the proposed change and getting your explicit permission.

To be clear on where things stand: everything I've done for Phase 3 so far has been documentation-only (in `Documentation/`) — no app code touched, and nothing committed. That remains the case.

When we move to Phase 4 (the Guest Search slice), I'll pause before writing any Swift, lay out exactly what I intend to add/change, and wait for your go-ahead.

## User

Why are you asking me Phase 5 questions when we havn't done Phase 4 yet?

## Assistant

You're right — that's a mislabel on my part. Phase 5 is Review, which only happens *after* Phase 4 implementation. Those are really **open design questions to resolve during Phase 4** (mostly small implementation choices), not Phase 5 review items. I incorrectly tagged them "Phase 5," including in the `Architecture.md` heading. Let me fix that.

### Tool Edit File V2

## Assistant

Fixed. To recap the corrected sequence:

- **Phase 3 (Architecture)** — done: the three docs + decisions are written.
- **Phase 4 (Implementation)** — next: build the Guest Search slice. The small open questions (HTML rendering, client caching) get decided *here*, as we implement.
- **Phase 5 (Review)** — later: reviewing the implemented code for complexity, accessibility, testability, etc.

So those questions don't need answers now — they'll come up naturally when we start Phase 4. The persistence and terminology items, which *did* need deciding at the architecture stage, are resolved.

Nothing else changed, and no app code was touched. Ready to start Phase 4 whenever you are — and I'll ask before writing any Swift.

## User

what do you mean by DTO (used in DecisionLog)?

## Assistant

**DTO** stands for **Data Transfer Object**.

In this project it means: plain Swift structs whose only job is to mirror the exact shape of the JSON that TVMaze returns, so they can be decoded with `Codable`. They're a "transfer" format — used to get data across the network boundary and nothing more.

The key idea in our architecture is keeping DTOs **separate** from the app's domain models. Concretely, three tiers (from `Architecture.md` §2):

1. **DTOs** — match TVMaze JSON 1:1. Network-only. Example:

```swift
struct ShowDTO: Codable {
    let id: Int
    let name: String
    let status: String          // raw string like "Running", "To Be Determined"
    let premiered: String?      // date as a raw string
    let summary: String?        // contains HTML tags
    let image: ImageDTO?
    let embedded: EmbeddedDTO?  // maps from JSON key "_embedded"
}
```

2. **Domain models** — clean types the rest of the app uses, with API quirks already cleaned up:

```swift
struct Show {
    let status: ShowStatus      // a real enum, not a raw string
    let premiered: Date?        // a real Date, not a string
    let summaryPlainText: String?   // HTML already stripped
}
```

3. **Persistence models** — SwiftData `@Model` types (Slice 2).

**Why bother with a separate DTO layer?** It quarantines all the messy parts of the TVMaze API — raw date strings, HTML in `summary`, open-ended `status` values, the `_embedded`/`_links` HAL structure — at the network edge. The views, view models, and the `NextSeasonCalculator` only ever see the clean domain types. If TVMaze changes its JSON, we fix the mapping in one place and nothing else in the app breaks.

So in the DecisionLog, "DTO/domain split" is shorthand for exactly this separation between the raw-JSON structs and the clean app-facing models.

## User

That's fine for the documentation, but when it comes to writing code please use "Data" instead.  Ie, "ShowData".

## Assistant

Got it. The conceptual term **DTO** stays in the documentation, but in actual Swift code I'll use the **`Data` suffix** — `ShowData`, `SeasonData`, `SearchResultData`, etc.

Let me record this convention so it's applied consistently in Phase 4, and update the one place in the docs that names concrete code types.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/AGENTS.md","offset":42,"limit":15}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/AGENTS.md","offset":30,"limit":13}
```

### Tool Edit File V2

## Assistant

Now update the concrete code type names in the `Architecture.md` file layout (the docs' conceptual "DTO" wording stays):

### Tool Edit File V2

## Assistant

Done. Summary of what I recorded:

- **`AGENTS.md`** (Coding Style) now states: data-transfer types use the `Data` suffix in code (`ShowData`, `SeasonData`, `SearchResultData`), while "DTO" may still be used in documentation. This ensures I follow it automatically in Phase 4.
- **`Architecture.md`** §10 file layout: the concrete type-name examples now use the `Data` suffix.

The conceptual term "DTO" remains in the prose of the docs (per your call), but every actual Swift type I write will use `...Data`. No app code was changed.

## User

I forgot to ask - do you automatically read skills files such as swiftui-pro.md, or do I need to tell you to read them?

## Assistant

Short answer: **they're not auto-loaded.** I only automatically receive each skill's short *description* and file path — not its contents. I read the full skill file (with the Read tool) only when I decide it's relevant to the task at hand, and I'm instructed to do that proactively as a first step when it applies.

So in practice:

- **You don't strictly need to tell me** — for this project I'll read the relevant Swift skills on my own when the work matches. Concretely, the ones I'd pull in:
  - `swiftui-pro` — when writing/reviewing any SwiftUI views
  - `swiftdata-pro` — when implementing the `WatchlistRepository` / SwiftData layer (Slice 2)
  - `swift-concurrency-pro` — when writing the `async/await` networking and actors
  - `swift-testing-pro` — when writing the test suite
- **But telling me explicitly removes the guesswork.** Proactive reading is a judgment call, so if you say "use swiftui-pro for this," it's guaranteed rather than dependent on my relevance assessment.

One caveat worth flagging: since Phase 3 has been documentation-only, I haven't read any of those skill files yet — there was no Swift code to write. When we start Phase 4 and I'm about to write actual Swift, I'll read the applicable skill(s) first (and I'll mention that I'm doing so). If you'd like, I can treat "always read the relevant Swift skill before writing Swift" as a standing instruction for this project.

## User

That's fine.

## Assistant

Got it — I'll treat that as a standing instruction: before writing any Swift in this project, I'll read the relevant Swift skill(s) first (`swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`, `swift-testing-pro` as applicable) and note that I'm doing so.

Want me to record this in `AGENTS.md` so it persists across future chats, or just keep it in effect for our current work?

## User

sure, go ahead

## Assistant

I'll add it to `AGENTS.md` under AI Instructions.

### Tool Edit File V2

## Assistant

Recorded in `AGENTS.md` under AI Instructions, so it'll apply to this and future chats. Whenever I'm about to write Swift, I'll read the applicable skill(s) first and tell you which ones I used.
