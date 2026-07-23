# Tracked state reconciliation issue

## User

Please fix this issue found by ChatGPT:

Repository-backed tracked-state reconciliation exists in two forms

Search refreshes all tracked IDs:

* SearchWatchlistTracking.refresh, lines 12–30.

Detail refreshes one show:

* ShowDetailViewModel.refreshTrackedState, lines 91–99.

These are not exact clones and should not necessarily be combined. But both manually account for persisted state versus pending undo state, and only Search currently excludes a pending removal explicitly.

That creates a conceptual inconsistency: the definition of “currently tracked” depends partly on the screen.

A more coherent abstraction would be a shared method that answers effective tracked state, considering the pending-removal coordinator

## Assistant

I'll inspect both tracked-state refresh paths and the pending-removal coordinator so we can share one effective-tracked definition.

I'll add a shared `WatchlistEffectiveTracking` helper and route both refresh paths through it so pending removals are treated the same everywhere.

Effective “tracked” state is now defined in one place, and both Search and Detail use it.

### What changed
- Added `WatchlistEffectiveTracking`: persisted ∩ not pending-removal
- `SearchWatchlistTracking.refresh` and `ShowDetailViewModel.refreshTrackedState` both call that helper
- Detail now receives `undoRemoval` on load/refresh, so it excludes pending removals the same way Search does
- Detail reconciles on any pending-removal change (not only when it clears)
- Added `WatchlistEffectiveTrackingTests` (3 tests, all passing)

Skills used: `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`

### What to test
1. Untrack from Search → star empties; Undo restores it  
2. Untrack from Detail → same  
3. Untrack on Watchlist, open Detail during the undo window → Detail star should be empty  
4. Tap Undo while Detail is open → star fills again  
5. Flip between Search and Detail during a pending removal → stars stay consistent

## User

Are you expecting the confirmation toast to transfer to the detail page, so that the removal can still be cancelled?  If so, it's not doing that.  Opening the detail page causes the toast to stay visible for just a second, then disappear with no way to cancel the removal.

## Assistant

That toast should stay available across navigation — I'll trace what clears the pending removal when Detail opens.

Yes — the toast is app-rooted and should stay usable on Detail. Watchlist’s `onDisappear` was committing the removal on push (NavigationStack hides the list), which dismisses the toast. I’ll commit only when leaving the Watchlist tab instead.

Yes — the toast is hosted at the app root and should stay available on Detail so you can still Undo/OK.

What went wrong: Watchlist committed the pending removal in `onDisappear`. Pushing Detail makes the list disappear, so that looked like “left Watchlist” and cleared the toast after a moment.

**Fix:** commit only when the selected tab actually leaves Watchlist, not on NavigationStack push.

### What to test
1. On Watchlist, untrack a show → toast appears  
2. Open that show’s Detail → toast should remain; Undo should still work  
3. Switch to Search while a removal is pending → removal should commit (toast goes away)

## User

That works, but it looks terrible;  on the detail page the toast is covering up part of the About text. I think that the toast should go away when the detail page opens, but the removal should be cancelled.  That's consistent with what happens if you remove a show from the watchlist and then remove another while the first removal is still pending.  The first removal is cancelled, because Ok wasn't tapped.

## Assistant

Opening Detail should dismiss the toast and undo the pending removal (restore the show), not keep the toast over the About text. I'll wire that into Detail’s appear/load path.

Opening Detail now dismisses the undo toast and **cancels** the pending removal (show stays tracked). Untracking from Detail itself is unchanged — the toast still appears there, since that screen is already open.

One correction on the analogy: starting a second watchlist removal does **not** cancel the first — it **commits** the first, then starts the new undo window. Detail navigation is the cancel/restore path.

### What to test
1. Untrack on Watchlist or Search → toast shows  
2. Open Detail → toast goes away; show is tracked again  
3. On Detail, untrack → toast still appears and Undo/OK still work

## User

That seems to be working.

## Assistant

Good. Effective tracked state is shared, and opening Detail cancels any pending undo toast instead of leaving it over the content.
