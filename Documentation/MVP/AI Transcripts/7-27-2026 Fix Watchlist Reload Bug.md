# Watchlist update issue

## User

When I ran NextSeason today for the first time since Friday, it sent me a notification that Star Trek: Strange New Worlds is now airing.  But in the watchlist it was still listed under Coming Soon and premiereing on July 22nd.  Seems like maybe the watchlist isn't being updated when the app starts?

## Assistant

That sounds like a refresh gap between notifications and the watchlist. I'll trace how shows get updated on launch versus when notifications fire.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool New agent

### Tool Ripgrep Raw Search

```
{"pattern":"Coming Soon|now airing|Now Airing|refresh|scenePhase|premiere","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"**/*.{swift,md}","caseInsensitive":true,"multiline":false,"toolCallId":"call-bbccbce6-985a-4381-86fd-9374ab62bec5-2\nfc_86bd2bad-6223-9ca7-9b7d-b79172165abd_2","offset":0}
```

## Assistant

The diagnosis looks solid: refresh updates SwiftData and can notify, but the watchlist UI never reloads afterward. I'll confirm that path in code and fix it.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift","offset":90,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"notifyWatchlistDataChanged|watchlistReloadToken","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-b1715d0c-5de8-4acd-9438-b1d93ff89481-5\nfc_d6127985-2489-913e-a415-729914cfad67_2","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Watchlist*Test*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AppNavigationCoordinator.swift","offset":120,"limit":30}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshAllIfNeeded|RefreshOutcome|struct.*Outcome|enum.*Outcome","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-a0573745-109c-4540-896a-5e2da9616dfd-10\nfc_712350b8-1175-9bc8-9fb2-1fe2633ef43d_3","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshAllIfNeeded|refreshAll\\(|scenePhase","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-9e9f9448-5647-4338-9de4-dc935cf14732-11\nfc_a3025ad3-e558-9fb0-affc-0a3969fbfc3c_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","limit":80}
```

## Assistant

Confirmed: the refresh updates SwiftData and can fire the notification, but nothing tells the watchlist to reload its in-memory list. I'll bump the reload token after the foreground refresh so the UI picks up the new status.

### Tool Edit File V2

## Assistant

Yes — that’s exactly what was going wrong.

**What happened:** Opening the app ran a foreground refresh, which correctly moved Strange New Worlds to “airing,” wrote that to SwiftData, and sent the “now airing” notification. The watchlist UI, though, keeps an in-memory snapshot and only reloads on tab select, appear, or pull-to-refresh — so it kept showing **Coming Soon** with the July 22 premiere.

**Fix:** After the foreground refresh finishes, the app now calls `notifyWatchlistDataChanged()` so the watchlist reloads from the updated store. That also covers the case where a background refresh updated data while you were away and the next foreground refresh is skipped by the 15‑minute throttle.

**What to test:** With a show that should have moved from Coming Soon → Airing Now, force-quit, reopen (or background and return). Confirm you still get the notification (if appropriate) and that the watchlist section/subtitle update without needing pull-to-refresh.

## User

I don't know of a show fitting that description.  Can you set up the situation using temporary code changes?

## Assistant

I'll look at how beta diagnostics and simulated updates already work so we can stage a Coming Soon → Airing Now case without relying on a real premiere.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsSimulatedUpdateRunner.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","limit":250}
```

### Tool Ripgrep Raw Search

```
{"pattern":"simulated|Simulated|ProfileFlow|DEBUG|beta","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-25960e2b-388b-45c1-ad57-8dfa3d080501-17\nfc_29d566a9-557f-9abf-9e50-2edf3fa3eb42_2","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/DecisionLog.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","offset":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"struct TrackedShow|lastNotifiedSignature|func updateAfterRefresh","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-5f7be431-20b8-4307-a099-8184de82b9f2-20\nfc_b6c02937-a5c0-9ea8-9f6c-20fcd50fb881_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","offset":248}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Strange New Worlds|44933|showID.*=","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-5f7be431-20b8-4307-a099-8184de82b9f2-22\nfc_b6c02937-a5c0-9ea8-9f6c-20fcd50fb881_3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/TrackedShow.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"openDiagnostics|AppNavigationCoordinator|notifyWatchlistDataChanged","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-22b6aacd-f964-4a2c-9231-e6012a185d94-25\nfc_2a0b2515-0ffe-9f57-87ac-8fe220be75d0_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshPolicy.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/BetaDiagnosticsPresentationModifier.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"NextSeasonStatus","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","glob":"**/NextSeasonStatus*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-cae22f96-4366-495a-ba74-7228d0a3eafc-29\nfc_3cb9a928-91bc-94be-a89e-add634e4effc_2","offset":0}
```

### Tool Run Terminal Command V2

## Assistant

I'll add a temporary DEBUG Diagnostics action that rewinds a watchlist show to Coming Soon (July 22), clears the notification signature, and resets the refresh throttle so backgrounding and returning exercises the real fix path.

### Tool Ripgrep Raw Search

```
{"pattern":"enum TVMazeDate|func dateOnly|struct.*EnvironmentKey","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-b3deb5ce-5f57-4970-8df8-38d4c7613d0b-31\nfc_e6d48f24-b592-9d3a-a493-69dc7d6218c6_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus.swift"}
```

### Tool Todo Write

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","offset":250,"limit":200}
```

### Tool Todo Write

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","offset":44,"limit":80}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"]}
```

## Assistant

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

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Ripgrep Raw Search

```
{"pattern":"StaleUIRepro|resetForegroundRefreshThrottle|notifyWatchlistDataChanged|TEMPORARY UI repro|stageStaleComingSoon","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"call-13c523a6-4884-4c5e-a5d0-9de4c87be67c-50\nfc_43ddb53a-2efb-9beb-8ac6-ac23b295a1a3_0","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"notifyWatchlistDataChanged","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-13c523a6-4884-4c5e-a5d0-9de4c87be67c-51\nfc_43ddb53a-2efb-9beb-8ac6-ac23b295a1a3_1","offset":0}
```

## Assistant

Temporary repro code is gone. The foreground-refresh fix remains: after `refreshAllIfNeeded()`, the watchlist still reloads via `notifyWatchlistDataChanged()`.
