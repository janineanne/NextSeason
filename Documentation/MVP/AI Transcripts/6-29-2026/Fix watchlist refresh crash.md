# Background crash investigation

## User

I'm trying to track down the background crash and I'm a little stuck.  The crash is now happening reliably after 10 minutes, which tracks with you setting that for the wishlist refresh rate, so I think we can assume that's what's crashing.  But the last thing printed to Xcode's console is "breadcrumb enter_background'.  If it was crashing in background refresh we should be seeing "refresh_scheduler_configure" or even "background_watchlist_refresh".  Thoughts?

## Assistant

Investigating breadcrumb logging and the background refresh flow to determine why refresh breadcrumbs aren't appearing before the crash.

### Tool Ripgrep Raw Search

```
{"pattern":"breadcrumb","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_f5a6f922-6f1b-4ec1-93e7-e0fd8a49b5f","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshScheduler.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/BackgroundRefreshConfiguration.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"background_watchlist_refresh|enter_background|recordEnterBackground","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_e5fd85b4-f70d-42c6-ac67-0b1684d728a","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts/idle-soak-test.sh"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"10 \\* 60|600|10m|earliestBeginDate","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_d9a04088-1c85-4bba-b9af-8e5663ef6bc","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"BGTask|background","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"*.plist","caseInsensitive":false,"multiline":false,"toolCallId":"tool_ad3a8ea1-8e50-44d6-9188-fffcbfa148a","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/App-Info.plist"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"scenePhase|background|BGTask|Timer|Task \\{","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_6b7140e3-20de-4452-94c5-26b58734caf","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/Theme/AppThemeIconService.swift","limit":140}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistUndoRemoval.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"UIBackgroundTask|beginBackgroundTask|expirationHandler","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_11ec9ff8-0fa0-4b36-b495-b3389672f34","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"simulateLaunch|BGTaskScheduler|Scenario D","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_70e75118-5fab-48df-bf29-5b46bca2e22","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/6-29-2026/Instruments Report Stage 2.md","limit":80}
```

## Assistant

Your read on the **10-minute timing** is reasonable, but **`enter_background` as the last Xcode line does not rule out background refresh** — and it also does not prove it. A few things in the current instrumentation explain why you are stuck.

## What those breadcrumbs actually mean

**`refresh_scheduler_configure` is a launch breadcrumb, not a refresh breadcrumb.** It runs once in the `.task` on `WindowGroup` at startup, along with the initial `scheduleNextRefresh()`:

```86:95:NextSeason/NextSeasonApp.swift
            .task {
                guard !UITestingConfiguration.isEnabled else { return }
                AppDiagnosticsLogger.breadcrumb("refresh_scheduler_configure")
                RefreshScheduler.configure {
                    AppDiagnosticsLogger.logTaskStart("background_watchlist_refresh")
                    await refreshService.refreshAll()
                    AppDiagnosticsLogger.logTaskComplete("background_watchlist_refresh")
                }
                RefreshScheduler.scheduleNextRefresh()
            }
```

If you background the app soon after launch, you may have seen that earlier and not tied it to the 10-minute event. You would **not** expect to see it again when the BG task fires.

**There is no breadcrumb literally named `background_watchlist_refresh`.** The handler uses `logTaskStart`, which records `task_start:background_watchlist_refresh`. When the BG task actually runs, the first refresh-specific marker is:

```33:37:NextSeason/Services/RefreshScheduler.swift
            AppDiagnosticsLogger.breadcrumb("background_task_started")
            scheduleNextRefresh()

            let work = Task { @MainActor in
                AppDiagnosticsLogger.logTaskStart("bg_app_refresh")
```

So at fire time you should look for `background_task_started`, then `task_start:bg_app_refresh`, then `task_start:background_watchlist_refresh`, then `watchlist_refresh_start`.

## Why Xcode stops at `enter_background`

This is the big one. After `recordEnterBackground()` runs, the process is usually **suspended**. The Xcode debugger console is a poor witness for what happens while suspended:

1. Logs from a **BGAppRefreshTask wake** often never appear in Xcode’s console until the process crashes, is jetsam’d, or returns to foreground.
2. If the process is **killed without flushing OSLog**, the last line you saw while still attached (`enter_background`) stays the last line you saw — even if code ran afterward.

