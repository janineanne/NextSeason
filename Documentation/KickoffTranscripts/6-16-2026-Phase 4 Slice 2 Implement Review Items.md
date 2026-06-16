# Code review feedback and action items

## User

I asked ChatGPT to review the latest code. Here is its feedback.  Please address these comments.

I found one important issue:
High priority — background refresh can miss updates.
WatchlistRefreshService.refreshAll() asks TVMaze for only .day updates, but background refresh is best-effort and may not run every 12 hours. If iOS delays refresh for more than a day, the app could miss a TVMaze update entirely.
Relevant code:
updates = try await tvMaze.updatedShows(since: .day)
I’d change this to .week at minimum, or choose the window based on the oldest lastCheckedAt.
Other smaller notes:
Medium — notification authorization is requested only after adding a show.
That’s fine for MVP, but there’s no user-visible explanation before the system prompt. Later, you may want an onboarding-style explanation.
Medium — detail view reloads every time its task runs.
ShowDetailView creates the VM once, but still calls load() every .task execution. Not disastrous, just potentially extra network traffic.
Low — deliver() only accepts .authorized.
requestAuthorizationIfNeeded() treats .provisional and .ephemeral as allowed, but deliver() silently skips them. Probably not relevant unless you use provisional notifications.

## Assistant

I'll review the feedback against the current code and start with the high-priority background refresh window, then the notification and detail-view items.

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistRefreshService|updatedShows|refreshAll","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_fa7a1ccc-a7e0-4a91-b55e-d9d1c6aedd4","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"requestAuthorizationIfNeeded|deliver\\(","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_3e50e88d-d0e2-43c1-b58f-a7f07a2b7a1","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ShowDetailView|\\.task","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4cfefc4d-cfb4-4a43-afac-ac5ab4071d2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeUpdatePeriod","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4f66870c-f6a0-4be5-b258-6b52d480da2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"lastCheckedAt|TrackedShow","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_bfa6cf8a-ebf8-476a-bb44-6b3863e8aa9","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Notification*"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/TrackedShow.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeClient.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

## Assistant

Implementing fixes: adaptive update window from `lastCheckedAt`, load-once detail view, notification pre-prompt, and aligned `deliver()` authorization.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift","limit":30}
```

### Tool Glob File Search

```
{"globPattern":"**/*Notification*Tests*"}
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

## Assistant

Updating `requestAuthorizationIfNeeded` to reuse the shared helper and adding tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Ripgrep Raw Search

```
{}
```

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistRefreshServiceTests","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_f06e7684-6991-426a-8071-b5acf90493b","offset":0}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeService.swift"]}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeUpdatePeriodTests|StatusChangeDetectorTests","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_5ce6c538-2b9d-44d8-91f9-4141770f1dc","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"StatusChangeDetectorTests","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_0b3808af-70b5-4565-92f8-998e399c2bf","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*.xcodeproj/**"}
```

### Tool Glob File Search

```
{"globPattern":"**/Package.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"NextSeasonTests|Synchronized","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_dfed995d-3fe5-4897-adc6-602bcdc7670","offset":0}
```

## Assistant

Fixing the detail view: `.task(id:)` still runs on every appearance, so we'll skip reload when the view model already matches the show.

### Tool Edit File V2

## Assistant

All four review items are addressed. Summary of changes:

### High — adaptive update window for background refresh
`WatchlistRefreshService` no longer always requests `.day` updates. It picks the smallest TVMaze window that still covers the gap since the oldest `lastCheckedAt`:

- ≤ 1 day → `.day`
- ≤ 1 week → `.week`
- \> 1 week → `.month`

This is in `TVMazeUpdatePeriod.covering(since:now:)` with unit tests in `TVMazeUpdatePeriodTests.swift` and integration tests in `WatchlistRefreshServiceTests`.

### Medium — notification explanation before the system prompt
When a user tracks a show and notification permission is still `.notDetermined`, the app shows a **“Stay in the Loop”** alert explaining why notifications are useful. The system permission dialog only appears if they tap **Enable Notifications**. **Not Now** still saves the show without requesting permission.

### Medium — detail view avoids redundant reloads
`ShowDetailView` uses `.task(id: show.id)` and only creates/loads the view model when the show ID changes. Navigating back to an already-loaded detail view no longer triggers another network fetch. **Try Again** on failure still works.

### Low — consistent notification authorization handling
`deliver()` and `requestAuthorizationIfNeeded()` now share a `canDeliverAlerts()` helper that treats `.authorized`, `.provisional`, and `.ephemeral` as allowed.

---

**What to test in the app:**
1. Track a show with notifications not yet granted — confirm the explanation alert appears before the system prompt.
2. Open a show detail, go back, reopen the same show — confirm it does not show a loading state again (unless the view was recreated).
3. Background refresh behavior is harder to test manually; run the new unit tests in Xcode (`TVMazeUpdatePeriodTests`, updated `WatchlistRefreshServiceTests`).

## User

There is a build error in ShowDetailViewModel - please fix

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"]}
```

### Tool Run Terminal Command V2

## Assistant

Likely cause: comparing to `.notDetermined` without importing UserNotifications. Adding a helper on `NotificationService` to keep that dependency out of the view model.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"]}
```

## Assistant

The build error was from comparing to `.notDetermined` in `ShowDetailViewModel` without importing `UserNotifications` — that enum case isn’t visible with only `Foundation` imported.

I fixed it by moving that check into `NotificationService`:

```swift
func needsAuthorizationPrompt() async -> Bool
```

`ShowDetailViewModel` now calls `notifications.needsAuthorizationPrompt()` instead of referencing `UNAuthorizationStatus` directly. Rebuild and it should compile.

## User

We removed the system image next to the show status from the watchlist view, but it's still there on the detail view.  Please remove it from there too.

### Tool Ripgrep Raw Search

```
{"pattern":"displayLabel|systemImage|status","glob":"**/Watchlist*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_da71364b-b278-4e8d-9608-86aba101184","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"displayLabel|systemImage|status","glob":"**/ShowDetail*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_11354046-0486-4a15-971d-493c25ddbc8","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":83,"limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"systemImage","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4e48be93-c260-46b6-abc9-5b398ace136","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/NextSeasonStatus+Display.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"status\\.systemImage|systemImage","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_c7c9e38f-6cb7-4e36-ae21-44e3713f3a3","offset":0}
```

### Tool Run Terminal Command V2

## Assistant

Removing the next-season status icon in the detail view to match the watchlist's plain text headline.

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":103,"limit":30}
```

### Tool Ripgrep Raw Search

```
{"pattern":"\\.systemImage","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_d19a5cc8-b281-445b-99be-b64d380f667","offset":0}
```

## Assistant

Removing the unused `systemImage` property now that nothing references it.

### Tool Edit File V2

## Assistant

Removed the SF Symbol from the **Next Season** section on the detail view so it matches the watchlist: plain `Text(status.headline)` instead of a `Label` with an icon.

Also removed the now-unused `systemImage` property from `NextSeasonStatus+Display.swift`.

**To verify:** Open a show detail and confirm the next-season line in the group box has no icon, consistent with watchlist rows.
