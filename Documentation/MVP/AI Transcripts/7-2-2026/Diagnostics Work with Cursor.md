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

## User

There's a warning in BetaBuildConfiguration: 

/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/BetaBuildConfiguration.swift:20:44 'appStoreReceiptURL' was deprecated in iOS 18.0: Use AppTransaction.shared and Transaction.all from StoreKit.framework instead

## User

I would like the diagnostics to be available to beta testers, but thet TestFlight app doesn't show the Version number at all.  Can you make it visible to everyone, like the Theme switcher, but also note which changes need to be reversed later?

## User

One more thing about the diagnostics.  The Crash Investigation section is still showing a crash from 4 days ago. There's a fine line between preserving data and allowing it to go stale.  What would you suggest as the ideal behavior here?

## Assistant

Reviewing how breadcrumbs are stored and surfaced in diagnostics so the recommendation matches the current implementation.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","limit":60}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsDiagnosticsReport.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"loadPersisted|persistedBreadcrumb|breadcrumbsDefaults","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_de04663c-7019-4812-8c4e-734a31e93b6","offset":0}
```

## Assistant

The stale data you’re seeing fits how the current design works — and where it doesn’t draw a clear line yet.

## What’s happening today

There are really **two stores**:

1. **In-memory breadcrumbs** (`breadcrumbStore`) — what the Crash Investigation list shows via `recentBreadcrumbs()`.
2. **Persisted breadcrumbs** (UserDefaults) — written on every `enter_background`, read on the next launch for abrupt-termination detection, and included in the shared report as “Persisted breadcrumbs (prior session).”

Persisted breadcrumbs are **never cleared** after a normal launch or after you’ve looked at them. So they can stick around for days.

The in-memory list can also look old if iOS **never killed the process** — the app stayed suspended for days and the breadcrumb buffer was never reset.

So the problem isn’t “too much retention” alone; it’s that **session activity**, **last crash artifact**, and **export payload** are all mixed together without expiry or a “handled” state.

---

## Ideal behavior (what I’d recommend)

Think in terms of **one optional incident snapshot**, not an ever-growing log.

### 1. Split the UI into two concepts

| Section | Purpose | Retention |
|--------|---------|-----------|
| **This session** | What happened since this process started | Current launch only; cap at ~20 entries |
| **Last incident** (optional) | Breadcrumbs from a suspected crash/force-quit | Only when relevant; show age (“4 days ago”) |

Crash Investigation should default to **this session**. “Last incident” appears only when there’s something worth investigating.

### 2. Persist only for abrupt termination — not every background

Today, every background writes breadcrumbs to UserDefaults. That turns “last background snapshot” into “maybe a crash,” which is misleading.

Better:

- On **graceful** `enter_background`: mark session as ended; **don’t** treat that as a crash artifact.
- On **next launch** with `hadActiveSession == true`: treat prior persisted breadcrumbs as **one incident package**, log it, surface it once in diagnostics.
- On **next launch** with `hadActiveSession == false`: **clear** any persisted incident data (previous exit was clean).

That alone fixes most “4 days ago” noise.

### 3. Expire or consume incident data

After an incident is captured, clear it when **any** of these is true:

- **48 hours** have passed (good default for beta; 24h if you want stricter)
- User **opens Diagnostics** (consume-on-view), or taps **Share Report**
- **App version/build changed** (old incident belongs to an old build)
- **Two consecutive clean launches** (crash didn’t recur; stop surfacing it)

That’s the fine line: **keep long enough to report, short enough not to feel broken**.

### 4. Reset in-memory breadcrumbs on meaningful session boundaries

To avoid multi-day suspended processes showing ancient timestamps:

- Stamp **session start** at launch.
- On foreground after a long gap (e.g. **>4 hours**), treat it as a fresh session and clear the in-memory buffer (or label “Resumed after 4 days — session restarted”).

### 5. Keep MetricKit separate

MetricKit crash summaries in Xcode Organizer remain the source of truth for stack traces. Breadcrumbs are **context before termination**, not a crash log. The footer could say something like: *“Incident breadcrumbs are kept up to 48 hours after a suspected crash.”*

---

## Concrete policy I’d ship for NextSeason beta

```
Launch (clean previous exit)     → clear persisted incident
Launch (abrupt previous exit)    → keep prior breadcrumbs as "Last incident"
                                   + record incident timestamp + build number
