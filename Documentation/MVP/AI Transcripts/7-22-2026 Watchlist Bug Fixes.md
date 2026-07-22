# Real Housewives of Atlanta bug

## User

When I search for The Real Housewives of Atlanta, the search row says "Ongoing series". When I look at the show detail, it says "Currently showing Season 17". But when I put it on the watchlist and look at it from there, it says "Returing - no next season announced yet".  This appears to be a bug - is it?

## Assistant

I'll check how status copy is derived in search, show detail, and the watchlist — inconsistent messaging for the same show would indicate a bug.

### Tool Todo Write

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Ongoing series|Currently showing|no next season|Returning","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-cdc5e03f-4bf8-4097-afc5-eb8ab993e5e9-2\nfc_30920dd7-e1d8-9d68-8a61-4b7a61659586_2","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"statusMessage|statusText|releaseStatus|seasonStatus|ShowStatus","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-cdc5e03f-4bf8-4097-afc5-eb8ab993e5e9-3\nfc_30920dd7-e1d8-9d68-8a61-4b7a61659586_3","offset":0}
```

## Assistant

There's prior discussion of similar wording — I'll compare how detail and watchlist compute next-season status for the same show.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/NextSeasonStatus+Display.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"NextSeasonCalculator|NextSeasonStatus|\\.airing|\\.returning","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-a6089132-ac35-4c7b-8b99-43b2907e773e-5\nfc_dfcf362e-054f-961f-9727-84c617071499_1","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/NextSeasonCalculator*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NextSeasonCalculator.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/TrackedShow.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"add\\(|track\\(|save.*show|fromDetail|insert","glob":"**/Watchlist*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-08c05eaf-cd5b-4ad9-8e4a-f8411f89c799-10\nfc_93d3f164-28ce-90fa-8e6d-1377125bd4c9_2","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"func add|trackShow|saveShow|upsert","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-08c05eaf-cd5b-4ad9-8e4a-f8411f89c799-11\nfc_93d3f164-28ce-90fa-8e6d-1377125bd4c9_3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistTracking.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Persistence/SwiftDataWatchlistRepository.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistTracking|add\\(|toggleTrack|isTracked","glob":"**/Search*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-c1ec5f2a-e755-4c43-9c36-b839905d0aa9-15\nfc_ef632f7e-889c-9de4-b999-f7f457bad50f_3","offset":0}
```

## Assistant

Checking whether search-track saves incomplete season data, and what TVMaze reports for this show.

### Tool Ripgrep Raw Search

```
{"pattern":"search\\(|SearchResult|toDomain|seasons","glob":"**/Search*.swift|**/ShowData*.swift|**/TVMaze*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-f8270686-c60c-489b-8fc7-1026bf563198-16\nfc_a68f7320-0ead-983b-b091-9e1172a52bbb_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","limit":180}
```

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/6-24-2026 Implement Watchlist Redesign.md","offset":340,"limit":30}
```

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"func search|Show\\(from|toDomain|embed","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-0a9901f7-5389-41a9-beeb-77589ee3795d-21\nfc_f4b4d370-fe70-9c9b-99c7-7c9640c2d912_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/ShowStatus.swift"}
```

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/ShowRow.swift","limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeClient.swift","limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"headline|nextSeason|subtitle","glob":"**/WatchlistView*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-f70bbc05-275a-47ca-b5ba-9129458efb3e-26\nfc_f73ee84a-3be2-97bc-bc96-631948b93015_3","offset":0}
```

## Assistant

TVMaze confirms Season 17 is still airing — checking whether tracking from search persists incomplete status.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchWatchlistTracking.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Track.*search|from search|incomplete|without seasons|returningNoSeasonYet","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-4c4eb906-df51-4909-bf00-7a13856bc34c-28\nfc_e4e42e3d-de16-975e-8f09-603fa2b63339_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/NextSeasonCalculatorTests.swift","offset":70,"limit":40}
```

### Tool Todo Write

### Tool Todo Write

## Assistant

Yes — the watchlist line is wrong for this show.

TVMaze currently has Season 17 premiered `2026-04-05`, ending `2026-08-23`, with a next episode on `2026-07-26`. Detail is correct: **Currently showing Season 17**.

What’s going on:

| Surface | What it shows | Source |
|---|---|---|
| Search | “Ongoing series” | TVMaze `status` only (`Running`) — intentional |
| Detail | “Currently showing Season 17” | Fresh `NextSeasonCalculator` with seasons + next episode |
| Watchlist | “Returning — no next season announced yet” | Cached `TrackedShow.nextSeason` from when it was saved |

Search’s “Ongoing series” vs detail’s season line is fine — different fields on purpose. Detail vs watchlist should match, and they don’t.

