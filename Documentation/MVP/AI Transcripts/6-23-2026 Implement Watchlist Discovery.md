# Watchlist discoverability feedback

## User

Please read "Watchlist Discoverability" in Release Roadmap.md and give me your thoughts/ideas.

The file I found is `Documentation/Post-MVP/Roadmap.md`, but it doesn't contain a section titled "Watchlist Discoverability" (the closest is "Watchlist Management"). Let me check whether there's a different file or section I'm missing.

## Assistant

The "Watchlist Discoverability" section is in `Documentation/MVP/Release Readiness.md`. Let me read it.

Now let me look at the current implementation to ground my thoughts in what actually exists. Let me examine the relevant views.

Let me check the search row and the tab/content structure to see how tracking state is surfaced in lists.

I've read the "Watchlist Discoverability" section (`Documentation/MVP/Release Readiness.md` lines 87–106) and cross-checked it against the current implementation. Here's where the app actually stands against each of the section's questions, plus concrete ideas.

## Current state vs. the section's questions

**"Is the Track button obvious?"** — Partially. The only way to track is: Search → tap a row → tap the star in the nav bar (`ShowDetailView.swift` `watchlistToolbarItem`, top-right `.primaryAction`). A toolbar star is iOS-conventional but subtle for non-technical users, and there's no track affordance at all in the search list (`ShowRow.swift`).

**"Is it clear when a show is already tracked?"** — Only inside detail (the button flips to `star.fill` / "Tracking"). In search results there's **no indicator**, so re-searching a show you already track gives you no signal. This is the biggest real gap.

**"Is it obvious how to remove a show?"** — Weakly. Removal is swipe-to-delete in `WatchlistView` (a hidden gesture, no visible affordance) or re-tapping "Tracking" in detail. The "Tracking" label is also slightly ambiguous as a toggle (does tapping start or stop?).

**"Is it obvious what the app does?"** — The empty/idle states are decent (`WatchlistView` "No Tracked Shows…", `SearchView` "Find Your Next Season…"), but they're passive text, not actionable. A true first-run/welcome is correctly deferred to Medium priority.

## Ideas, roughly in priority order

1. **Tracked badge in search results** — show a filled star (or "Tracking" chip) on `ShowRow` when the show is already on the watchlist. Directly answers "is it already tracked?" Requires plumbing the set of tracked IDs from the repository into `SearchViewModel`. Medium effort, high payoff.

2. **Actionable watchlist empty state** — `ContentUnavailableView` supports an `actions:` closure. Add a "Find a Show" button that flips `coordinator.selectedTab = .search`. Cheap, and it reinforces what the app is for far better than static copy.

3. **Visible removal affordance** — add an `EditButton` to the `WatchlistView` toolbar so delete isn't a hidden swipe. Low cost.

4. **Confirmation + sensory feedback on track** — currently you just see a spinner, then the state flips. Add `.sensoryFeedback` (success haptic) and a brief confirmation that restates the value ("Added — we'll notify you when its next season has a date"). This both gives "feedback when tracking begins" and quietly teaches what the app does. Note the first-track notification prompt ("Stay in the Loop") already exists, which is good.

5. **More prominent Track control in detail (debatable)** — consider a `.borderedProminent` Track button in the content (e.g. under the Next Season box) in addition to the toolbar star. More discoverable, but it competes with the iOS toolbar convention, so I'd weigh this against beta feedback rather than do it blindly.

## My recommendation

If you want to knock this section out before beta, I'd do **#2 and #3 now** (both are tiny, low-risk diffs), and **#1** as the one meaningful piece of work since it closes the genuine "already tracked?" gap. I'd hold **#4/#5** as polish to validate against beta observation (the section itself says to validate during beta).

A couple of these overlap with adjacent roadmap items worth keeping in mind: "First-Run Experience" (Medium) and "Visual Polish" empty-states, so I'd avoid over-investing in onboarding copy here and let that live in the dedicated first-run work.

Want me to implement any of these? I'd suggest starting with the empty-state button and EditButton, then the tracked badge.

## User

Yes, please implement 2, 3, 1 in that order.

## Assistant

I'll start by reading the supporting files I'll need to touch: the view models, repository, navigation coordinator, and the accessibility IDs.

Let me find the `AccessibilityID` definitions and check how the repository notifies of changes.

Let me check the `Show` model and the `WatchlistViewModel` to understand state and IDs.

Let me review the UI tests so my changes stay compatible with them.

Let me check the repository environment default and the `Show+Preview` helpers (since previews and tests rely on them).

Let me verify the repository is injected at the app root.

I have full context now. Let me set up a task list and implement in the requested order.

Per the project's AGENTS.md, I'll read the relevant SwiftUI skill before writing Swift.

Skill noted (`swiftui-pro`). Now implementing #2 and #3 in `WatchlistView`.

Now the empty state with the actionable button:

Now add `hasTrackedShows` to the `WatchlistViewModel`:

Now wire the `onFindShow` closure from `ContentView` to switch to the Search tab:

#2 and #3 are done. Now #1: the tracked badge in search results.

First, add the tracked indicator to `ShowRow`:

Now update `SearchView` to track which shows are on the watchlist and pass that into each row:

Let me review the final state of the modified files to make sure everything is consistent.

Everything looks consistent. Let me build to confirm it compiles. First let me find the Xcode project and an available simulator.

Xcode 26.5 is present but not the active developer dir. I'll point `xcodebuild` at it directly.

The simulator service couldn't run inside the sandbox. Let me retry outside the sandbox using a generic simulator destination (which only needs to compile, not boot a device).

No errors. Let me confirm the final build result explicitly.

Build succeeds. All three changes are implemented and compiling.

All three are implemented and the app builds cleanly (`BUILD SUCCEEDED`). I read the `swiftui-pro` skill before writing the SwiftUI changes, as required by AGENTS.md.

## What changed

