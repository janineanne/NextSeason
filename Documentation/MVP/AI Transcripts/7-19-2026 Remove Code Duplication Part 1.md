# Code duplication in watchlist

## User

Please fix this code duplication found by ChatGPT:

Add is shared, but the complete track/untrack flow is still duplicated

WatchlistAdding successfully abstracts persistence, analytics, and notification-prompt arming. But each surface still orchestrates watchlist toggling separately.

## Assistant

I'll look at how `WatchlistAdding` is used and where track/untrack is still duplicated across surfaces.

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistAdding|track|untrack|isOnWatchlist|toggleWatchlist","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"0\nfc_osZvnLm-4RCkTt-c5e91361-aws_ue1_0","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Watchlist*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"addToWatchlist|removeFromWatchlist|WatchlistService|armNotification","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"2\nfc_osZvnLm-4RCkTt-c5e91361-aws_ue1_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistAdding.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchWatchlistTracking.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchWatchlistTrackingContext.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistUndoRemoval.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"handleTrack|requestRemoval|addToWatchlist|isTracked|WatchlistAdding|toggleTrack|trackButton","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"9\nfc_osZvogZ-4RCkTt-57acb1c9-aws_ue1_1","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistActionSource|duplicat|track/untrack|WatchlistAdding","glob":"**/*.{md,swift}","caseInsensitive":false,"multiline":false,"toolCallId":"10\nfc_osZvogZ-4RCkTt-57acb1c9-aws_ue1_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":180,"limit":50}
```

### Tool Ripgrep Raw Search

```
{"pattern":"complete track|track/untrack flow|orchestrat|WatchlistToggle|WatchlistTracking","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation","caseInsensitive":false,"multiline":false,"toolCallId":"12\nfc_osZvp6z-4RCkTt-2ce2960a-aws_ue1_1","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/Documentation/**/*duplicat*"}
```

### Tool Glob File Search

```
{"globPattern":"**/*Code Review*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"complete track|WatchlistAdding successfully|orchestrates watchlist|track/untrack flow","path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-transcripts","caseInsensitive":false,"multiline":false,"toolCallId":"15\nfc_osZvpyA-4RCkTt-eb33a127-aws_ue1_0","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistAdding|track/untrack|complete track","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/Post-MVP","caseInsensitive":false,"multiline":false,"toolCallId":"16\nfc_osZvpyA-4RCkTt-eb33a127-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-concurrency-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistAdding|complete track|orchestrat|toggle","path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-transcripts/95f4c6d0-35c7-48f8-b7bf-34209dbd3e6d","caseInsensitive":false,"multiline":false,"toolCallId":"19\nfc_osZvqSv-4RCkTt-2f6c5eac-aws_ue1_0","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/ShowDetail*Tests*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"addToWatchlist|handleTrackButton|ShowDetailViewModel|SearchWatchlistTracking","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests","caseInsensitive":false,"multiline":false,"toolCallId":"21\nfc_osZvqSv-4RCkTt-2f6c5eac-aws_ue1_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":170,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"pendingRemoval|undoRemoval|onChange.*pending","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"24\nfc_osZvr9m-4RCkTt-34a1daaa-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/7-12-2026 Clean up duplicated code paths.md","offset":240,"limit":40}
```

### Tool Ripgrep Raw Search

```
{"pattern":"PBXFileSystemSynchronized|WatchlistAdding","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","caseInsensitive":false,"multiline":false,"toolCallId":"26\nfc_osZvssR-4RCkTt-74d82f35-aws_ue1_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsService.swift","limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":100,"limit":40}
```

## Assistant

I'll expand `WatchlistAdding` into a shared track/untrack toggle, then have Search and Show Detail call that instead of each orchestrating the flow.

### Tool Todo Write

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-concurrency-pro/skills/swift-concurrency-pro/SKILL.md","limit":40}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/skills/swiftui-pro/SKILL.md","limit":40}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Fixing a bug: after a successful add, `isTracked` flips before `defer` runs, so the updating lock would never clear.

### Tool Edit File V2

### Tool Edit File V2

### Tool Ripgrep Raw Search

```
{"pattern":"addToWatchlist|applyTrackedState|trackedShow\\(\\)","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"38\nfc_osZwCGY-4RCkTt-3e591705-aws_ue1_0","offset":0}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Todo Write

## Assistant

Search and Show Detail now share one track/untrack path instead of each wiring add/remove themselves.

### What changed
- **`WatchlistAdding.toggle(...)`** — shared orchestration for undo-pending, request undoable untrack, or add (still uses `add` for the persist/analytics/prompt steps)
- **`SearchWatchlistTracking`** and **`ShowDetailViewModel`** — call `toggle` and only update local star state from the outcome
- **`ShowDetailView`** — track tap is a thin pass-through to the view model

Side benefit: tapping the search-row star during the undo window now undoes (same as detail/watchlist), instead of trying to add again.

Skills used: `swiftui-pro`, `swift-concurrency-pro`.

### What to test
- Track / untrack from search row and show detail
- Undo toast after untrack from both surfaces
- Tap star again during the undo window (should restore tracked)
- First-track notification prompt still appears when permission hasn’t been granted
