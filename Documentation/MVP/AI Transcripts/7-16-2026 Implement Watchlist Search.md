# Wishlist search feature

## User

Please add a search feature to the Wishlist, with the search bar at the top of the list.

## Assistant

I'll explore the codebase to understand the Wishlist feature and how the app is structured.

I notice the app uses "Watchlist" terminology. Let me check if "Wishlist" exists anywhere and read the main Watchlist view.

The app uses "Watchlist" (there's no "Wishlist" feature), so I'll add search to the Watchlist. Let me read the ViewModel and supporting types.

Let me check the `TrackedShow` model and how search is done in the existing Search feature for consistency.

Let me look at how `AccessibilityID` is defined in the app and check the empty-state / search-empty patterns.

I have enough context. The app uses "Watchlist" (no "Wishlist" feature exists), so I'll add search there.

My plan:
1. `WatchlistViewModel`: add a `searchText` property and a `filteredShows` computed property (case/diacritic-insensitive name match).
2. `WatchlistView`: render `filteredShows`, add a `.searchable` bar pinned at the top of the list, and show a "no matches" state when a search returns nothing.
3. Add accessibility identifiers for the search field and no-results state.

Let me make the changes.

Now update the view. First the List content to use `filteredShows`:

Now the animation value, searchable modifier, and overlays:

Now add the `noSearchResults` view. Let me add it after `emptyState`:

Now add the `noResults` accessibility identifier:

Let me verify the final view changes are correct and consistent:

Let me verify the build compiles.

The simulator service isn't reachable in the sandbox. Let me retry outside the sandbox.

The build succeeds. Here's what I changed.

## Summary

The app's saved-shows feature is called the **Watchlist** (there's no "Wishlist"), so I added a search bar to filter it. Since filtering is purely local, the full list stays intact so removal/undo animations keep working.

**`WatchlistViewModel.swift`**
- Added a bindable `searchText` property and a `filteredShows` computed property that narrows `shows` by name using `localizedStandardContains` (case- and diacritic-insensitive). Empty/whitespace queries return all shows.

**`WatchlistView.swift`**
- Added `.searchable(...)` with `placement: .navigationBarDrawer(displayMode: .always)` so the search bar is pinned at the top of the list, with the prompt "Search Watchlist".
- The `ForEach` and list animation now drive off `filteredShows` instead of `shows`.
- Added a `noSearchResults` state (a `ContentUnavailableView`) shown when a search matches nothing but the watchlist isn't empty. The original "No Tracked Shows" empty state still shows only when the watchlist is genuinely empty.

**`UITestingConfiguration.swift`**
- Added `AccessibilityID.Watchlist.noResults` for the no-matches state.

A design note: I kept `.searchable` applied unconditionally (even on an empty watchlist) rather than toggling it based on show count. Toggling it would change the `List`'s view identity when the last row is removed, which the existing code explicitly warns against (it can crash `UICollectionView` mid-animation).

## What to test
- Open the Watchlist with several tracked shows; confirm the search bar sits at the top and filtering by partial name works (try mixed case and accented characters).
- Search for something with no match and confirm the "No Matches" message appears with your query.
- Clear the search and confirm all shows return.
- Swipe/track-button removal + undo still animates correctly while a search is active and when it's empty.
- Empty watchlist still shows the "No Tracked Shows" / "Find a Show" empty state.

Want me to add a UI test covering the search + no-results flow, or tweak the search-bar behavior (e.g. hide on scroll instead of always-visible)?

## User

Please add any applicable tests

## Assistant

I'll look at the existing WatchlistViewModel tests to match style and conventions, then add tests for the new search filtering.

Let me check the repository's `add` method and the swift-testing skill for best practices.

I'll add search-filtering tests to the existing suite, matching its style. First a helper to build shows with distinct ids/names, then the tests.

Now let me run the test suite to confirm the new tests pass.

All tests pass. 

## Summary

I added unit tests for the new Watchlist search filtering in `NextSeasonTests/WatchlistViewModelTests.swift`, matching the existing Swift Testing style.