The bug: tracking often saves a search-result `Show` with **no seasons**. The calculator then falls through to `.returningNoSeasonYet` for any running show. That wrong snapshot sticks on the watchlist until a refresh actually re-fetches the show (and incremental refresh can skip it if TVMaze hasn’t flagged an update).

So for RHOA, watchlist should say the same thing as detail. Happy to fix by fetching full show data before computing `nextSeason` on add (and/or forcing a refresh after track).

## User

Yes, fix please

## Assistant

I'll fix add-to-watchlist so we always compute `nextSeason` from a full show payload (seasons + next episode), not the search stub.

### Tool Todo Write

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-concurrency-pro/skills/swift-concurrency-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-testing-pro/skills/swift-testing-pro/SKILL.md","limit":60}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistTracking\\.(add|toggle)|repository\\.add\\(","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-aba9cae4-e76e-4f8e-ad25-7224818a6d06-35\nfc_0950225c-44d7-9f58-ac26-1a113fd1939c_3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchWatchlistTrackingContext.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistTrackingTests.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeService.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeService|MockTVMaze|FakeTVMaze|stub.*show|show\\(id:","glob":"**/NextSeasonTests/**/*.swift","caseInsensitive":false,"headLimit":40,"multiline":false,"toolCallId":"call-d9fdfe61-2b82-4073-9d1a-5e577ba7a992-39\nfc_386150c4-1efd-9b1d-9f1a-3f9137c438d0_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/ProfileFlowRunner.swift","offset":140,"limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","offset":120,"limit":50}
```

### Tool Ripgrep Raw Search

```
{"pattern":"RefreshPolicy|shouldPerformForegroundRefresh|shouldRefresh","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-f27ee73c-18e9-49ef-a01d-b32103f817f9-42\nfc_6b077222-e9cd-9430-b4d1-64e3be7c47d7_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","limit":140}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRepositoryTests.swift","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","limit":120}
```

### Tool Ripgrep Raw Search

```
{"pattern":"watchlistTrackingContext|tvMaze","glob":"**/SearchView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-0b858ccb-847f-4063-a220-d7677467e420-47\nfc_18483507-cbba-9605-9f21-1bb2e85daad2_2","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshAll|force:|\\.refresh","glob":"**/Watchlist*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-0be7d58a-fb95-4feb-b22b-c1ad104bfad4-48\nfc_1ea3e7e4-3a1e-9fe5-a333-04ea0cfacf1e_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/ProfileFlowRunner.swift","offset":250,"limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistTracking\\.toggle|WatchlistTracking\\.add","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-9ff3219c-866f-4673-a2b9-bd58d3afdcd6-51\nfc_71b11c6c-5631-9246-85fb-397027c3f62f_1","offset":0}
```

## Assistant

Intended change: before persisting a track, fetch the full show when seasons are missing (search stubs), then compute `nextSeason` from that payload.

### Tool Todo Write

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Updating tests and checking for any remaining call sites.

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistTracking\\.(toggle|add)|SearchWatchlistTrackingContext\\(","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-96d25cf2-0701-4a92-8439-43c7bc9bfdeb-58\nfc_e80dfa8a-9fbc-931b-be98-728109648703_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/ShowDetailViewModelTests.swift","offset":180,"limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/NextSeasonCalculatorTests.swift","limit":80}
```

### Tool Edit File V2

### Tool Ripgrep Raw Search

```
{"pattern":"struct NextEpisode|init\\(","glob":"**/NextEpisode*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-03869ee1-46e0-404e-9b4e-f56c2ad8df74-62\nfc_10520a4a-2ef0-94c7-824e-ad513dafd37a_0","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"NextEpisode\\(","glob":"**/NextSeasonTests/**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-03869ee1-46e0-404e-9b4e-f56c2ad8df74-63\nfc_10520a4a-2ef0-94c7-824e-ad513dafd37a_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextEpisode.swift"}
```

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Tests passed. Making the helper private, then verifying ShowDetail tests still compile.

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Todo Write

## Assistant

Fixed. Tracking now loads full show details when the search stub has no seasons, so watchlist `nextSeason` matches detail.

**What changed**
- `WatchlistTracking.add` fetches `/shows/:id` when `seasons` is empty before saving
- Wired `tvMaze` through search + detail track paths
- Tests cover search-stub → airing status, and skip-fetch when seasons already exist

**What to test**
1. Remove RHOA from the watchlist (or pull to refresh — that forces a re-fetch and should also fix the existing row)
2. Track it again from search (star on the row)
3. Watchlist should show **Currently showing Season 17**, same as detail

Skills used: `swift-concurrency-pro`, `swift-testing-pro`

## User

Removing the show and adding it again updated the status, but pull-to-refresh did not. Another bug?

## Assistant

