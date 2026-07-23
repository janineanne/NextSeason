# TestFlight diagnostics feature

## User

Add a TestFlight-only diagnostics feature for beta validation.

Goals:
- Do not change production behavior.
- Add a hidden diagnostics screen or debug menu available only in DEBUG or TestFlight builds.
- Show:
  - last refresh/check timestamp
  - next intended 12-hour refresh window if available
  - last fetch result
  - last notification decision
- Add buttons:
  - Force refresh now
  - Send test notification
  - Run simulated update scenario

For the simulated update scenario:
- Use an injected fake data provider, not TVMaze.
- On first run, return baseline season data.
- On second run, return a newer season/episode date so the existing update detection logic believes a real update occurred.
- Route this through the same notification decision path used by real data.
- Clearly label all fake data as “Beta diagnostics / simulated.”
- Ensure this code cannot affect normal user data or App Store production behavior.

## Assistant

I'll explore the codebase to find how refresh, notifications, and debug/TestFlight gating work before adding the diagnostics screen.

Implementing beta-only diagnostics: gating entry to DEBUG/TestFlight, recording refresh state, and adding a simulated update path that never touches real watchlist data.

Resetting simulated scenario state after step 2 so repeated test runs start clean.

Added a TestFlight-only beta validation layer that does not change App Store production behavior.

### Access (DEBUG or TestFlight only)
- Long-press the version label under “Data provided by TVMaze” to open **Diagnostics**
- In App Store production builds, the version line is not tappable and the sheet is unavailable (`BetaBuildConfiguration`)

### Beta validation section
Shows:
- **Last refresh** timestamp
- **Next refresh window** (12 h production cadence, or 10 min if accelerated soak mode is on)
- **Last fetch result**
- **Last notification decision**
- **Last simulation** summary (after running the scenario)

### Actions
1. **Force Refresh Now** — runs `refreshAll(force: true)` against the real watchlist via TVMaze
2. **Send Test Notification** — delivers an immediate notification labeled **“Beta diagnostics / simulated”**
3. **Run Simulated Update Scenario** — two-step fake-data flow:
   - **Step 1:** undated season 3 → pending debounce, no notification
   - **Step 2:** dated season 3 → notification via the same `StatusChangeDetector` + `NotificationService` path as real refreshes

Simulated data uses an in-memory `DiagnosticsSimulatedDataProvider` (show ID `777777`) and never writes to SwiftData or the watchlist.

### Production safety
- All diagnostics recording no-ops when `BetaBuildConfiguration.isAvailable` is false
- Removed the old DEBUG-only test notification section from the watchlist
- Shared report export includes beta refresh fields when applicable

### What to test
1. **DEBUG build:** Long-press version → open Diagnostics → verify beta section and buttons
2. **Force refresh** with tracked shows → confirm timestamps and fetch result update
3. **Send test notification** (with notifications allowed) → confirm alert appears
4. **Simulated scenario:** tap twice → step 1 shows pending debounce, step 2 delivers notification
5. **Production/release sanity:** Confirm version long-press does nothing without a TestFlight receipt

**Skills used:** `swiftui-pro`
