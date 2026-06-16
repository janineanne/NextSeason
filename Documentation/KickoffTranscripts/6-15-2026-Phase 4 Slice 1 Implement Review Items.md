
# NextSeason project overview

## User

I asked ChatGPT to review the code and it came up with these suggestions:

1.
Docs say:
NextSeason/<version> (contact)
Code uses:
NextSeason/<version>

Not urgent, but I’d either update the code later or soften the documentation.

2.
otential date bug in NextSeasonCalculator.
This line may mark a season as ended too early on its actual end date:
let hasEnded = latest.endDate.map { $0 < now } ?? false
Because endDate is parsed as midnight UTC, a season ending “today” may count as ended for most of that day. I’d add a test for “season ends today” and probably compare date-only values instead of exact Date.

3.
I’d add tests for:
season end date is today
future undated season while current season is airing
nextepisode with no airdate
empty HTML summary / whitespace-only summary

Please make these changes, or let me know your reasons if you object.

## Assistant

I'll work through ChatGPT's review items: find the User-Agent doc mismatch, fix the end-date comparison in `NextSeasonCalculator`, and add the missing tests.

### Tool Ripgrep Raw Search

```
{"pattern":"User-Agent|user.?agent|NextSeason/","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"*.{md,swift}","caseInsensitive":false,"multiline":false,"toolCallId":"tool_5020e937-ca2d-4bd7-97d0-35990e63c2b","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/TVMazeDate.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/NextSeasonCalculatorTests.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/SummaryFormatterTests.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":20,"limit":15}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Architecture.md","offset":138,"limit":10}
```

## Assistant

I'll add UTC date-only comparison helpers, fix the calculator's end-date logic, soften the User-Agent docs, and add the missing tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Next: `SummaryFormatter` displayable-content helper, update `ShowDetailView`, and add the new tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":95,"limit":35}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

All three review items are addressed. Here's what changed and why:

## 1. User-Agent documentation
**Decision:** Soften the docs to match the code (not add a fake contact string).

Updated `TVMazeResearch.md` to say `NextSeason/<version>` with a note that contact info may be added later. `Architecture.md` already matched the code.

## 2. Date comparison bug (real issue — fixed)
ChatGPT was right. TVMaze dates are calendar days at midnight UTC, but `Date.now` includes time of day. So on a season's **last day**, `endDate < now` could be true from mid-morning onward and wrongly mark the season as ended.

**Fix:** Added UTC date-only helpers on `TVMazeDate` (`isOnOrBefore`, `isBefore`, `isAfter`) and updated `NextSeasonCalculator` to use them for premiere, end, and scheduled-date checks. A season now counts as ended only when its end **calendar day** is before today's.

## 3. New tests (all passing)
**NextSeasonCalculator:**
- Season end date is today → still `.airing` (uses noon on the end date — this would have failed before the fix)
- Undated future season while current season is airing → `.airing`, not `.announcedUndated`
- Next episode with no airdate → `.airing(season:)`

**SummaryFormatter:**
- Empty HTML → no displayable content
- Whitespace-only HTML → no displayable content

Also wired `SummaryFormatter.hasDisplayableContent(_:)` into `ShowDetailView` so whitespace-only summaries don't show an empty "About" block (same behavior as a missing summary).

**Test run:** all 27 tests pass.

Nothing committed yet — say the word if you want these on `main`.

## User

Please make a branch called Phase-4-Review-Items and commit these changes there.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Unspecified

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason","branchName":"Phase-4-Review-Items"}
```

## Assistant

Done. Created branch **`Phase-4-Review-Items`** and committed as `d8fee6c`:

**Address Phase 4 review items: date-only logic and tests**

7 files changed:
- UTC date-only comparison helpers + calculator fix
- New calculator and summary formatter tests
- Whitespace-only summary handling in `ShowDetailView`
- User-Agent doc alignment in `TVMazeResearch.md`

You're on `Phase-4-Review-Items` with a clean working tree. Not pushed yet — let me know if you'd like that.

## User

One other thing from ChatGPT:  NextSeasonCalculator treats an undated nextEpisode in a new season as .airing. That’s reasonable, but slightly optimistic.  Should we fix this too?

## Assistant

Let me trace the current logic and what each status actually tells the user.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/NextSeasonStatus+Display.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"nextepisode|next episode|\\.airing","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","caseInsensitive":false,"multiline":false,"toolCallId":"tool_c2b56038-ef00-4f3d-a2b9-9ae4c1468f8","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":140,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/TVMazeResearch.md","offset":165,"limit":30}
```