**#2 — Actionable watchlist empty state** (`WatchlistView.swift`, `WatchlistViewModel.swift`, `ContentView.swift`)
- The empty state now has a prominent "Find a Show" button. Tapping it switches to the Search tab via a new `onFindShow` closure, which `ContentView` wires to `coordinator.selectedTab = .search`.
- Switched from `uiTestMarker` (which collapsed children with `children: .ignore`) to `.accessibilityElement(children: .contain)` + identifier, so the button stays reachable by VoiceOver while keeping the empty-state queryable by UI tests.

**#3 — Visible removal** (`WatchlistView.swift`, `WatchlistViewModel.swift`)
- Added an `EditButton` to the watchlist toolbar (`.topBarTrailing`), shown only when there are tracked shows (new `hasTrackedShows` computed property). This exposes the existing `onDelete` swipe action as a visible control. Swipe-to-delete still works.

**#1 — Tracked badge in search results** (`ShowRow.swift`, `SearchView.swift`)
- `ShowRow` gains an optional `isTracked` flag that renders a filled yellow star and adds an accessibility *value* of "Tracked" (I used `.accessibilityValue` rather than appending to the label, so the existing exact-label UI test queries still match).
- `SearchView` reads the watchlist repository from the environment, keeps a `Set<Int>` of tracked IDs, refreshes it on appear and whenever the navigation path changes (so it updates after you track/untrack in detail and pop back), and passes `isTracked` into each row.

## What to test
- **Empty watchlist:** "Find a Show" appears and jumps to the Search tab.
- **Edit button:** appears only when you have shows; tapping it reveals delete controls; deleting the last show returns to the empty state and hides Edit. Swipe-to-delete still works.
- **Tracked badge:** track a show, return to Search, re-run the same search — the row should show a star. Untrack it and the star should disappear after returning.
- **VoiceOver:** confirm the empty-state button is reachable and tracked rows announce "Tracked".

One note worth flagging: I scoped this to the existing two-tab architecture and didn't touch onboarding/first-run copy, since that's a separate Medium-priority roadmap item. The existing UI tests should still pass given the label/identifier choices above, but I couldn't run the simulator test suite here (the sandbox blocked CoreSimulatorService) — I verified compilation only. You may want to run `SearchAndTrackUITests` locally to confirm.

## User

Small problem - I went into the Wishlist tab, tapped the Edit button and removed the three tracked shows, from top to bottom.  The app crashed after I deleted the third one with this error:

*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid update: invalid number of items in section 0. The number of items contained in an existing section after the update (1) must be equal to the number of items contained in that section before the update (0), plus or minus the number of items inserted or deleted from that section (0 inserted, 0 deleted) and plus or minus the number of items moved into or out of that section (0 moved in, 0 moved out). Collection view: <SwiftUI.UpdateCoalescingCollectionView: 0x10ee88000; baseClass = UICollectionView; frame = (0 0; 402 874); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x10fc8ed00>; backgroundColor = UIExtendedSRGBColorSpace 0 0 0 0; layer = <CALayer: 0x10ef5c1e0>; contentOffset: {0, -168}; contentSize: {402, 190.66666666666666}; adjustedContentInset: {168, 0, 122.66666666666674, 0} topEdge=<style=soft backgroundCapture=sampled> bottomEdge=<style=soft backgroundCapture=sampled>; layout: <UICollectionViewCompositionalLayout: 0x105053200>; dataSource: <_TtGC7SwiftUI31UICollectionViewListCoordinatorGVS_28CollectionViewListDataSourceOs5Never_GOS_19SelectionManagerBoxS2___: 0x1022d6d00>>'
*** First throw call stack:
(
	0   CoreFoundation                      0x00000001804c3dec __exceptionPreprocess + 172
	1   libobjc.A.dylib                     0x0000000180063438 objc_exception_throw + 72
	2   Foundation                          0x0000000181075818 _userInfoForFileAndLine + 0
	3   UIKitCore                           0x0000000185abe9ac -[UICollectionView _Bug_Detected_In_Client_Of_UICollectionView_Invalid_Number_Of_Items_In_Section:] + 96
	4   UIKitCore                           0x0000000185abe224 -[UICollectionView _endItemAnimationsWithInvalidationContext:tentativelyForReordering:animator:collectionViewAnimator:] + 10420
	5   UIKitCore                           0x0000000185ac7d08 -[UICollectionView _endUpdatesWithInvalidationContext:tentativelyForReordering:animator:collectionViewAnimator:] + 132
	6   UIKitCore                           0x0000000185ac7f1c -[UICollectionView _performBatchUpdates:completion:invalidationContext:tentativelyForReordering:animator:animationHandler:] + 360
	7   SwiftUI                             0x00000001d2eb9778 $s7SwiftUI30UpdateCoalescingCollectionViewC19performBatchUpdates_10completionyyycSg_ySbcSgtFySbcfU_yyXEfU0_ + 232
	8   SwiftUI                             0x00000001d29a2b70 $sytIegr_Ieg_TR + 20
	9   SwiftUI                             0x00000001d2c0fff4 $sIeg_IyB_TR + 20
	10  UIKitCore                           0x0000000186aa608c +[UIView(Animation) performWithoutAnimation:] + 68
	11  SwiftUI                             0x00000001d2eb95fc $s7SwiftUI30UpdateCoalescingCollectionViewC19performBatchUpdates_10completionyyycSg_ySbcSgtFySbcfU_ + 1864
	12  SwiftUI                             0x00000001d28f9e1c $sSo23UIViewAnimatingPositionVIegy_ABIeyBy_TR + 40
	13  UIKitCore                           0x0000000185ac7aa4 -[UICollectionView _updateAnimationDidStop:finished:] + 1284
	14  libdispatch.dylib                   0x0000000100e77ee8 _dispatch_call_block_and_release + 24
	15  libdispatch.dylib                   0x0000000100e91374 _dispatch_client_callout + 12
	16  libdispatch.dylib                   0x0000000100e86ff0 _dispatch_main_queue_drain + 1208
	17  libdispatch.dylib                   0x0000000100e86b28 _dispatch_main_queue_callback_4CF + 40
	18  CoreFoundation                      0x0000000180422a94 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 12
	19  CoreFoundation                      0x0000000180421c6c __CFRunLoopRun + 1884
	20  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	21  GraphicsServices                    0x00000001933599c0 GSEventRunModal + 116
	22  UIKitCore                           0x00000001864a54cc -[UIApplication _run] + 776
	23  UIKitCore                           0x0000000186b9f910 UIApplicationMain + 120
	24  SwiftUI                             0x00000001d2ecdfa4 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_ + 164
	25  SwiftUI                             0x00000001d2ecdd18 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF + 180
	26  SwiftUI                             0x00000001d2c5f094 $s7SwiftUI3AppPAAE4mainyyFZ + 148
	27  NextSeason.debug.dylib              0x00000001010c6610 $s10NextSeason0aB3AppV5$mainyyFZ + 40
	28  NextSeason.debug.dylib              0x00000001010c748c __debug_main_executable_dylib_entry_point + 12
	29  dyld                                0x00000001004170e4 start_sim + 20
	30  ???                                 0x000000010024fe00 0x0 + 4297391616
)
libc++abi: terminating due to uncaught exception of type NSException
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid update: invalid number of items in section 0. The number of items contained in an existing section after the update (1) must be equal to the number of items contained in that section before the update (0), plus or minus the number of items inserted or deleted from that section (0 inserted, 0 deleted) and plus or minus the number of items moved into or out of that section (0 moved in, 0 moved out). Collection view: <SwiftUI.UpdateCoalescingCollectionView: 0x10ee88000; baseClass = UICollectionView; frame = (0 0; 402 874); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x10fc8ed00>; backgroundColor = UIExtendedSRGBColorSpace 0 0 0 0; layer = <CALayer: 0x10ef5c1e0>; contentOffset: {0, -168}; contentSize: {402, 190.66666666666666}; adjustedContentInset: {168, 0, 122.66666666666674, 0} topEdge=<style=soft backgroundCapture=sampled> bottomEdge=<style=soft backgroundCapture=sampled>; layout: <UICollectionViewCompositionalLayout: 0x105053200>; dataSource: <_TtGC7SwiftUI31UICollectionViewListCoordinatorGVS_28CollectionViewListDataSourceOs5Never_GOS_19SelectionManagerBoxS2___: 0x1022d6d00>>'
terminating due to uncaught exception of type NSException
CoreSimulator 1051.54 - Device: iPhone 17 Pro (B3C33F57-46F3-445D-9D60-CE4ACC2F994B) - Runtime: iOS 26.5 (23F77) - DeviceType: iPhone 17 Pro

