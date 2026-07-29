# Watchlist update issue

## User

When I ran NextSeason today for the first time since Friday, it sent me a notification that Star Trek: Strange New Worlds is now airing.  But in the watchlist it was still listed under Coming Soon and premiereing on July 22nd.  Seems like maybe the watchlist isn't being updated when the app starts?

## Assistant

That sounds like a refresh gap between notifications and the watchlist. I'll trace how shows get updated on launch versus when notifications fire.

The diagnosis looks solid: refresh updates SwiftData and can notify, but the watchlist UI never reloads afterward. I'll confirm that path in code and fix it.

Confirmed: the refresh updates SwiftData and can fire the notification, but nothing tells the watchlist to reload its in-memory list. I'll bump the reload token after the foreground refresh so the UI picks up the new status.

Yes — that’s exactly what was going wrong.

**What happened:** Opening the app ran a foreground refresh, which correctly moved Strange New Worlds to “airing,” wrote that to SwiftData, and sent the “now airing” notification. The watchlist UI, though, keeps an in-memory snapshot and only reloads on tab select, appear, or pull-to-refresh — so it kept showing **Coming Soon** with the July 22 premiere.

**Fix:** After the foreground refresh finishes, the app now calls `notifyWatchlistDataChanged()` so the watchlist reloads from the updated store. That also covers the case where a background refresh updated data while you were away and the next foreground refresh is skipped by the 15‑minute throttle.

**What to test:** With a show that should have moved from Coming Soon → Airing Now, force-quit, reopen (or background and return). Confirm you still get the notification (if appropriate) and that the watchlist section/subtitle update without needing pull-to-refresh.

## User

I don't know of a show fitting that description.  Can you set up the situation using temporary code changes?

## Assistant

I'll look at how beta diagnostics and simulated updates already work so we can stage a Coming Soon → Airing Now case without relying on a real premiere.

I'll add a temporary DEBUG Diagnostics action that rewinds a watchlist show to Coming Soon (July 22), clears the notification signature, and resets the refresh throttle so backgrounding and returning exercises the real fix path.

Temporary DEBUG repro is ready in Diagnostics.

**How to use it**
1. Rebuild and run.
2. Open **About → Diagnostics**.
3. Tap **Stage Coming Soon → Airing UI Repro** (section labeled TEMPORARY UI repro).
4. Tap Done, open **Watchlist** — the show (SNW if tracked, otherwise an airing show / first show) should be under **Coming Soon** with a July 22 premiere.
5. Leave the app (Home / app switcher), then come back.
6. You should get a “now airing” notification, and the row should move to **Airing Now** without pull-to-refresh.

Don’t use pull-to-refresh for this check — that path already reloaded the list.

When you’re done verifying, tell me and I’ll strip out the temporary Diagnostics section and the DEBUG throttle helper.

## User

That works, please strip out the temporary code.

## Assistant

I'll remove the temporary Diagnostics repro and related DEBUG helpers, and leave the real foreground-refresh reload fix in place.

Temporary repro code is gone. The foreground-refresh fix remains: after `refreshAllIfNeeded()`, the watchlist still reloads via `notifyWatchlistDataChanged()`.
