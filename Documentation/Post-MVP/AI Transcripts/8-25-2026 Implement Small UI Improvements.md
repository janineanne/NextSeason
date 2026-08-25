# VoiceOver accessibility fixes

## User

Cursor Prompt: Fix VoiceOver Delete and Undo Toast Placement

Please make two targeted accessibility fixes in the Watchlist UI. Preserve existing behavior and formatting as much as possible; do not broadly refactor unrelated code.

1. Add an accessible VoiceOver equivalent for swipe-to-delete

Currently, sighted users can swipe a Watchlist row to delete it, but with VoiceOver enabled there is no usable equivalent. VoiceOver focus lands on the show row content and the separate star button, and the normal horizontal swipe gesture is owned by VoiceOver navigation.

Keep the current accessibility structure where:

* the show information / NavigationLink is one VoiceOver element
* the star button remains a separate VoiceOver element

Do not combine the entire row into a single accessibility element, because the star needs to remain independently actionable.

Instead, add an explicit accessibility action to the show-row / NavigationLink element, named something clear such as:

Remove from watchlist

When invoked, this accessibility action should use the same immediate-removal path as sighted swipe-to-delete, including the same undo behavior. Do not make it behave like tapping the star if those two removal mechanisms intentionally differ.

Expected VoiceOver behavior:

* Focus the show row.
* VoiceOver announces that actions are available.
* Swiping up/down through VoiceOver actions exposes “Remove from watchlist.”
* Activating it immediately removes the row and presents the existing Undo toast.

Reuse the existing removal coordinator / delete implementation rather than creating duplicate deletion logic.

2. Use the normal anchored Undo toast position with VoiceOver

The VoiceOver-specific toast currently uses voiceOverToast() and is always bottom-centered.

The existing comment says:

Bottom-centered layout; pass-through overlay so the list stays reachable.

The important requirement appears to be the pass-through overlay, not the bottom placement.

Change the VoiceOver presentation so the toast uses the same anchored position near the affected row/star as the normal sighted toast, while preserving the VoiceOver accessibility behavior that is currently working.

Requirements:

* Preserve the pass-through behavior so the full-screen overlay does not block access to the Watchlist underneath.
* Preserve the existing VoiceOver focus sequence for the toast:
    * first announce/focus the removal message
    * then move focus to Undo after the existing delay
* Preserve the longer VoiceOver timeout if one currently exists.
* Do not reintroduce .accessibilityHidden(true) on a parent/container that contains the toast, because that previously caused the toast’s accessibility elements to disappear from VoiceOver.
* The Undo and OK controls must remain reachable and correctly announced.
* The list underneath must remain reachable while the toast is visible.

Ideally, remove the unnecessary layout difference between the VoiceOver and non-VoiceOver toast implementations if that can be done safely, while keeping VoiceOver-specific focus/timing behavior separate where needed.

Verify

Please inspect the relevant Watchlist row, .onDelete, removal coordinator, toast overlay, and accessibility focus code before changing anything.

After making the changes, verify these cases conceptually and with any existing tests that apply:

1. Sighted swipe-to-delete still works exactly as before.
2. VoiceOver user can invoke “Remove from watchlist” from the show row using VoiceOver actions.
3. That VoiceOver action uses the same immediate-delete + Undo behavior as swipe-to-delete.
4. Star-button removal still behaves as before.
5. With VoiceOver on, the Undo toast appears near the affected row rather than always at the bottom.
6. VoiceOver announces the toast and then focuses Undo as before.
7. Undo and OK remain accessible.
8. The Watchlist remains reachable while the toast is visible.
9. No unrelated UI or accessibility behavior is changed.

Please show me the specific code changes you make and briefly explain why each one is needed.

## Assistant

I'll inspect the Watchlist row, delete path, toast overlay, and VoiceOver focus code first so the two accessibility fixes stay targeted. I'll also read the SwiftUI skill before writing any Swift.

