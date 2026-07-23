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

Implementing fixes: adaptive update window from `lastCheckedAt`, load-once detail view, notification pre-prompt, and aligned `deliver()` authorization.

Updating `requestAuthorizationIfNeeded` to reuse the shared helper and adding tests.

Fixing the detail view: `.task(id:)` still runs on every appearance, so we'll skip reload when the view model already matches the show.

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

Likely cause: comparing to `.notDetermined` without importing UserNotifications. Adding a helper on `NotificationService` to keep that dependency out of the view model.

The build error was from comparing to `.notDetermined` in `ShowDetailViewModel` without importing `UserNotifications` — that enum case isn’t visible with only `Foundation` imported.

I fixed it by moving that check into `NotificationService`:

```swift
func needsAuthorizationPrompt() async -> Bool
```

`ShowDetailViewModel` now calls `notifications.needsAuthorizationPrompt()` instead of referencing `UNAuthorizationStatus` directly. Rebuild and it should compile.

## User

We removed the system image next to the show status from the watchlist view, but it's still there on the detail view.  Please remove it from there too.

Removing the next-season status icon in the detail view to match the watchlist's plain text headline.

Removing the unused `systemImage` property now that nothing references it.

Removed the SF Symbol from the **Next Season** section on the detail view so it matches the watchlist: plain `Text(status.headline)` instead of a `Label` with an icon.

Also removed the now-unused `systemImage` property from `NextSeasonStatus+Display.swift`.

**To verify:** Open a show detail and confirm the next-season line in the group box has no icon, consistent with watchlist rows.

## User

Please commit and merge to main.

## Assistant

Checking git state, then committing and merging to main.

Staging all changes, committing, then merging into main.

Retrying with your approval — committing all branch work, then merging to main.

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

Pushed `main` to `origin/main` (`0440311..f7d1598`). Both local commits are now on the remote:

1. `2560733` — Add local watchlist with notifications and background refresh
2. `f7d1598` — Address Phase 4 Slice 2 review items and polish detail UI

## User

Have you considered VoiceOver?  Do you expect it to work correctly?

## Assistant

Reviewing VoiceOver-related accessibility across the app's views and interactions.

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

Implementing VoiceOver fixes: labeled loading states, explicit watchlist row labels, and a clearer Track button.

Fixing the unlabeled loading state in `WatchlistView`.

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

Fixing a missing closing brace in `trackButtonHint`.

The build error was a missing closing brace on `trackButtonHint()` — the function body wasn’t closed before `header(viewModel:)` started. That’s fixed now; rebuild and it should compile.

## User

I just noticed that when I tap in the search box the navigation stack title slides up and disappears.  Is that typical SwiftUI behavior or are you doing it on purpose?

## Assistant

Checking how search is wired into the navigation stack.

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
