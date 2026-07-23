# Last background refresh label

## User

Something I have noticed is that the "Last Refresh" time in Diagnostics is always very close to the current time.  I assume that means it's fetching when the app foregrounds.  This isn't very useful since the app has to be foregrounded before that value can be checked, so we will never know if the app was also checking in the background.  Can you make that into "last background refresh" instead?

## User

Adding persistence sounds like a good idea

## Assistant

`lastBackgroundRefreshAt` now persists in `UserDefaults`, using the same approach as launch diagnostics in `AppDiagnosticsLogger`.

**Changes:**
- **`BetaRefreshDiagnostics`** — Loads the saved timestamp on init and writes it when a background refresh completes successfully. Persistence is skipped during UI tests to avoid cross-test pollution.
- **`DiagnosticsDocumentationCopy`** — Notes that the timestamp survives app launches.
- **`BetaRefreshDiagnosticsTests`** — Verifies the value survives creating a new instance.

**What to test:**
1. Run a background refresh (accelerated soak-test mode helps), then force-quit and relaunch — **Last background refresh** should still show that earlier time.
2. Foreground the app and open Diagnostics — the timestamp should not jump to “now.”
3. If no background refresh has ever completed, it should still show empty/never.

## User

You said "Last fetch result / Last notification decision still reflect the most recent refresh of any kind (including foreground), which is unchanged.", but the Last fetch result field says "Skipped:  Foreground policy (15 min minimum)".  What does that mean?  It does not seem to be showing the most recent refresh of any kind.

## Assistant

You were right to question that — my earlier description was wrong for how the UI actually behaved.

**What "Skipped: Foreground policy (15 min minimum)" meant**

When the app returns to the foreground, it tries a lightweight refresh via `refreshAllIfNeeded()`. To avoid hammering TVMaze, that path skips network work if a foreground refresh already ran within the last 15 minutes.

Opening Diagnostics triggers that same foreground path. If you'd used the app recently, the skip fired and **overwrote** "Last fetch result" with that policy message — even though no refresh actually happened. It wasn't reporting a real fetch outcome; it was reporting "we decided not to refresh just now."

**What I changed**

The beta validation fields are now consistently **background-only**, matching the timestamp:

- **Last background fetch result** — outcome of the last `BGAppRefreshTask` run
- **Last background notification decision** — notification pipeline result from that same run

Foreground refreshes (including opening Diagnostics) and the 15-minute debounce no longer touch these fields. Both values persist across launches, like the timestamp.

**What to test**

1. Open Diagnostics after using the app — fetch result should **not** show the foreground policy skip message.
2. After a background refresh completes, those fields should update with real outcomes (e.g. "Refreshed 2 show(s)" or "No TVMaze changes…").
3. Force Refresh Now still works for manual testing, but won't overwrite the background diagnostics.

## User

I think we still need last foreground fetch because tapping "Force refresh now" appears to do nothing now.

## Assistant

Good catch — Force Refresh was working, but nothing on screen updated to show it.

There are now separate **foreground** fields in the Beta validation section:

- **Last foreground refresh** — timestamp
- **Last foreground fetch result** — e.g. "Refreshed 3 show(s)" or "No TVMaze changes…"
- **Last foreground notification decision** — what the pipeline decided

These update only when you tap **Force Refresh Now**. Automatic foreground checks when opening the app still don't touch them, so background validation stays clean.

Foreground values are in-memory for the current session (not persisted), since they're mainly for immediate manual testing feedback.

**What to test:** Tap Force Refresh Now with shows on your watchlist — the three foreground fields should update right away while the background fields stay unchanged.

## User

ok, I think that's good now.  Please take a look at the dignostics documentation and update it as needed.

## Assistant

Updated the diagnostics documentation to match how the screen actually works now.

**In-app help (`DiagnosticsDocumentationCopy` + `DiagnosticsDocumentationView`)**

- **Overview** — Explains the background vs foreground split and what persists.
- **Beta validation — Background** — Covers the three background fields, that they survive app launches, and that opening Diagnostics does not update them.
- **Beta validation — Foreground** — Covers Force Refresh fields, session-only scope, and that automatic foreground refreshes (including the 15-minute debounce) do not update them.
- **Beta validation — Simulation** — Separates fake-data runs from real polling.
- **Beta actions** — Fixed **Send Test Notification** (uses fake sample data, not the watchlist). Force Refresh now points to the foreground fields above.
- **Share report** — Notes which fields are always exported vs session-only.

The help sheet now uses three Beta validation sections instead of one long block, aligned with the field groupings on the screen.

**Diagram** (`Documentation/MVP/Diagrams/05-beta-diagnostics-and-testing.md`) — Updated stale "Last refresh" nodes to the current background/foreground field names and data flow.

Open **Diagnostics → info (ⓘ)** to review the revised help text.

## User

One last thing about the diagnostics page - the notification actions should be disabled if notifications haven't been enabled, right?

## Assistant

Yes — that makes sense. The three notification test actions are now disabled when alert permission isn't granted:

- **Send Test Notification**
- **Schedule Pipeline Test Notification**
- **Run Simulated Update Scenario**

**Force Refresh Now** stays enabled since it's a fetch test, not a notification test.

When notifications are off, a footer under Beta actions explains that permission is required. Status also refreshes when you return to the app (e.g. after enabling alerts in Settings), so the buttons should enable without closing Diagnostics.

Help text under Beta actions notes the permission requirement as well.

**What to test:** With notifications denied, confirm the three actions are disabled and the footer appears. Enable notifications in Settings, return to Diagnostics, and confirm they become tappable.
