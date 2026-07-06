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

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Semantic Search Full

```
{"query":"TestFlight DEBUG build detection diagnostics debug menu","targetDirectories":[],"explanation":""}
```

### Tool Semantic Search Full

```
{"query":"refresh check timestamp notification decision update detection","targetDirectories":[],"explanation":""}
```

### Tool Glob File Search

```
{"globPattern":"**/*Debug*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TestFlight|DEBUG|ThemeSwitcher","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_992c49e4-1e2a-4783-ae42-4c1cb34cc5a","offset":0}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","globPattern":"**/*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/ThemeSwitcherView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshScheduler.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppDiagnosticsLogger.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshPolicy.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/BackgroundRefreshConfiguration.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService+Environment.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"PreviewTVMazeService|AppVersionInfo|openDiagnostics","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_7ec98495-c98c-4a11-977f-a0e4162d5e7","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Diagrams/08_analytics_and_diagnostics.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Previews/Show+Preview.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/TVMazeAttributionView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsDiagnosticsReport.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/TrackedShow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/Show.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistRefreshService|refreshAll","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_28e34947-b3f1-4d24-bd1f-2238f495d50","offset":0}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason","globPattern":"**/*Test*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","limit":120}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Features/Debug","glob":"**/*.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_5446e850-442b-4b65-a6a5-9818b4263be","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextEpisode.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"DiagnosticsView|ThemeSwitcherView","glob":"*.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4488c0c4-9b7a-4570-abd2-51422355727","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/NextSeasonStatus+Display.swift"}
```

## Assistant

Implementing beta-only diagnostics: gating entry to DEBUG/TestFlight, recording refresh state, and adding a simulated update path that never touches real watchlist data.

### Tool Todo Write

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsService.swift","offset":170,"limit":40}
```

### Tool Ripgrep Raw Search

```
{"pattern":"diagnosticsReport","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_54993fba-cd64-4c37-a9af-8c9fc0dbc4b","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsService.swift","offset":200}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsService.swift","limit":90}
```

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsService.swift","offset":155,"limit":25}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Todo Write

## Assistant

Resetting simulated scenario state after step 2 so repeated test runs start clean.

### Tool Edit File V2

## Assistant

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