So “last console line = crash site” is misleading for background work. This matches your soak script’s guidance to use **`log stream`** (or `./Scripts/idle-soak-test.sh`) rather than the Xcode console for Scenario D.

## A diagnostic gap that makes this worse

`recordEnterBackground()` does two things that work against crash investigation:

```62:67:NextSeason/Utilities/AppDiagnosticsLogger.swift
    nonisolated static func recordEnterBackground() {
        persistBreadcrumbs()
        UserDefaults.standard.set(false, forKey: sessionActiveDefaultsKey)
        logger(for: .scene).notice("enter_background")
        breadcrumb("enter_background")
    }
```

- **`sessionActive` is cleared** on a normal background transition, so a kill 10 minutes later may **not** trigger `possible_abrupt_termination` on the next launch.
- **`persistBreadcrumbs()` runs before `enter_background` is appended**, and nothing in the BG refresh path persists again. So even reopening the app may not show `enter_background` or any BG-task breadcrumbs from the dead session.

That can make it feel like “nothing happened after background” when something did — you just did not capture it.

## Three plausible stories (all consistent with what you see)

| Story | What happened | Why console stops at `enter_background` |
|--------|----------------|----------------------------------------|
| **A. BG refresh crash** | iOS fires the task ~10m after schedule; refresh code runs and crashes | Logs during wake never reached Xcode; breadcrumbs not persisted |
| **B. Jetsam / OS kill while suspended** | Process killed with no Swift code running | Timing may correlate with 10m only coincidentally, or iOS reclaiming memory on a schedule |
| **C. BG task never ran** | Something else killed the app at ~10m | Same last-visible log; check whether `background_task_scheduled` appeared at launch |

Story A is still plausible given the 10-minute cadence. Story B is equally plausible given the logging blind spot. Story C is worth ruling out.

## What I would do next

1. **Capture logs outside Xcode** for one repro:
   ```bash
   ./Scripts/idle-soak-test.sh
   ```
   Background the app and wait for the crash. Search the log file for `background_task_started`, `watchlist_refresh_start`, `JetsamEvent`, or `exited`.

2. **After the crash, relaunch and check Diagnostics** (Settings → Diagnostics in the app). Because of the gap above, also check whether launch logged `recovery_after_abrupt_termination` or MetricKit crash breadcrumbs.

3. **Confirm scheduling at launch** — you should see `background_task_scheduled` and `background_refresh_accelerated_10m` in the launch window, not at the 10-minute mark.

4. **Force the BG path while attached** (fastest way to confirm refresh is involved):
   ```text
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.TrialByFyre.NextSeason.watchlist-refresh"]
   ```
   Run that in the LLDB console after backgrounding. If that crashes reliably, you have your culprit without waiting 10 minutes.

5. **Check device settings**: Background App Refresh enabled for NextSeason, Low Power Mode off. Debugger attachment can change BG scheduling behavior.

## Bottom line

Missing `refresh_scheduler_configure` at the 10-minute mark is expected — it is not part of the refresh firing path. Missing `background_task_started` in **Xcode’s console** is **not** strong evidence that BG refresh did not run; it is very often an artifact of suspended-background logging.

The 10-minute correlation is a good lead, but the next step is to observe the **device unified log** during the soak, or simulate the BG task directly. If you want, I can add a small change so BG-task breadcrumbs are persisted immediately at `background_task_started` and so `enter_background` does not prematurely clear the “abrupt termination” session flag — that would make the next repro much easier to read.

## User

Something's wrong with idle-soak-test.sh;  when I run it the first line in the log is "log: unrecognized option `--device-udid'"

## Assistant

Checking how `log stream` accepts device options on this machine.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Web Search

```
{"searchTerm":"macOS log stream device-udid physical iPhone unified logging","toolCallId":"tool_b2b282c3-a87f-4439-8a54-910394750f6"}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts/idle-soak-test.sh"}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"log stream|idevicesyslog|device-udid","path":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts","caseInsensitive":false,"multiline":false,"toolCallId":"tool_6f0a3ed1-d2f4-41e2-a38e-e473d2c80e8","offset":0}
```

