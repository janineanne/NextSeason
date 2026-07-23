# Code duplication in watchlist

## User

Please fix this code duplication found by ChatGPT:

Add is shared, but the complete track/untrack flow is still duplicated

WatchlistAdding successfully abstracts persistence, analytics, and notification-prompt arming. But each surface still orchestrates watchlist toggling separately.

## Assistant

I'll look at how `WatchlistAdding` is used and where track/untrack is still duplicated across surfaces.

I'll expand `WatchlistAdding` into a shared track/untrack toggle, then have Search and Show Detail call that instead of each orchestrating the flow.

Search and Show Detail now share one track/untrack path instead of each wiring add/remove themselves.

### What changed
- **`WatchlistAdding.toggle(...)`** — shared orchestration for undo-pending, request undoable untrack, or add (still uses `add` for the persist/analytics/prompt steps)
- **`SearchWatchlistTracking`** and **`ShowDetailViewModel`** — call `toggle` and only update local star state from the outcome
- **`ShowDetailView`** — track tap is a thin pass-through to the view model

Side benefit: tapping the search-row star during the undo window now undoes (same as detail/watchlist), instead of trying to add again.

Skills used: `swiftui-pro`, `swift-concurrency-pro`.

### What to test
- Track / untrack from search row and show detail
- Undo toast after untrack from both surfaces
- Tap star again during the undo window (should restore tracked)
- First-track notification prompt still appears when permission hasn’t been granted
