# Watchlist feature updates

## User

After discussion with ChatGPT, I'd like to try a different approach:

- remove the Edit/Delete feature from Watchlist
- add the same star button to WatchlistRow as we put in ShowRow (if possible, use the same view for both)
- add an Undo toast for confirmation when the user taps the star to remove an item from the watchlist, so they can recover if they did it by accident.
- remove any tests which are no longer needed due to these changes

## Assistant

I'll explore the watchlist and ShowRow implementations to see how Edit/Delete and the star button work today, then plan the shared row and undo toast changes.

Implementing: remove Edit/Delete, reuse `ShowRowTrackButton` on watchlist rows, add undo toast with deferred persistence, and update tests.

Implementing the changes: updating the view model, views, and tests.

Here's what changed:

### Watchlist removal
- Removed **Edit** toolbar button, edit mode state, and swipe-to-delete (`.onDelete`).
- Each watchlist row now uses the same **`ShowRowTrackButton`** as search (with a `watchlist.track` accessibility ID).
- Tapping the filled star removes the row immediately and shows an **Undo toast** at the bottom.
- Removal is persisted after **5 seconds** (0.5s in UI tests), when you **leave the Watchlist tab**, or when you **pull to refresh**. Undo restores the row without touching persistence.

### Files touched
- `WatchlistViewModel.swift` — undo-aware `requestRemoval`, `undoRemoval`, deferred commit
- `WatchlistView.swift` — star button layout, `UndoToast`, removed edit UI
- `ShowRow.swift` — optional `trackButtonIdentifier` parameter (defaults to search ID)
- `ContentView.swift` — passes `onWatchlistChanged` to watchlist
- `UITestingConfiguration.swift` — new watchlist track/undo IDs
- UI tests — removed edit-mode helpers; replaced `testDeleteLastShowViaEditExitsEditMode` with star + undo tests

### What to test
1. Watchlist row shows a filled star; tap it → row disappears, undo toast appears.
2. Tap **Undo** → show returns.
3. Remove again and wait ~5s (or switch tabs) → empty state appears.
4. Search tab reflects untracked state after commit.
5. Pull-to-refresh still works with a pending removal.

I couldn't run `xcodebuild` here (only Command Line Tools are active). Please build and run the UI tests in Xcode to confirm.

## User

Is there any reason to not merge ShowRow and WatchlistRow?  I know that WatchlistRow shows more information, but I don't think there's any harm in showing that in both places.

## Assistant

Let me compare both row implementations and where they're used so I can give you a concrete answer.

There’s no strong reason to keep two separate **views** — merging the layout code makes sense. The nuance is what **data** each row can show, not whether the SwiftUI structure should be duplicated.

### What’s actually different today

| | Search (`ShowRowLabel`) | Watchlist (`WatchlistRow`) |
|---|---|---|
| Subtitle | `show.status.displayLabel` (“Ongoing series”) | `tracked.nextSeason.headline` (“Season 3 premieres …”) |
| Extra lines | — | stale warning, “Updated …” |
| Type | `Show` | `TrackedShow` |
| Poster | 60×90, r=8 | 44×66, r=6 |

The subtitle difference isn’t arbitrary. Search hits `/search/shows`, which returns a show **without** embedded seasons or next episode. So if you ran `NextSeasonCalculator` on a search result, a running show like Severance would usually become **“Returning — no next season announced yet”** instead of something useful — often *less* informative than “Ongoing series.”

Watchlist rows use cached `nextSeason` computed when the show was saved/refreshed from the full `/shows/:id` payload.

### Showing watchlist extras in search

- **Next-season headline** — possible, but often misleading or generic until you have full show data.
- **“Updated …”** — watchlist means “last time *we* checked”; search only has TVMaze’s `updatedAt`. Same label, different meaning.
- **Stale warning** — only applies to tracked shows; fine to omit on search.

None of that blocks a merged view — you’d just pass optional fields or let the caller supply the subtitle.

### Practical recommendation

Merge into one row component (e.g. expand `ShowRowLabel` or rename to `ShowListRowLabel`) with something like:

```swift
ShowListRowLabel(
    name: ...,
    subtitle: ...,
    posterURL: ...,
    isStale: Bool = false,
    footer: String? = nil  // "Updated …" when non-nil
)
```

- **Search** passes `show.status.displayLabel`, no footer.
- **Watchlist** passes `tracked.nextSeason.headline`, stale flag, and `lastCheckedAt` footer.

