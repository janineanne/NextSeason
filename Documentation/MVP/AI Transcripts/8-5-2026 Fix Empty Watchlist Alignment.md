# Watchlist alignment issues

## User

The "no tracked shows" view for watchlist has some alignment problems, both with and without notifications enabled, as you can see in the screenshots.  Please fix.

## Assistant

I'll inspect the Watchlist empty-state layout and related SwiftUI code to fix the attribution/star overlap and centering issues.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Glob File Search

```
{"globPattern":"**/*Watchlist*"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"No Tracked Shows|Data provided by TVMaze|Find a Show","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-758a915e-826e-4bb5-ba05-f8c1cb0abb2b-2\nfc_ov2HgsN-3LYxF7-dc8844a8-aws_ue1_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/TVMazeAttributionView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/assets/Simulator_Screenshot_-_iPhone_17_Pro_-_2026-08-05_at_13.20.14-e37e83e3-0f13-4b89-b3f4-a3fc9b79dd42.png"}
```

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/assets/Simulator_Screenshot_-_iPhone_17_Pro_-_2026-08-05_at_13.20.28-0a51bcfd-e5b2-4c07-be18-8e8f574d8e05.png"}
```

## Assistant

The empty-state overlay is colliding with the List’s TVMaze footer. I’ll check how Search handles attribution and whether any tests cover this.

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeAttributionView|Section \\{\\s*\\} footer","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-84663d3e-37ad-47d2-9a56-eacd5e4d789a-7\nfc_ov2HmyP-3LYxF7-001734a3-aws_ue1_0","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"emptyState|empty.*watchlist|TVMazeAttribution|showsDisabledBanner","glob":"*Test*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-84663d3e-37ad-47d2-9a56-eacd5e4d789a-8\nfc_ov2HmyP-3LYxF7-001734a3-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/NotificationsDisabledBanner.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"appPlainListStyle|listRowBackground|ContentUnavailableView","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-84663d3e-37ad-47d2-9a56-eacd5e4d789a-10\nfc_ov2HmyP-3LYxF7-001734a3-aws_ue1_3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":150,"limit":140}
```

### Tool Ripgrep Raw Search

```
{"pattern":"PD-002|PD-008|attribution|TVMaze","glob":"**/DecisionLog.md","caseInsensitive":false,"multiline":false,"toolCallId":"call-8a21a439-277e-43af-9450-3950c94d804c-12\nfc_ov2Hq8X-3LYxF7-2d48b1eb-aws_ue1_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/AppScreenBackground.swift"}
```

## Assistant

The empty-state overlay sits on a still-mounted `List`, and the TVMaze footer keeps showing underneath—that causes the overlap and the misaligned white strip. I'll hide that footer whenever the list has nothing to show.

### Tool Edit File V2

## Assistant

**Fixed.** The empty/no-results overlay was drawn on top of a still-mounted `List`, and the TVMaze attribution footer stayed visible underneath—so it overlapped the star and left that misaligned white strip (with and without the notifications banner).

**Change:** In `WatchlistView`, the attribution footer only appears when there are filtered shows. Empty and no-results states match Search (no attribution behind `ContentUnavailableView`). The List stays mounted so the last-row removal crash fix is unchanged.

**Please test:**
1. Empty watchlist with notifications off — banner visible, empty state centered, no attribution overlap/white strip  
2. Empty watchlist with notifications on — clean centered empty state, no stray attribution bar  
3. Watchlist with shows — attribution still at the bottom  
4. Search with no matches on a non-empty watchlist — no footer peeking through

## User

Looks good!

## Assistant

Glad it looks right.