Pull-to-refresh should force a full re-fetch — I'll check why it left the stale status in place.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift","offset":100,"limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshFromNetwork|refreshAll\\(force|reloadScreen|prepareAndReload","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-1c6147e1-557f-4663-8a19-57eaf2195720-74\nfc_61c5b154-4a15-9ea0-99f9-d57e5419c014_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/TVMazeClient.swift","offset":95}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Persistence/TrackedShowEntity.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","offset":200,"limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":100,"limit":50}
```

### Tool Ripgrep Raw Search

```
{"pattern":"watchlistRefreshService|WatchlistRefreshService\\(","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-fbfc684f-2f24-4e03-8c60-957946fd37ba-79\nfc_9c233e9b-ba5f-9eb5-928e-23cbe211e682_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","offset":100,"limit":100}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/DTO/SeasonData.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Mapping/ShowData+Domain.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"TVMazeDate|isBefore|isOnOrBefore|isAfter","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-584dc64f-c72a-4686-b1d3-0499417a9497-83\nfc_ce66229b-9627-94c5-9866-bf2822d328a1_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Persistence/InMemoryWatchlistRepository.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService+Environment.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/App/AppCompositionRoot.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/TVMazeDate.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshFromNetwork|refreshService","glob":"**/WatchlistViewModelTests.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-c01f4bda-4697-4098-9527-69678967e206-88\nfc_ce0637b0-96a0-946e-848b-b894da515316_3","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":57,"limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshable|force refresh|pull.to.refresh|Updated","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-a9a7a039-bb34-4cbd-9b73-655c39b732db-90\nfc_00c93dc4-2f63-944b-bbfb-ee84b5d98752_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/6-15-2026 Phase 4 Slice 1 Implement Review Items.md","offset":220,"limit":100}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshAllIfNeeded|refreshFromNetwork|foreground_watchlist","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-c5e1c618-aea7-4086-85ea-29df7df21a8f-92\nfc_21a4b07f-a5f1-92d3-b145-33f0ab4f8c70_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/NextSeasonStatus+Codable.swift"}
```

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":150,"limit":120}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ForEach|ShowRowLabel|WatchlistRow","glob":"**/WatchlistView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-f5bbd1ac-b68c-42d6-8fd3-df3b73d1d351-96\nfc_5b6567e2-e7c8-9961-bc28-2d24f654449e_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/ShowRow.swift","offset":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistSection.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":270,"limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistCollapsibleSection|isExpanded|collapsed","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-ba5a1ff1-0428-4895-bca9-753f34b54818-100\nfc_e42af70b-3f2c-9f39-9745-156d5b23c14b_2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift","limit":140}
```

### Tool Ripgrep Raw Search

```
{"pattern":"WatchlistView\\(|watchlistRefreshService","glob":"**/ContentView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-1d2348c1-a5a0-45b9-a166-b8edd2c5f6fc-102\nfc_a367393e-1aaa-9751-866c-79e3cd223f72_1","offset":0}
```

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","offset":280,"limit":80}
```

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"refreshService\\?","glob":"**/WatchlistViewModel.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-9c4c49ec-c14b-4559-aea3-5b5630f5fcb8-106\nfc_a7a17758-6334-9d3d-a151-fe422368d45b_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift","offset":80,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistViewModel.swift","limit":95}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"func deliver","glob":"**/Notification*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-15d45636-983b-40cf-8a9c-487eecc6bc35-110\nfc_4da2f01e-6687-9296-990d-4fc0509398df_0","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","limit":120}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","offset":175,"limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ModelContainer|SwiftDataWatchlistRepository","glob":"**/NextSeasonTests/**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-9988fb49-e4c5-4a06-a4b2-6fccfb2ecc91-113\nfc_cb7d4778-657d-9369-b706-f80f3b69b5cb_0","offset":0}
```

### Tool Todo Write

## Assistant