## Assistant

This is the classic SwiftUI `List` + `onDelete` crash: the row removal is performed asynchronously (inside a `Task`) and the reload routes through the `.loading` state, so the collection view's animated batch update sees a data source whose item count doesn't match what it expects. The fix is to update the model **synchronously** within the `onDelete` closure so the List's diff stays consistent, and persist in the background.

Let me check for other callers of `remove(showID:)` before changing the view model.

Let me check whether any tests exercise `WatchlistViewModel.remove` directly.

Now I'll fix the view model. I'll replace the async `remove(showID:)` with a synchronous optimistic update that persists in the background and reconciles on failure.

Now update the `onDelete` handler to call it synchronously:

Let me rebuild to confirm.

`remove(atOffsets:)` is a SwiftUI-only API. I'll avoid importing SwiftUI into the view model and use a Foundation-only removal instead.

Fixed and building cleanly.

## What caused the crash

The old delete path was asynchronous and routed through the loading state:

```swift
.onDelete { offsets in
    for index in offsets {
        let showID = shows[index].id
        Task { await viewModel.remove(showID: showID) }   // async
    }
}
```

…and `remove` called `load()`, which set `state = .loading` (replacing the `List` with a `ProgressView`) before reloading. When you deleted the **last** row, `UICollectionView` had already begun its animated 1→0 batch update, but the data source was swapped out from under it asynchronously, so the item count no longer matched what the animation expected → `NSInternalInconsistencyException: invalid number of items in section 0`.

## The fix

The model now updates **synchronously inside the `onDelete` closure**, so the List's data source matches the deletion animation immediately. Persistence runs in the background, and only on a persistence failure does it reconcile by reloading from disk.

```47:68:NextSeason/Features/Watchlist/WatchlistViewModel.swift
    func remove(at offsets: IndexSet) {
        guard case .loaded(var shows) = state else { return }
        let removedIDs = Set(offsets.map { shows[$0].id })
        shows.removeAll { removedIDs.contains($0.id) }
        state = .loaded(shows)

        Task {
            do {
                for id in removedIDs {
                    try await repository.remove(showID: id)
                }
            } catch is CancellationError {
                return
            } catch {
                await load()
            }
        }
    }
```

```102:104:NextSeason/Features/Watchlist/WatchlistView.swift
                .onDelete { offsets in
                    viewModel.remove(at: offsets)
                }
```

This also removes the brief loading flicker on every delete, and correctly handles multi-row deletes in a single `IndexSet`. I kept the view model free of SwiftUI by using a Foundation-only `removeAll` instead of `remove(atOffsets:)`.

## What to test
- In the Watchlist, Edit → delete all shows top-to-bottom (and bottom-to-top); deleting the last one should now show the empty state with no crash.
- Swipe-to-delete a single row, and full-swipe delete.
- Confirm removed shows stay gone after backgrounding/relaunching (persistence still works).

## User

That didn't fix the crash - the same thing still happens.

## Assistant

The fix didn't work because the real culprit is different from pure async timing. When you delete the **last** row, two structural changes happen during the same animated batch update: (1) the `.loaded` case switches to the separate empty-state branch, tearing down the `List` mid-animation, and (2) the `#if DEBUG` section's row count changes (from "Send Test Notification" button + text → just text) exactly when `shows.first` becomes `nil`. Either of these makes `UICollectionView`'s batch-update math inconsistent — and both fire precisely on the last deletion, which is why it only crashes on the third one.