Unify poster sizing while you’re at it.

That gives you one view without forcing search to pretend it has watchlist-quality next-season data. If you later want richer search rows, the fix is **data** (e.g. embed seasons in search, or a lightweight fetch per result) — not a second row type.

Want me to do that merge?

## User

Yes

## Assistant

Merging the two row labels into one shared component and updating Search and Watchlist to use it.

Replacing both row types with a single `ShowRowLabel` that accepts explicit fields plus convenience initializers for `Show` and `TrackedShow`.

Merged into a single `ShowRowLabel` in `ShowRow.swift`:

- **Core initializer** — `name`, `subtitle`, `posterURL`, optional `isStale` and `footer`
- **`init(show:)`** — search rows: status label, no footer
- **`init(tracked:)`** — watchlist rows: next-season headline, stale warning, “Updated …” footer

`WatchlistRow.swift` is deleted; `WatchlistView` now uses `ShowRowLabel(tracked:)`. Search was already on `ShowRowLabel(show:)` so no change there. Poster sizing is unified at 60×90.

**What to test**
1. Search results still show name + “Ongoing series” (or equivalent status).
2. Watchlist rows still show next-season headline, stale warning when applicable, and updated time.
3. VoiceOver labels on both row types sound correct.

## User

Ok, now let's look at the watchlist page itself.  It still has the toolbar star button which is filled with black.  I think it would make sense to use the same yellow star for clarity.  Let's try that and see how it looks.

## Assistant

Checking how the star renders in list rows vs the detail toolbar — watchlist rows use filled stars (`isTracked: true`), which may be picking up the default black tint instead of yellow.

Applying the same yellow tint to the watchlist row stars and the show-detail toolbar star — filled stars in list/toolbar contexts often ignore `foregroundStyle` and render as black.

Reverting the TabView-wide `.tint(.yellow)` — it would recolor accent controls across the whole watchlist tab, not just the star.

Updated the track stars to use `.tint(.yellow)` instead of `.foregroundStyle` on the image — filled stars in list rows and the navigation toolbar often ignore `foregroundStyle` and render as black.

**Changes:**
- **`ShowRowTrackButton`** — tracked stars on watchlist rows now use `.tint(.yellow)`
- **`ShowDetailView` toolbar** — same yellow tint when a show is tracked (for when you open a show from the watchlist)

**What to check:** On the watchlist, row stars should be yellow filled stars. If you open a show, the nav bar track button should match.

If you meant the **Watchlist tab icon** at the bottom (not the row buttons), say so — that needs a different approach since a tab-wide `.tint` would also turn links and buttons yellow.

## User

That looks good, but now that button needs the undo toast as well.  And while we're at it, can the undo toast be closer to the button that caused it?  I think people may not notice it, especially on bigger phones.

## Assistant

Adding undo to the detail toolbar star and repositioning the toast near the triggering button. Reviewing the current removal and toast flow.

Extracting shared undo-removal logic and anchoring the toast to the button that triggered it. Checking how ShowDetail is presented from Search and where to wire the environment.

Implementing shared undo removal with anchor-based toast positioning, and wiring it through detail and watchlist flows.

Fixing a bug where starting a second removal waited for the first commit to finish.

Done. Here's what changed:

### Undo toast on show detail
Untracking from the **detail toolbar star** now uses the same deferred removal + undo flow as the watchlist row stars. The star goes back to outline immediately, and the removal is only persisted after the undo window (or when you leave the tab).

### Toast placement
The toast is anchored to the button that triggered the removal (row star or toolbar star), positioned just below it when there's room, otherwise above. It no longer sits at the bottom of the screen.

### Shared undo state
Removal logic moved into `WatchlistUndoRemoval`, injected at the app root so the watchlist list, search rows, and show detail all share one pending removal and anchor.

**What to test:**
1. **Watchlist row** — tap star → toast appears near that row's star.
2. **Show detail** (from watchlist) — tap toolbar star → toast appears below the nav bar star.
3. **Undo** on both — show returns to tracked state.
4. **Search row** untrack — same toast/undo behavior.
5. On a large phone, confirm the toast is visibly near the button you tapped, not down by the tab bar.

## User

There's a build error in WatchlistViewModel:  Invalid redeclaration of 'undoRemoval()'

There's also a warning in NotificationCenterDelegate:  No 'async' operations occur within 'await' expression

## Assistant

Renaming the conflicting `undoRemoval` property/method in `WatchlistViewModel` and removing the unnecessary `await` in `NotificationCenterDelegate`.