## Assistant

ChatGPT has a fair point, but I wouldn't call it a **bug** — it's a **wording/semantics** choice. Whether to change it depends on what you want "Currently showing Season X" to mean.

## What the code does today

Step 2 only runs when `nextepisode.season` is **higher than the latest season with a past premiere**. In other words: TVMaze is pointing at a **new** season, not the one you're already in.

Then:

- future `airdate` → `.scheduled`
- **no `airdate`** (or not in the future) → `.airing`

So `.airing` here really means: *"We know the next episode belongs to season N, but we don't have a date."* The UI turns that into **"Currently showing Season N"** — which does sound like episodes are on air right now.

## Why that's optimistic

TVMaze's `nextepisode` embed means *there is an upcoming episode record*, not necessarily that the season is broadcasting today. With no `airdate`, it might be:

- a TBA placeholder for a new season,
- data still being filled in,
- imminent but not yet premiered.

**"Currently showing Season X"** overstates that. **"Season X announced — date to be confirmed"** (`.announcedUndated`) is more accurate: we know season X is coming, but we can't claim it's on air.

## Why the current choice isn't crazy

The signal *is* stronger than a bare undated season row — TVMaze has linked a **next episode** to that season. Some teams would treat that as "new season is starting / underway" and prefer something active over `.announcedUndated`.

The problem is mostly the **`.airing` label**, not the detection logic.

## My recommendation

**Yes, I'd change it** — but narrowly:

When `nextepisode.season > latestAired` and there's **no future airdate**, return **`.announcedUndated(season:)`** instead of **`.airing(season:)`**.

Keep **`.airing`** for cases where you have real evidence the season is on air:

- latest season has premiered and hasn't ended (step 3), or
- `nextepisode` has a concrete `airdate` that's today or in the past (premiere day / already started).

That aligns with your ProductSpec labels and the "honest UI" principle from PD-008 — don't tell users a season is showing when you only know it's been announced.

**One-line rule:** *No date → don't say "currently showing."*

## What I'd update if you want this

1. Change the step 2 fallback from `.airing` → `.announcedUndated`
2. Update the test `nextEpisodeWithNoAirdate` accordingly
3. Optionally add a test: undated `nextepisode` **with** a matching undated season row → still `.announcedUndated` (same outcome, clearer intent)
4. Tweak `TVMazeResearch.md` §4 table so `airing` isn't tied to bare `nextepisode.season` without a date

No new enum case needed — `.announcedUndated` already fits.

Want me to make that change on `Phase-4-Review-Items`?

## User

Yes

## Assistant

Updating the calculator so an undated `nextEpisode` maps to `.announcedUndated`, then adjusting tests and docs.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Done. Here's the updated rule:

**When `nextepisode.season` points at a new season:**
- **Future `airdate`** → `.scheduled`
- **`airdate` on or before today** → `.airing` (season is actually underway)
- **No `airdate`** → `.announcedUndated` (was `.airing`)

So we no longer say "Currently showing Season X" without a concrete date.

**Also updated:**
- `nextEpisodeWithNoAirdate` test — now expects `.announcedUndated(season: 2)`
- New test — undated `nextepisode` plus matching undated season row → still `.announcedUndated`
- `TVMazeResearch.md` §4 — classification table reflects the new logic

All 28 tests pass.

These changes are on `Phase-4-Review-Items` but **not committed yet** (they sit on top of `d8fee6c`). Want me to commit them to that branch?

## User

Yes

### Tool Run Terminal Command V2

## Assistant

I'll commit only the review-item code changes and leave your kickoff transcripts and `pbxproj` edits out.
