# VoiceOver functionality issue

## User

VoiceOver isn't working very well.  Is this something you are able to work on?

## User

Go ahead.

## Assistant

Implementing VoiceOver fixes across the banner, list rows, show detail, undo toast, and search hints.

Updating ShowDetailView to group the header and next-season section for VoiceOver.

Checking ShowDetailView after the partial edit:

Fixing the next-season section: `.combine` was blocking the "Try Again" button in the failed state.

Building to verify the project compiles.

VoiceOver improvements are in. Build succeeded. Here’s what changed:

## Changes

**1. Fixed buttons trapped inside combined elements**
- `NotificationsDisabledBanner` — removed `.combine` so “Open Settings” is its own focusable control
- `SearchResultsLimitFooterView` — switched to `.contain` so “Search on TVMaze.com” stays tappable

**2. Search & watchlist rows**
- Navigation links now hint “Opens show details” via a shared `showDetailLinkAccessibility()` helper

**3. Show detail screen**
- Title, status, network, and genres are read as one grouped element (fewer swipes)
- “Next Season” card reads as one label when loading or loaded
- Failed state keeps “Try Again” separate so it stays actionable

**4. Undo toast**
- Announces “Removed from watchlist” when it appears
- Moves VoiceOver focus to the toast
- Adds hints on Undo (“Restores the show…”) and OK (“Confirms removal…”)

**5. Search results hint**
- Marked as static text so VoiceOver treats it as guidance, not a button

## What to test with VoiceOver

1. **Watchlist** — notifications banner: confirm “Open Settings” is focusable and activates
2. **Search results** — row link should hint “Opens show details”; track star should still work separately
3. **Show detail** — header and next-season status should read in fewer swipes
4. **Untrack a show** — toast should be announced and Undo/OK should be easy to find

If anything still feels off, tell me which screen and what VoiceOver says — I can tune further (e.g. the About section on show detail).

## User

For the most part it's much better, but when I untrack a show, only "removed from watchlist" is read aloud;  undo and ok are ignored.  Also the toast's 5 second delay is too short when waiting for things to be read aloud;  is there any way to have it be longer only when VoiceOver is in use?

## Assistant

Investigating the undo toast dismissal timing and why VoiceOver skips the Undo and OK buttons.

Fixing two issues: container focus and a full-screen `GeometryReader` are likely hiding the toast buttons from VoiceOver; we'll focus the Undo button and extend the undo window when VoiceOver is active.

Fixing toast accessibility: the full-screen `GeometryReader` and container focus were blocking Undo/OK. Pinning the toast to the bottom when VoiceOver is on and extending the undo timer.

Adding a quick unit test for the VoiceOver-aware undo window duration.

Two separate issues were causing this — both are addressed now.

## Why Undo/OK were ignored

1. **Focus was on the whole toast**, not the buttons — VoiceOver read the container and stopped.
2. **The full-screen `GeometryReader` overlay** used for positioning often traps or hides child elements from VoiceOver traversal.

## Fixes

**Undo toast (`UndoToast.swift`)**
- VoiceOver now moves focus to the **Undo** button ~0.9s after the “Removed from watchlist” announcement (time for the announcement to finish).
- When VoiceOver is on, the toast is **pinned to the bottom center** instead of floating near the star button — simpler layout, reliable button discovery.
- Visual layout (anchored near the track button) is unchanged when VoiceOver is off.

**Undo timer (`AccessibilityPreferences.swift` + `WatchlistUndoRemoval.swift`)**
- Default: **5 seconds** (unchanged)
- VoiceOver on: **20 seconds**
- UI tests: **30 seconds** (unchanged)

## What to test

With VoiceOver on, untrack a show and confirm:
1. You hear “Removed from watchlist”
2. Focus moves to **Undo** (swipe right for **OK**)
3. The toast stays visible long enough to reach both buttons

If 20 seconds still feels tight, we can bump it — 30 seconds is easy to change.

## User

Why did you move the location of the toast?

## Assistant

The toast moved **only when VoiceOver is on** — that was a deliberate tradeoff, not an accident.

## Why I did it

The original toast was positioned with a full-screen `GeometryReader` and `.position()` near the track button. That works visually, but it often causes VoiceOver problems:

- The `GeometryReader` fills the screen and can interfere with the accessibility tree
- `.position()` takes the toast out of normal layout, so VoiceOver may not reliably reach **Undo** and **OK**
- That matched what you saw: the announcement played, but the buttons were skipped

Pinning the toast to the **bottom center** when VoiceOver is on avoids that layout and makes the buttons much easier to find.

## The tradeoff

VoiceOver users get a **different toast location** than sighted users. I chose reliability over keeping the exact same spot.

## If you want the same location everywhere

We can keep the anchored position for everyone and fix VoiceOver another way, for example:

- Restructure positioning so it doesn’t rely on a full-screen `GeometryReader`
- Keep focus on **Undo** and the longer timer, but leave the toast by the star button

If you want that, I can revert the VoiceOver-only repositioning and try a layout fix that preserves the original placement.

## User

No, that's ok.  I was just curious.

## Assistant

Makes sense. Short version: the anchored layout was getting in VoiceOver’s way, so with VoiceOver on the toast sits at the bottom where the buttons stay reachable. Without VoiceOver, it still appears next to the track button as before.

## User

The "removed from watchlist" label is no longer being read aloud.  I tap the star to untrack, the toast comes up in the new location, and Undo is selected and read.

## Assistant

The announcement is likely being cut off when focus jumps to Undo. I'll read the toast code and adjust focus order so the message is read first.

Replacing the announcement (which focus to Undo cancels) with a two-step focus: read the message text first, then move focus to Undo.

The announcement was being cancelled when focus jumped straight to **Undo** — VoiceOver prioritizes the focused element over a posted announcement, so you only heard "Undo, button."

The fix uses a two-step focus sequence instead:

1. Focus lands on the **"Removed from watchlist"** text first so VoiceOver reads it naturally
2. After ~1.8 seconds, focus moves to **Undo** so you can act quickly

You can also swipe to **Undo** or **OK** right away without waiting for the auto-focus.

Try untracking again with VoiceOver — you should hear the message, then Undo. If the pause before Undo feels too long or too short, I can tune the timing.

## User

That's good, thanks!

## Assistant

Glad it's working well now. If you notice anything else with VoiceOver as you keep using the app, just let me know.
