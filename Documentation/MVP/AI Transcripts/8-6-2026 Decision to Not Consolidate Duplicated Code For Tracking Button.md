# Code duplication reduction

## User

There is some code duplication between these operations:

* SearchWatchlistTracking.handleTrackButton
* ShowDetailViewModel.handleTrackButton

Can you reduce the duplication wiithout making the code more complicated or harder to read?  Or should it be left the way it is?

## Assistant

I'll locate both `handleTrackButton` implementations and compare them to see whether a shared helper would simplify things or add noise.

Checking the shared `WatchlistTracking` module and call sites for full context.

My recommendation: **leave it as is.**

The meaningful shared logic is already extracted. Both methods delegate the real work to `WatchlistTracking.toggle`, and tracked-state resolution lives in `WatchlistTrackingState`. What remains duplicated is the surface-specific orchestration around that call.

## What’s actually duplicated

Both `handleTrackButton` methods follow the same shape:

1. Guard against in-flight updates
2. Compute `shouldLockForAdd` (lock only on add, not undo)
3. Call `WatchlistTracking.toggle`
4. Switch on `ToggleOutcome`
5. Handle errors with analytics + recovery

That structure is similar, but the details differ in ways that matter:

| Concern | Search | Show Detail |
|--------|--------|-------------|
| State | `trackedShowIDs` / `updatingShowIDs` (many rows) | `isTracked` / `isUpdatingWatchlist` (single show) |
| Success | Update a set, dismiss search hint | Update a bool, sometimes refresh from repo |
| `.ignored` | Full `refresh()` | `refreshTrackedState()` |
| Errors | Silent reconcile via `refresh()` | User-facing alert + conditional recovery |
| Add failure | Refresh from persistence | Restore prior star (`wasTracked`) |

Show detail’s error path is intentionally different — it sets `watchlistActionErrorMessage` and avoids clobbering `loadState`, which search doesn’t need.

## Why further extraction would hurt readability

To dedupe further, you’d need something like a shared coordinator with several closures:

```swift
// Hypothetical — not recommended
WatchlistTracking.performToggle(
    ...
    isBlocked: { ... },
    acquireAddLock: { ... },
    releaseAddLock: { ... },
    onOutcome: { outcome in ... },
    onError: { error, context in ... }
)
```

That would hide behavior behind callbacks. To understand what happens on a search-row tap vs. a detail tap, you’d jump between a generic helper and two call sites. The current code keeps each surface’s behavior in one place, which is easier to follow and test.

You could extract tiny helpers (`shouldLockForAdd`, error-context strings), but that saves only a few lines and adds indirection for little gain.

## When it would be worth revisiting

Consider a shared helper only if:

- A third surface gets the same pattern (e.g. watchlist list rows)
- The outcome/error handling converges across surfaces
- You’re fixing a bug that must stay consistent in both places

Until then, the duplication is **parallel structure**, not copy-pasted business logic. The split between shared core (`WatchlistTracking`) and surface-specific orchestration (search vs. detail) is a reasonable place to draw the line.

**What to test:** No code changes needed. If you ever refactor, run `ShowDetailViewModelTests` and manually verify search-row star toggles (add, remove, undo pending removal, and error recovery).