Next I’ll inspect the delete/removal APIs and any existing toast tests so the VoiceOver action can reuse the same immediate-delete path.

I’ve confirmed the two paths: swipe uses immediate delete, the star uses deferred removal. Next I’ll add a VoiceOver “Remove from watchlist” action on that immediate path and switch the VoiceOver toast to the same anchored layout.

I'll add a shared immediate-delete method, attach a VoiceOver “Remove from watchlist” action to the show row, and use the same anchored toast for VoiceOver without blocking the list.

Skills used: `swiftui-pro`, `swift-testing-pro`.

Two targeted accessibility fixes, no layout split between VoiceOver and sighted toasts, and no change to star-button deferred removal.

## 1. VoiceOver “Remove from watchlist” action

Swipe-to-delete is owned by VoiceOver navigation, so the show-row `NavigationLink` now exposes an explicit rotor action. The star stays a separate VoiceOver element.

The action calls the same immediate-delete path as `.onDelete`, not star-button `requestRemoval`.

```255:268:NextSeason/Features/Watchlist/WatchlistView.swift
                    .accessibilityIdentifier(
                        "\(AccessibilityID.Watchlist.row).\(tracked.id)")
                    // VoiceOver cannot use the list swipe gesture, so expose the
                    // same immediate-delete path as `.onDelete` as a rotor action.
                    .accessibilityAction(named: String(localized: "Remove from watchlist")) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            viewModel.deleteImmediately(
                                tracked,
                                rowAnchor: rowFrames[tracked.id] ?? .zero
                            )
                        }
                        rowFrames[tracked.id] = nil
                    }
```

Swipe and VoiceOver now share one implementation: drop the row, persist immediately, show the undo toast.

```163:173:NextSeason/Features/Watchlist/WatchlistViewModel.swift
    /// Immediate delete shared by swipe-to-delete and the VoiceOver row action.
    /// Drops the row from the list synchronously, then persists and shows an
    /// informational undo toast. Distinct from star-button `requestRemoval`.
    func deleteImmediately(_ tracked: TrackedShow, rowAnchor: CGRect) {
        removeShow(showID: tracked.id)
        removalCoordinator.requestImmediateRemoval(
            tracked,
            anchor: rowAnchor,
            source: .watchlist
        )
    }
```

## 2. Same anchored toast for VoiceOver

`voiceOverToast()` (bottom-centered, and previously `.accessibilityHidden(true)` on the overlay) is gone. VoiceOver now uses the same row/star-anchored toast as sighted users.

Kept VoiceOver-specific behavior:
- focus message, then Undo after the existing delays
- 20s VoiceOver undo window in `AccessibilityPreferences`
- pass-through overlay (no full-screen hidden container)
- `.accessibilitySortPriority(1)` so the toast is found first

```142:194:NextSeason/Features/Watchlist/UndoToast.swift
        content
            .overlay {
                if isPresented {
                    anchoredToast
                }
            }
            // ... VoiceOver focus timing unchanged ...
    }

    /// Anchored near the trigger. The GeometryReader has no background and is
    /// not itself an accessibility element, so empty overlay space stays
    /// pass-through for touch and VoiceOver. Do not apply
    /// `.accessibilityHidden(true)` on this container — that hides the toast.
    private var anchoredToast: some View {
        GeometryReader { proxy in
            // ... same position math as before ...
        }
        .accessibilitySortPriority(1)
        .zIndex(1)
        .transition(.undoToastEntrance)
    }
```

## Verification

`WatchlistViewModelTests` and `WatchlistPendingRemovalTests` passed, including a new test that the single-show API matches swipe (row gone immediately, same toast anchor, persisted).

Please confirm on device with VoiceOver:

1. Sighted swipe-to-delete still removes immediately and shows Undo near the row.
2. Focus the show row (not the star) → Actions → **Remove from watchlist** → row disappears, Undo toast appears.
3. Star-button untrack is still deferred (row stays until OK / timeout).
4. With VoiceOver on, the toast sits near the affected row/star, not always at the bottom.
5. VoiceOver reads the removal message, then moves to Undo.
6. Undo and OK stay reachable; you can still swipe to Watchlist rows while the toast is up.

## User

I can't figure out how to focus the show row.

## Assistant

I'll inspect how the Watchlist row is exposed to VoiceOver so I can tell you exactly what to focus and how.

The show row is the **left side** of the list item (poster + title), not the whole row and not the star.

With VoiceOver on:

1. Tap once on the **poster or show title**.
   Or swipe right until you hear the show’s name, its next-season status, “Updated …”, and the hint **Opens show details**.
2. That is the show row. You should **not** hear **Stop tracking …** — that is the star, one swipe further right.
3. With the show row focused, swipe **down** (or up). VoiceOver cycles actions. You want **Remove from watchlist**.
4. Double-tap to activate it.

If VoiceOver says **Actions available**, you are on the right element. If you only hear **Stop tracking [show]**, swipe **left** once.

A single tap only moves the VoiceOver cursor (the black box). Double-tap is what activates.

## User

We're going to make a few more layout changes while we're at it.

First:  Always place the Undo toast above the tab bar, for VoiceOver and non-VoiceOver alike. Keep the pass-through overlay and all of the existing VoiceOver focus/timing behavior.

## Assistant

I'll inspect the current toast overlay and tab-bar layout first, then move the Undo toast so it always sits above the tab bar for both VoiceOver and non-VoiceOver.

I’ll keep the pass-through overlay and VoiceOver focus timing, and switch the toast to a single bottom placement just above the tab bar for everyone. The row-anchor layout can go.

The Undo toast is now always bottom-centered, just above the tab bar, for VoiceOver and sighted use. Row-anchored placement is gone.

What stayed the same:
- Pass-through overlay (no background, no `.accessibilityHidden` on the container)
- VoiceOver focus order: message, then Undo after the existing delays
- 20s VoiceOver undo window

What to check:
1. Swipe-to-delete and star untrack — toast sits above the tab bar, not on it and not next to the row.
2. Same placement with VoiceOver on.
3. Tab bar still tappable / reachable while the toast is up.
4. Undo / OK still work; VoiceOver still reads the message, then Undo.

The next layout change can go on top of this.

## User

Next one - please remove the "About NextSeason" button at the bottom of the Watchlist and replace it with a left nav bar button using the ellipsis image.  It should bring up the About sheet as before.  Put this on all three screens - search, watchlist and show details.

## Assistant

I’ll inspect how the About footer and sheet are wired today, then replace the Watchlist bottom button with a leading ellipsis nav-bar item on Search, Watchlist, and Show Details.

I’ll replace the bottom About footer with a leading ellipsis toolbar button, reuse the existing About sheet, and add that button on Search, Watchlist, and Show Details.

The bottom **About NextSeason** footer is gone. Search, Watchlist, and Show Details now have a leading nav-bar ellipsis that opens the same About sheet.

It still only appears in Debug / TestFlight builds (`openAppAbout` is unset in App Store builds). VoiceOver gets the label **About NextSeason** and the existing diagnostics hint.

What to check:
1. Watchlist — no footer text above the tab bar; ellipsis is on the left, search stays on the right.
2. Search — same leading ellipsis.
3. Show Details — ellipsis on the left next to Back.
4. Tap it on each screen — About sheet is unchanged.
5. App Store / non-beta builds still hide the button.

## User

Please take it off the show detail view - it looks too crowded next to the back button.

## Assistant

Removed the ellipsis from Show Details. It stays on Search and Watchlist only.

## User

There's a warning in updateUIViewController:  "No calls to throwing functions occur within 'try' expression"

## Assistant

That warning came from `try? await Task.yield()` — `Task.yield()` does not throw. It’s now `await Task.yield()`.

