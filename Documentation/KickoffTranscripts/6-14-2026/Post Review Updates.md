# NextSeason project overview

## User

Something we haven't considered is how reliable TVMaze is.  An app like this is only as good as its data.  Can you investigate this and add your findings to TVMazeResearch?

## Assistant

Good call — data reliability is an existential risk for an app whose entire value is "trust me about when the next season drops." Let me investigate TVMaze's data sourcing, accuracy, freshness, and service availability, then write up findings.

### Tool Web Search

```
{"searchTerm":"TVMaze data quality crowd-sourced user contributed how is data maintained accuracy","toolCallId":"toolu_vrtx_01QamkGdyw3HDmbzWpc1MeS4"}
```

### Tool Web Search

```
{"searchTerm":"TVMaze API uptime reliability status page outages 2026","toolCallId":"toolu_vrtx_01UP1mT28jmpZbdsDyK9R1WR"}
```

### Tool Web Search

```
{"searchTerm":"TVMaze vs TMDB vs TheTVDB data accuracy TV show season dates comparison","toolCallId":"toolu_vrtx_01U3osx6R8gZ27KjiuHXkmNc"}
```

## Assistant

I have solid findings from multiple angles. Let me add a reliability section to `TVMazeResearch.md`. First I'll renumber the existing final section, then insert the new one before it.

### Tool Edit File V2

## Assistant

Let me review the now-redundant items in the old "Open questions / risks" list and tighten them.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":300,"limit":30}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":323,"limit":15}
```

## Assistant

The timeliness item is now covered in §6.3, so I'll point it there instead of repeating.

### Tool Edit File V2

## Assistant

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

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Architecture.md","offset":258,"limit":34}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Architecture.md","offset":284,"limit":28}
```

### Tool Edit File V2

## Assistant

Now I'll add a row to the decisions table in §11 and a decision-log entry.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Done. The reliability mitigations are now reflected in all three places:

- **`Architecture.md` §8** — added a "Reliability-driven notification rules" subsection (debounce/confirm before notifying, dedup signature, graceful `404`/`429`/`5xx` handling, honest "last updated" + attribution UI).
- **`Architecture.md` §11** — added a decisions-table row for debounced, date-backed notifications, referencing PD-008.
- **`DecisionLog.md`** — added **PD-008** capturing the decision and its rationale, linking back to the `TVMazeResearch.md` §6 findings and the `TVMazeService` provider-swap contingency.

These remain documentation-only; nothing will be built until Slice 2, and no app code was touched.

