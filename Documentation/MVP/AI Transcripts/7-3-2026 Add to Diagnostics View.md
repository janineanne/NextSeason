# (1) Diagnostics view debug button

## User

Please add a debug/diagnostics button to the diagnostics view that:

* creates a fake “new season” event
* runs the normal notification pipeline
* schedules a local notification for 5–10 seconds later

## Assistant

Added a **Schedule Pipeline Test Notification** button to the Diagnostics beta actions section. It exercises the real notification path end-to-end, not a shortcut around it.

### What it does

1. **Fake new-season event** — Seeds the in-memory simulated show (`Beta diagnostics / simulated`) in a “returning, no season yet” state, then fetches fake TVMaze data with a dated Season 3 premiere.
2. **Normal pipeline** — Runs `WatchlistRefreshService.refreshAll(force:)` → `NextSeasonCalculator` → `StatusChangeDetector` → notification delivery, same as a real refresh.
3. **Delayed delivery** — Routes the notification through `DiagnosticsDelayedNotificationDelivering`, which schedules it via `UNTimeIntervalNotificationTrigger` for a random **5–10 seconds** later so you can background the app first.

### Files changed

- `DiagnosticsView.swift` — new button and helper text
- `DiagnosticsSimulatedUpdateRunner.swift` — `runDelayedNewSeasonNotification()`
- `DiagnosticsDelayedNotificationDelivering.swift` — new adapter
- `DiagnosticsSimulatedDataProvider.swift` — `forcePhase(_:)` to jump straight to the dated season
- `NotificationService.swift` — `deliverAfterDelay` is no longer `#if DEBUG` only, so TestFlight release builds can use it (still only called from beta diagnostics)

### What to test

1. Long-press the version label → open **Diagnostics**
2. Tap **Schedule Pipeline Test Notification**
3. Background the app within a few seconds
4. Confirm a “Next season update” notification arrives for **Beta diagnostics / simulated**
5. Check **Last notification decision** and **Last simulation** in the beta validation section for the pipeline summary

**Send Test Notification** still delivers immediately (bypasses the pipeline). **Run Simulated Update Scenario** still uses the two-step debounce flow. The new button is the single-tap, delayed pipeline test.

## User

Looks good!  Please write up documentation for the Diagnostics page and put it behind an info button on that page.  You can move the explanatory text that's already there for a few fields to the new document.

## Assistant

I'll locate the Diagnostics view and any existing explanatory copy, then add an info button that opens the new documentation.

Creating documentation copy and a help sheet, then wiring an info button on Diagnostics and moving the existing footer text into the doc.

Added in-app Diagnostics documentation behind an info button on the Diagnostics screen.

### What changed

**New files**
- `DiagnosticsDocumentationCopy.swift` — help text for every section (overview, App, Beta validation, Beta actions, Launch investigation, Usage, Share report)
- `DiagnosticsDocumentationView.swift` — sheet with sectioned help, rendered with lightweight Markdown for bold labels

**Updated `DiagnosticsView.swift`**
- Added an **info.circle** toolbar button (top-left) that opens the help sheet
- Removed inline footer/caption text that now lives in the doc:
  - Launch investigation footer (TestFlight crash reports note)
  - Beta validation footer (real polling vs. simulated data)
  - Share report footer (nothing sent automatically)
  - Beta actions caption (pipeline test and two-step simulation instructions)

### What to test

1. Open **About → Diagnostics** in a Debug or TestFlight build.
2. Tap the **info** button (top-left) and confirm the help sheet covers all sections.
3. Confirm the Diagnostics list is cleaner without the old footers.
4. Check VoiceOver labels: “Diagnostics help” / “Explains what each field and action does”.

## User

Looks great, thanks!

## Assistant

Glad it helped. If you want to tweak the help copy or add anything else to Diagnostics later, just say the word.
