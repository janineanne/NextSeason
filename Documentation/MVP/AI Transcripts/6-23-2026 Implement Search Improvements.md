# Search fallback UX implementation

## User

In Release Readiness.md, please implement the Search Fallback UX section under Search Quality Improvements.

### Tool Glob File Search

```
{"globPattern":"**/Release Readiness.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Release Readiness.md"}
```

## Assistant

I'll explore the search feature to understand how the search view and empty state currently work.

### Tool Glob File Search

```
{"globPattern":"**/*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchViewModel.swift"}
```

## Assistant

Let me look at the accessibility IDs, ShowRow, and the attribution inset helper to match existing patterns.

### Tool Ripgrep Raw Search

```
{"pattern":"enum Search|idlePrompt|AccessibilityID|uiTestMarker|tvmazeAttributionInset","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_vrtx_01FoTRR1yxGU8Leu8npLZqfm","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/UITestingConfiguration.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"empty|No Results|emptyState|search\\.|noResults","glob":"**/*UITests/*.swift","outputMode":"content","caseInsensitive":true,"multiline":false,"toolCallId":"toolu_vrtx_01XmgtqkNBn8Ht2LUHg8UmZN","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift"}
```

## Assistant

I have enough context. I'll implement the Search Fallback UX by replacing the bare "no results" empty state with the helpful guidance copy from the doc, and add a stable accessibility identifier for it (matching existing patterns).

First, add the accessibility ID.

### Tool Edit File V2

## Assistant

Now replace the `.empty` case with the helpful fallback state.

### Tool Edit File V2

## Assistant

Now let me mark the section as implemented in the doc, matching the existing `Status:` convention used elsewhere (e.g. the Notifications section).

### Tool Edit File V2

## Assistant

Let me verify the final SearchView reads correctly.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":34,"limit":45}
```

## Assistant

I've implemented the **Search Fallback UX** section.

## Intended change (as required by the safety rule)
The doc asks that when a search returns nothing, the app should *not* imply the show doesn't exist (TVMaze caps results at 10 with no pagination). So I replaced the generic "no results" state with the guidance copy from the doc.

## What changed
- `NextSeason/Features/Search/SearchView.swift`: The `.empty` case previously used `ContentUnavailableView.search(text:)` (which shows "No Results for …"). It now shows a custom `ContentUnavailableView` titled **"Can't Find Your Show?"** with the doc's suggested guidance: try a more specific title (e.g. "Star Trek Voyager" instead of "Star"), or include a year or subtitle. A short comment explains the API-limitation rationale.
- `NextSeason/Utilities/UITestingConfiguration.swift`: Added `AccessibilityID.Search.noResults` and applied it via the existing `uiTestMarker` helper, consistent with the idle prompt and watchlist empty state.
- `Documentation/MVP/Release Readiness.md`: Added a `Status: Implemented.` note to the section, matching the convention used by the Notifications section.

No view-model logic, architecture, or dependencies changed — the `.empty` state itself is unchanged, only its presentation. This keeps the diff small and reviewable.

## What to test
- Search for a nonsense string (e.g. "zzzzzzx") → you should see the new "Can't Find Your Show?" guidance instead of "No Results".
- Confirm the idle prompt, loading, results, and failure states still behave as before.
- The SwiftUI preview in `SearchView.swift` still renders.
- If you later add a UI test for empty search, it can target `search.noResults`.

One note: I kept this scoped to the empty state per the section's wording ("provide a helpful empty/failure state"). If you'd also like a "don't see your show?" hint shown *below* a full 10-result list (the other consequence of the 10-result cap), I can add that as a follow-up — let me know.

## User

Is there a trademark or copyright issue with using "Star Trek: Voyager" in the no results text?

## Assistant

Short answer: it's low risk, but it's avoidable risk, and I'd lean toward changing it. (I'm not a lawyer, so treat this as practical product judgment, not legal advice.)

The nuances:

**Why it's probably fine**
- Using a real title purely to *illustrate how to search* is classic nominative/descriptive use — you're referring to the show, not branding your app with it. This is the same reason it's fine that users can search for and see "Star Trek: Voyager" results in the app at all (sourced from TVMaze).
- You're not implying endorsement, affiliation, or selling anything under that name.

**Why I'd still change it**
- It's hardcoded marketing-adjacent copy (an example in your own UI text), which reads slightly more like "using the brand" than dynamically displaying API data. It's a needless distinction to have to defend.
- "Star Trek" is an aggressively protected franchise (Paramount/CBS). Even with a strong fair-use position, the cost of just picking a neutral example is zero.
- An invented example communicates the *concept* ("be more specific, add a subtitle/year") just as well without naming anyone's IP.

**Recommended swap**
Use a generic, non-trademark example that still demonstrates "specific title + subtitle/year," e.g.:

> Try a more specific title (for example, add a subtitle or the year), or check the spelling.

Or with a clearly generic placeholder:

> Try a more specific title — for example, include a subtitle or year instead of just one word.

Want me to update the copy in `SearchView.swift` (and the matching example in `Release Readiness.md`) to a neutral version? If so, I can also keep a concrete-but-generic example if you prefer specificity over abstraction.

## User

What would a concrete-but-generic example look like?

## Assistant

Here are a few options, from most abstract to most concrete:

**Option A — concrete pattern, no invented title**

> Try a more specific title instead of a single word — add a subtitle or the year (for example, "Title: Subtitle" or "Title 2019").

This is concrete about *what to do* and uses a placeholder ("Title") rather than naming anything.

**Option B — invented title**

> Try a more specific title (for example, "Harbor Lights: Season One" instead of "Harbor"), or include a year or subtitle.

This mirrors your original structure exactly, just with a made-up show name.

The catch with Option B: any plausible-sounding title risks accidentally being a real show somewhere in the TVMaze catalog, which reintroduces (a smaller version of) the same concern. You can reduce that by choosing something deliberately bland/unlikely, but you can't fully guarantee it.

**My recommendation:** Option A. It keeps the "concrete" feel you liked — it still shows the *shape* of a better query ("Title: Subtitle", "Title 2019") — without betting on whether an invented name collides with a real one. It also ages well: no IP to revisit later.

Want me to apply Option A to `SearchView.swift` and update the example in `Release Readiness.md` to match?

## User

yes

## Assistant

I'll update both the UI copy and the doc example to Option A.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Done. Both now use the neutral, concrete-but-generic Option A copy:

- `SearchView.swift` — the no-results description now reads: "Try a more specific title instead of a single word — add a subtitle or the year (for example, "Title: Subtitle" or "Title 2019")."
- `Release Readiness.md` — the suggested copy block matches.

The title ("Can't Find Your Show?") and the `search.noResults` accessibility marker are unchanged. No real IP is referenced anymore.

To verify: run a search that returns nothing and confirm the new guidance text renders.
