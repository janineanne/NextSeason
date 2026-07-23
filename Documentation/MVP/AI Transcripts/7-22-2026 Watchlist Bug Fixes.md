# Real Housewives of Atlanta bug

## User

When I search for The Real Housewives of Atlanta, the search row says "Ongoing series". When I look at the show detail, it says "Currently showing Season 17". But when I put it on the watchlist and look at it from there, it says "Returing - no next season announced yet".  This appears to be a bug - is it?

## Assistant

I'll check how status copy is derived in search, show detail, and the watchlist — inconsistent messaging for the same show would indicate a bug.

There's prior discussion of similar wording — I'll compare how detail and watchlist compute next-season status for the same show.

Checking whether search-track saves incomplete season data, and what TVMaze reports for this show.

TVMaze confirms Season 17 is still airing — checking whether tracking from search persists incomplete status.

Yes — the watchlist line is wrong for this show.

TVMaze currently has Season 17 premiered `2026-04-05`, ending `2026-08-23`, with a next episode on `2026-07-26`. Detail is correct: **Currently showing Season 17**.

What’s going on:

| Surface | What it shows | Source |
|---|---|---|
| Search | “Ongoing series” | TVMaze `status` only (`Running`) — intentional |
| Detail | “Currently showing Season 17” | Fresh `NextSeasonCalculator` with seasons + next episode |
| Watchlist | “Returning — no next season announced yet” | Cached `TrackedShow.nextSeason` from when it was saved |

Search’s “Ongoing series” vs detail’s season line is fine — different fields on purpose. Detail vs watchlist should match, and they don’t.

The bug: tracking often saves a search-result `Show` with **no seasons**. The calculator then falls through to `.returningNoSeasonYet` for any running show. That wrong snapshot sticks on the watchlist until a refresh actually re-fetches the show (and incremental refresh can skip it if TVMaze hasn’t flagged an update).

So for RHOA, watchlist should say the same thing as detail. Happy to fix by fetching full show data before computing `nextSeason` on add (and/or forcing a refresh after track).

## User

Yes, fix please

## Assistant

I'll fix add-to-watchlist so we always compute `nextSeason` from a full show payload (seasons + next episode), not the search stub.

Intended change: before persisting a track, fetch the full show when seasons are missing (search stubs), then compute `nextSeason` from that payload.

Updating tests and checking for any remaining call sites.

Tests passed. Making the helper private, then verifying ShowDetail tests still compile.

Fixed. Tracking now loads full show details when the search stub has no seasons, so watchlist `nextSeason` matches detail.

**What changed**
- `WatchlistTracking.add` fetches `/shows/:id` when `seasons` is empty before saving
- Wired `tvMaze` through search + detail track paths
- Tests cover search-stub → airing status, and skip-fetch when seasons already exist

**What to test**
1. Remove RHOA from the watchlist (or pull to refresh — that forces a re-fetch and should also fix the existing row)
2. Track it again from search (star on the row)
3. Watchlist should show **Currently showing Season 17**, same as detail

Skills used: `swift-concurrency-pro`, `swift-testing-pro`

## User

Removing the show and adding it again updated the status, but pull-to-refresh did not. Another bug?

## Assistant

Pull-to-refresh should force a full re-fetch — I'll check why it left the stale status in place.

I'll add a regression test for force-refresh correcting stale status, then trace why pull-to-refresh wouldn't apply that update in the UI.

There are uncommitted watchlist changes — checking whether those broke pull-to-refresh.

Force refresh corrects status in unit tests — the likely issue is incremental refresh skipping shows when TVMaze’s `updated` timestamp hasn’t changed, so a bad search-track snapshot never heals. Hardening refresh to re-check those cases, and moving `.refreshable` onto the List.

Updating tests for the new recheck behavior, and moving `.refreshable` onto the List.

Yes — related bug.

Refresh only re-fetched a show when TVMaze’s `updated` timestamp moved. After a search-track, that epoch was already current, so the wrong **Returning** snapshot stayed put. Force refresh *should* have rebuilt it (and does in unit tests); automatic refresh never would.

**What I changed**
- Refresh now also re-checks `.returningNoSeasonYet`, `.airing`, and `.scheduled` even when TVMaze reports no update (calendar + stale-snapshot heal)
- Moved pull-to-refresh onto the `List` so the gesture is more reliable with searchable
- Cancellation during a show fetch no longer gets swallowed as a soft failure

**What to test**
1. Track a show from search again (or use one still stuck on Returning)
2. Pull to refresh on Watchlist — status should match detail (and may move section, e.g. Waiting → Airing Now)
3. Or leave the app and come back — foreground refresh should heal Returning snapshots too

## User

Now that the first bug has been fixed, how can I recreate the situation for testing?

## Assistant

Since the add path is fixed, normal search-track won't recreate the bad snapshot — I'll check whether Diagnostics already has a way to inject one for testing.

You can’t recreate it through normal use anymore — tracking from search now fetches full show details before saving.

**To test the refresh heal specifically**, temporarily force a bad snapshot:

1. In `WatchlistTracking.resolvedShowForTracking`, make it always return the stub (skip the fetch):

```swift
private static func resolvedShowForTracking(
    _ show: Show,
    tvMaze: any TVMazeService
) async throws -> Show {
    show  // temporarily skip the detail fetch
}
```

2. Search for RHOA → track from the **search row star** (not detail).
3. Watchlist should show **Returning — no next season announced yet** again.
4. Pull to refresh — it should flip to **Currently showing Season 17** (and move into **Airing Now**).
5. Revert that temporary change.

**Without code changes**, you can still verify the add fix: track from search → watchlist should already match detail. The unit test `forceRefreshCorrectsStaleReturningStatus` covers the refresh heal path.

I can add a Diagnostics action that injects a stale Returning row if you want a no-code-edit way to retest later.

## User

That works, however.  When I did this, pull-to-refresh resulted in two notifications, one for Real Housewives and one for another show on my watchlist.  That seems wrong?

## Assistant

Pull-to-refresh shouldn't spam notifications for status heals — I'll check how change detection decides to notify and whether force refresh should stay silent.

Yes — that's wrong for pull-to-refresh. Force refresh re-checks every show and treats heals like real events (e.g. Returning → Airing), so it fires notifications while you're in the app. I'll suppress notification delivery on user-initiated pull-to-refresh; status will still update.

Yes — that was wrong.

Pull-to-refresh re-fetches every show and was treating status heals like real events (e.g. Returning → Airing → “Season 17 is now airing”). The second alert was the same path for another show that also had a meaningful delta.

**Fix:** pull-to-refresh (and Diagnostics force refresh) still update the list, but no longer schedule notifications. Background/automatic refresh still notifies as before.

**What to test:** recreate the stale Returning row, pull to refresh — status should update with no alerts.