**Refactors to reduce duplication:**
- `makeShow(id:name:)` — builds a `Show` with distinct id/name (the old fixed `sampleShow` now delegates to it).
- `loadedViewModel(with:)` — a helper that creates a view model backed by an `InMemoryWatchlistRepository`, seeds it with shows, and reloads.

**New tests (covering `searchText` / `filteredShows`):**
- `emptySearchReturnsAllShows` — no query shows everything.
- `whitespaceQueryReturnsAllShows` — whitespace-only query is treated as no filter.
- `searchMatchesPartialName` — partial substring matching.
- `searchIgnoresCaseAndDiacritics` — parameterized over `"POKEMON"`, `"pokemon"`, `"pokémon"` to verify case- and diacritic-insensitivity.
- `searchWithNoMatchesReturnsEmpty` — non-matching query returns an empty filtered list while the backing list is untouched.
- `filteringDoesNotMutateBackingList` — confirms `filteredShows` never mutates `shows` (important since removal/undo animations depend on the full list).

All 13 tests in the suite pass (the parameterized case runs 3 times). These are model-level tests; the `.searchable` UI wiring itself isn't unit-testable via Swift Testing (that'd require an XCUITest). Let me know if you'd like me to add a UI test for the search bar and no-results state.

## User

Yes, please add UI tests too

## Assistant

I'll look at the existing UI test infrastructure to match conventions.

Let me read the existing UI test files to understand how they add shows to the watchlist and their structure.

The stub only has one preview show ("Severance"). Let me check how the stubbed search service works to see if I can get multiple shows into the watchlist for filtering tests.

The stub returns a single show ("Severance") for any query, so the watchlist can only hold one show in UI tests. That's still enough to test the search bar filtering behavior. Let me verify how the watchlist search bar exposes itself (searchField accessor uses "Search TV shows" — I need the "Search Watchlist" one) and check where the stub is wired.

The stub returns only "Severance" for any query, so the watchlist holds a single show in UI tests — still enough to verify the search bar filters it in/out. Let me add the base-class accessors for the watchlist search field and no-results element, plus the `noResults` ID.

Now create the UI test file. First let me check whether the project auto-includes files (Xcode 16 synchronized groups) or needs manual registration.

The project uses synchronized file groups, so new files are auto-included. Now I'll create the UI test file.

Now let me run the new UI tests.

The UI test run is taking a long time (build + simulator boot + 4 UI tests). Let me keep waiting.

The `rg | head` pipe is block-buffering, so nothing shows until xcodebuild finishes. Let me wait for completion.

Mixed results — one passed, three failed, but with signs of a badly overloaded simulator (a runner even failed with "Timed out waiting for AX loaded notification", and tests took 200–337s each). Notably, `testWatchlistClearingSearchRestoresRow` passed, and it exercises the whole flow (find search field, type, no-results appears, clear, row restored). That suggests the failures are parallel-execution flakiness rather than logic errors. Let me re-run serially with parallelism disabled to confirm.

Exit code 0 — serial run passed. Let me confirm the details.

All 4 UI tests pass when run serially (the earlier failures were parallel-execution flakiness — the machine was overloaded, and one runner even failed to initialize with an AX timeout). Let me clean up the temp log.

All UI tests pass. Here's what I added.

## Summary

UI tests exercise the Watchlist search end-to-end. Since the UI-test stub returns a single show ("Severance") for any query, the tests verify filtering behavior with that one tracked show.

**`NextSeasonUITests/NextSeasonUITestCase.swift`** (shared harness)
- Added `watchlist.noResults` to `UITestAccessibilityID.Watchlist` (matches the app-side ID).
- Added element accessors `watchlistNoResults` and `watchlistSearchField` (the field's placeholder is "Search Watchlist", distinct from the Search tab's "Search TV shows").
- Added `searchWatchlist(for:)`, `clearWatchlistSearchField()`, and `watchlistSearchFieldText()` helpers, mirroring the existing Search-tab helpers (including the keyboard-dismiss and clear-button fallbacks).