Let me look at the current file state to fix both.

I'll restructure so the `List` is never torn down on the empty transition (empty state moves to an `.overlay`), and make the debug section's row count invariant to the show count.

Now add the `emptyState` view and make the debug section structurally stable:

Now let me rebuild to confirm it compiles.

Build is clean. Let me verify behavior by running the existing UI test suite (especially the remove-from-watchlist test) on a simulator to confirm no regression.

The single-delete test passes and finds the new overlay-based empty state. Let me also run the track test, which asserts the empty state is *absent* when a show is present (verifying the overlay only appears when empty).

Both tests pass. Here's the proper fix and why the previous attempt missed.

## Why my first fix didn't work

The crash isn't fundamentally about async timing — it's about the `List`'s structure changing in two ways during the deletion of the **last** row, both of which break `UICollectionView`'s animated batch-update consistency check:

1. **List teardown:** the `case .loaded where shows.isEmpty` branch swapped the whole `List` out for a `ContentUnavailableView` the instant the count hit zero — i.e. mid-deletion-animation.
2. **Debug section row count change:** the `#if DEBUG` section rendered a *button + text* when `shows.first != nil` and *just text* when empty. Deleting the last show changed that section from 2 rows to 1 row in the same update as the row deletion.

Both fire only on the final delete, which is exactly why it crashed "after the third one." My async→sync change was a correct improvement but didn't touch either of these.

## What I changed now

`WatchlistView.swift`:
- **Merged the two `.loaded` cases into one** that always keeps the `List` mounted. The empty state is now shown as an `.overlay` (with an opaque background) instead of replacing the `List`, so deleting the last row animates a clean 1→0 deletion without tearing the collection view down.

```90:116:NextSeason/Features/Watchlist/WatchlistView.swift
        case .loaded(let shows):
            // The List is kept mounted even when empty (empty state is an overlay)
            // so deleting the last row doesn't tear the List down mid-animation,
            // which crashes UICollectionView with "invalid number of items".
            List {
                ...
            }
            .listStyle(.plain)
            .tvmazeAttributionInset()
            .overlay {
                if shows.isEmpty {
                    emptyState
                }
            }
```

- **Made the debug section's row count constant** (always button + text). It's disabled when empty and the text adapts, but the structure no longer changes when the last show is removed.