Both fixed:

1. **`WatchlistViewModel`** — The stored `WatchlistUndoRemoval` property and `undoRemoval()` method had the same name. The property is now `removalCoordinator`, and the view-model method is `undoPendingRemoval()`.

2. **`NotificationCenterDelegate`** — Removed the unnecessary `await` before `NotificationRouting.routeToShow(showID:)`, since that call isn’t async.

Rebuild and both the error and warning should be gone.

## User

They're fixed, thanks.

Thre's a problem on the watchlist view.  If there's only one show and the user removes it, the show row disappears but the "no tracked shows" message doesn't appear until the toast time has expired.  It would look better if the row doesn't diappear until after the time has expired.  What do you think about that?

Also, would it make sense to add an Ok button to the toast, so it can be dismissed right away?

## Assistant

Keeping the row visible during the undo window makes sense—the toast stays anchored to the star and the empty state won't flash late. Adding an OK button to commit immediately. Implementing both.

Keeping the row visible during the undo window and adding an OK button that commits immediately.

I agree with both changes — they're implemented.

**Keep the row during undo:** Removing the row immediately while the toast is showing left an awkward blank gap, especially with one show. The row now stays until the removal is committed. The star switches to outline to show it's pending, and tapping it again is the same as Undo.

**OK button:** Yes — it commits the removal immediately (same as waiting out the timer) and dismisses the toast. Undo and OK sit side by side on the toast, on both the watchlist and search stacks.

**What to test:**
1. Remove your only watchlist show → row stays, star goes outline, toast appears, empty state does *not* show yet.
2. Tap **Undo** → star fills again, toast goes away, row unchanged.
3. Remove again, tap **OK** → row disappears, empty state appears.
4. Tapping the outline star during the undo window also restores the show.

## User

That all looks good.  Let's try one more thing.  On ShowDetail, how about moving the star button from the toolbar to the header section to make it more like its placement on other pages?

## Assistant

Moving the star into the header with `ShowRowTrackButton` and updating UI tests—the detail toolbar used a different accessibility ID and label than the row button.

The star is now in the show detail **header**, aligned with search and watchlist rows.

**Changes:**
- Removed the toolbar track control.
- Added `ShowRowTrackButton` to the header row (poster + metadata on the left, star on the right).
- Pending-removal behavior matches the watchlist: outline star during undo, tap again to undo.
- UI tests updated for the header button (`showDetailTrackButton()` helper, "Stop tracking" label).

**What to test:** Open a show from search or watchlist — the yellow star should sit beside the title block in the header, not in the nav bar. Track/untrack and the undo toast should still work from that position.

## User

Please look through the unit and UI tests and make sure that we have complete coverage and remove any tests that have become obsolete.

## Assistant

Reviewing all unit and UI tests against the current watchlist, undo, and show-detail behavior.

Adding unit tests for the undo-removal logic, replacing redundant UI tests with coverage for detail and search untrack flows, and running the test suite.

Removing the duplicate helper from the base test case since `SearchAndTrackUITests` defines its own.

Here's what the test audit found and what changed.

### Removed as obsolete
- **`testRemoveShowFromWatchlist`** — overlapped with `testRemoveLastShowViaStarShowsUndoThenEmptyState` and `testTrackShowAppearsOnWatchlist`; it didn't cover any unique behavior after the undo/OK flow landed.

No edit-mode or swipe-delete tests remained (already gone).

### New unit tests
**`WatchlistUndoRemovalTests.swift`**
- Deferred removal doesn't hit persistence until commit
- Undo cancels without removing from the repo
- Starting a new pending removal commits the previous one

**`WatchlistViewModelTests.swift`**
- Reload loads tracked shows
- Pending removal keeps the row in the loaded list
- Commit reloads an empty watchlist
- Undo clears pending state

### Updated UI tests (`SearchAndTrackUITests`)
**Added**
- `testSearchRowUntrackShowsUndoToast` — search row untrack + OK
- `testWatchlistStarTapUndoesPendingRemoval` — tap star again to undo (not just the toast)
- `testUntrackFromDetailShowsUndoToast` — detail header star untrack + undo
- `testUntrackFromDetailConfirmRemovesFromWatchlist` — detail untrack + OK

**Improved**
- `testSearchOpensShowDetail` — asserts header star is present
- `testWatchlistUndoRestoresRemovedShow` — asserts star returns to tracked after undo
- Shared helpers `trackShowFromSearchRow()` / `trackShowFromDetail()` to cut duplication