I'll add a regression test for force-refresh correcting stale status, then trace why pull-to-refresh wouldn't apply that update in the UI.

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"forceRefreshCorrectsStaleReturningStatus|Force refresh recomputes","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","caseInsensitive":false,"multiline":false,"toolCallId":"call-6544e459-b4e8-4f92-a586-fd5f85bc43b6-118\nfc_0c0dab75-9d8b-9b8d-bc1a-9da6d8e95f3c_0","offset":0}
```

### Tool Run Terminal Command V2

## Assistant

There are uncommitted watchlist changes — checking whether those broke pull-to-refresh.

### Tool Run Terminal Command V2

## Assistant

Force refresh corrects status in unit tests — the likely issue is incremental refresh skipping shows when TVMaze’s `updated` timestamp hasn’t changed, so a bad search-track snapshot never heals. Hardening refresh to re-check those cases, and moving `.refreshable` onto the List.

### Tool Todo Write

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Updating tests for the new recheck behavior, and moving `.refreshable` onto the List.

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","offset":109,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":100,"limit":130}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Edit File V2

### Tool Todo Write

## Assistant

Yes — related bug.

Refresh only re-fetched a show when TVMaze’s `updated` timestamp moved. After a search-track, that epoch was already current, so the wrong **Returning** snapshot stayed put. Force refresh *should* have rebuilt it (and does in unit tests); automatic refresh never would.

**What I changed**
- Refresh now also re-checks `.returningNoSeasonYet`, `.airing`, and `.scheduled` even when TVMaze reports no update (calendar + stale-snapshot heal)
- Moved pull-to-refresh onto the `List` so the gesture is more reliable with searchable
- Cancellation during a show fetch no longer gets swallowed as a soft failure

**What to test**
1. Track a show from search again (or use one still stuck on Returning)
2. Pull to refresh on Watchlist — status should match detail (and may move section, e.g. Waiting → Airing Now)
3. Or leave the app and come back — foreground refresh should heal Returning snapshots too

## User

Now that the first bug has been fixed, how can I recreate the situation for testing?

## Assistant

Since the add path is fixed, normal search-track won't recreate the bad snapshot — I'll check whether Diagnostics already has a way to inject one for testing.

### Tool Ripgrep Raw Search

```
{"pattern":"returningNoSeasonYet|simulate|inject|seed|stub|watchlist","glob":"**/Features/Debug/**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-170b0b7b-fc29-430c-8cec-a5e8cef3b8a8-133\nfc_354d4906-6ac8-917e-bd3b-d478e10736b7_0","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Diagnostics|simulate|force refresh|seed","glob":"**/Documentation/MVP/**/*Diagnostics*","caseInsensitive":false,"headLimit":40,"multiline":false,"toolCallId":"call-170b0b7b-fc29-430c-8cec-a5e8cef3b8a8-134\nfc_354d4906-6ac8-917e-bd3b-d478e10736b7_1","offset":0}
```

## Assistant

You can’t recreate it through normal use anymore — tracking from search now fetches full show details before saving.

**To test the refresh heal specifically**, temporarily force a bad snapshot:

1. In `WatchlistTracking.resolvedShowForTracking`, make it always return the stub (skip the fetch):

```swift
private static func resolvedShowForTracking(
    _ show: Show,
    tvMaze: any TVMazeService
) async throws -> Show {
    show  // temporarily skip the detail fetch
}
```

2. Search for RHOA → track from the **search row star** (not detail).
3. Watchlist should show **Returning — no next season announced yet** again.
4. Pull to refresh — it should flip to **Currently showing Season 17** (and move into **Airing Now**).
5. Revert that temporary change.

**Without code changes**, you can still verify the add fix: track from search → watchlist should already match detail. The unit test `forceRefreshCorrectsStaleReturningStatus` covers the refresh heal path.

I can add a Diagnostics action that injects a stale Returning row if you want a no-code-edit way to retest later.

## User

That works, however.  When I did this, pull-to-refresh resulted in two notifications, one for Real Housewives and one for another show on my watchlist.  That seems wrong?

## Assistant

Pull-to-refresh shouldn't spam notifications for status heals — I'll check how change detection decides to notify and whether force refresh should stay silent.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"notification|force refresh|PD-008|meaningful","path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP","glob":"**/*.{swift,md}","caseInsensitive":false,"multiline":false,"toolCallId":"call-9e56977a-e306-43f0-ac72-a37ec0d96e10-136\nfc_3b49240a-8dac-9b92-a5c7-4ecf636a944f_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/WatchlistRefreshService.swift","limit":180}
```

## Assistant

Yes — that's wrong for pull-to-refresh. Force refresh re-checks every show and treats heals like real events (e.g. Returning → Airing), so it fires notifications while you're in the app. I'll suppress notification delivery on user-initiated pull-to-refresh; status will still update.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swift-testing-pro/skills/swift-testing-pro/SKILL.md","limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"refreshAll\\(force","glob":"**/*.{swift}","caseInsensitive":false,"multiline":false,"toolCallId":"call-e6a2e43e-2e49-4977-97d5-724fdf877f1a-139\nfc_088b8897-0eb3-9e47-9ed3-4dc2060a61a0_1","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/WatchlistRefreshServiceTests.swift","offset":155,"limit":80}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/DiagnosticsView.swift","offset":310,"limit":40}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

Yes — that was wrong.

Pull-to-refresh re-fetches every show and was treating status heals like real events (e.g. Returning → Airing → “Season 17 is now airing”). The second alert was the same path for another show that also had a meaningful delta.

**Fix:** pull-to-refresh (and Diagnostics force refresh) still update the list, but no longer schedule notifications. Background/automatic refresh still notifies as before.

**What to test:** recreate the stale Returning row, pull to refresh — status should update with no alerts.