The synchronous `remove(at:)` from the earlier fix stays in place (it's still the correct pattern and removes the loading flicker).

## Verification
- App builds cleanly.
- `testRemoveShowFromWatchlist` passes (deletes the only show → empty state appears via the overlay).
- `testTrackShowAppearsOnWatchlist` passes (empty-state overlay correctly absent when a show is present).

## What to test manually
Please re-run your exact repro: Watchlist → Edit → delete all three shows top-to-bottom (and try bottom-to-top, and swipe-delete). The last deletion should now land on the "No Tracked Shows" empty state with no crash. I couldn't auto-reproduce the 3-show edit-mode case because the UI-test stub only returns a single show, so a manual check on that specific multi-delete flow would be worthwhile.

## User

That fixed the crash, but there's another bug.  Edit mode isn't closed out after the last show is deleted, so when the user adds more shows and then returns to the wishlist, it is already in edit mode when it should not be.

## Assistant

The leftover edit mode happens because `EditButton` drives the `editMode` environment, but when the last show is deleted the button disappears while `editMode` is still `.active`, and nothing resets it. I'll own the `editMode` binding and reset it to `.inactive` whenever the list becomes empty.

Now reset edit mode when the list becomes empty:

Build is clean. Let me re-run the remove test to make sure owning the `editMode` binding didn't regress anything.

Fixed and verified.

## What was wrong
`EditButton` toggles SwiftUI's `editMode` environment value. When you deleted the last show, `hasTrackedShows` became `false` and the `EditButton` was removed from the toolbar — but the underlying `editMode` was still `.active`, and nothing brought it back down. So the next time the list had rows, it was already editing.

## The fix (`WatchlistView.swift`)
- Added a view-owned binding: `@State private var editMode: EditMode = .inactive`, injected via `.environment(\.editMode, $editMode)` so both the `EditButton` and the `List` share it.
- Reset it when the list empties:

```117:121:NextSeason/Features/Watchlist/WatchlistView.swift
            .onChange(of: shows.isEmpty) { _, isEmpty in
                // Deleting the last show hides the Edit button; exit edit mode so
                // the watchlist isn't still editing when shows are added later.
                if isEmpty { editMode = .inactive }
            }
```

## Verification
- Builds cleanly.
- `testRemoveShowFromWatchlist` still passes.

## What to test manually
- Edit mode → delete all shows → the empty state should appear *not* in edit mode. Add shows back and return to the Watchlist; it should be in normal (non-editing) mode with the Edit button available again.
- Confirm Edit/Done and swipe-to-delete still behave normally with multiple shows.

## User

That seems to work, but these steps are still a problem:
- add 3 shows to Wishlist
- delete top to bottom 
- see the No Tracked Shows, message in wishlist
- tap the Find a Show button

Sometimes that goes to the search page, but sometimes it goes to the detail page for the last show that was deleted.  Not only should this behavior be consistent, but when it goes to the detail page the "add to wishlist" button is still filled, indicating that it's still on the wishlist, even though it was just deleted.

## Assistant

Two things are happening here, and the clue "detail page for the last show... track button still filled" is the key. Let me look at the navigation coordinator and the detail view model to confirm the mechanism.

Confirmed the mechanism. This isn't really about the watchlist — it's the **search tab's** retained navigation stack:

- To add each show, you search → tap a show (this pushes its detail onto the **search tab's** `searchPath`) → tap Track → switch to the Watchlist tab. The search tab's navigation stack is left sitting on that last-viewed show's detail.
- "Find a Show" only does `coordinator.selectedTab = .search`, so it switches to the search tab **wherever its stack happens to be** — sometimes the search root, sometimes that stale detail page.
- That stale `ShowDetailView` shows a filled Track button because `ShowDetailViewModel.isTracked` is cached from when it first loaded (line 57) and is never refreshed when the view reappears — so even though you deleted the show, it still looks tracked.

The fix is to make "Find a Show" reset the search stack to its root before switching tabs, so it always lands on the actual search screen.

I'll add a small intent method to the coordinator so this navigation behavior is cohesive and testable.

Build is clean. Here's the fix.

## Root cause
The bug was in the **search tab's** navigation stack, not the watchlist. When you add shows, each one is viewed via `SearchView` → the show's detail gets pushed onto `coordinator.searchPath`, and that push is never popped when you switch to the Watchlist tab. So:

- "Find a Show" did only `selectedTab = .search`, dropping you wherever the search stack was left — sometimes the search screen, sometimes a stale detail page. That's the inconsistency.
- The stale detail showed a filled Track button because `ShowDetailViewModel` caches `isTracked` at load time (`ShowDetailViewModel.swift` line 57) and never re-checks it on reappear, so a show you deleted from another tab still looked tracked.

## The fix
"Find a Show" now resets the search stack to its root before switching tabs, so it always lands on the actual search screen:

```24:34:NextSeason/Services/AppNavigationCoordinator.swift
    /// Switches to the Search tab at its root, popping any detail screen the
    /// search stack was left on (e.g. a show viewed while adding to the
    /// watchlist) so the user lands on the search screen itself.
    func showSearchRoot() {
        searchPath = NavigationPath()
        selectedTab = .search
    }
```

`ContentView` now calls `coordinator.showSearchRoot()` from the empty-state button.

## What to test
- Your exact repro: add 3 shows, delete top-to-bottom, tap "Find a Show" → it should **always** land on the Search screen (with the search field), never on a stale detail page. Repeat a few times since the old behavior was intermittent.
- Sanity: from search, view a show's detail, go to Watchlist, come back to Search via the tab bar directly — that still preserves your place (only "Find a Show" forces the root).

## One related note (not fixed here)
There's a separate latent issue: `ShowDetailView` doesn't refresh its tracked state when it reappears, so a detail page left open in one tab can show a stale Track button if the show's tracked status changes elsewhere. My fix sidesteps it for the "Find a Show" flow by never landing you on that stale page, but if you'd like, I can make `ShowDetailView` re-check `repository.contains` on reappear so the Track button is always accurate regardless of how you get there. Want me to do that as a follow-up?

## User

Yes please

## Assistant

I'll add a `refreshTrackedState()` to the detail view model and call it whenever the detail view (re)appears, so the Track button always reflects the current repository state.

Now call it when the detail view reappears:

Let me run the test that exercises reopening a show's detail to confirm the refresh logic doesn't regress tracked-state display.

Done. The follow-up is implemented and verified.

## What I changed
`ShowDetailViewModel.swift` — added a method that re-reads tracked status from the repository, guarded so it won't clobber an in-flight toggle:

```42:52:NextSeason/Features/ShowDetail/ShowDetailViewModel.swift
    /// Re-reads tracked status from the repository so the Track control reflects
    /// changes made elsewhere (e.g. the show was removed on the Watchlist tab)
    /// when this screen reappears. Skipped mid-toggle to avoid clobbering an
    /// in-flight optimistic update.
    func refreshTrackedState() async {
        guard !isUpdatingWatchlist else { return }
        if let tracked = try? await repository.contains(showID: initialShow.id) {
            isTracked = tracked
        }
    }
```

`ShowDetailView.swift` — calls it on reappear:

```50:54:NextSeason/Features/ShowDetail/ShowDetailView.swift
        .onAppear {
            // Reconcile tracked state on reappear (e.g. returning to this screen
            // after the show was removed on the Watchlist tab).
            Task { await viewModel?.refreshTrackedState() }
        }
```

The existing `.task(id: show.id)` still handles the initial load; `onAppear` now reconciles the Track button each time the screen comes back into view, so it can't show a stale "Tracking" state for a show that was removed elsewhere.

## Verification
- Builds cleanly.
- `testReopeningTrackedShowReflectsTrackedState` passes (reopening a tracked show still correctly shows "Tracking").

## What to test manually
- Search a show → open its detail (don't dismiss) → go to Watchlist → it's there → delete it → tab back to Search (via the tab bar, landing on that detail): the Track button should now show the empty star ("Track"), not filled.
- Inverse: open a detail for an untracked show, track it from the Watchlist side of things isn't possible, but toggling on the detail itself should still behave normally (the mid-toggle guard prevents flicker).

## User

Looks good!  So did you finish the three todos (3, 2 and 1) that we identified earlier?  Or did these bugs send us off on a detour?

## Assistant

Yes — all three are done. The bugs were a detour *within* the features we just built, not separate work, so finishing the fixes also finished the todos. Here's the rundown:

**#2 — Actionable watchlist empty state** ✅
- "Find a Show" button on the empty state, switching to the Search tab.
- Bug fixes layered on top: kept the `List` mounted (empty state via overlay) so deleting the last show no longer crashes, and made "Find a Show" land on the search *root* instead of a stale detail page.

**#3 — Visible removal via Edit button** ✅
- `EditButton` in the Watchlist toolbar (shown when there are shows).
- Bug fixes layered on top: synchronous deletion to fix the `UICollectionView` crash, and resetting `editMode` to `.inactive` when the list empties so it doesn't stay in edit mode.

**#1 — Tracked badge in search results** ✅
- Filled-star badge on already-tracked search rows, refreshed when returning from a detail screen.

Plus the bonus you approved: `ShowDetailView` now reconciles its Track button on reappear, so it can't show a stale "Tracking" state.

Everything builds cleanly and the relevant UI tests pass. The only thing I'd flag as *not done* (because it was never in scope) is broader test coverage for the new multi-delete/edit-mode flow — the existing UI-test stub only returns a single show, so the 3-show edit-mode delete path isn't covered by an automated test. I can add that if you'd like; otherwise the three todos are complete.

## User

I think that in addition to showing the tracked badge in search results we should also have an actual button there, so the user can track their show without having to open the detail page if they're sure it's the right one.

## Assistant

I'll add an inline track/untrack control on each search row, reusing the existing watchlist repository and the same tracked-state refresh we already use when returning from detail.

I'll add a tappable track control on each search row, wire it through `SearchView` with the same notification prompts as detail, and keep the row label separate from the button so navigation still works.

Using a per-show accessibility identifier so multiple search results don't share the same `search.track` id.

Using show ID for the accessibility identifier instead of the name — names can have spaces and special characters.

Done. Each search result now has a tappable track control beside the row, so users can add or remove a show without opening detail.

## What changed

**`ShowRow.swift`** — Split into two pieces:
- `ShowRowLabel` — poster, title, and status (inside the `NavigationLink`)
- `ShowRowTrackButton` — star button (outline when untracked, filled yellow when tracked), with a spinner while saving

**`SearchView.swift`** — Each result row is now:
- Tap the row → open detail (unchanged)
- Tap the star → track or untrack inline

Tracking uses the same repository and notification flow as the detail screen (including the "Stay in the Loop" and "Notifications Are Off" alerts on first track).

**`UITestingConfiguration.swift`** — Added `search.track` accessibility identifier (per-show: `search.track.{id}`).

## What to test
- Search for a show → tap the **star** (not the row) → confirm it fills in and the show appears on the Watchlist tab.
- Tap the filled star again → confirm it untracks and disappears from the watchlist.
- Tap the **row** itself → detail still opens; its Track button should match the star state.
- First-time track from search → notification prompt should still appear.

If you want, I can add a UI test that tracks directly from the search list without opening detail.

## User

It seems to be working well, except that if I tap the star on the search row, then tap the row to go to the detail page there's a noticeable delay before the star button displays.

## Assistant

The detail screen likely waits on a full API load before it shows the track button, even though search already knows the show is tracked. I'll trace that path and see where we can show the correct state immediately.

## Assistant

The detail screen waits for the full network load before it reads tracked state and enables the track button, even though tracking is already known locally. I'll load tracked status in parallel with the show fetch and show the button immediately.

The delay came from two things on the detail screen:

1. **Tracked status waited on the network** — `isTracked` was only read *after* the full TVMaze fetch finished, even though it's a local database lookup.
2. **The Track button was disabled until load finished** — so you saw an empty, greyed-out star until the API returned.

## What I changed

**`ShowDetailViewModel`**
- `load()` now fetches tracked status **in parallel** with the show details request, so the star updates almost immediately from local storage.
- `toggleWatchlist()` no longer requires the full show to be loaded — it uses `fullShow ?? initialShow`, so track/untrack works right away.

**`ShowDetailView`**
- Creates the view model immediately via `onChange(of: show.id, initial: true)` instead of waiting for `.task` to start.
- The Track button is only disabled while a toggle is in progress, not while next-season data is loading.

The "Next Season" section still shows its own loading spinner until TVMaze responds — only the toolbar track state is instant now.

## What to test
- Track from the search row star → tap the row → detail should show **Tracking** with a filled star right away.
- Open detail for an untracked show → star should appear immediately (outline), not after a pause.
- Toggle track on detail before next-season finishes loading — should still work.

## User

There is still a much smaller but still noticeable delay before the star appears, in all states.

## Assistant

The star still waits on async work because `isTracked` starts false and the view model isn't created until after the first frame. I'll trace navigation into detail and seed tracked state synchronously at push time.

The remaining delay is the optional view model (full-screen spinner first) plus `isTracked` starting false until async work finishes. I'll create the view model at navigation time with the known tracked state so the star renders on the first frame.

The remaining delay had two causes on our side:

1. **The view model was created one frame late** — `ShowDetailView` started with `viewModel == nil`, showed a full-screen spinner, then built the view model in `onChange`. The toolbar (and star) couldn't appear until that second pass.
2. **`isTracked` always started as `false`** — even when search already knew the show was tracked, we waited for an async repository read before updating the star.

## Fix

**Pass tracked state at navigation time** — when pushing detail from search, we now pass `isTracked: trackedShowIDs.contains(show.id)`. From the watchlist, we pass `isTracked: true`.

**Create the view model in `init`** — `ShowDetailView` now initializes `@State` with a fully configured `ShowDetailViewModel` on the first frame, including the correct `isTracked` value. No optional view model, no loading gate before the screen appears.

The async `refreshTrackedState()` still runs on appear to reconcile if something changed elsewhere, but the star should render correctly immediately.

## What to test
- Track from search row → open detail → filled star should appear with the screen, not pop in afterward.
- Open detail for an untracked show → outline star should be there immediately.
- Open from watchlist → filled star immediately.
- Remove on watchlist, return to an already-open detail via tab switch → should still reconcile to untracked after appear.

If you still notice a tiny delay, it's likely the navigation transition animating the toolbar in — that would be system behavior rather than waiting on our data. Let me know if it still feels off after trying this build.

## User

That looks great now, thanks!

## Assistant

Glad it’s working smoothly now.

You’ve got a solid discoverability pass in place: inline tracking on search, tracked badges, a clearer empty watchlist, visible edit/remove, and detail that shows the right track state right away. If you want to tackle the next release-readiness item, just say the word.

## User

After all that, do we need to add any more tests?

## Assistant

I'll compare what we shipped against the existing unit and UI tests so I can give you a straight answer on what's covered and what's still worth adding.

You don't *need* a big testing push before beta — the core track flow is already covered — but a few **targeted** tests would be worthwhile because almost everything we added isn't exercised yet.

## What's already covered

Existing UI tests still validate the main path:

- Search → detail → Track → watchlist
- Reopening detail reflects tracked state
- Swipe-to-delete returns to empty watchlist
- Empty watchlist on tab switch

Those tests all go through **detail**, not the new search-row affordances.

## What's not covered (new behavior)

| Feature | Risk if untested |
|---|---|
| **Inline track from search row** | New primary UX path; completely untested |
| **"Find a Show" → Search tab** | We fixed stale-detail navigation; easy to regress |
| **Edit → delete last show** | We fixed a crash and edit-mode-stuck bug |
| **`showSearchRoot()`** | No unit test (unlike other coordinator behavior) |

## Recommendation

**Not required for beta**, but I'd add **2–3 UI tests** if you want confidence without much effort:

1. **`testTrackFromSearchRowWithoutOpeningDetail`** — search, tap the row's star (not the row), confirm watchlist updates. Highest value.
2. **`testFindShowButtonNavigatesToSearch`** — empty watchlist → "Find a Show" → lands on search idle prompt (not a detail screen).
3. **`testDeleteLastShowViaEditExitsEditMode`** *(optional)* — track one show, Edit → delete, confirm empty state and that Edit is gone when you add again.

One small **unit test** worth adding:

- **`AppNavigationCoordinatorTests`**: `showSearchRoot()` clears `searchPath` and selects the search tab.

I'd skip unit tests for `WatchlistViewModel.remove(at:)` and `ShowDetailViewModel.initialIsTracked` unless you want deeper coverage — the UI tests above would catch most regressions users would actually hit.

**Bottom line:** You're in good shape for beta as-is. If you want a safety net for the work we just did, those 2–3 UI tests plus the coordinator unit test are the right scope — not a broad rewrite. Want me to add them?

## User

Go ahead and add the ones you recommend

## Assistant

I'll add the recommended UI tests and the `showSearchRoot()` unit test. First I'm checking accessibility IDs and how the stubbed search service behaves in tests.

## User

Start multitasking

## Assistant

I'll pick up the failing UI tests in a background worker and finish the recommended test coverage we started.

Multitasking is on. A background worker is finishing the recommended tests and fixing the two UI tests that failed (`testFindShowButtonNavigatesToSearch` and `testDeleteLastShowViaEditExitsEditMode`). I'll report back when that run is complete.

## User

Lastly, please update the "Watchlist Discoverability" section in Release Readiness with all the visible changes we've just made that affect the watchlist.

## Assistant

I'll have a background worker update the Watchlist Discoverability section in Release Readiness with the watchlist-related changes we shipped.

A background worker is updating the **Watchlist Discoverability** section in `Documentation/MVP/Release Readiness.md` with the watchlist and search discoverability changes we shipped. I'll let you know when that's done.

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: subagent
status: success
task_id: 50e1cac8-b9a7-4f7e-abc5-b2f9cfe8a6c2
title: Update Release Readiness doc
detail: <user_visible_high_level_summary>
Updated the **Watchlist Discoverability** section in `Documentation/MVP/Release Readiness.md` to reflect completed work: watchlist empty state, edit mode, search-row tracking, detail tracked-state fixes, bug fixes, and test coverage. Added Status, Remaining Opportunities, and Success Criteria to match the Search Quality Improvements format.
</user_visible_high_level_summary>
<response>
## Summary

Updated the **Watchlist Discoverability** section in `Documentation/MVP/Release Readiness.md`:

- Replaced **Potential Improvements** with **Implemented Improvements**, grouped by Watchlist tab, Search tab, and Show detail
- Added a **Bug Fixes** subsection for the three crash/stale-state fixes
- Added **Status: Implemented** with test coverage (UI + unit)
- Added **Remaining Opportunities** for onboarding/first-run work (cross-referenced to First-Run Experience)
- Added **Success Criteria** aligned with the Search Quality Improvements section

Goal and Questions are unchanged for beta validation. No other sections were modified.
</response>
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-transcripts/75e690eb-39a2-4bf6-aac9-68473ce27b53/subagents/50e1cac8-b9a7-4f7e-abc5-b2f9cfe8a6c2.jsonl
</task>
</system_notification>
<user_query>The beginning of the above subagent result is already visible to the user. Perform any follow-up actions (if needed). DO NOT regurgitate or reiterate its result unless asked. If multiple subagents have now completed and none are still running, briefly summarize the findings and conclusions across all of them. Otherwise, if no follow-ups remain, end your response with a brief third-person confirmation that the subagent has completed. If you mention an agent or subagent in your response, link it with the `[label](id)` format using the agent_id or task_id from the notification instead of printing the raw ID. Don't repeat the same confirmation every time.</user_query>

## Assistant

Checking whether the test-fix subagent finished and if anything still needs follow-up.

The doc update is done, but the test-fix subagent never finished — I'll resume it so the two failing UI tests get fixed.

The [Release Readiness doc update](50e1cac8-b9a7-4f7e-abc5-b2f9cfe8a6c2) is complete — no further doc follow-up needed.

The [test-fix subagent](ef33e392-2981-4e37-8185-60ca5de62720) is still running; it should finish fixing the two failing UI tests (`testFindShowButtonNavigatesToSearch` and `testDeleteLastShowViaEditExitsEditMode`) and verify the full suites. I'll report back when that finishes.

## User

I asked ChatGPT to review the project and it identified a couple of documentation issues:

2. One diagram is outdated
    Documentation/MVP/Diagrams/07_post_mvp_architecture.md says notifications are not part of MVP, but they are now implemented. Update that wording to say push/cloud notifications are post-MVP; local notifications are MVP.
3. Architecture.md still reads pre-implementation
    It says “No implementation yet” and labels Watchlist/Notification/SwiftData pieces as future/Slice 2 in places. Since Slice 2 is implemented, this should be revised or renamed as historical architecture.

Please fix these.

## Assistant

I'll read both docs and compare them to what's actually implemented so the notification and architecture wording matches the current MVP.

Only the MVP diagram copy exists in the repo; I'll update that file plus `Architecture.md` and the diagrams README.

Updating `Architecture.md` to reflect the implemented MVP.

Updating the decision-context diagram so it doesn't still say notifications are deferred.

Both documentation issues are fixed. Summary:

## 1. `Documentation/MVP/Diagrams/07_post_mvp_architecture.md`
- Renamed the backend node to **Cloud Notification Service** (distinct from MVP local notifications).
- Replaced the old “not part of MVP” wording with a **Relationship to the MVP** section:
  - **MVP:** local notifications on-device (`NotificationService`, `RefreshScheduler`, `BGTaskScheduler`)
  - **Post-MVP:** push/cloud notifications via APNs + backend
- Updated `Documentation/MVP/Diagrams/README.md` to match.

Also updated `08_decision_context.md` so it no longer says “Notifications deferred” without distinguishing local vs push.

## 2. `Documentation/MVP/Architecture.md`
- Removed **“No implementation yet”**; added **implementation status** (Slices 1 & 2 shipped).
- Updated the layering diagram: removed `· future` labels; added `WatchlistView`, `WatchlistViewModel`, `WatchlistRefreshService`.
- §7–§8: persistence and **local notifications** marked as implemented; push/cloud called out as post-MVP.
- §10 file layout: removed `// future` comments; added `WatchlistRefreshService`.
- §11 decisions table and §12 open questions updated to reflect resolved Slice 2 work.

The doc stays the Phase 3 design reference, with pointers to `01_system_architecture.md` for the current MVP view. Code samples in §3 are unchanged except for a note that live domain types use `summaryHTML` etc.

No code changes — documentation only. A quick read-through of those three files is enough to verify.

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: subagent
status: aborted
task_id: ef33e392-2981-4e37-8185-60ca5de62720
title: Fix and finish new tests
detail: Subagent was aborted by the user
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/agent-transcripts/75e690eb-39a2-4bf6-aac9-68473ce27b53/subagents/ef33e392-2981-4e37-8185-60ca5de62720.jsonl
</task>
</system_notification>
<user_query>The beginning of the above subagent result is already visible to the user. Perform any follow-up actions (if needed). DO NOT regurgitate or reiterate its result unless asked. If multiple subagents have now completed and none are still running, briefly summarize the findings and conclusions across all of them. Otherwise, if no follow-ups remain, end your response with a brief third-person confirmation that the subagent has completed. If you mention an agent or subagent in your response, link it with the `[label](id)` format using the agent_id or task_id from the notification instead of printing the raw ID. Don't repeat the same confirmation every time.</user_query>

## Assistant

The test-fix subagent was aborted, so I'll check whether those UI tests still need fixing.

## User

UI tests testTrackFromSearchRowWithoutOpeningDetail and testDeleteLastShowViaEditExitsEditMode are still failing.  Please fix.

## Assistant

I'll read both failing tests and run them to see what's breaking.

Fixing two issues: the watchlist not reloading when returning to the tab (stale empty state), and brittle edit-mode delete / search helpers in the tests.

Fixing watchlist reload on tab switch and making edit-mode deletion use the minus button instead of swipe.

Adding stable watchlist row identifiers and an explicit reload when switching to the Watchlist tab.

Tests still failing — I'll pull failure details and inspect the test and app code.

Watchlist likely stays stale after inline track because reload only runs on tab switch. I'll notify the coordinator when tracking changes and consolidate watchlist reload logic, then fix edit-mode delete in the UI tests.

Implementing watchlist reload when tracking changes from Search, and fixing edit-mode delete in the UI tests.

`.task(id:)` cancellation was leaving the watchlist stuck on loading when the reload token changed quickly. I'll fix that by not resetting to loading on refresh.

Checking whether the search-row track action completes and whether the watchlist reload task is cancelled.

Identifying the issue: a fast search-row track can leave the watchlist stuck on `.loading` when reload tasks cancel each other. Initializing with `.loaded([])` so the list stays mounted.

## Assistant

Track-from-search test passes. Checking what's failing in the edit-mode delete test.

Edit mode changes the accessibility hierarchy — updating the delete helper to locate the row by label instead of the stable ID.

Edit mode changes the row's accessibility tree — switching to delete by table cell index instead of label.

SwiftUI List may expose a collection view, not a table — updating the delete helper and the test's final watchlist assertion.

Swipe-delete is disabled in edit mode — updating the helper to tap the minus control instead.

Edit mode entry looks flaky — improving the helper and re-running the test.

## User

It looks like the simulator you were running a UI test in crashed.  That may not be your fault;  it happens fairly regularly.  But you'll have to start up whatever you were doing over again.

## Assistant

Restarting the UI test run to check current status after the simulator crash.

Track-from-search passes. Checking what's still failing in the edit-mode delete test.

## Assistant

Edit mode works, but delete still fails — swipe is disabled there. Updating the delete helper to tap the cell's minus control and handle immediate deletion.

Fixing the assertion: use `waitForNonExistence` instead of negating `waitForExistence`.

Delete test passed. Running all three together to confirm.

Both UI tests pass now. After the simulator crash I re-ran them and finished the last fix.

### Root causes

1. **`testTrackFromSearchRowWithoutOpeningDetail`** — The watchlist could get stuck on a loading spinner when reload tasks were cancelled in quick succession. Starting from `.loaded([])` and notifying the watchlist when tracking from search fixed stale/empty watchlist state.

2. **`testDeleteLastShowViaEditExitsEditMode`** — Edit-mode delete doesn’t support swipe. The helper needed to tap the leading minus control on the list cell (via coordinate), then confirm Delete if it appears.

### Changes

**App**
- `WatchlistViewModel` — initial state is `.loaded([])`; `reload()` no longer flashes loading on refresh
- `SearchView` — calls `onWatchlistChanged()` after track/untrack
- `ContentView` / `AppNavigationCoordinator` — `notifyWatchlistDataChanged()` bumps reload token
- `WatchlistView` — uses `.task(id: watchlistReloadToken)` plus `onAppear` reload

**UI tests**
- Dismiss keyboard after search so the track button stays tappable
- `waitForWatchlistRow()` helper with stable ID + label fallback
- Improved edit-mode entry and delete helpers (cell coordinate tap for minus, `waitForNonExistence` to verify deletion)

### What to test manually
- Track a show from the search row star → switch to Watchlist → row appears
- Edit → delete the only show → empty state returns, Done is gone
- Re-track from search → watchlist shows the show again without opening in edit mode