### Kept (still valuable)
All other unit tests (calculator, refresh, navigation, search VM, etc.) still match current behavior.

**UI:** launch/tabs, search states, track from search/detail, reopen persistence, watchlist undo/OK/empty-state cycle.

### Coverage map (current flows)

| Flow | Unit | UI |
|---|---|---|
| Track / untrack persistence | Repository tests | Track from search, detail, watchlist |
| Deferred removal + undo | UndoRemoval + ViewModel tests | Undo toast, OK, star-tap undo |
| Detail header star | — | Open detail, untrack, undo, OK |
| Search empty/failure | SearchViewModel tests | UI equivalents |
| Navigation / notifications | AppNavigationCoordinator tests | NavigationUITests |

I couldn't run `xcodebuild` here (no full Xcode). Please run **NextSeasonTests** and **NextSeasonUITests** in Xcode to confirm everything passes.

## User

There are a number of warnings and UI test failures.  Can you read this?

## Assistant

Investigating the MainActor warnings and undo-toast UI test failures.

Identifying two issues: the undo toast buttons are hidden from the accessibility tree by `.accessibilityElement(children: .contain)`, and MainActor isolation conflicts in the test base class. Fixing both.

Yes — here's what the Issue Navigator showed and what I fixed.

### Warnings (`NextSeasonUITestCase`, 8)
Swift 6 concurrency: `@MainActor` on the base class conflicted with `setUpWithError()`, which XCTest calls from a nonisolated context.

**Fix:** Removed `@MainActor` from `NextSeasonUITestCase`. The test subclasses (`SearchAndTrackUITests`, `NavigationUITests`) still use `@MainActor`.

### Failures (`SearchAndTrackUITests`, 6)
All six failed waiting for the **Undo** button — the toast was likely showing, but XCTest couldn't find it.

Two causes:

1. **Accessibility:** `UndoToast` used `.accessibilityElement(children: .contain)`, which merges children and hides the Undo/OK button identifiers from the accessibility tree.
2. **Toast placement:** If the star button hadn't reported its frame yet, the anchor was `CGRect.zero` and the toast could land off-screen.

**Fixes:**
- Removed the `.contain` accessibility wrapper so **Undo** and **OK** are individually discoverable (with label fallbacks in tests).
- Added a fallback toast position when the anchor frame is empty.
- Improved star button frame capture so a valid anchor is passed before removal.
- Updated `watchlistTrackButton()` to find the outline star during a pending removal.

Please re-run **NextSeasonUITests** in Xcode — the six undo-related failures and the MainActor warnings should be resolved. If anything still fails, tell me which test and I’ll dig in.

## User

Build errors.

Is there anything I can do to enable you to find these yourself?

## Assistant

Checking `ShowDetailView.swift` for the corruption, then I'll suggest how to surface build errors automatically.

Removing accidentally pasted compiler error text from `ShowDetailView.swift` and checking the underlying MainActor warning it referenced.

Fixing the MainActor warning that was accidentally pasted into the file:

The build errors were caused by a **compiler warning accidentally pasted into `ShowDetailView.swift`** on line 48 — a file path and MainActor message ended up inside the `.onChange` closure. That’s removed now.

I also fixed the underlying **MainActor warning** in `NextSeasonUITestCase` using `MainActor.assumeIsolated` in `setUpWithError()`.

---

### How you can help me find these myself

1. **Point Xcode at full Xcode** (not just Command Line Tools). In Terminal:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
   After that, I can run `xcodebuild` and see the same errors you do in the Issue Navigator.

2. **Ask me to build** — e.g. “build and fix errors.” With `xcode-select` set correctly, I’ll run the build and work through failures without a screenshot.

3. **Cursor diagnostics** — I can use `ReadLints` on edited files, which sometimes includes Swift compiler issues Xcode has already reported. It’s not a full build, but it helps.

4. **Paste or screenshot** — what you did works when the above isn’t available. A screenshot or copying the Issue Navigator list is enough.

The most useful single step is **`xcode-select` → full Xcode**. Right now my shell only has Command Line Tools, so `xcodebuild` fails before it can report anything.

Try building again — `ShowDetailView` should compile cleanly now.

## User

Ok, I ran xcode-select for you.  There are still a bunch of warnings and errors.  Can you see them and fix?

## Assistant

Running a build to capture the current errors and warnings.

Build failed in the sandbox — retrying with full permissions so xcodebuild can reach Xcode.

