# NextSeason project overview

## User

Something we haven't considered is how reliable TVMaze is.  An app like this is only as good as its data.  Can you investigate this and add your findings to TVMazeResearch?

## Assistant

Good call — data reliability is an existential risk for an app whose entire value is "trust me about when the next season drops." Let me investigate TVMaze's data sourcing, accuracy, freshness, and service availability, then write up findings.

I have solid findings from multiple angles. Let me add a reliability section to `TVMazeResearch.md`. First I'll renumber the existing final section, then insert the new one before it.

Let me review the now-redundant items in the old "Open questions / risks" list and tighten them.

The timeliness item is now covered in §6.3, so I'll point it there instead of repeating.

Added a thorough **§6 "Data reliability & service availability"** to `TVMazeResearch.md` (and renumbered the old "Open questions" to §7, removing the now-duplicated timeliness note). Findings are from web research plus the TVMaze forums/API docs, verified 2026-06-14.

## What I found

**How the data is made — crowd-sourced but moderated**
- 100% user-generated; completeness is "as complete as the community makes it" (no paid editorial guarantee).
- Real safeguards exist: new-contributor probation/verification, reputation-based permissions, an **edit-conflict auto-lock** on frequently-changed fields (only Trusted Contributors+ can then edit), blocked re-creation of deleted bad entries, and a stated preference for official sources. TVMaze claims 99%+ of edits are correct.

**Numbering quirks that affect us**
- Numbering follows the network of original premiere; shows without official numbering use the **calendar year as season number** (confirms the `season: 2026` soap case — our calculator already handles this).

**The real risk for *this* app — freshness, not uptime**
- Our promise hinges on how fast the community adds an (often undated) next-season row and then a real premiere date. That latency is variable and community-dependent, plus the API's own 60-min cache. Popular shows update fast; niche/foreign shows can lag.
- Because fields are editable, a speculative/placeholder date could appear then get corrected — which could cause a **false or premature notification**.

