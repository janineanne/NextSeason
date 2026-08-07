# Watchlist screen search bar

## User

Please modify the watchlist screen so that the search bar is hidden unless the user taps a search button on the right side of the nav bar (next to the info button).  It should then slide into place and stay there until the user either taps the button again, switches to the search tab, or backgrounds/exits the app

## Assistant

I'll locate the watchlist screen and how its search bar and nav bar are wired today, then add a toggle that slides the bar in and resets on tab switch or app background.

Implementing a toggleable search bar with toolbar control, and updating UI tests so they open search first.

Updating UI tests to tap the search button before interacting with the search field.

Refactoring dismiss logic so search text clears whenever the drawer closes, including system dismissals.

The watchlist search bar is now hidden by default and revealed from a toolbar button. Here’s what changed:

### Behavior
- **Hidden by default** — the search drawer no longer uses `displayMode: .always`
- **Search button** — magnifying glass in the trailing nav bar (to the left of the About/info button); switches to an **xmark** while search is open
- **Slide-in animation** — toggling uses a 0.25s ease-in-out animation via SwiftUI’s `isPresented` binding on `.searchable`
- **Auto-dismiss** when:
  - The user taps the button again
  - They switch to the Search tab
  - The app goes to the background
- **Query cleared** whenever search is dismissed

### Files changed
- `WatchlistView.swift` — toolbar button, `isSearchPresented` state, dismiss handlers
- `ContentView.swift` — passes `selectedTab` so Watchlist can detect tab switches
- `AccessibilityID.swift` — added `watchlist.search` identifier
- UI test helpers updated to tap the search button before interacting with the field

### What to test
1. Open Watchlist with tracked shows — confirm no search bar until you tap the magnifying glass
2. Tap search — bar slides in; filter works as before
3. Tap xmark — bar dismisses and the list resets
4. Open search, switch to Search tab — search should be gone when you return to Watchlist
5. Open search, background the app — search should be dismissed on return
6. Confirm the search button sits next to the info button in the nav bar

## User

The search bar is still visible.

## Assistant

Investigating why the search bar stays visible — likely an issue with how `.searchable` and `isPresented` interact.

`.searchable` with `isPresented: false` still leaves the drawer visible when the list is at the top. I'll apply `.searchable` only when search is open so the bar is fully hidden otherwise.

The issue was that `.searchable` always reserves the navigation-bar drawer, even with `isPresented: false` — that binding only controls focus/activation, not whether the field is shown.

**Fix:** `.searchable` is now applied only when search is open, via `WatchlistSearchPresentationModifier`. When search is closed, the modifier is not on the list at all, so no search bar appears.

When you tap the magnifying glass, the modifier is added and the drawer slides in with `displayMode: .always`. Tapping xmark, switching tabs, or backgrounding the app removes it again.

Please rebuild and confirm the search bar is gone on load, then appears only after tapping the toolbar button.

## User

This works, but a couple of nits:

When the user taps the search button, the bar appears where it used to be and then moves up to the top with the X to close.  Is it possible to just have it appear up there?

When I switch betweeen the Search and Watchlist tabs with the search bar hidden, the transition is smooth.  When switch from Watchlist to Search with the watchlist search bar active, there's a little bit of a stutter.  I'm not sure but I think the transition to the search tab is being delayed while the search bar hides.

Is it possible to fix either of these?

## Assistant

I'll inspect the watchlist search presentation and tab-switch dismiss logic to fix the open animation and the stutter when leaving Watchlist with search active.

The double motion comes from animating `.searchable` onto a large-title list, then the system moving it into the nav bar. Tab stutter is from animating dismiss during the tab switch. I'll open search instantly with an inline title and dismiss without animation when leaving the tab.

Checking whether `.searchable` should live on the navigation stack instead of the list — that may be causing the drawer placement issue.

Moving `.searchable` to the NavigationStack level (matching SearchView) so it mounts in the nav bar instead of the list drawer.

Both issues had the same root cause: how and when the search UI was being mounted and animated.

### 1. Search bar appearing in the old spot first
Two things were causing the double motion:
- `.searchable` was attached to the **List**, so it appeared in the list’s drawer slot first, then moved into the nav bar when activated
- Opening was wrapped in `withAnimation`, which animated that whole transition

**Fixes:**
- Moved `.searchable` to the **NavigationStack** level (same as the Search tab)
- Collapse to **inline** title when search is open so there’s no large-title drawer slot
- Open search **without animation** so it appears directly in the nav bar

### 2. Tab switch stutter
Leaving Watchlist with search open called `dismissWatchlistSearch()` with a 0.25s animation, which fought the tab transition.

**Fix:** Dismiss instantly (no animation) when switching tabs or backgrounding the app. Manual close via the X still animates smoothly.

### What to verify
1. Tap search — bar should appear immediately at the top, no slide from below
2. Tap X — should close with a smooth transition back to the large title
3. Open search, switch to Search tab — tab change should feel as smooth as when search was hidden
4. Background the app with search open — search should be gone when you return

## User

The transition between tabs is good now.

On the watchlist, tapping the search button causes the searchbar to appear below a small title, which then disappears and the bar animates the rest of the way to the top of the screen.

## Assistant

The remaining double animation comes from `.searchable`'s activation flow. I'll replace it with a custom top search bar that appears in place immediately.

Replacing `.searchable` with a toolbar search field so it appears in the nav bar immediately, without the system's two-step activation animation.

The double animation was built into `.searchable` — UIKit always shows the field in the drawer first, then animates it into the active nav-bar position. That isn’t something we can fully override while using `.searchable`.

**Fix:** Replaced `.searchable` with a custom `WatchlistSearchField` placed in the toolbar’s `.principal` slot. When you tap search:

- The large title is cleared instantly
- The search field appears directly in the nav bar (no drawer step)
- The keyboard focuses immediately

The X button, tab-switch dismiss, and filtering behavior are unchanged.

Please try tapping search again — it should appear in place at the top with no intermediate stop below a small title.

## User

Ew. That doesn't look good at all.

## Assistant

The toolbar search field is causing the layout gap. I'll switch back to `.searchable` in the drawer below the large title, without activating it into the nav bar.

Replacing the toolbar field with `.searchable` in the drawer below the large title—no `isPresented` binding, so it won't jump into the nav bar.

Fair point — the custom toolbar field fought the large title and left that awkward gap.

I removed it and went back to native `.searchable`, with one important change: **no `isPresented` binding**. That binding was what caused the two-step animation (drawer → jump into the nav bar). Without it, the field stays in the standard drawer slot below the "Watchlist" large title.

**What you should see now:**
- Large "Watchlist" title stays put
- Tapping search slides the native search bar in below the title (where it originally lived)
- No cramped field at the very top, no empty gap
- X in the toolbar still closes it; tab switch is still instant

Please try it again. If tapping *into* the search field still causes a jump to the top, let me know — that's a separate UIKit focus behavior we can tackle next.

## User

Much better!

## Assistant

Glad that landed better. The native drawer placement below the large title is the right fit here — it looks like standard iOS list search without fighting the navigation bar.

If anything else feels off as you use it, just say the word.