**`NextSeasonUITests/WatchlistSearchUITests.swift`** (new)
- `testWatchlistExposesSearchFieldWhenShowsTracked` — the search field appears at the top once a show is tracked.
- `testWatchlistSearchKeepsMatchingRowVisible` — typing "Sev" keeps the Severance row and shows no "no matches" state.
- `testWatchlistSearchWithNoMatchShowsNoResults` — a non-matching query hides the row and shows the no-matches state.
- `testWatchlistClearingSearchRestoresRow` — clearing the query restores the row and dismisses the no-matches state.
- Private helper `trackPreviewShowAndOpenWatchlist()` seeds the watchlist via the Search tab, then switches to the Watchlist tab.

## A note on the test run
The first (default) run failed 3 of 4 tests, but that was **parallel-execution flakiness** — the simulator was overloaded (tests took 200–337s and one runner failed to initialize with "Timed out waiting for AX loaded notification"). Re-running with `-parallel-testing-enabled NO` passed all 4 cleanly (16–47s each). If your CI runs these in parallel clones, watch for that; you may want to run the UI test target serially or give it more simulator headroom.

The earlier unit tests (`WatchlistViewModelTests`) also still pass. Want me to also verify the full UI test suite runs green, or is this scoped run sufficient?

## User

This is good;  I'll run them, they seem to run faster when I do it.

## Assistant

Sounds good. Everything's in place:

- **Feature:** search bar pinned at the top of the Watchlist (`WatchlistViewModel.filteredShows` + `.searchable` in `WatchlistView`), with a "No Matches" state.
- **Unit tests:** `WatchlistViewModelTests` covering empty/whitespace queries, partial matches, case/diacritic-insensitivity, no-match, and backing-list integrity.
- **UI tests:** `WatchlistSearchUITests` covering the search field, matching, no-results, and clear-to-restore.

Go ahead and run them locally. If anything comes back red, send me the failure output and I'll dig in.

## User

The UI tests are showing two errors:

testSwitchToWatchlistTabShowsEmptyState():
XCTAssertTrue failed - Watchlist tab should show the empty state when no shows are tracked.

trackPreviewShowAndOpenWatchlist():
testWatchlistSearchKeepsMatchingRowVisible(): XCTAssertTrue failed - The search-row track button should reflect the tracked state.

## Assistant

Before changing anything, let me determine whether these are real regressions or the same parallel-run flakiness we saw. I'll run the pre-existing empty-state test and the last-row-removal test in isolation, serially.

Good — this is very informative:

- **`testSwitchToWatchlistTabShowsEmptyState` passed in isolation** (34s). So my always-on search bar does *not* break the empty state; that failure was parallel-run flakiness.
- **`testRemoveLastShowViaStarShowsUndoThenEmptyState` failed**, but the failure is `Neither element nor any descendant has keyboard focus` on the **Search-tab** field (`label: 'Search TV shows'`) inside the pre-existing `search(for:)` helper — a known keyboard-focus flake, unrelated to the Watchlist search feature.

So both failures you saw are environmental flakiness, not real regressions. That said, one of the failures was in *my* helper, so I'll make it more robust: the "search-row track button should reflect the tracked state" assertion depends on async tracking reflecting back onto the search row (flaky under load). The real goal is just getting a show onto the watchlist, which is confirmed by the watchlist row appearing.

Let me run the full `WatchlistSearchUITests` suite serially to confirm the more robust helper still passes.

The failure is again the **pre-existing Search-tab keyboard-focus flake** (`NextSeasonUITestCase.swift:370`, `label: 'Search TV shows'`) — it happens while my helper types into the *Search tab* to seed the watchlist. The 3 watchlist-search assertions themselves all passed.

I can sidestep this entirely: the app's "Try an Example" button prefills and runs the search for "Severance" without any manual typing, avoiding the flaky Search-tab keyboard interaction. I'll also harden my watchlist-search helper to wait for keyboard focus before typing.

Now harden the watchlist search helper to wait for keyboard focus before typing:

All 4 pass again, now with the flaky Search-tab typing removed from the seeding path. Let me clean up the temp logs.

