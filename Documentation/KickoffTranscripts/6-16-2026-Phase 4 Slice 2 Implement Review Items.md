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

## User

Please commit and merge to main.

## Assistant

Checking git state, then committing and merging to main.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-tools/7dad06be-4f08-4c9f-87cc-e130947a48f0.txt","limit":200}
```

### Tool Run Terminal Command V2

## Assistant

Staging all changes, committing, then merging into main.

### Tool Run Terminal Command V2

## Assistant

Retrying with your approval — committing all branch work, then merging to main.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Committed and merged to `main`. Summary:

**Commit** `f7d1598` on `Phase2-Slice2`:
> Address Phase 4 Slice 2 review items and polish detail UI.

Includes the adaptive TVMaze update window, notification pre-prompt, detail view reload fix, authorization alignment, status icon removal, tests, and documentation transcripts.

**Merge** — fast-forward of `Phase2-Slice2` into `main`, bringing in:
1. `2560733` — local watchlist with notifications and background refresh
2. `f7d1598` — review fixes and UI polish

`main` is now 2 commits ahead of `origin/main` with a clean working tree. Say if you want me to push to remote.

## User

Execute the selected diff-tab push action.

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Pushed `main` to `origin/main` (`0440311..f7d1598`). Both local commits are now on the remote:

1. `2560733` — Add local watchlist with notifications and background refresh
2. `f7d1598` — Address Phase 4 Slice 2 review items and polish detail UI

## User

Have you considered VoiceOver?  Do you expect it to work correctly?

## Assistant

Reviewing VoiceOver-related accessibility across the app's views and interactions.

### Tool Ripgrep Raw Search

```
{"pattern":"accessibility|VoiceOver|accessibilityLabel|accessibilityHint|accessibilityHidden|accessibilityElement","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_0e02fbed-a207-41a2-9dc7-69fbdf821a4","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/references/accessibility.md"}
```

### Tool Glob File Search

```
{"globPattern":"**/Features/**/*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/ShowRow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"displayLabel","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_a7f3932a-6427-4d03-bae5-a98cc41bb47","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Models/Domain/ShowStatus.swift"}
```

## Assistant

Yes, I’ve considered it — but only lightly. For an MVP the basics are in place; I would **not** expect a fully polished VoiceOver experience without a dedicated pass and device testing.

## What should work

**Search rows** are the best case. `ShowRow` hides the decorative poster, combines the text into one element, and sets an explicit label:

```23:24:NextSeason/Features/Search/ShowRow.swift
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(show.name), \(show.status.displayLabel)")
```

Inside a `NavigationLink`, VoiceOver should announce something like “Severance, Ongoing series, link.”

**Watchlist rows** follow a similar pattern — poster hidden, children combined — so name, next-season status, stale warning, and last-updated date should read as one link:

```30:31:NextSeason/Features/Watchlist/WatchlistRow.swift
        .accessibilityElement(children: .combine)
```

**Detail view** has a few good choices:
- Poster is hidden from VoiceOver
- Track button uses a text `Label` (“Track” / “Tracking”), not icon-only
- There’s an explicit hint on that button
- Loading and error states mostly use labeled `ProgressView` / `Button("Try Again")`
- Tabs use text labels, not icon-only tab items

**Dynamic Type** looks fine — the app uses semantic fonts (`.headline`, `.subheadline`, `.body`) rather than fixed sizes.

## Where I expect friction

**1. Track button while updating**

When the watchlist toggle is in progress, the button label becomes only a `ProgressView`:

```89:96:NextSeason/Features/ShowDetail/ShowDetailView.swift
                if viewModel.isUpdatingWatchlist {
                    ProgressView()
                } else {
                    Label(
                        viewModel.isTracked ? "Tracking" : "Track",
                        systemImage: viewModel.isTracked ? "star.fill" : "star"
                    )
```

VoiceOver will likely say something vague like “Progress indicator” instead of “Updating watchlist.” That’s the clearest gap.

**2. Detail header still uses a `Label` with a TV icon for show status**

```109:109:NextSeason/Features/ShowDetail/ShowDetailView.swift
                Label(viewModel.displayShow.status.displayLabel, systemImage: "tv")
```

You removed icons from the next-season line for visual consistency; this one remains. VoiceOver may include extra icon noise (“tv”) before the status text.

**3. No custom labels on watchlist rows**

Search rows set an explicit `accessibilityLabel`; watchlist rows don’t. Combined children usually work, but reading order and verbosity are less controlled — especially with the stale warning `Label` plus “Updated …” timestamp.

**4. Initial detail loading**

Before the view model exists, the screen is an unlabeled `ProgressView()`. VoiceOver may not explain that show details are loading.

**5. No announcements for state changes**

Tracking a show, finishing a load, or getting a notification prompt won’t be announced automatically. VoiceOver users only discover those by moving focus again.

**6. Not tested on device**

There’s no evidence of VoiceOver testing in the project — no accessibility previews, UI tests, or manual test notes. SwiftUI often behaves well by default, but toolbars, `NavigationLink`, `GroupBox`, and `alert` are worth verifying on a real device.

## Bottom line

| Area | Expectation |
|---|---|
| Tab navigation | Should work |
| Search results | Should work well |
| Watchlist rows | Should mostly work; may be verbose |
| Detail content reading | Should work |
| Track / untrack action | Works, except during loading |
| Alerts & links | Should work |
| Dynamic Type | Should work |
| Polish / confidence | Not yet — needs a VoiceOver pass |

So: **usable for MVP, not something I’d call “done.”** The highest-value fixes would be:

1. Keep a text label on the Track button while `ProgressView` is showing (e.g. “Updating…”).
2. Change the header status from `Label(..., systemImage: "tv")` to plain `Text`.
3. Add an explicit `accessibilityLabel` to `WatchlistRow`, mirroring `ShowRow`.
4. Run a 15-minute VoiceOver walkthrough on device: search → detail → track → watchlist → delete.

I can implement those accessibility improvements if you want.

## User

Yes, please create a branch and implement.

## Assistant

Creating a branch and implementing the VoiceOver improvements we identified.

### Tool Run Terminal Command V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":28,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift"}
```

## Assistant

Implementing VoiceOver fixes: labeled loading states, explicit watchlist row labels, and a clearer Track button.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Fixing the unlabeled loading state in `WatchlistView`.

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistRow.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift"]}
```

### Tool Unspecified

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason","branchName":"cursor/voiceover-accessibility"}
```

## Assistant

Branch `cursor/voiceover-accessibility` is ready with these VoiceOver improvements:

### ShowDetailView
- **Initial load** — `ProgressView("Loading show…")` instead of an unlabeled spinner
- **Track button** — always keeps a text label; shows “Updating…” with a spinner while toggling
- **Track button hint** — explains when disabled (“Available after show details finish loading”)
- **Show status** — plain `Text` instead of `Label` with a TV icon

### WatchlistRow
- **Explicit `accessibilityLabel`** — name, next-season status, stale warning (if any), and last-updated date
- **Stale warning** — plain `Text` instead of a `Label` with an icon (avoids extra icon noise)

### WatchlistView
- **Initial load** — `ProgressView("Loading watchlist…")` when the view model isn’t ready yet

**What to test with VoiceOver on:**
1. Search → open a show → confirm “Loading show…” is announced
2. Track / untrack → confirm “Updating…” is announced during the toggle
3. Watchlist row → confirm one clear announcement with all key info
4. Detail header → confirm status reads without “tv” icon noise

Want me to commit this or open a PR?

## User

There are build errors in ShowDetailView;  please fix

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"]}
```

## Assistant

Fixing a missing closing brace in `trackButtonHint`.

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"]}
```

## Assistant

The build error was a missing closing brace on `trackButtonHint()` — the function body wasn’t closed before `header(viewModel:)` started. That’s fixed now; rebuild and it should compile.

## User

I just noticed that when I tap in the search box the navigation stack title slides up and disappears.  Is that typical SwiftUI behavior or are you doing it on purpose?

## Assistant

Checking how search is wired into the navigation stack.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"navigationTitle|searchable|navigationBarTitleDisplayMode","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_3e595524-4b0d-439b-a25c-13546940afd","offset":0}
```

## Assistant

That's typical SwiftUI / iOS behavior — nothing in the app is explicitly hiding the title.

In `SearchView`, the title is set with the default large-title style:

```15:19:NextSeason/Features/Search/SearchView.swift
                .navigationTitle("NextSeason")
                .navigationDestination(for: Show.self) { show in
                    ShowDetailView(show: show)
                }
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
```

There’s no `.navigationBarTitleDisplayMode(.inline)` here, so iOS uses a **large title**. When `.searchable` is active and the field is focused, the system collapses that large title to make room for the search bar. That slide-up animation is built into UIKit/SwiftUI.

By contrast, `ShowDetailView` uses `.navigationBarTitleDisplayMode(.inline)`, so its title stays compact and doesn’t behave the same way.

If you want the search tab to feel more stable, common options are:

1. **`.navigationBarTitleDisplayMode(.inline)`** — compact title that stays put while searching (similar to Watchlist/detail).
2. **Different search placement** — e.g. `.searchable(..., placement: .toolbar)` or drawer display modes on newer iOS versions, depending on the look you want.

So: expected system behavior, not intentional custom logic. I can change it if you prefer a fixed inline title on Search.

## User

Ok, it's fine to leave it.

## Assistant

굿 — we'll leave the large title as-is. It's standard iOS search behavior, and the current setup is fine for the MVP.