**Service availability — strong**
- No official status page/SLA (it's free), but third-party monitors show **~100% uptime, ~0% errors, ~110–130 ms** over 30 days. During maintenance the site goes **read-only — reads keep working**, which is all we need.

## Mitigations I documented (feed into Slice 2)
- **Honest UI:** show a "last updated" timestamp + the required "Data by TVMaze" attribution — present as a convenient tracker, not an oracle.
- **Debounce notifications:** notify on changes that persist across two polls or are backed by a concrete date, not on the first transient edit (balanced against timeliness). The dedup signature already limits repeat/flapping alerts.
- **Handle `404`/deleted shows and `429`/outages gracefully.**
- **Contingency:** the `TVMazeService` protocol already isolates the network layer, so TheTVDB (TV-first, very stable) or TMDB could be added/swapped later without touching the UI — no need to build multi-source now.

**Bottom line:** TVMaze is fit for purpose (great uptime, sensible moderation, good upcoming-season coverage, free, no auth); the residual risk is inherent crowd-sourced freshness/accuracy, which we manage through honest UI and resilient notification logic rather than assuming perfect data.

One note: a couple of these mitigations (debounced notifications, `404` handling) are effectively small architecture decisions for Slice 2. I kept them in `TVMazeResearch.md` as you asked — want me to also reflect them in `Architecture.md` §8 and add a decision-log entry, or leave that until we actually build Slice 2?

## User

Yes

## Assistant

I'll reflect the reliability mitigations in `Architecture.md` §8 and add a decision-log entry. Let me read the current §8 first.

Now I'll add a row to the decisions table in §11 and a decision-log entry.

Done. The reliability mitigations are now reflected in all three places:

- **`Architecture.md` §8** — added a "Reliability-driven notification rules" subsection (debounce/confirm before notifying, dedup signature, graceful `404`/`429`/`5xx` handling, honest "last updated" + attribution UI).
- **`Architecture.md` §11** — added a decisions-table row for debounced, date-backed notifications, referencing PD-008.
- **`DecisionLog.md`** — added **PD-008** capturing the decision and its rationale, linking back to the `TVMazeResearch.md` §6 findings and the `TVMazeService` provider-swap contingency.

These remain documentation-only; nothing will be built until Slice 2, and no app code was touched.

## User

Ok, we are ready to continue.  Please proceed with Phase 4, and do your work on a new branch called Phase4.

## Assistant

I'll start Phase 4 (the Guest Search slice). Per our standing agreement, I'll do the setup (branch, skills, project inspection) and then lay out a concrete plan — but I won't write any Swift until you approve it.

Let me set up the branch and gather what I need (project structure + the Swift skills I'm required to read before writing Swift).

Setup gathered. Two important things I learned from the project file:

1. **Good news on file management:** the project uses Xcode 26 **file-system-synchronized groups** (`PBXFileSystemSynchronizedRootGroup`), so any `.swift` files I add inside the `NextSeason/` folder are picked up by the target automatically — no fragile `project.pbxproj` editing needed for app code.
2. **No test target exists yet**, and the build settings use `SWIFT_VERSION = 5.0` (with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency on). Both have implications I'll raise below.

Let me create the `Phase4` branch (working tree is clean).

I'm on the `Phase4` branch now, and I've read the `swiftui-pro` and `swift-concurrency-pro` skills (I'll read `swift-testing-pro` before writing tests). Per our agreement, here's the plan for **Slice 1 (Guest Search)** — I won't write any Swift until you approve.

## Plan: Slice 1 — Guest Search

Following `Architecture.md`, built as two reviewable steps so each compiles and is testable on its own:

**Step A — Search (end-to-end vertical slice)**
- `Models/DTO/` — `ShowSearchResultData`, `ShowData`, `SeasonData`, `ImageData` (Codable, mirror TVMaze JSON; `Data` suffix per your convention)
- `Models/Domain/` — `Show`, `Season`, `ShowStatus`, `NextSeasonStatus` + DTO→domain mapping
- `Services/TVMazeClient.swift` — `TVMazeService` protocol + actor implementation; `searchShows(matching:)` and `show(id:)` (with `embed[]=seasons&embed[]=nextepisode`), custom User-Agent, typed `TVMazeError`, 429 back-off
- `Features/Search/` — `SearchViewModel` (`@Observable`, debounced query, idle/loading/results/empty/failed states) + `SearchView` (searchable list with poster, title, status)
- Wire `ContentView`/`NextSeasonApp` to show `SearchView` in a `NavigationStack`

**Step B — Show Detail + next-season status**
- `Services/NextSeasonCalculator.swift` — the pure derivation function (`Architecture.md` §6)
- `Features/ShowDetail/` — `ShowDetailViewModel` + `ShowDetailView` (poster, summary, status, derived next-season status, "Data by TVMaze" attribution)
- Navigation from a search result to detail

**Defaults I'll apply** (the small Phase-4 open questions): strip `summary` HTML to plain text for now; no in-memory client cache in Slice 1 (rely on TVMaze's 60-min edge cache). I'll keep all code Swift 6 / strict-concurrency clean.

## Three things I need from you before coding

First, two findings that need a decision, then approval to start:

- **Test target:** there's currently no test target in the project, and I can't create one safely by hand-editing `project.pbxproj`. The clean path is for you to add a *Unit Testing Bundle* target in Xcode (named `NextSeasonTests`, Swift Testing). The pure `NextSeasonCalculator` + DTO decoding are our highest-value tests.
- **Swift language mode:** the project is set to `SWIFT_VERSION = 5.0` (with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency). `AGENTS.md` says Swift 6.2. The current setting already gives us modern concurrency; I'd suggest leaving it as-is for now and writing Swift-6-clean code, then flipping the language mode later. Changing it is an app-config edit I'd only do with your OK.

Approved. I'm writing **Step A (Search)** now, leaving the project at Swift 5 mode (+ MainActor default) and writing Swift-6-clean code. You'll add the `NextSeasonTests` target in Xcode later. The synchronized group means these new files build automatically.

Let me track the work and start creating files.

Creating the DTO models:

Now the domain models and mapping:

Now the utilities:

Now the networking layer:

Now the search feature (view model + views):

I referenced a `Show.preview` fixture — let me create it (DEBUG-only) and then `SearchView`.

Now wire the app entry point to `SearchView` and remove the template `ContentView`:

Now let me verify it compiles by building for the simulator.

`xcodebuild` is pointed at Command Line Tools, not Xcode. I can work around that without `sudo` by setting `DEVELOPER_DIR` for this command. Let me check for Xcode first.

Found Xcode 26.5. Let me build using `DEVELOPER_DIR` (no `sudo` needed). This may need to resolve the toolchain and could take a bit.

The build failed purely due to sandbox restrictions (can't write to `~/Library/Developer/Xcode/DerivedData`, can't reach `CoreSimulatorService`) — not code errors. Let me re-run outside the sandbox.

`** BUILD SUCCEEDED **` — Step A compiles cleanly with the Xcode 26.5 toolchain for the iOS Simulator.

Step A (Search) is done and building. Pausing here for your review as agreed, before Step B (Show Detail + next-season status).

## What I built (on branch `Phase4`)

New files under `NextSeason/`:
- **`Models/DTO/`** — `ShowData`, `SeasonData`, `ImageData`, `NetworkData`, `NextEpisodeData`, `EmbeddedData`, `ShowSearchResultData` (Codable, `Data` suffix per your convention)
- **`Models/Domain/`** — `Show`, `Season`, `ShowStatus` (open-ended enum that never drops unknown values)
- **`Models/Mapping/ShowData+Domain.swift`** — DTO→domain mapping
- **`Utilities/`** — `TVMazeDate` (formatter-free date parsing) and `String+HTML` (summary tag stripping)
- **`Services/`** — `TVMazeError` (user-facing messages), `TVMazeService` protocol, `TVMazeClient` actor (custom User-Agent, embeds, 429 back-off)
- **`Features/Search/`** — `SearchViewModel` (`@Observable`, debounced via `.task(id:)`, idle/loading/results/empty/failed states), `SearchView`, `ShowRow`
- **`Previews/Show+Preview.swift`** — DEBUG-only sample data

Changed/removed:
- `NextSeasonApp.swift` now launches `SearchView`
- Deleted the template `ContentView.swift` (the unused "Hello, world!" placeholder)

## Decisions I applied (the small open questions)
- Summary HTML → stripped to plain text for now
- No in-memory client cache in Slice 1 (relying on TVMaze's 60-min edge cache)
- Left `SWIFT_VERSION = 5.0`; code is written `nonisolated`/`Sendable`-clean to be Swift 6-ready

## How to test in Xcode
1. Open the project in Xcode 26.5, select an iOS 26 simulator, run.
2. Type in the search bar (e.g. "Severance", "Game of Thrones"). You should see a debounced results list with poster, title, and status.
3. Try an empty query (idle prompt), a nonsense query (empty-results state), and airplane mode (error state with "Try Again").
4. Previews: `SearchView.swift` and `ShowRow.swift` have working previews.

## Notes / what's deliberately not here yet
- **Tapping a result does nothing yet** — navigation + the show detail screen + the next-season status derivation are **Step B**.
- **No tests yet**: once you add the `NextSeasonTests` target in Xcode, Step B is where the high-value tests land (the pure `NextSeasonCalculator` and DTO decoding).
- Nothing has been committed; all changes are working-tree only on `Phase4`.

Want me to proceed with **Step B (Show Detail + next-season status)**?

## User

I've already added the test target.  Do you need me to do something so you can see it?

## Assistant

Let me check what the test target setup looks like now.

No, I'm all set — I can see it. The `NextSeasonTests` target exists and uses a file-system-synchronized group (`path = NextSeasonTests`), so any `.swift` files I add into the `NextSeasonTests/` folder are automatically picked up by the test target. No action needed from you.

Let me peek at the default test file to match the framework/style you got.

It's using **Swift Testing** (`import Testing`), which is exactly what we planned. I can write test files straight into `NextSeasonTests/`.

So everything's ready for **Step B (Show Detail + next-season status)**, which will include:
- `NextSeasonCalculator` (the pure derivation function) + `NextSeasonStatus`
- `ShowDetailView` / `ShowDetailViewModel`, and navigation from search results into detail
- A "Data by TVMaze" attribution credit
- **Tests** (now that the target exists): unit tests for every `NextSeasonCalculator` branch (airing / scheduled / announced-undated / returning / ended / unknown, plus the soap "year-as-season" and revival edge cases) and DTO decoding against a real JSON fixture

One small question before I start: shall I replace the placeholder `NextSeasonTests.swift` with the real test files, or leave it in place and add new files alongside it?

Want me to proceed with Step B?

## User

Why did you recommend sticking with Swift 5 instead of switching to 6 now?

## Assistant

Honest answer: it was a **conservative risk call for the first code slice**, and now that the slice builds, the reasoning has largely expired. Here's the full picture.

## Why I recommended staying on Swift 5 mode (at the time)
- **I couldn't iterate in a tight build loop.** When I proposed it, I hadn't yet confirmed I could even run `xcodebuild` here. In **Swift 6 language mode, data-race/isolation violations are hard compile errors**; in Swift 5 mode they're warnings (or off). I wanted to avoid a situation where a subtle isolation mistake I couldn't quickly verify would block the whole build on the very first slice.
- **You already get most of Swift 6's benefits without flipping the mode.** The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`, so we already write modern concurrency with main-actor defaults. The *language mode* mainly controls how strictly data-race safety is enforced.
- **It's a cheap, reversible decision** best made when we can compile and fix any diagnostics in a loop.

## Why that reasoning no longer really holds
- The Step A build **succeeded**, and I confirmed I *can* run `xcodebuild` (with the Xcode toolchain). So the build-loop concern is gone.
- I wrote everything `nonisolated` / `Sendable`-clean specifically so it'd pass strict checking — so the risk of a wall of errors is low.
- **`AGENTS.md` explicitly says Swift 6.2.** Staying on language mode 5 is mildly inconsistent with your own stated standard.
- The best time to adopt Swift 6 mode is **early, with little code** — which is exactly now. The longer we wait, the more unvalidated code accumulates.

## My updated recommendation
Switch to **Swift 6 language mode now**, before Step B. Concretely: flip `SWIFT_VERSION` to `6.0` for both targets, then rebuild and fix any strict-concurrency diagnostics that surface (I expect few or none, given how the code is written). It's an app-config change, so I'll only do it with your OK.

Want me to switch to Swift 6 now and re-verify the build, then proceed with Step B? (If you'd rather defer it, staying on 5 for now is still perfectly fine — it's easy to flip later.)

## User

Go ahead and switch to Swift 6, but don't proceed with Step B yet.

## Assistant

I'll switch the project to Swift 6 language mode and verify the build, but hold off on Step B. Let me find all `SWIFT_VERSION` settings first.

All four are target-level (app + test, Debug + Release). I'll switch them all to Swift 6.

Now rebuild to confirm the app still compiles cleanly under Swift 6 language mode (strict concurrency now enforced as errors).

`** BUILD SUCCEEDED **` under Swift 6 language mode, with no compile errors or warnings (the lone message is an unrelated AppIntents metadata note). Because the code was already written `nonisolated`/`Sendable`-clean, strict concurrency — now enforced as hard errors — passed without any changes needed.

## Summary
- Set `SWIFT_VERSION = 6.0` for all four configurations (app + `NextSeasonTests`, Debug + Release) in `project.pbxproj`.
- Rebuilt the app target for the iOS Simulator: clean.
- The project is now consistent with `AGENTS.md` (Swift 6.2 / strict concurrency).

A couple of notes:
- I verified the **app** target; the `NextSeasonTests` target only compiles during a test run, but its sole file right now is the trivial Swift Testing placeholder, so no issues are expected there.
- This was config-only — no source changes, and nothing committed.

As requested, I'm **not** starting Step B. Just say the word when you'd like me to proceed (and let me know your preference on replacing vs. keeping the placeholder `NextSeasonTests.swift`).

## User

Is there a compelling reason why you changed the root view to SearchView instead of keeping ContentView?  I would prefer to use the name that everyone knows to look for to start, but I'm not stuck on it if you have a better idea.

## Assistant

Honest answer: **no, there was no compelling reason.** It was a stylistic choice — I renamed it to `SearchView` for descriptive, feature-based naming (matching the per-feature folder layout). But your point is well taken: `ContentView` is the conventional entry point everyone instinctively looks for, and there's no real cost to keeping it.

Here's the "better idea" I'd suggest, which gives you both: keep **`ContentView` as the app's root view** (the familiar starting point), and have it host the focused `SearchView` feature. This isn't just a rename — `ContentView` becomes the natural home for the **`TabView`** we'll add in Slice 2 (Search tab + Watchlist tab), so it earns its place rather than being a pointless wrapper.

Let me restore `ContentView` as the root and point the app at it.

Done — `ContentView` is back as the root view, and the build is clean.

## What changed
- Recreated `NextSeason/ContentView.swift` as the app's root view; for now it renders `SearchView()`, and it's the spot where the Slice 2 `TabView` (Search + Watchlist) will live.
- Pointed `NextSeasonApp` back at `ContentView()`.
- `SearchView` stays as the focused search-feature view (owns its `NavigationStack`).

This keeps the conventional, discoverable entry point you wanted while preserving the feature-based structure — and gives `ContentView` a real job going forward rather than being dead weight.

Still holding on Step B. Nothing committed.

## User

It runs well;  I'm looking at the code now.

One thing that occurs to me - what abour reruns?  Can we be sure that the data won't show a previous season that's being re-broadcast?

## Assistant

Great question — reruns/re-broadcasts are exactly the kind of thing that could quietly corrupt a "next season" signal. Let me verify against live data rather than just assert. A heavily-rerun, long-ended show is the perfect test: The Big Bang Theory (ended 2019, constantly re-aired).

Confirmed with live data. Despite being in heavy rerun rotation, **The Big Bang Theory** shows:
- `status: Ended`
- **no `nextepisode`** (neither in `_links` nor embedded)
- last season is 12 (premiered 2018, ended 2019) — **no future or undated season row**

So a re-broadcast produces **zero** false signals. Here's why we're structurally safe, and the one residual case.

## Why reruns don't fool us

TVMaze's data model protects us by design (this ties back to `TVMazeResearch.md` §6.2):

1. **Numbering and dates are anchored to the *original* premiere**, never a rerun. Per TVMaze policy: "If an episode premiered on Netflix and is later shown on TV, the Netflix dates are what count." So re-airing season 1 does **not** change season 1's `premiereDate` and does **not** add a season row.
2. **Reruns aren't modeled as data at all** — there's no "rerun" flag and no duplicate episode entries. An episode has a single (original) `airdate`. So there's simply no future-dated rerun for us to misread.
3. **`nextepisode` is the next *unaired* episode by airstamp.** A rerun's episode already has a past airdate, so it never surfaces as `nextepisode`. That's confirmed above — BBT has none.

Our planned `NextSeasonCalculator` keys off exactly these rerun-immune fields: season rows + their original premiere dates, plus the next genuinely-unaired episode. A rerun touches none of them.

## The one residual risk (and it's already covered)

The only way a rerun could mislead us is **bad crowd-sourced data** — e.g., a contributor mistakenly entering a re-broadcast's date as a new season's `premiereDate`. That's not a rerun-modeling problem; it's the general data-accuracy risk we already documented in §6.4, mitigated by **PD-008** (debounce/confirm before notifying + dedup signature). So even that edge case is handled.

## What I'll do in Step B to lock this in

I'll add explicit `NextSeasonCalculator` test cases so this can't regress:
- **Ended-but-rerunning show** (BBT-shaped fixture: `Ended`, no `nextepisode`, all seasons past) → must derive `.ended`, never `.airing`/`.scheduled`.
- **Running show on hiatus, no new season row yet** → `.returningNoSeasonYet`, not `.airing`.
- Plus the already-planned specials/season-0 and "year-as-season" (soap) cases.

Net: I'm confident reruns won't show a previous season as new. Want me to also add a short "Reruns & re-broadcasts" note to `TVMazeResearch.md` §6 capturing this finding (with the BBT evidence), so the reasoning is on record? And I'll keep this in the Step B test plan either way.

## User

Yes please

## Assistant

I'll add a "Reruns & re-broadcasts" note to `TVMazeResearch.md` §6. Let me place it after §6.2 (numbering rules), since it builds on the original-premiere policy.

Now renumber the following three subsections and fix the cross-references.

Now fix the cross-references that pointed at the old section numbers (in the open-questions list and in `Architecture.md`).

Let me double-check no other stale `§6.x` references remain.

All cross-references are now consistent. The remaining `§6.3` mention is only in a kickoff *transcript* (a historical record of an earlier chat), which I've left untouched.

Done — added **§6.3 "Reruns & re-broadcasts"** to `TVMazeResearch.md` with:
- The three structural reasons reruns can't create false signals (original-premiere anchoring, no rerun modeling, `nextepisode` = next *unaired* episode)
- The live BBT evidence (2026-06-14)
- A pointer to the one residual risk (mis-entered data) and its mitigation (PD-008)
- A note that Step B will include an "ended-but-rerunning" calculator test

I also renumbered the subsequent §6 subsections (Timeliness→6.4, Data volatility→6.5, Service availability→6.6, Overall assessment→6.7) and updated the cross-references in both `TVMazeResearch.md` and `Architecture.md` to match.

Still holding on Step B, and nothing has been committed.

## User

In TVMazeClient, what's the purpose of the resolvingAgainstBaseURL parameter in the calls to URLComponents?

## Assistant

Good question — and the honest answer is that **in our code it's effectively a no-op**, but it's worth understanding when it *does* matter.

`URLComponents(url:resolvingAgainstBaseURL:)` builds a `URLComponents` by parsing a `URL`. The boolean only matters when the `URL` you pass is itself a **relative URL that has an associated base URL** (the kind you get from `URL(string:relativeTo:)`). It decides whether to resolve against that base before extracting the components:

- `true` → first resolve to the absolute URL (`url.absoluteURL`), then parse. Components reflect the fully-resolved URL.
- `false` → parse the URL's own string as-is (`url.relativeString`), without merging in the base.

Here's the difference when a base URL is actually involved:

```swift
let base = URL(string: "https://api.tvmaze.com")!
let rel  = URL(string: "search/shows", relativeTo: base)!

URLComponents(url: rel, resolvingAgainstBaseURL: false)?.host  // nil,  path = "search/shows"
URLComponents(url: rel, resolvingAgainstBaseURL: true)?.host   // "api.tvmaze.com", path = "/search/shows"
```

## Why it doesn't change anything for us

In `TVMazeClient` we build the URL with `baseURL.appending(path: "search/shows")`, which returns a **fully absolute, standalone URL with no associated base URL**. Since there's nothing to resolve against, `false` and `true` would produce identical components. I passed `false` simply because it's the literal "just parse this URL as given" behavior, which is the accurate description of what's happening.

A couple of related notes:
- The initializer is **failable** (returns an optional), which is why `components` is optional and the code uses `components?.url` with a `guard` that throws `TVMazeError.invalidURL`.
- If we had instead used relative URLs (`URL(string: "search/shows", relativeTo: baseURL)`), then the flag *would* matter and we'd want `true` so the host/scheme carried through.

If you'd prefer, I could simplify those calls to use `URLComponents(string:)` directly (building the absolute string), which sidesteps the parameter entirely — but the current form is correct as written.

## User

That's ok, I just wanted to understand it.

## Assistant

Sounds good. Happy to clarify anything else as you read through the code, or to kick off Step B whenever you're ready.

## User

I understand why you are stripping HTML tags from the summary at this point, but I would like to display the summary formatted the way they intend it to look by the time we're done if possible.

## Assistant

Yes, that's definitely doable with first-party APIs only (no new dependencies), and it's a nice touch for the detail screen. Good news: the summary isn't actually displayed anywhere yet — it only appears on the show detail screen, which is **Step B** — so we can choose the formatted approach *before* it's ever shown to a user. The current plain-text stripping is just a safe interim.

Here's how I'd approach it, and I'll record the decision so it isn't lost.

## What TVMaze gives us
Summaries contain light HTML — mostly `<p>`, `<b>`/`<strong>`, `<i>`/`<em>`, `<br>`, occasionally `<a>`. So we don't need a full HTML engine.

## Options (all first-party)
1. **`NSAttributedString` HTML import** (`documentType: .html`) → convert to `AttributedString`. Quick, but it's slow, must run on the main thread, and bakes in its own fonts/colors that fight Dynamic Type and our styling. I'd avoid it.
2. **Small dedicated HTML→`AttributedString` converter** (recommended): handle just TVMaze's tag set, applying bold/italic via semantic `inlinePresentationIntent` (so it scales with Dynamic Type and uses the app's font) and turning `<p>`/`<br>` into proper paragraph/line breaks. It's a pure function — fully unit-testable, fits our architecture, and gives the cleanest, most accessible result.
3. **HTML→Markdown→`AttributedString(markdown:)`**: tempting, but SwiftUI's Markdown collapses paragraph breaks unless you fight the options, so block structure gets awkward.

My recommendation is **option 2**: in Step B, keep the **raw** `summary` HTML on the domain model (e.g. `summaryHTML`) and add a small tested `SummaryFormatter` that produces an `AttributedString` for the detail view — preserving paragraphs, bold, and italics while respecting Dynamic Type and VoiceOver.

Let me capture this so it's on record (it also resolves one of our open Phase-4 questions).

Recorded. To summarize:

- **Decision (PD-009):** show summaries will be rendered with their intended formatting — paragraphs, bold, italics — using a small, unit-tested HTML→`AttributedString` converter that respects Dynamic Type and VoiceOver and matches the app's fonts. The raw `summary` HTML will be kept on the domain model so formatting happens at render time.
- **`Architecture.md` §12:** the "strip vs. render" open question is now marked resolved, pointing to PD-009.
- **Interim:** Slice 1 keeps the plain-text stripping only because the summary isn't displayed until the Step B detail screen.

So when we build Step B, I'll add the `SummaryFormatter` (plus tests) and the detail view will show the nicely formatted summary. No app code changed now, and nothing committed.

## User

Execute the selected diff-tab commit-and-push action.

Commit created with only the staged file. The rest remain uncommitted as instructed. Now pushing the branch.

Done.

- **Committed** (`a073c8b`) only the staged file: `NextSeasonTests/NextSeasonTests.swift` (1 file, 18 insertions). Message: "Add NextSeasonTests target placeholder test".
- **Pushed** `Phase4` to `origin` and set it to track `origin/Phase4`.
- All other modified/untracked files were left untouched, exactly as specified.

GitHub offered a PR link if you want it: https://github.com/janineanne/NextSeason/pull/new/Phase4

## User

Go ahead and commit and push all changes so far for phase 4, step A.

## Assistant

I'll commit all remaining Phase 4 Step A changes (app code + the related doc updates) and push. Let me review what's there first.

Everything looks like expected Step A work. Staging all, committing, and pushing.

Done — all Phase 4 Step A changes are committed and pushed.

- **Commit `7775fbc`** "Implement Phase 4 Step A: guest show search" — 25 files changed, 817 insertions, 18 deletions. Includes the networking layer (DTOs, domain models + mapping, `TVMazeClient`, service protocol, errors), the Search feature wired through `ContentView`, utilities + preview fixtures, the Swift 6 language-mode bump (+ test target) in `project.pbxproj`, and the related doc updates (Swift 6 / formatted-summaries decisions, rerun-safety research).
- **Pushed** to `origin/Phase4` (`a073c8b..7775fbc`).
- Working tree is now clean.

Whenever you're ready, the next step is **Step B (Show Detail + next-season status)**, which will also bring the formatted summary (PD-009) and the `NextSeasonCalculator` tests.

## User

Go ahead with Step B

## Assistant

Starting Step B. First, as required before writing Swift (and since this step includes tests), let me read the Swift Testing skill.

Read. I'll follow Swift Testing conventions (structs, `#expect`/`#require`, parameterized tests, injected mocks). Now building Step B.

First, the domain additions and model updates (add `NextSeasonStatus`, `NextEpisode`; keep raw summary HTML on `Show`).

Now update `Show` (raw summary HTML + `nextEpisode`) and the mapping:
Update the preview fixtures for the new fields:

Now the calculator:

Now the `SummaryFormatter` and a refactor of `String+HTML` to share entity decoding:

Now the detail screen (status display, view model, view) and wiring navigation from search:

Now wire navigation from the search results into the detail view:

Let me check how results rows are currently rendered so I can make them navigable:

Let me verify `ShowStatus.displayLabel` exists and check the embedded/nextepisode DTO field names used in mapping.

Now let me verify the `TVMazeService` protocol signature and `Season`/`SeasonData` fields for the tests.

Now let me check `TVMazeDate` and the search-result mapping so the decoding tests are accurate.

Let me check `ShowData` fields to make sure my test JSON decodes cleanly.

All optional except `id`/`name`. Now writing the tests.

Now let me build and run the tests. First locating Xcode and a simulator.

There's a booted iPhone 17 Pro. Running the test suite against it:

All 18 tests passed (including the placeholder). Step B is complete.

Step B (Show Detail + next-season status) is done. The build succeeds and all tests pass.

## What I built

**Domain model**
- `NextSeasonStatus` — the app's single answer to "is there a next season, and when?" (`airing`, `scheduled`, `announcedUndated`, `returningNoSeasonYet`, `ended`, `unknown`).
- `NextEpisode` — the next upcoming episode's season + airdate, used as an extra signal.
- Updated `Show`: now keeps the **raw `summaryHTML`** (was `summaryPlainText`) so summaries render formatted (PD-009), and added `nextEpisode`.

**Logic (pure, fully tested)**
- `NextSeasonCalculator.status(for:now:)` — the one place the "next season" rule lives. It's a pure function with an injectable `now`, ignores specials (season 0), and is rerun-safe by keying only off original premiere dates and the next *unaired* episode (TVMazeResearch §6.3).

**Formatting**
- `SummaryFormatter` — converts TVMaze's light HTML (`<p>`, `<br>`, `<b>/<strong>`, `<i>/<em>`, entities) to an `AttributedString` via Markdown, with a plain-text fallback. Refactored `String+HTML` to share entity decoding.

**UI**
- `ShowDetailView` + `ShowDetailViewModel` — shows artwork/metadata instantly from the search result, then loads full details (seasons + next episode) to derive and display the next-season status (with loading/error/retry states), plus the formatted summary and a "Data provided by TVMaze" attribution link.
- Wired navigation: search rows are now `NavigationLink`s into the detail screen.

**Tests (Swift Testing, 17 new)**
- `NextSeasonCalculatorTests` — covers every status branch incl. Severance-style undated S3, rerun-safe ended show, specials ignored, annual/daily shows, and the next-episode signal.
- `SummaryFormatterTests` — bold/italic/paragraphs/entities.
- `ShowDataDecodingTests` — decodes a `/search/shows` entry and a show-with-embeds payload, then derives status end-to-end.

## What you should test
- Search a show → tap a row → confirm the detail screen loads, the "Next Season" line reads sensibly, and the summary shows **bold/italic and paragraph breaks**.
- Try an ended show (e.g. Game of Thrones), a currently-airing show, and one between seasons (Severance) to sanity-check the status wording.
- Check the loading spinner and the error/Try Again path (e.g. airplane mode on the detail screen).

Note: I left the auto-generated placeholder `NextSeasonTests.example()` in place since you'd committed it — happy to remove it if you'd prefer. I did not commit anything; let me know when you want Step B committed and pushed.

## User

I forgot to have you make a new branch.  Please rename existing branch "Phase4" to "Phase4-StepA" and then make a new branch called "Phase4-StepB" for the uncommitted changes.

On `Phase4` with the Step B changes uncommitted. I'll rename the branch (working tree changes stay put), then create `Phase4-StepB` from it.

Done. Here's the result:

- Renamed the existing branch `Phase4` → `Phase4-StepA` (it still points at the committed Step A work).
- Created and switched to a new branch `Phase4-StepB`, which carries all the uncommitted Step B changes (5 modified files + the new `ShowDetail/`, calculator, formatter, domain types, and 3 test files).

One thing to note: `Phase4-StepA` on the remote still tracks the old name `Phase4` — the rename was local only. When you're ready to push Step B, let me know and I can also sort out the remote tracking (e.g. push `Phase4-StepB` with `-u`, and optionally update the remote `Phase4` ref). Nothing has been committed or pushed yet.

## User

That's a screenshot of the app.  The show "Call the Midwife" is currently in the middle of the latest season, which is why it says "Running", but I don't think that all users will understand that.  How about "Currently showing Season X" instead?

## Assistant

Let me look at the live TVMaze data for this show to understand why it reports "Returning — no next season announced yet" rather than detecting an airing season.

Good catch — but I dug into the live data and there's an important nuance worth surfacing before I change anything.

**What TVMaze's "Running" actually means:** it's a *production* status — the series is ongoing (not ended/cancelled). It does **not** mean "currently broadcasting new episodes." So a show can be "Running" while sitting between seasons.

**Call the Midwife specifically** — here's its current season data from TVMaze:

- S14: 2025-01-05 → 2025-12-26
- S15: 2026-01-11 → **2026-03-08**
- (no S16 yet, and no scheduled next episode)

Since the app's current date is mid-June 2026, S15 already finished airing back on March 8. So as far as the data is concerned, the show is *between seasons* right now — which is exactly why the "Next Season" box correctly says "Returning — no next season announced yet." It's not actually mid-season at the moment (at least not per TVMaze).

That matters because if I simply relabel the `Running` line as "Currently showing Season X" for every running show, it would be **wrong** for Call the Midwife today (and any other between-seasons show) — it'd claim S15 is showing when it ended in March.

The app *does* already have a proper "currently airing" concept: the `NextSeasonCalculator` produces an `.airing(season:)` state when a season is genuinely on air, and the "Next Season" box shows it (currently worded "Season X is airing now"). That's the right place for your phrasing.

So I'd like your steer on how to proceed (I won't touch app code until you pick):

The user wants both: reword the airing state to "Currently showing Season X", and soften "Running" → "Ongoing series". Let me check where the status label is used so I change it consistently.

Both edits are clean. `displayLabel` is shared by the search row and detail header, so softening it there is consistent. Making the two changes:

Done. Two changes:

1. **`ShowStatus.displayLabel`** — `.running` now reads **"Ongoing series"** instead of "Running" (applies to the detail header *and* the search-row subtitle, plus the row's accessibility label, so it's consistent everywhere). "Ended" and the others are unchanged.

2. **`NextSeasonStatus.headline`** — the `.airing` case now reads **"Currently showing Season X"** instead of "Season X is airing now". This only appears when a season is genuinely on air.

A heads-up on what you'll see when you re-run: **Call the Midwife will still say "Returning — no next season announced yet"** in the Next Season box, because per TVMaze its latest season (S15) ended 2026-03-08 and the app's date is mid-June — so it's genuinely between seasons right now. The metadata line will now read "Ongoing series" instead of "Running". To see the new "Currently showing Season X" wording, open a show whose current season is actually airing today (i.e. premiered but not yet ended).

What to test:
- Search results subtitles and a detail header now show "Ongoing series" for running shows.
- A show that's mid-season shows "Currently showing Season X" in the Next Season box.
- "Ended" shows (e.g. Game of Thrones) are unchanged.

No tests reference these exact strings, so the suite is unaffected, but I can re-run it if you'd like. Nothing committed yet.

## User

Ok, that looks good.

In the same screenshot, you can see that in the summary there is a space before the word "Based", which shouldn't be there.  Is that due to an extra space from the data being displayed, or some other formatting problem?

## Assistant

Let me look at the raw summary HTML from TVMaze to see exactly what's there.

It's the data — not a layout bug in your view. Here's the raw summary TVMaze returns for this show:

```
<p>...during the 1950s &amp; decades following. \xa0Based on the best-selling memoirs of Jennifer Worth.</p>
```

Right before "Based" the source text contains **two** whitespace characters: a normal space followed by `\xa0`, which is a **non-breaking space (U+00A0)**. So TVMaze's editors left a stray double-space in the text. It renders as the gap you're seeing.

A couple of notes on why our formatter doesn't currently clean it up:
- We decode the `&nbsp;` *entity*, but here the API already delivers the literal `\xa0` character, so that replacement doesn't catch it.
- We don't collapse repeated/normalize whitespace, so the extra space passes straight through to the screen.

This kind of messy whitespace is common in crowd-sourced TVMaze summaries, so it's worth handling generically rather than per-show.

I'd suggest adding a small normalization step in `SummaryFormatter` that:
- converts non-breaking spaces (U+00A0) to regular spaces, and
- collapses runs of horizontal whitespace (spaces/tabs) into a single space — **while preserving the paragraph line breaks** (`\n\n`) we intentionally add.

I'd also add a test case for the "space + nbsp" situation so it stays fixed.

Want me to make that change? (Per your standing rule, I won't touch the code until you confirm.)

## User

Yes, and please add one or more tests for this.

## Assistant

Implementing it. First the normalization in `SummaryFormatter`, preserving the paragraph/line breaks we add:

Now the tests — including the exact "space + non-breaking space" case from Call the Midwife:

Now let me run the test suite to confirm everything passes:

All 21 tests pass, including the new whitespace cases.

## What changed

**`SummaryFormatter`** — added a whitespace-normalization step (after tag stripping / entity decoding, before the trim) that:
- converts non-breaking spaces (U+00A0) to regular spaces,
- collapses runs of spaces/tabs into a single space,
- tidies any spaces around line breaks,
- all while **preserving** the paragraph (`\n\n`) and line (`\n`) breaks we intentionally insert.

So the Call the Midwife summary now reads "...decades following. Based on..." with a single space.

**`SummaryFormatterTests`** — 3 new tests:
- `collapsesSpaceAndNonBreakingSpace` — the exact "space + `\u{00A0}`" case from Call the Midwife.
- `collapsesDoubleSpaces` — plain repeated spaces.
- `normalizationKeepsParagraphs` — confirms collapsing doesn't eat paragraph breaks.

## What to test
- Reopen Call the Midwife and confirm the gap before "Based" is gone.
- Spot-check a couple of other shows' summaries to confirm bold/italic and paragraph spacing still look right.

Nothing committed yet — let me know when you'd like Step B committed/pushed.

## User

I'd like to add a link to the show's page on TVMaze.  You decide the best way to do that.

## Assistant

The show object from TVMaze includes a `url` field (the canonical show page, e.g. `https://www.tvmaze.com/shows/44933/severance`). I'll thread that through the DTO → domain model and present it as a "View on TVMaze" link, keeping the existing credit line. (Using the `swiftui-pro` and `swift-testing-pro` skills already loaded this session.)

Let me read the current `Show.swift` for exact context.

Now update the preview fixtures:

Now update the detail view's footer to add the "View on TVMaze" link:

Now add `url` to the decoding test and assert the mapping:

The calculator test helper constructs `Show` directly, so it needs the new field too. Let me update it.

Let me check for any other direct `Show(` constructions I might have missed:

All three covered. Running the test suite to confirm:

Build and tests pass. Here's what I added for the TVMaze show link:

## Changes

**Data layer**
- `ShowData` (DTO): decode the `url` field from TVMaze.
- `Show` (domain): new `tvMazeURL: URL?` — the canonical show page.
- Mapping: `tvMazeURL: url.flatMap(URL.init(string:))`.

**UI** (`ShowDetailView` footer)
- Added a **"View on TVMaze"** link (with an `arrow.up.right.square` icon) that opens the show's specific page, shown only when a URL is available.
- Kept the **"Data provided by TVMaze"** credit beneath it as the attribution line.

This handles both purposes cleanly: an actionable link to *this show's* page, plus the required attribution/link-back to TVMaze. The links open in Safari via SwiftUI's `Link`.

**Tests / fixtures**
- Added `url` to the decoding test JSON and assert `tvMazeURL` maps correctly.
- Updated both preview fixtures and the calculator test helper with the new field.

## Design note
I chose a dedicated "View on TVMaze" link rather than repurposing the credit line, so the attribution stays clear and the navigation intent is obvious. If `url` is ever missing (rare for real shows), the link simply hides and only the credit shows.

## What to test
- Open a show and tap "View on TVMaze" — it should open that show's page on tvmaze.com in Safari.
- Confirm the footer looks right (link above, grey credit below).

Nothing committed yet.

## User

That works, but it doesn't look right.  Let's move the "view on TVMaze" link up so it's part of the About section, and move the "Data provided by TVMaze" down to the bottom of the page, centered.

Now I'll restructure: fold the link into the About section and make the credit a centered bottom line.

Let me verify it compiles with a quick build:

Build succeeds. Here's the new layout:

- **"View on TVMaze" link** now lives inside the **About** section, right under the summary text (with a little top spacing to separate it from the paragraph).
- **"Data provided by TVMaze"** is now a standalone footnote at the **bottom of the page, centered**, with extra top padding to set it apart as a credit line.

I also made the About section resilient: it now appears if there's *either* a summary or a TVMaze URL, so the link won't vanish on the rare show with no summary.

What to check:
- The "View on TVMaze" link sits neatly at the end of the About block and still opens the show page.
- The grey "Data provided by TVMaze" credit is centered at the very bottom.

Nothing committed yet.

## User

That looks good.  Please add a preview with sample data to provide a visual example of how this would look if the summary info about the show is empty or missing.

## Assistant

Good idea. To make this preview clean and deterministic (no network), I'll let the detail view accept an injected service, add a "missing summary" fixture, and a tiny preview mock service. Let me look at the current preview helpers first.

I'll add a "missing summary" fixture plus a reusable preview mock service (so previews don't hit the network), then let `ShowDetailView` accept an injected service.

Now update `ShowDetailView` to accept an injected service and add the two named previews:

Build succeeds. Here's what I added:

**`ShowDetailView` previews** — now two named previews:
- **"With summary"** — the normal Severance case.
- **"Missing summary"** — a fixture with no description, showing how the screen degrades gracefully: the **About** section collapses to just the "View on TVMaze" link, and the centered credit stays at the bottom.

**Supporting changes:**
- New fixture `Show.previewMissingSummary` (no `summaryHTML`, but a real status and TVMaze URL).
- A reusable `PreviewTVMazeService` mock (DEBUG only) that returns fixed data, so previews render the next-season status **deterministically without any network calls**.
- `ShowDetailView.init` now takes an optional `service` (defaults to `TVMazeClient()`), so the production call site `ShowDetailView(show:)` is unchanged while previews inject the mock.

To view it: open `ShowDetailView.swift` in Xcode's canvas and switch between the "With summary" and "Missing summary" preview tabs.

Note on design: I gave the missing-summary fixture a TVMaze URL so you can see the About section render with only the link. If you'd also like a third preview where *both* summary and URL are absent (About section hidden entirely), I can add that too. Nothing committed yet.

## User

In the case where the summary is missing, can you suppress the About label so the only thing that displays is the link?

## Assistant

Done. The "About" header now only renders when there's actual summary text. When the summary is missing, the section shows just the "View on TVMaze" link — no orphaned "About" label.

You can confirm in the "Missing summary" preview tab of `ShowDetailView`. Nothing committed yet.

## User

Looks good, thank you!

## Assistant

You're welcome! Step B is in good shape: show detail with derived next-season status, formatted summaries with whitespace cleanup, the "View on TVMaze" link, and graceful handling of missing summaries — all building and tested.

Whenever you're ready, just say the word and I'll commit and push the Step B changes to the `Phase4-StepB` branch (and we can sort out the remote tracking for the renamed `Phase4-StepA` at the same time).

## User

Go ahead

Step A is already on `origin/Phase4` and in sync. Now I'll commit the Step B changes and push the new branch. Let me stage and commit first.

Committed. Now let me check for any open PRs (so I don't disrupt anything when sorting out the Step A remote) and push the new branch:

Step B is pushed and tracking `origin/Phase4-StepB`. `gh` isn't installed, so let me check for an open PR on the old `Phase4` branch via the API before touching it (the repo appears public).

The repo is private, so I can't verify PR status unauthenticated — meaning I shouldn't blindly delete the old remote `Phase4` branch (deleting it would close any open PR against it).

I'll do the safe, additive part now: push `Phase4-StepA` to a matching `origin/Phase4-StepA` and set its upstream. Then I'll ask you about the old `Phase4` ref.

All set on the push side. Current state:

- **`Phase4-StepB`** → committed (`a3886a5`) and pushed, tracking `origin/Phase4-StepB`.
- **`Phase4-StepA`** → pushed to `origin/Phase4-StepA`, now tracking it (no longer pointing at the old `origin/Phase4`).

The one leftover is the **old `origin/Phase4` remote branch**. It still exists and now duplicates `Phase4-StepA`. I didn't delete it because the repo is private and I couldn't confirm whether a PR is open against it — deleting it would close any such PR.

How would you like to handle the old `origin/Phase4` branch?

The user explicitly chose to delete it, so I'll surface the approval card for this remote deletion.

All done. Final state:

- **`origin/Phase4`** — deleted.
- **`origin/Phase4-StepA`** — holds the Step A work (`7775fbc`).
- **`origin/Phase4-StepB`** — holds the new Step B commit (`a3886a5`), and your local branch tracks it.
- **`main`** — unchanged.

Everything is committed, pushed, and the remote branch naming now matches your local Step A / Step B split. When you want to open a PR for Step B, GitHub gave you this link:

`https://github.com/janineanne/NextSeason/pull/new/Phase4-StepB`

## User

Is there anything left to do in Phase 4?

## Assistant

Let me check the project's Phase 4 definition against what we've built.

Let me read the exact Slice 1 scope checklist and the build-order section to compare against what's built.

Short answer: **the Slice 1 (Guest Search) work that Phase 4 was scoped to deliver is functionally complete.** Step A + Step B together cover the entire documented Slice 1 scope.

Checking against `ProductSpec.md` §4 (Slice 1 scope):

| Slice 1 requirement | Status |
|---|---|
| Search shows by title (FR-001/002) | ✅ Step A |
| Results with title, artwork, status (FR-003) | ✅ `ShowRow` |
| Detail screen with next-season status — number, premiere date, status labels (FR-008–010) | ✅ Step B (`NextSeasonCalculator` + `ShowDetailView`) |
| Clear empty / loading / error states | ✅ Search (idle/loading/empty/failed) + Detail (loading/failed/retry) |
| Works without login | ✅ guest-only |

So against the spec's "Slice 1 is done when…" criteria, you're there.

**The remaining Phase 4 implementation is Slice 2 — Save & Notify** (Sign in with Apple, SwiftData watchlist behind `WatchlistRepository`, notifications, background refresh). That's designed in the docs (PD-007, PD-008) but intentionally deferred, so it's the next big chunk of Phase 4 whenever you're ready.

That said, there are a few **small loose ends within Slice 1** worth tidying before declaring it fully buttoned-up:

1. **No `SearchViewModel` tests.** `Architecture.md` §10 lists `SearchViewModelTests.swift` as planned, and `SearchViewModel` (debounce, state transitions, error mapping) is currently untested. Worth adding for the "be testable" bar / portfolio quality.
2. **Stale docs about the summary.** `Architecture.md` §12 and `DecisionLog.md` PD-009 still say Slice 1 uses "interim plain-text stripping since the summary isn't displayed yet" — but Step B now displays the formatted summary. Those notes should be updated.
3. **Placeholder test.** The auto-generated `NextSeasonTests.example()` is still there and does nothing — worth removing.
4. **Open question (minor):** `Architecture.md` §12 still leaves "Slice 1: in-memory response caching in `TVMazeClient` vs. rely on TVMaze's edge cache?" undecided. Fine to defer, but it's an open item.

Want me to knock out the Slice 1 loose ends (add `SearchViewModel` tests, refresh the stale docs, drop the placeholder test), or move on to planning Slice 2?

## User

Let's answer that question first.  Adding response caching seems like a good idea, but what do you think?

## Assistant

Good question to settle properly. Before I give an opinion, let me check what caching headers TVMaze actually sends — that decides whether we even need to build anything.

Both endpoints return `Cache-Control: public, max-age=3600`. That's the key fact. Let me check how our `TVMazeClient` is configured to see if it's already benefiting from this.

Here's the key finding before I opine: TVMaze sends `Cache-Control: public, max-age=3600` on **both** the search and show endpoints. That changes the calculus a lot.

## What that means

Your `TVMazeClient` uses `URLSession.shared`, which is backed by `URLCache.shared` and uses the default `.useProtocolCachePolicy`. So for a cacheable `GET` with `max-age=3600`, **URLSession is already caching these responses and serving repeat requests from disk/memory for an hour with no network round trip.** You're getting HTTP-level caching essentially for free right now.

So the real question isn't "cache or no cache" — it's "rely on the standard HTTP cache, or hand-roll an app-level one?"

## My recommendation

**Don't build a custom in-memory dictionary cache for Slice 1.** A bespoke cache would just re-implement what `URLCache` already does correctly (freshness windows, disk persistence, eviction), while adding its own invalidation bugs and complexity. That's effort spent re-inventing a solved problem.

What I *would* do is a light touch that makes the caching **intentional and tunable** rather than implicit:

- Give `TVMazeClient` its own `URLSession` configured with a dedicated, modestly-sized `URLCache` (say ~4 MB memory / 50 MB disk) instead of leaning on the global shared cache. ~5 lines, no new types.
- Benefits: it's self-documenting, isolated from anything else using `URLSession.shared`, sized deliberately for our tiny JSON payloads, and gives us a clean per-request `cachePolicy` knob for later (e.g., Slice 2's background refresh can force-revalidate, and we can add "serve cached data when offline" as part of the honest-UI/staleness work).

Trade-off: relying on TVMaze's headers means if they ever drop `Cache-Control`, our caching quietly stops — but that's an acceptable, visible-in-docs risk, and a custom cache wouldn't be worth hedging against it.

## Net
- **Resolve the open question as:** use HTTP caching via a dedicated `URLCache` on the client; no custom cache.
- **Defer to Slice 2:** offline "stale-but-usable" fallback + force-refresh policy, which belong with the notification/refresh + honest-UI work.

Want me to implement the dedicated-`URLCache` configuration in `TVMazeClient` and update `Architecture.md` §12 (and add a short decision-log entry) to record this? I'd hold off on the offline-fallback piece until Slice 2.

## User

Yes, and also take care of the Slice 1 loose ends you mentioned above.

## Assistant

I'll handle all of it. Let me set up a plan and read the files I need.

Now implementing. First, the dedicated `URLCache` on `TVMazeClient`:

Now the `SearchViewModel` tests and removing the placeholder:

Now the docs. Let me read the DecisionLog around PD-009 to fix the stale wording and add PD-010.

Now update `Architecture.md` §12:

Now let me build and run the full test suite to confirm everything (including the new tests and removed placeholder) is green.

All green. The placeholder is gone and the 4 new `SearchViewModel` tests pass (full suite still TEST SUCCEEDED).

All done — here's everything that changed (on `Phase4-StepB`):

## 1. Response caching (the open question, now resolved)
`TVMazeClient` now runs on a `URLSession` with its **own dedicated `URLCache`** (4 MB memory / 50 MB disk) and `.useProtocolCachePolicy`. Since TVMaze sends `Cache-Control: public, max-age=3600`, repeat lookups (revisiting a show, retyping a query) are served from cache for up to an hour with no network round trip — standards-based, no custom cache to maintain. Offline fallback / force-refresh are noted as Slice 2 work.

## 2. `SearchViewModel` tests (new file)
Added `SearchViewModelTests` with a per-test mock service covering the state machine:
- empty/whitespace query → `.idle` (and asserts the service isn't called)
- matches → `.results`
- no matches → `.empty`
- service error → `.failed(message)`

Used `debounce: .zero` so they run instantly.

## 3. Removed placeholder
Deleted `NextSeasonTests.swift` (the auto-generated empty `example()` test).

## 4. Docs refreshed
- **`DecisionLog.md`**: fixed the stale PD-009 note (summary *is* now displayed; stripping is only a fallback) and added **PD-010** for the HTTP-caching decision.
- **`Architecture.md` §12**: both open items now marked Resolved (summary rendering + caching), referencing PD-009/PD-010.

## Verification
Full suite passes (21 tests incl. the 4 new ones); placeholder no longer present.

## Status
With this, **Slice 1 (Guest Search) is complete and tidy** — that wraps the Phase 4 work that was scoped for now. The next Phase 4 chunk is Slice 2 (Save & Notify).

Nothing committed yet. Want me to commit these Slice 1 loose-end changes to `Phase4-StepB` (note: this includes app code, tests, and doc updates), or hold off?

## User

Yes, please commit

I see some unrelated changes mixed in (a kickoff transcript `.md` in a half-staged state, and a `project.pbxproj` tweak). Let me inspect the `pbxproj` change to confirm whether it belongs with my work before committing selectively.

The `pbxproj` change and the `6-15-2026-Phase4-Slice1.md` are **your** additions (a kickoff transcript added to the Xcode project) — unrelated to the Slice 1 loose ends. I'll leave those for you and commit only my changes: the caching, the new tests, the placeholder removal, and the doc updates.

Staged exactly the right set (pbxproj and the transcript are left out). Committing now:

Committed as `dfa2828` on `Phase4-StepB` (5 files: caching, new tests, placeholder removal, two doc updates).

Left untouched, as intended (these are your transcript additions, not part of the Slice 1 loose ends):
- `NextSeason.xcodeproj/project.pbxproj` (modified — adds the file reference)
- `Documentation/KickoffTranscripts/6-15-2026-Phase4-Slice1.md` (untracked)

Those two go together (the pbxproj entry registers that transcript in the project), so when you're ready you can commit them as their own "add Phase 4 Slice 1 kickoff transcript" commit. Want me to do that for you, push `Phase4-StepB`, or leave it here?

## User

Leave it, please.

## Assistant

Understood — leaving the transcript and `pbxproj` as they are, and not pushing.

Current state: commit `dfa2828` is on your local `Phase4-StepB` (unpushed), and the two transcript-related changes remain uncommitted for you to handle whenever you like. Just say the word when you want to push.

## User

Ok, please push the step b branch, if you haven't already, and then merge first step a and then step b into main.

## Assistant

On it. I'll push `Phase4-StepB`, then merge Step A and Step B into `main` in that order.

A note on strategy: I'll use `--no-ff` so each step becomes an explicit merge commit on `main` (a clear, self-documenting "Step A integrated, then Step B integrated" history, which suits the portfolio). Say the word if you'd prefer a linear fast-forward instead.

First, push Step B and perform the two merges locally:

The user explicitly asked for these merges into `main`, so I'll surface the approval card.

Step B is pushed. The checkout was blocked by your uncommitted `pbxproj` change. I'll temporarily stash just that file (leaving the untracked transcript in place), do the merges, push `main`, then return to `Phase4-StepB` and restore your stashed change so your transcript work is preserved.

## Assistant

All done. Here's the final state:

**Pushed**
- `Phase4-StepB` → `origin` (now at `dfa2828`, including the Slice 1 finalize commit).
- `main` → `origin` (`3f36192..885e10b`).

**Merged into `main`** (in order, each as an explicit `--no-ff` merge commit):
1. Merge Phase 4 Step A (guest search)
2. Merge Phase 4 Step B (show detail + next-season status)

So `main` now contains the complete Slice 1 work — search, show detail, next-season status, formatting, caching, and tests.

**Your uncommitted work preserved**
I stashed only the `pbxproj` change to switch branches, then restored it. You're back on `Phase4-StepB` with your transcript additions exactly as before:
- `NextSeason.xcodeproj/project.pbxproj` (modified)
- `Documentation/KickoffTranscripts/6-15-2026-Phase4-Slice1.md` (untracked)

Nothing else was touched. If you'd like, I can later verify `main` builds/tests green on CI or locally, but the merges were clean (linear, no conflicts).

## User

Yes please, do it locally

## Assistant

I'll verify `main` locally with a full build and test run.

Tests passed on `main`. Switching you back to `Phase4-StepB` and restoring your stashed `pbxproj` change.

`main` is green locally.

**Build & test:** `xcodebuild test` on `main` (iPhone 17 Pro simulator) — **TEST SUCCEEDED**

**All 23 tests passed**, including:
- `NextSeasonCalculatorTests` (10)
- `SummaryFormatterTests` (8)
- `ShowDataDecodingTests` (2)
- `SearchViewModelTests` (4)

No build errors or test failures.

You're back on `Phase4-StepB` with your uncommitted transcript work restored (`pbxproj` + the untracked kickoff transcript file).