Diagnosis and fix, in short:

## What the two failures actually were
Neither was a real regression from the Watchlist search feature:

1. **`testSwitchToWatchlistTabShowsEmptyState`** — passed cleanly in isolation (34s). My always-on search bar does not break the empty state; this was parallel-run flakiness (the machine was overloaded, as it was in our very first run where a test runner even failed with an AX-load timeout).

2. **`testWatchlistSearchKeepsMatchingRowVisible` (via my `trackPreviewShowAndOpenWatchlist`)** — the underlying cause was a pre-existing **Search-tab keyboard-focus flake**: `search(for:)` taps the "Search TV shows" field and immediately types, and under load the focus handoff loses the key events (`Neither element nor any descendant has keyboard focus`). My helper only used that path to seed a tracked show.

## What I changed (test-only)
- **`WatchlistSearchUITests.swift`** — `trackPreviewShowAndOpenWatchlist()` now seeds via the app's **"Try an Example"** button (which prefills/runs the "Severance" search with no manual typing), then taps Track and verifies the **watchlist row appears** (the real signal that tracking persisted) instead of asserting the search-row star flips.
- **`NextSeasonUITestCase.swift`** — `searchWatchlist(for:)` now waits for the keyboard to appear after tapping the field before typing, so the watchlist search field reliably has focus.

No changes to the feature code or to unrelated shared helpers. Verified: `WatchlistSearchUITests` passes 4/4 serially (two consecutive green runs).

## Recommendation
Your UI test target is prone to flakiness when Xcode runs tests in parallel simulator clones (we saw 3/4 fail in parallel vs 4/4 pass serially). If you can, run the UI test target with **parallel execution disabled** (or fewer clones). The remaining flakes I saw are all in the pre-existing `search(for:)` Search-tab typing path — if you'd like, I can harden that shared helper (wait for keyboard focus + retry) so the whole suite is more stable, but I left it untouched for now since it's outside this feature's scope.

## User

Go ahead

## Assistant

I'll harden the shared `search(for:)` helper. Let me read its current form and the surrounding line numbers.

I'll add a shared `focusSearchField(_:)` helper that taps and waits for the keyboard (retrying the tap), then route all four search/clear helpers through it. Let me add the helper and update `search(for:)` and `clearSearchField`.

Now update the watchlist helpers to route through `focusSearchField` for consistency:

Let me verify both clear helpers are intact after the edits.

Both helpers are intact. Now let me run the full UI test target serially to confirm the hardened helpers work across all tests that type into search fields.

The full UI target passed (exit 0). Let me confirm the summary and check for any flake retries.

All 26 UI tests pass with zero failures and — importantly — **no "keyboard focus" flakes** anywhere in the log (previously `testRemoveLastShowViaStarShowsUndoThenEmptyState` failed on exactly that). Let me clean up.

Done. I hardened the shared keyboard-focus handling in the UI test harness.

## What changed (`NextSeasonUITests/NextSeasonUITestCase.swift`)
- Added a shared `focusSearchField(_:)` helper that taps a search field and waits for the keyboard to appear, **retrying the tap** until focus is confirmed (or a timeout). This addresses the root cause of the flake: XCUITest drops synthesized key events when `typeText` races the focus handoff to a `.searchable` field.
- Routed all four search/clear helpers through it:
  - `search(for:)` — now focuses immediately before typing (also fixes a latent bug where clearing first could leave the field unfocused before `typeText`).
  - `clearSearchField(...)`, `searchWatchlist(for:)`, `clearWatchlistSearchField()` — all use `focusSearchField` instead of a bare `.tap()`.

## Result
Full UI target, serial run: **26/26 passed, 0 failures**, with no `Neither element nor any descendant has keyboard focus` errors in the log — including `testRemoveLastShowViaStarShowsUndoThenEmptyState`, which was failing on that exact flake before.

Net state of the whole task:
- Feature: Watchlist search bar pinned at top, with a "No Matches" state.
- Unit tests: `WatchlistViewModelTests` (7 search cases).
- UI tests: `WatchlistSearchUITests` (4 cases) + hardened shared keyboard helpers benefiting the entire suite.

