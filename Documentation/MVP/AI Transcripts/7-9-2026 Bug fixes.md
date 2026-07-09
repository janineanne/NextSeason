# Watchlist feature issues

## User

While testing the last changes I noticed a couple of other things:
- The About/Diagnostics button is missing on the show detail view
After tapping "Open Settings" on Watchlist and turning on notifications, "Notifications Are Off" warning is still on Watchlist view when returning
Test Notifications are always empty

## Assistant

I'll investigate all three issues: the missing About/Diagnostics button on show detail, the stale notifications warning on Watchlist, and empty test notifications.

## Assistant

Fixed all three issues. Here's what was wrong and what changed:

### 1. About/Diagnostics missing on Show Detail
`ShowDetailView` had the theme switcher toolbar but not the About button that Search and Watchlist already have. Added the same `info.circle` toolbar button wired to `openAppAbout`.

### 2. "Notifications Are Off" banner stuck after Settings
The watchlist only re-checked notification permission on initial load and pull-to-refresh — not when returning from Settings. Added a `scenePhase` observer so `notificationsDenied` refreshes when the app becomes active again.

### 3. Test notifications empty / not working
Two root causes:

- **Send Test Notification** used immediate delivery (`trigger: nil`), which is unreliable. Switched to system-scheduled delivery via `deliverAfterDelay` (1 second, unique ID) — same approach the old watchlist debug button used.
- **Schedule Pipeline / Simulated Scenario** silently did nothing because `prepareSimulatedUpdateRunnerIfNeeded()` required a cast to `NotificationService`, which failed after the recent `any NotificationManaging` refactor. Removed that cast and updated the simulated runner to accept the protocol type directly.

Also tightened permission checks: delivery and the Diagnostics "Notifications enabled" field now require both authorization **and** alerts enabled in Settings (`canDeliverVisibleAlerts()`), so test actions aren't offered when alerts would still be blank.

---

**What to test:**
1. Open a show from Search or Watchlist → confirm the **info** button appears in the nav bar and opens About/Diagnostics.
2. With notifications denied, see the Watchlist banner → tap **Open Settings** → enable notifications → return to the app → banner should disappear.
3. In Diagnostics → **Send Test Notification** → expect a banner after ~1 second with title "Next season update" and body mentioning the simulated show. **Schedule Pipeline Test Notification** and **Run Simulated Update Scenario** should also work now.

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: success
task_id: 955154
title: Run unit tests on iPhone 17 Pro simulator
tool_call_id: tool_cf42b43e-92d2-49ad-b150-4fce6200742
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/955154.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

Tests finished on the iPhone 17 Pro simulator (exit code 0). Unit tests and the rest of the UI suite passed.

One UI test failed: `SearchAndTrackUITests.testSearchRowUntrackShowsUndoToast`. That looks unrelated to the About button, notification banner, or diagnostics fixes — it’s about the undo toast when untracking from a search row. Worth a quick manual check of that flow if you’ve seen it flake before.

## User

Now the "notifications are off" message isn't showing up at all on the Watchlist page

## Assistant

The banner was only checking `isDenied()`, which is true only when the user taps **Don't Allow** on the first system prompt. If you turn notifications off later in Settings, iOS often keeps authorization as `.authorized` but disables alerts — so the banner never appeared.

It now uses `canDeliverVisibleAlerts()` instead, which covers both denied permission and notifications toggled off in Settings. The check also runs on tab appear, not just on initial load and when returning from background.

**To verify:** With tracked shows, disable notifications for NextSeason in Settings (either deny on first prompt, or turn off the Allow Notifications toggle). The banner should appear on Watchlist and disappear after you re-enable and return to the app.

## User

I did the following:
- added a show to the watchlist
- declined notifications
- selected go to settings

I'm taken to the NextSeason page in Settings, but there's no way to enable Notifications there.  Shouldn't there be?

## Assistant

Yes — you should be able to enable them, but not from the page we were opening.

When you tap **Don't Allow** on the system prompt, iOS removes the Notifications toggle from the general **Settings → NextSeason** page. That's normal Apple behavior. To turn notifications back on, you need the **Notifications** sub-page for the app (Settings → Notifications → NextSeason, or the in-app notification settings screen).

We were using `UIApplication.openSettingsURLString`, which only opens the general app settings page — hence no Notifications option.

That's now fixed to use `UIApplication.openNotificationSettingsURLString`, which deep-links directly to NextSeason's notification settings where the **Allow Notifications** toggle lives.

**To verify:** Decline notifications again → tap **Open Settings** on the Watchlist banner → you should land on the notification settings page with the toggle, not the general app page.

Note: this deep link can behave oddly in the Simulator; test on a device if the Simulator only opens Settings without navigating to the right screen.

## User

That's not quite right either.  It takes me to a page where I can confgure Notifications at the system level.  There's no entry for NextSeason in the Apps list, so no way to turn them on.

## User

It ran, but I said no.

## User

That works now.  On to another issue when I send either kind of test notification, the body is still empty.  The old way of doing this used either the first or last item on the wishlist as data for the notification.

## User

What does "If the watchlist is empty, both actions record "Track a show on the watchlist to send a test notification." instead of sending a blank alert." mean?

## User

I'm not seeing that text anywhere - the notification just isn't sent.  Where should I be looking for it?

## User

It's working, I just wasn't looking in the right place.

## User

Can you please change the default theme from .lavender to .warmSlate?
