# Watchlist Insert Highlight

## User

Please add sections to the Watchlist to group the shows in this order with these section titles:
1. Airing Now
2. Coming Soon
3. Waiting for a Date
4. Ended
5. Unknown

Let me know if you need a definition of what these titles mean.

Any section that has no shows in it should disappear completely;  there should be no empty sections.  All sections should be collapsible.

## Assistant

I'll check how watchlist status is modeled today so we can map those groups before asking for definitions.

Existing `NextSeasonStatus` maps cleanly to those titles, so I’ll use that and implement collapsible, hide-when-empty sections.

Updating the watchlist UI to use collapsible status sections.

Fixing the incomplete test helper so the search-grouping test uses the repository correctly.

Checking whether

`Section(isExpanded:)` works with the app’s plain list style — if not, I’ll use a custom collapsible header.

Watchlist shows are now grouped into collapsible status sections. Empty sections are omitted.

I used the existing `NextSeasonStatus` cases — no new product definitions needed unless you want different boundaries:

| Section | Status |
|---|---|
| Airing Now | Currently airing |
| Coming Soon | Future premiere date known |
| Waiting for a Date | Season announced without a date, or returning with nothing announced yet |
| Ended | Show has ended |
| Unknown | Not enough information |

Coming Soon is sorted by premiere date (soonest first). Other sections keep the current newest-added order. Tap a section header to collapse/expand it.

**What to test:** Track shows in a few different statuses, confirm only non-empty sections appear, collapse/expand works, and search still filters correctly across sections.

## User

Sorting Coming Soon by premiere date is good, cut I'd like to sort the rest of the sections alphabetically, like this:
    * Scroll so the insertion point is visible.
    * Insert the row with animation.
    * Briefly highlight it (a subtle background tint fading out over ~1 second is enough).

## Assistant

Alphabetical sorting for the other sections is clear. The three bullets after “like this” look like a different insert/highlight feature — I’ll sort first, then confirm whether you meant those UX steps too.

Coming Soon still sorts by premiere date; every other section now sorts alphabetically by show name (case- and diacritic-insensitive).

The three bullets after “like this” (scroll to insertion point, animated insert, brief highlight) don’t sound like sorting — did those get pasted by mistake, or do you want that behavior when a show is added to the watchlist?

## User

I want that behvior, inserting the row into the correct alphabetical place in the list.

## Assistant

I'll trace how shows get added to the watchlist, then wire up scroll-to-row, animated insert, and a brief highlight at the correct sorted position.

I'll queue newly added shows, then on Watchlist reveal them at the sorted position with scroll, insert animation, and a short highlight.

Fixing the insertion detection bug, then updating WatchlistView.

Revealing only when the Watchlist tab is visible, and using a scroll target so we can scroll without holding a `ScrollViewProxy` across reloads.

Holding the new row out of the list until reveal so we don't get a flash before the insert animation.

When a show is added, the Watchlist now inserts it at its sorted position with scroll and a brief highlight.

**Behavior**
- Add from Search or Show Detail queues the new show
- When the Watchlist tab is visible (or when you switch to it), the row inserts with animation in the right section/order, that section expands if needed, the list scrolls to it, and an accent tint fades out over ~1 second
- Reduce Motion shortens the highlight and skips scroll animation

**What to test**
1. Track a show from Search, then open Watchlist — it should animate in at the alphabetical (or Coming Soon date) spot with highlight
2. With a long list, add a show that belongs mid-list and confirm it scrolls into view
3. Collapse a section, add a show that belongs there, and confirm the section opens for the insert

## User

I don't think I described this very well.  It should be something like this:

* Insertion point visible?
    * Animate insertion + highlight.
* Insertion point off-screen?
    * Scroll to insertion point.
    * Animate insertion.
    * Highlight.

If the watchlist isn't visible when the show is added, it should just be added in the correct place without any scrolling or highlighting.

## Assistant

I'll simplify so scroll/highlight only run when Watchlist is already visible; off-tab adds just land silently in sorted order.

Updating so animation/scroll/highlight only run when the Watchlist list is on screen; off-tab adds stay silent.

Updated to match that behavior:

- **Watchlist list on-screen, insertion point visible** → animate insert + highlight (no scroll)
- **Watchlist list on-screen, insertion point off-screen** → scroll to the spot, then animate insert + highlight
- **Watchlist not visible** (other tab, or Show Detail covering the list) → show is added in sorted order quietly — no scroll, no highlight, no delayed reveal when you come back

**What to test:** Add from Search, then open Watchlist — the show should already be in place with no animation. Animated insert/highlight only applies when the list itself is visible at add time.

## User

Since it's not possible to add a new show with the watchlist visible, please remove everything related to visible insertion of a new show.  Just do it quietly.

## Assistant

I'll strip out the visible-insertion path (scroll, highlight, pending insert) so adds just land quietly in sorted order.

Removed the visible-insertion path. Adds now just reload the watchlist and land quietly in the correct sorted section — no scroll, highlight, or insert animation.
