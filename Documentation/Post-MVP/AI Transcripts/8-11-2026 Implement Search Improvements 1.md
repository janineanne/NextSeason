# TheTVDB search integration

## User

Pleas implement using TheTVDB.com's API [REDACTED TVDB API KEY] for searches, paginated with 10 results per page; retain TVMaze as NextSeason’s canonical show/season provider; resolve a selected TheTVDB result to TVMaze before entering the existing show-detail/watchlist flow.  See https://www.thetvdb.com/api-information#attribution for attribution requirements and implement them on the search page (the data everywhere else should still be coming from TVMaze).

## Assistant

I'll implement TheTVDB-powered search with TVMaze resolution and attribution. First I'll read the Swift skills and inspect the current search/TVMaze flow.

Next I'll check TheTVDB API auth/search docs and read the current search implementation files.

I'll request approval to probe the live APIs, and meanwhile continue mapping the search/selection flow in code.

I'll add TheTVDB networking and DTOs first, then rework search to paginate through TVDB and resolve selections to TVMaze.

Next I'll rework the search view model and update every `TVMazeService` mock for the new lookup methods.

Wiring services through the app and updating stubs, tests, and copy next.

Default MainActor isolation is blocking TheTVDB config defaults in the actor — marking that configuration `nonisolated`.

I'll add a quiet background prefetch of TVMaze IDs so watchlist stars stay accurate on search results without blocking the UI.

Search now uses TheTVDB (10 per page); selecting or tracking a result resolves to TVMaze before the existing detail/watchlist path. Skills used: `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`.

### Architecture
- **Search:** TheTVDB v4 (`/login` → JWT, then `/search?type=series&limit=10&offset=…`)
- **Canonical data:** Still TVMaze for detail, watchlist, refresh
- **Handoff:** On open/track → `GET /lookup/shows?thetvdb=` (IMDb fallback) → full TVMaze show → existing flow

### Notable pieces
- `TheTVDBClient` / `TheTVDBService` + DTOs/domain `TVDBSearchResult`
- `SearchViewModel` pagination + resolve cache + background id prefetch (for stars)
- Search attribution: sample TheTVDB copy + link to [thetvdb.com](https://www.thetvdb.com/) (detail/watchlist still credit TVMaze)
- Removed the old “top 10 / search on TVMaze” footer; **Load More Results** instead
- API key in `TheTVDBConfiguration.swift`

### What to test
1. Search “Severance” / “Star” — results + Load More
2. Open a result → detail still TVMaze-backed
3. Track from search row and from detail
4. Attribution on search loading/results footer
5. Empty / failure / Try an Example
6. A TheTVDB-only title that isn’t on TVMaze → clear error alert

## User

This is looking good!  A couple more things:
- I think the TVDB attribution is supposed to include their logo, which is on the attribution page on their website.  Please add it.
- Please comment this code as thoroughly as we have done in the rest of the codebase.

## Assistant

I'll pull TheTVDB's attribution logo guidance and match the project's existing attribution/commenting style.

I'll bundle both official attribution logos (light/dark) and add comments to match the rest of the codebase.

Logo assets are in place (light/dark). Updating the attribution view and adding thorough comments across the TheTVDB code.

Done. Two changes:

### Logo
Bundled TheTVDB’s official attribution marks from their API page into `TheTVDBLogo.imageset`:
- Light: `logo2.png`
- Dark: `logo1.png`

`TheTVDBAttributionView` now shows the logo plus their sample copy, all linked to TheTVDB.com (same pattern as their sample block).

### Comments
Added the same style of file/API/flow comments used elsewhere across the TheTVDB client, config, DTOs/mapping, search VM, load-more footer, attribution view, TVMaze lookup bridge, and preview stubs.

**What to check:** Search loading/results footer — logo readable in light and dark, tap opens TheTVDB.com.

## User

That's not quite what I meant with the attribution. Something lkke this, which is the sample on their webpage:

## Assistant

I'll restyle the attribution to match their sample banner: dark teal bar, logo left, copy right.

Checking how the attribution sits in the list footer so the banner layout isn't clipped.

Updated to match their sample banner: dark teal chip (`#365658`), logo on the left, sample copy on the right, thin dark border, whole banner links to `/subscribe`.

**What to check:** Search results/loading footer — should look like their sample chip; tap should open TheTVDB’s subscribe page.

## User

That's the right layout, but I didn't mean for you to copy the colors, too (my fault, I wasn't clear).  You can go back to the colors you were using before, but keep the layout like this

## Assistant

I'll keep the logo-left / text-right layout and restore the app’s secondary text styling (no teal banner).

Updated: same horizontal layout (logo + copy), but back to the app’s secondary text style with no teal chip. The logo again adapts for light/dark.

## User

Much better. One more thing - can you make "TheTVDB" in the text look like a link, so people know they can tap on the view to go to their site?

## Assistant

I'll style “TheTVDB” with accent + underline so it reads as the tappable link.

“TheTVDB” is now accent-colored and underlined so it reads as a link; the whole attribution row still opens their site.

