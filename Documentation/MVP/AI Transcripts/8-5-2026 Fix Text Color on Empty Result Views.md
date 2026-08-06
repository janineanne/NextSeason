# Fix ContentUnavailableView green

## User

It seems that the only use of ContentUnavailableView that has green text is "Find Your Next Season" on Search. None of the others do, despite the user of .appPrimaryText() on all of them.  They should all use the same green.

## Assistant

I'll look at how `ContentUnavailableView` and `.appPrimaryText()` are used so we can make the green styling consistent.

### Tool Get Mcp Tools

```
{"server":"cursor-app-control","toolName":"rename_chat","toolCallId":"call-5d017403-cd7e-4e70-991a-ff3c1674a27b-0\nfc_ov2PdXw-6SkKZu-dfbc3f91-aws_ue1_0"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ContentUnavailableView|\\.appPrimaryText","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-5d017403-cd7e-4e70-991a-ff3c1674a27b-1\nfc_ov2PdXw-6SkKZu-dfbc3f91-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Mcp

```
{"name":"cursor-app-control-rename_chat","args":{"title":"Fix ContentUnavailableView green"},"toolCallId":"call-c0f161bd-22a2-4176-85f4-e547b51bb30c-3\nfc_ov2Pf3g-6SkKZu-8edf17fa-aws_ue1_0","providerIdentifier":"cursor-app-control","toolName":"rename_chat","smartModeApprovalOnly":false,"skipApproval":true,"serverIdentifier":"cursor-app-control"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"appPrimaryText|func appPrimary","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-c0f161bd-22a2-4176-85f4-e547b51bb30c-4\nfc_ov2Pf3g-6SkKZu-8edf17fa-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":160,"limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":235,"limit":60}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppScreenBackground.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"appAccentText|appSecondaryText|AppColor|accent","glob":"**/*.{swift}","caseInsensitive":false,"headLimit":40,"multiline":false,"toolCallId":"call-e7cc24d0-5178-45c5-860f-f1acdc940336-8\nfc_ov2PgbT-6SkKZu-46d6656f-aws_ue1_1","offset":0}
```

## Assistant

The idle Search title uses `.appAccentText()` (green); the others use `.appPrimaryText()` (system primary). I'll align the other `ContentUnavailableView` titles to the same accent styling.

### Tool Ripgrep Raw Search

```
{"pattern":"Can't Find Your Show|No Tracked Shows|No Matches|Something Went Wrong|Find Your Next Season|ContentUnavailableView","glob":"**/*Test*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-2f36171f-9a62-4508-bb1c-29af047522be-9\nfc_ov2Phet-6SkKZu-6a0711af-aws_ue1_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":165,"limit":15}
```

### Tool Edit File V2

### Tool Edit File V2

## Assistant

The green came from `.appAccentText()`, not `.appPrimaryText()`. Only “Find Your Next Season” used accent; the others applied primary (system label color) to the whole `Label`.

All empty/error `ContentUnavailableView` titles in Search and Watchlist now match that pattern: accent title text, primary icon.

**Test:** Search idle, no-results, and error states; Watchlist empty, no-matches, and error — titles should all share the same green.
