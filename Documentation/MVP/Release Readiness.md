# NextSeason - Release Readiness

## Purpose

This document tracks the work required before NextSeason is shared publicly, linked from a resume, or distributed to beta testers.

The goal is not to add major new functionality. The goal is to ensure the application feels professional, understandable, and reliable.

---

# Release Criteria

Before sharing the application with external users:

- Core functionality is complete.
- No known critical defects exist.
- Basic usability issues have been addressed.
- Application behavior is predictable.
- The app reflects professional software engineering practices.

---

# High Priority

## Search Quality Improvements

### Goal

Users should be able to find the show they are looking for even when search terms are imperfect.

### Potential Improvements

- Ignore punctuation differences.
- Ignore common articles ("The", "A").
- Improve result ranking.
- Handle common abbreviations.
- Handle partial title searches.
- Improve matching of alternate show names.

### TVMaze Coverage Summary

The `/search/shows` endpoint is backed by Elasticsearch with a fuzzy algorithm
(fuzziness 2) and ranks results by relevance (fuzzy closeness + popularity weight
+ exact-match boost), including matches against alternate (AKA) names. Most of the
improvements above are therefore already handled server-side, so the remaining
app-side work is narrow:

- Already handled by TVMaze: punctuation differences, partial title searches,
 alternate (AKA) name matching, and relevance/popularity ranking.
- Mostly covered indirectly (low value): ignoring common articles — partial
 matching already returns e.g. "The Office" for "office".
- Real app-side opportunities: common abbreviation / acronym aliasing (e.g.
 "GoT", "SVU"), which TVMaze does not expand, and app-purpose result ordering
 (de-emphasize ended shows, surface shows with a known/upcoming next season).
 
### Search Fallback UX

TVMaze's public search API returns a maximum of 10 results with no pagination,
even though the website exposes additional pages.

If a user cannot find the desired show, provide a helpful empty/failure state
instead of implying that no matching show exists.

Potential copy:

> Can't find your show?
>
> Try a more specific title instead of a single word — add a subtitle or the
> year (for example, "Title: Subtitle" or "Title 2019").

This is a low-cost usability improvement that addresses the API limitation
without adding significant complexity.

Validate during beta whether search is actually a pain point before investing
further.

Status: Implemented. The no-results state in `SearchView` now shows guidance
("Can't Find Your Show?") encouraging a more specific query instead of the
generic "no results" message.

### Success Criteria

Most users can successfully find and track a show without needing multiple search attempts.

---

## Watchlist Discoverability

### Goal

New users should immediately understand how to track a show.

### Questions

- Is the Track button obvious?
- Is it clear when a show is already tracked?
- Is it obvious how to remove a show?
- Is it obvious what the app does?

### Implemented Improvements
∫
**Watchlist tab**

- Actionable empty state with a prominent "Find a Show" button that switches to the Search tab at root (clears stale search navigation via `showSearchRoot()`).
- Edit button in the toolbar when the watchlist has shows; exposes delete controls (swipe-to-delete still works).
- Empty-state overlay pattern keeps the list mounted when empty to avoid a UICollectionView crash on last delete.
- Edit mode resets when the last show is deleted (no stuck edit mode).

**Search tab**

- Tracked badge — filled yellow star on search rows for already-tracked shows.
- Inline track button — star button on each search row to track/untrack without opening detail.
- Notification prompts when tracking from a search row (same behavior as show detail).

**Show detail**

- Immediate tracked state at navigation time so the Track button shows the correct state on the first frame.
- `refreshTrackedState` on reappear reconciles if the watchlist changed elsewhere.

### Bug Fixes

- Deleting the last watchlist show no longer crashes.
- "Find a Show" no longer lands on a stale detail page from a prior search session.
- Detail Track button no longer shows stale "Tracking" after removal elsewhere.

Status: Implemented. UI and unit tests cover track-from-search-row, Find a Show navigation, edit-delete-last-show exiting edit mode, and `showSearchRoot()` on `AppNavigationCoordinator`.

### Remaining Opportunities

- Improved onboarding copy.
- Welcome screen / first-run guidance (see First-Run Experience).

### Success Criteria

Users can find, track, and remove shows without confusion. Tracked state is visible and consistent across Search, detail, and Watchlist.

---

## Visual Polish

### Goal

The application should feel intentional and complete.

### Potential Improvements

- App-wide color palette.
- Consistent spacing.
- Improved typography hierarchy.
- Better loading states.
- Better empty states.
- Refined dark mode appearance.
- Final app icon.

### Success Criteria

Users describe the app as "finished" rather than "a prototype."

---

# Medium Priority

## First-Run Experience

### Goal

Help users understand the app without instructions.

### Potential Improvements

- Welcome screen.
- Brief explanation of purpose.
- Suggested first search.
- Guidance when watchlist is empty.

---

## Accessibility Review

### Verify

- Dynamic Type support.
- VoiceOver navigation.
- Button labeling.
- Color contrast.
- Focus order.

---

## Analytics Foundation

### Goal

Collect enough information to guide future product decisions.

### Suggested Metrics

- Searches performed.
- Search result counts.
- Search-to-track conversion.
- Watchlist additions.
- Watchlist removals.
- Notification opens.

---

## Feedback Mechanism

### Goal

Make it easy for beta users to report issues.

### Options

- Email feedback link.
- Report incorrect data action.
- Simple feedback form.

---

# Beta Testing

## Initial Test Group

Target 5-10 users.

Prefer:

- Non-technical users.
- Frequent television viewers.
- iPhone users of varying experience levels.

---

## Validation Tasks

Ask testers to:

1. Search for a favorite show.
2. Add a show to the watchlist.
3. Remove a show from the watchlist.
4. Understand recent updates.
5. Enable notifications.

Observe without providing instructions.

---

## Success Criteria

Users can complete common tasks without assistance.

Repeated confusion should generate roadmap items.

---

# Technical Validation

## Notifications

Verify:

- Permission request flow.
- Background delivery.
- Notification tap routing.
- Duplicate suppression.
- Cold-launch behavior.

Status: Implemented. Continue validation during beta.

---

## Data Accuracy

Verify:

- Search results are relevant.
- Season information is accurate.
- Change detection behaves as expected.

---

# Portfolio Readiness

Before linking from resume:

- README updated.
- Screenshots available.
- Architecture documented.
- AI-assisted development process documented.
- No known critical issues.

The application should demonstrate product thinking, engineering judgment, and effective AI collaboration.