### Tool Run Terminal Command V2

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts","globPattern":"**/*.sh"}
```

## Assistant

Confirming the issue: on current macOS, `log stream` has no `--device-udid` (only `log collect` does). Updating the script to poll with `log collect` instead.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts/idle-soak-test.sh"}
```

## Assistant

Fixing a scoping bug: `device` and `stamp` are local to `main()` but referenced from helper functions.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

The script was wrong for current macOS. On your system, **`log stream` only works for the local Mac** — it has no `--device-udid` flag. That option exists on **`log collect`**, which is why the script failed immediately.

**What changed in `idle-soak-test.sh`:**
- Detects whether `log stream` supports device streaming (it does not on your macOS)
- Falls back to **polling** with `log collect --device-udid … --last 2m` every 30 seconds, then `log show` on each slice
- Uses `/usr/bin/log` directly instead of `xcrun log`
- On Ctrl+C, still saves a 1-hour `.logarchive` for post-crash analysis

**Run it again:**
```bash
./Scripts/idle-soak-test.sh
```

You should see:
```
Using polled device logs (--last 2m every 30s).
(`log stream --device-udid` is not available on this macOS version.)
```

If collection fails (device locked, trust prompt, permissions):
```bash
USE_SUDO=1 ./Scripts/idle-soak-test.sh
```

Tighter polling during Scenario D:
```bash
POLL_INTERVAL_SECONDS=15 POLL_WINDOW=3m ./Scripts/idle-soak-test.sh
```

**Note:** Poll output will repeat lines across overlapping windows — that is expected. Search for `background_task_started` or `watchlist_refresh_start` in the `.soak-logs/idle-soak-*.log` file.

The same broken `log stream --device-udid` pattern is also in `profile-performance-suite.sh` and `resume-performance-suite.sh` if you hit it there next.

## User

Am I supposed to have the app already running and backgrounded before I run this script, or do I do that after?

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Scripts/idle-soak-test.sh","limit":40}
```

## Assistant

**Start the script first, then launch and background the app.**

The script only captures logs while it is running. It does not start NextSeason. For Scenario D, the sequence should be:

1. **Run the script** (phone plugged in, unlocked, trusted).
2. **Launch NextSeason** on the device — ideally a Release/TestFlight build, not attached to the Xcode debugger if you can avoid it.
3. **Wait a few seconds** so launch breadcrumbs show up (`refresh_scheduler_configure`, `background_task_scheduled`, etc.).
4. **Background the app** (Home gesture).
5. **Leave the script running** and wait past the 10-minute BG refresh window.

That way you capture both `enter_background` and anything that happens afterward (e.g. `background_task_started`).

If you background **before** starting the script, you can still catch the ~10-minute crash, but you may miss `enter_background` and launch scheduling logs — the poll window is only the last 2 minutes by default.

For **Scenario A/B** (foreground idle): script first → launch app → stay on Search or Wishlist → wait.

For **Scenario C** (foreground/background cycles): script first → then run your 30 min on / 30 min off cycle.

**Quick sanity check:** after step 4, you should see `breadcrumb enter_background` in the terminal within the next poll or two. If you do not, collection is not working yet (device locked, trust, or try `USE_SUDO=1`).

## User

I think this is what is causing the crash:

2026-06-29 22:47:19.098 E  runningboardd[34:1919fe8] [com.apple.runningboard:general] RBSStateCapture remove item called for untracked item <RBConnectionClient| 14384 name:app<com.TrialByFyre.NextSeason(75686C95-5DF8-4F23-86ED-1DE3DAE3F6F1)> entitlements:<RBEntitlements|

## User

Yes

## User

That seems to have fixed it. Now, before I forget, please put the refresh interval back to 12 hours

## Assistant

Done. Two changes:

**`BackgroundRefreshConfiguration.swift`** — `forceAcceleratedForSoakTest` is now `false`, so the default interval is **12 hours**.

**`NextSeasonApp.swift`** — On launch, if you’re not actively soak-testing (`forceAcceleratedForSoakTest` or `-AcceleratedBackgroundRefresh`), any **persisted 10-minute flag in UserDefaults is cleared**. That way your device doesn’t keep the accelerated interval from Scenario D.

For future soak tests you can still use either:
- Set `forceAcceleratedForSoakTest = true` temporarily, or
- Launch once with `-AcceleratedBackgroundRefresh`

After the next launch you should see `background_task_scheduled earliest=43200s accelerated=false` in the logs.

## User

Is there any other debug or temporary code that should be reverted before I commit this?

## Assistant

Good question. Here’s a pre-commit checklist based on your **current uncommitted diff** and a quick scan of the repo.

## Revert or fix before commit

**1. Xcode scheme — Debug launch config (accidental)**  
`NextSeason.xcscheme` changed `LaunchAction` from **Release → Debug**. That’s almost certainly from soak debugging. Revert it unless you intentionally want Run to always use Debug:

```xml
buildConfiguration = "Release"
```

**2. `.soak-logs/` — do not commit**  
Untracked and large (logs + `.logarchive` files from your soak runs). It’s not in `.gitignore` yet, so it’s easy to accidentally `git add .`. Either leave it out or add:

```
.soak-logs/
```

**3. Accidental formatting in `NextSeasonApp.swift`**  
This got mangled during editing — worth cleaning up:

```swift
if phase == .background
{
```

**4. Include `BackgroundRefreshConfiguration.swift`**  
It’s still **untracked** but is part of the fix (12h default + soak-test opt-in). Make sure it’s in the commit.

## Already fine for this commit

- **`forceAcceleratedForSoakTest = false`** — production 12h interval is restored.
- **`RefreshScheduler` / init configure changes** — real fix, keep.
- **`idle-soak-test.sh` fixes** — useful tooling, keep.
- **Diagnostics (`AppDiagnosticsLogger`, MetricKit, Diagnostics UI)** — intentional beta instrumentation from earlier work, not soak temp code.

## Pre-existing “beta, not soak” items (not introduced by this work)

These are **known** and documented; you don’t need to revert them for *this* commit unless you’re aiming for App Store rather than beta:

- **`ThemeSwitcherButton`** visible outside `#if DEBUG` (comment in `NextSeasonApp` points to Release Readiness).
- **Profile flow / `-ProfileFlow` / `-UITesting` hooks** — launch-arg gated, fine to keep.
- **`WatchlistView` debug test-notification UI** — `#if DEBUG` only.

## Optional follow-up (not blocking this commit)

- **`profile-performance-suite.sh` / `resume-performance-suite.sh`** still use broken `log stream --device-udid` (same issue we fixed in `idle-soak-test.sh`).

---

**Suggested commit set:**  
`RefreshScheduler.swift`, `NextSeasonApp.swift`, `BackgroundRefreshConfiguration.swift`, `Scripts/idle-soak-test.sh`  
**Exclude:** `.soak-logs/`, scheme Debug change (unless you want it)  
**Fix:** the `if phase == .background` formatting

Want me to revert the scheme, fix that formatting, and add `.soak-logs/` to `.gitignore` for you?

## User

Please fix that formatting, and add .soak-logs/ to .gitignore, and fix profile-performance-suite.sh / resume-performance-suite.sh.  Leave the scheme as it is;  it should be Debug most of the time.

## Assistant

Here’s what changed:

### `NextSeasonApp.swift`
- Fixed the broken `if phase == .background` formatting (tab/newline).

### `.gitignore`
- Added `.soak-logs/` so soak output isn’t accidentally committed.

### `Scripts/lib/device-log-capture.sh` (new)
- Shared helper used by the performance scripts.
- Uses `log stream --device-udid` when macOS supports it.
- Otherwise collects a recent window with `log collect --last` after each trace (same approach as the soak script).

### `Scripts/profile-performance-suite.sh` & `Scripts/resume-performance-suite.sh`
- Source the shared helper instead of calling broken `xcrun log stream --device-udid`.
- Pass an appropriate `--last` window on each `stop_log*` call (e.g. `45s` for 35s traces, `${limit}` for stress runs).

The Xcode scheme was left on **Debug** as requested.
