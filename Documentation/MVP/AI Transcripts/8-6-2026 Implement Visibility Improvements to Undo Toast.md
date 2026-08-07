# Swipe-to-delete feature update

## User

Let's discuss the new swipe-to-delete feature in Watchlist.

When the user presses the delete button, or swipes all the way to the left, the row is removed immediately, the row below it slides up to take its place, and then the undo toast appears at the bottom of the space where the deleted row was, which is now the newly-moved row.  Given that the row backgrounds and the toast background are both very neutral, it's easy to miss it.

Let's try these changes to see if they will help:
* Give the toast a stronger visual treatment (accent-colored Undo, trash icon, slightly higher contrast).
* Add a brief entrance animation (slide up + fade in over ~0.2 seconds).

## Assistant

I'll locate the Watchlist undo toast implementation first, then apply stronger styling and a short slide-up + fade-in entrance.

Updating `UndoToast.swift`: stronger contrast (accent Undo, trash icon, surface background) and a ~0.2s slide-up + fade-in entrance.

Updated `UndoToast.swift` with stronger styling and a short entrance animation. This applies everywhere the undo toast appears (watchlist swipe/delete, star untrack, search, detail).

### Visual treatment
- **Trash icon** (`trash.fill`) in accent color at the leading edge
- **Message** uses primary text instead of secondary
- **Undo** is accent-colored with plain button style so it reads as the primary action
- **OK** uses primary text for clearer contrast
- **Background**: accent-tinted surface (same pattern as `NotificationsDisabledBanner`) instead of neutral material; light shadow on pre–iOS 26

### Entrance animation
- **0.2s ease-out** slide up (~10pt) + fade in on appear
- Fade-only on dismiss so it doesn’t fight the row sliding up

### What to test
1. **Watchlist swipe-to-delete** — toast should stand out against the row that slides up underneath it
2. **Delete button** (full swipe) — same behavior
3. **Star untrack / search / detail** — toast styling should be consistent there too
4. **VoiceOver** — message and Undo focus order should be unchanged
5. **Light and dark mode** — accent tint and contrast on both

If it still blends in after swipe-delete, next options could be a stronger accent wash, a brief highlight on the row area, or anchoring the toast slightly below the moved row instead of overlapping it.