Diagnostics UI                   → "This session" always
                                   + "Last incident" only if <48h and same build
Open Diagnostics / Share Report  → clear "Last incident"
Version/build bump               → clear "Last incident"
Background (graceful)            → persist session flag only, not full breadcrumb archive
```

---

## What not to do

- **Don’t** keep unbounded UserDefaults history — cap count *and* time.
- **Don’t** show persisted data without an **age label** — “4 days ago” vs looking current is confusing.
- **Don’t** require manual “Clear” as the only path — beta testers won’t do it; auto-expire is better (optional Clear is fine).

---

**Bottom line:** Preserve breadcrumbs **only across suspected crashes**, show them **once with a timestamp**, and **auto-clear** after 48 hours, share/view, or a new build. Day-to-day diagnostics should reflect **this session**, not last week’s background snapshot.

If you want this implemented, I can wire it into `AppDiagnosticsLogger` and split the Crash Investigation section in `DiagnosticsView` accordingly.

## User

Ok, go ahead and do all of this excep dno't clear last incident on Open Diagnostics.  I don't want a user to see something, decide to report it, and find it gone.

## Assistant

Implementing session vs. last-incident breadcrumb handling: persisting only on abrupt termination, auto-expiring after 48h, and clearing on share (not on opening Diagnostics).

## Assistant

Implemented the incident lifecycle with your one exception: **opening Diagnostics does not clear last incident** — only Share/Copy export does.

### Behavior

**This session**
- In-memory breadcrumbs for the current process only
- Cleared after **4+ hours** suspended (when returning to foreground)

**Last incident**
- Created only when the previous launch detects an **abrupt termination** (session flag still active)
- Uses a **session buffer** synced during the session — not the old “save everything on every background” approach
- Graceful background clears the buffer without creating an incident

**Auto-clear last incident when:**
- **48 hours** have passed
- **App version/build** changes
- **Two consecutive clean launches** (graceful exit → relaunch twice)
- User **Share Report** or **Copy Report** (not on opening Diagnostics)

**Legacy data:** Old UserDefaults breadcrumbs from before this change are **discarded on first launch** (no promotion of stale 4-day-old entries).

### UI changes
- **This session** — current breadcrumbs
- **Last incident** — only when relevant, with relative age (“4 days ago”) and build number
- Export footer explains the 48h retention and that share/copy clears the stored incident

### Files touched
- `AppDiagnosticsLogger.swift` — core lifecycle
- `DiagnosticsView.swift` — split sections + export clearing
- `AnalyticsDiagnosticsReport.swift` — updated export format
- `NextSeasonApp.swift` — long-suspension session reset
- `AppDiagnosticsLoggerTests.swift` — tests for the main rules

### What to test
1. Normal use → background → relaunch: **This session** only; no stale last incident
2. Force-quit → relaunch: **Last incident** appears with pre-crash breadcrumbs
3. Open Diagnostics, close without sharing: incident **still there**
4. Copy/Share report: incident **cleared**
5. Two normal relaunch cycles after a crash: incident **cleared** automatically

## User

Step 2 isn't working - after the relaunch I'm still seeing "this session", no report of the force-quit.

## Assistant

The root cause was **`recordEnterBackground()` running before iOS force-quits the app** (including from the app switcher). That handler was:

1. Setting `sessionActive = false` → next launch looked like a clean exit  
2. Clearing the session buffer → no breadcrumbs left to promote  

### Fix
- **Keep the session buffer** when entering background (sync pre-background state to disk)
- **Don’t treat background as a clean shutdown** (`sessionActive` stays true)
- **`enter_background` is in-memory only** for “This session” — it isn’t written to the crash buffer
- **Resume handshake**: when the app returns to foreground in the **same process**, set `sessionResumedAfterBackground = true` so a normal background → reopen cycle doesn’t create a false incident
- **On relaunch**: promote to **Last incident** only if the previous session was active, the buffer is non-empty, and the app **did not** resume after background

### Retest
1. Open the app and do something visible (search, open a show)
2. Background or stay in the switcher, then **force quit**
3. Relaunch and open Diagnostics  
   → **Last incident** should show pre-quit breadcrumbs (without `enter_background`)

4. Control test: background → reopen normally → use the app → relaunch  
   → should **not** show a spurious last incident

The footer text now clarifies that last incident means “ended without returning to foreground,” which covers force-quit, crash, or jetsam.

## User

In step 4, what do you mean by "relaunch"? I don't know how to do that without force quitting the app.

## Assistant

Good catch — “relaunch” was confusing in that step.

You **don’t** need to force quit for the control test. Here’s what I meant, more clearly:

### Control test (normal use — should **not** create Last incident)

1. Open the app and do something (search, open a show).
2. Send the app to the background (Home gesture / switch apps).
3. Tap the NextSeason icon again to **reopen** it.
4. Use the app a bit more.
5. Open Diagnostics.

**Expected:** You should see **This session** only (including things like `enter_background` when you backgrounded). **No Last incident** section from that flow.

That works because iOS usually **resumes the same process** when you tap the icon again. We record that resume, so it doesn’t count as a crash/force-quit.

---

### When **Last incident** appears

It shows up after a **new app start** where the previous session ended **without** that resume — for example:

- Force quit from the app switcher
- A real crash
- iOS killing the app in the background (jetsam)

So the flow is:

1. Use the app  
2. Force quit (or crash)  
3. Tap the icon to open the app again ← this is the only “relaunch” that matters for Last incident  
4. Open Diagnostics → **Last incident** should appear  

---

### Why I mentioned “relaunch” in step 4

I was trying to describe a **second** cold start after a normal background/resume cycle. That’s hard to do on device without force quit or Xcode, and it’s not something you need to test manually.

**Practical manual tests:**

| Test | Steps | Expected |
|------|--------|----------|
| Force quit | Use app → force quit → open app → Diagnostics | **Last incident** appears |
| Normal resume | Use app → background → tap icon → Diagnostics | **No Last incident** (same session) |

Sorry for the unclear wording earlier.

## User

No problem.  Unfortunately, even after following your clearer description, I'm still seeing the last incident section.

## Assistant

Investigating launch/scene ordering and the resume handshake — a cold start after background may promote an incident before `becameActive` runs.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift","limit":150}
```