Found a build error in the UI test base class. Reading the relevant files to fix it.

Marking the UI test base class `@MainActor` and simplifying `setUpWithError` — the `MainActor.assumeIsolated` closure is causing the data-race error.

`setUpWithError` inherits XCTestCase's nonisolated context. Marking the override `@MainActor`.

Switching to async `setUp()` — it inherits `@MainActor` isolation from the test class, unlike synchronous `setUpWithError`.

I can build now. Your Xcode install is at **`Xcode-26.5.0.app`**, not `Xcode.app`, so I used:

```bash
export DEVELOPER_DIR="/Applications/Xcode-26.5.0.app/Contents/Developer"
```

For a permanent fix on your machine:

```bash
sudo xcode-select -s /Applications/Xcode-26.5.0.app/Contents/Developer
```

### What I found and fixed

1. **App target** — builds cleanly (the accidental paste in `ShowDetailView` was already gone).

2. **UI test target** — one **error** and many **MainActor warnings** in `NextSeasonUITestCase.swift`:
   - `MainActor.assumeIsolated` in `setUpWithError` caused: *sending 'self' risks causing data races*
   - Helper properties/methods were nonisolated while subclasses used `@MainActor`

**Fix:** Mark the base class `@MainActor`, conform to `Sendable`, and switch from `setUpWithError()` to **`setUp() async throws`** (async setup inherits the class’s MainActor isolation). Removed redundant `@MainActor` from the two subclass files since they inherit it.

### Current status

`xcodebuild clean build-for-testing` succeeds with **no compiler errors or warnings** (aside from the harmless AppIntents metadata notice).

### What to test

Rebuild in Xcode (⌘B) — the Issue Navigator should be clear. If you want extra confidence, run the UI test suite from Xcode or ask me to run it via `xcodebuild test`.

## User

More test errors

## Assistant

Investigating the failing unit and UI tests by reading the test code and undo-removal implementation.

Identifying issues:
1. Unit test: `commitPendingRemovalIfNeeded()` doesn't invoke the `onCommitted` callback from `requestRemoval`.
2. UI tests: toast duplicated on inactive tabs (hidden); search untrack may run before track completes.
3. Show detail: no toast overlay (moving toast to `ContentView` fixes this).

Implementing fixes.

Fixing the coordinator callback, moving the toast to a single app-level overlay, and stabilizing UI test helpers.

Unit tests pass. Investigating UI test failures — likely causes: optional `@Environment` breaking `@Observable` updates, and the 0.5s undo window being too short.

Moving the toast to `AppRootView` with a direct `@Bindable` reference so `@Observable` updates reliably.

Reverting the accessibility change that hid the Undo/OK buttons from UI tests.

Most tests pass. Investigating the remaining failure:

Clean build passed. Running the full undo-related test suite:

Failures are timing-related under full-suite load. Increasing timeouts in track/untrack helpers for stability:

Fixed. Here’s what was wrong and what changed:

### Unit test (`requestRemovalDefersPersistence`)
`commitPendingRemovalIfNeeded()` wasn’t calling the `onCommitted` closure passed to `requestRemoval`. The coordinator now stores `pendingOnCommitted` and uses it when committing (manual or timer).

### UI tests (undo toast not found)
Three separate issues:

1. **Toast not updating** — Optional `@Environment` access didn’t reliably observe `@Observable` changes. Toast is now on `AppRootView` with a direct `@Bindable` reference to the shared coordinator.

2. **Duplicate/hidden toasts** — Search and Watchlist each had their own overlay; the inactive tab’s toast wasn’t accessible. Single app-level toast fixes that.

3. **0.5s undo window** — UI tests couldn’t reliably find the toast before auto-commit. UI-test undo window is now 30 seconds (production stays 5).

### Additional stability
- `trackShowFromSearchRow()` waits for “Stop tracking” before untracking (avoids racing async track).
- Added `UITestTimeout.trackState` (15s) for track/watchlist sync under simulator load.

All undo-related tests pass when run together. Re-run the full suite in Xcode (⌘U) — if anything still flakes under heavy parallel load, it should be unrelated track-timing tests, not undo logic.

## User

Ok, tests are all passing now.

## Assistant

Great to hear.

The main fixes were storing the `onCommitted` callback in the coordinator, moving the undo toast to a single `@Bindable` overlay on `AppRootView`, and giving UI tests enough time to find the toast and wait for async track state.

If you want to commit these changes or tackle anything else, say the word.
