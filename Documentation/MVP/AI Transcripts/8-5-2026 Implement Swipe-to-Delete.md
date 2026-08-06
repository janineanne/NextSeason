# Watchlist swipe-to-delete feature

## User

Please add swipe-to-delete to the watchlist rows.  This does not replace or change in any way the ability to tap the star to remove a row.

## Assistant

I'll add swipe-to-delete on watchlist rows while keeping the star remove action unchanged. Checking the SwiftUI skill and current watchlist implementation.

Looking at how removal works so swipe-to-delete can reuse the same undoable path as the star.

Adding trailing swipe-to-delete that calls the same undoable `requestRemoval` path as the star (row stays until commit). Using `.zero` for the toast anchor so placement falls back to the bottom, matching the existing toast logic.

Swipe-to-delete is on watchlist rows. Skills used: `swiftui-pro`.

**What changed**
In `WatchlistView`, each row now has a trailing destructive **Delete** swipe action (`allowsFullSwipe: true`). It calls the same `requestRemoval` path as the star, so undo/OK toast behavior is unchanged. The star button is untouched.

**What to test**
1. Swipe a watchlist row left → Delete appears; tap or full-swipe → undo toast, star empties, then row removes after OK/timeout.
2. Tap the star on another row → still removes with undo as before.
3. Undo after a swipe delete → show stays on the list.
4. Swipe-delete the last show → empty state after commit.

## User

It's ok to have a delete toast but it should work differently.  Instead of waiting to delete, the row should delete immediately when the delete button is tapped, and then the toast comes up.  It's more informational than trying to prevent a mistake, since delete is a known destructive action.

Also, a couple of issuse:
- you should be using .onDelete so the button is red
- the toast is being placed at the bottom of the screen, which causes the List to scroll if the row being deleted is also near the bottom.

## Assistant

Swipe delete should remove the row immediately, then show an informational toast—using `.onDelete` for the red button and fixing toast placement so the list doesn’t jump. Digging into the removal/undo flow next.

Implementing immediate swipe deletion via `.onDelete`, an informational toast with Undo that restores, and row-anchored toast placement so it doesn’t sit at the bottom.

Updating the removal coordinator to support immediate swipe-delete, then wiring the view and view model.

Simplifying navigation dismiss (both modes just clear toast state), then updating call sites.

Making `undoPendingRemoval` properly async so tests and callers wait for the undo to finish.

Swipe-to-delete now behaves differently from the star. Skills used: `swiftui-pro`.

**Behavior**
- **Swipe (`.onDelete`)** — system red Delete; row leaves immediately; removal persists; toast is informational. Undo restores the show; OK/timeout only dismisses the toast.
- **Star** — unchanged deferred removal (row stays until commit).

**Toast placement**
- Anchored to the deleted row’s frame (not the bottom of the screen).
- Zero-frame fallback moved to mid-screen so it doesn’t tug the list.

**What to test**
1. Swipe → red Delete → row animates out → toast near that row → Undo restores; OK leaves it gone.
2. Full-swipe delete on a bottom row — list shouldn’t jump to show a bottom toast.
3. Star remove still defers delete with the existing toast flow.

## User

<timestamp>Wednesday, Aug 5, 2026, 5:35 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: success
task_id: 545439
title: Run watchlist-related unit tests
tool_call_id: call-6314a3bb-e26b-42c1-abf6-0722f52bab91-83
fc_ov3cVR5-6SkKZu-899fa270-aws_ue1_1
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/545439.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

The earlier test run couldn’t reach the iOS Simulator (sandbox/CoreSimulator connection). A follow-up run with full permissions passed — all 33 watchlist-related tests succeeded.