Note these were still run serially. Parallel clone runs may still be slow/contended on a loaded machine, but the keyboard-focus flake specifically should now be resolved regardless of parallelism.

## User

I have another error now, in settingsEntryPointClearsDeferWhenUndetermined(): Expectation failed: await service.needsAuthorizationPrompt(): // User explicitly opted in; the system prompt would appear on a real device.

If that is also from running the tests in parallel, then where should I set -parallel-testing-enabled to NO?

## Assistant

Let me find that failing test to see whether it's parallel-related or a real issue.

This is a **test-isolation bug**, not really "parallel" in the UI-clone sense. Let me confirm the mechanism and check for a test plan.

Confirmed the root cause. It's a **unit-test isolation bug**, and it's pre-existing (I didn't touch these files). Here's the mechanism:

All `NotificationServiceTests` share one `UserDefaults` suite named `"NotificationServiceTests"`. Swift Testing runs test functions **in parallel in-process** by default. Even though the suite is `@MainActor`, each test suspends at its `await` points, letting another test's synchronous writes interleave:

- Your test clears the defer flag via `enableNotificationsFromSettingsEntryPoint()`, then at the next `await` another test runs `makeDefaults()` (wipes the shared suite) and `deferAuthorizationPrompt()` (re-sets the flag) in the *same* suite — so your final `needsAuthorizationPrompt()` reads a defer flag it never set and returns `false`, failing the expectation.

Important nuance: `-parallel-testing-enabled NO` only controls **UI-test simulator clones**. It does **not** stop Swift Testing's in-process parallelism, so it wouldn't fix this. The correct fix is to isolate state per test.

I'll give each service its own unique `UserDefaults` suite so parallel tests can't clobber each other.

Now let me run the NotificationServiceTests (in default parallel mode) a few times to confirm the isolation fix holds.

All 7 tests pass in all 3 runs (in default parallel mode), including `settingsEntryPointClearsDeferWhenUndetermined()`. The isolation fix holds.

## Summary

**The error was a test-isolation bug, not UI-clone parallelism.** All `NotificationServiceTests` shared one `UserDefaults` suite (`"NotificationServiceTests"`). Swift Testing runs test functions in parallel in-process, and at each `await` suspension another test's synchronous `makeDefaults()`/`deferAuthorizationPrompt()` could clobber the shared defer flag — so `settingsEntryPointClearsDeferWhenUndetermined()` occasionally read a flag it never set.

**Fix** (`NextSeasonTests/NotificationServiceTests.swift`): each service now gets a **unique** suite name (`"NotificationServiceTests.<UUID>"`), so parallel tests can't interfere. This keeps parallelism (fast) and removes the shared mutable state. Verified: 3 consecutive parallel runs, 7/7 passing each time.

## Where to control parallelism (your question)

There are two *separate* parallelism systems:

1. **UI tests (XCUITest) — simulator clones.** This is what `-parallel-testing-enabled NO` controls. Set it via any of:
   - **Command line:** `xcodebuild ... -parallel-testing-enabled NO`
   - **Scheme:** Product → Scheme → Edit Scheme → **Test** → expand the UI test target → **Options…** → uncheck **"Execute in parallel on Simulator"**
   - **Test plan** (if you add one): the target's **"Execute in parallel (if possible)"** toggle

2. **Unit tests (Swift Testing) — in-process tasks.** `-parallel-testing-enabled NO` does **not** affect these. If you ever want to serialize a Swift Testing suite, annotate it: `@Suite(.serialized) struct MyTests { … }`. But the better fix (which I applied here) is per-test isolation rather than serializing.

My recommendation: keep the unit tests parallel (they're now properly isolated), and only consider disabling clone parallelism for the **UI** target if your machine gets overloaded — that's purely a speed/stability tradeoff, since the keyboard-focus fix already removed the main UI flake.

No app/feature code changed in this step — only the test's `UserDefaults` isolation.