## Assistant

Identifying two bugs: incident capture runs in `init()` before `becameActive` can mark a resume, and same-process background→foreground should clear a stale last incident after normal return. Deferring promotion until the scene becomes active and clearing the incident on same-process resume.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift","offset":250}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/AppDiagnosticsLoggerTests.swift"}
```

## Assistant

Deferring incident capture until the scene becomes active, and clearing last incident on same-process background→foreground resume (normal return to the app).

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift","offset":380}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Fixing call order: run `recordBecameActive` before `finalize` so same-process background resume cancels pending incidents.

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Persisting the resume acknowledgment across process boundaries so a background→resume cycle before a relaunch doesn't create a false incident.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Two separate bugs were causing what you saw:

### What was wrong

1. **Stale incidents** — A last incident from an earlier force-quit test stayed on disk until you shared/copied, waited 48 hours, or hit two clean launches.

2. **Timing** — Incident capture ran in `init()` before the scene became active, so a normal background → reopen could look like a crash.

3. **No clear on resume** — Returning to the app in the **same session** (background → tap icon) never cleared a stored last incident.

### What changed

- **Deferred capture** — Incidents are only saved when the scene becomes active, not at startup.
- **Resume cancels pending incidents** — Background → foreground in the same process clears pending capture and any stored last incident.
- **Cross-process resume** — If you background, reopen, then iOS later starts a fresh process, that resume is remembered so it still doesn’t create a false incident.

### How to retest

**Control test (should NOT show Last incident):**
1. Open the app, use it briefly.
2. Send it to the background (Home).
3. Tap the icon to return.
4. Open Diagnostics.

→ **This session** only. **No Last incident.**

**Force-quit test (SHOULD show Last incident):**
1. Use the app.
2. Force quit from the app switcher.
3. Tap the icon to open again.
4. Open Diagnostics **before** backgrounding again.

→ **Last incident** with pre-quit breadcrumbs.

**Note:** If you force quit, see the incident, then background and reopen, the incident will clear on resume (by design — you’ve returned to the app normally). Share or copy the report first if you need to keep it.
