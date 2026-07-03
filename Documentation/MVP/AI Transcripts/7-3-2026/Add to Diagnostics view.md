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

### Tool Glob File Search

```
{"globPattern":"**/*Diagnostic*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Diagnostics","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_952bbab1-206a-4ad0-8923-0abc3383da5","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"info.*button|InfoButton|\\.help\\(|documentation|HelpView|AboutView","glob":"**/*.swift","caseInsensitive":true,"multiline":false,"toolCallId":"tool_2daa73f8-b962-4b58-b6ac-5ed08d6d4da","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Help*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"info\\.circle|Markdown|HelpSheet|DocumentationView|\\.sheet.*help","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_e024d5cf-fd80-4563-b83e-6b115c6811c","offset":0}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","globPattern":"**/*.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/Diagrams/07-beta-diagnostics-and-testing.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":100,"limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":115,"limit":80}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Glob File Search

```
{"globPattern":"**/*Copy*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Text\\(.*markdown|LocalizedStringResource|\\.md|bundle.*markdown","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_47d98daf-9584-4fc5-b25e-e51b77d67f5","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Privacy*"}
```

### Tool Glob File Search

```
{"globPattern":"**/*About*"}
```

### Tool Glob File Search

```
{"globPattern":"**/*.xcassets/**"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/AppAboutView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"DiagnosticsView\\.swift|AppAboutView\\.swift","path":"/Users/janine/Documents/TbF Projects/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_0a482f5b-3309-44a1-b2de-5c720e2fd57","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/6-30-2026/Add notification options to Diagnostic menu.md","limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/FirstRunCopy.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"\\.md|\\.txt|Bundle\\.main","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_dffac09f-7339-4cf5-a4c0-753bdc52844","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"DiagnosticsView|AppAboutView|FirstRunCopy","path":"/Users/janine/Documents/TbF Projects/NextSeason","glob":"*.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"tool_22a1e248-d1a0-4820-b859-bafbe4ba0e0","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*.pbxproj"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsSimulatedUpdateRunner.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"PBXFileSystemSynchronized|Debug","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"headLimit":40,"multiline":false,"toolCallId":"tool_b65636a5-aa08-45b6-9fbb-fef0848ec56","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsDiagnosticsReport.swift","limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"appSecondaryText","glob":"**/*.swift","caseInsensitive":false,"headLimit":5,"multiline":false,"toolCallId":"tool_5fd07125-d4df-47cf-a8e0-802b08a92c4","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/SummaryFormatter.swift","limit":50}
```

### Tool Ripgrep Raw Search

```
{"pattern":"enum AppSpacing","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_1ddd40d5-9cb6-4ba7-a665-3aa4697dae2","offset":0}
```

## Assistant

Creating documentation copy and a help sheet, then wiring an info button on Diagnostics and moving the existing footer text into the doc.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsDocumentationView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsDocumentationCopy.swift"]}
```

### Tool Run Terminal Command V2

## Assistant

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
