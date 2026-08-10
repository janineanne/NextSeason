# Undo toast delay issue

## User

Got a fun one for you.

Most of the time, the Ok button on the undo toast works fine.  Tap the button and the row and the toast immediately go away.  But every now and then it waits until the timer has expired to go away.  I can't be positive but I think this only happens on a real phone, not on the simulator.

Here's the console output for the two cases:

Slow:
task_cancel name=undo_removal_timer
breadcrumb task_cancel:undo_removal_timer
task_start name=undo_removal_timer
breadcrumb task_start:undo_removal_timer
watchlist_write_remove show_id=48902
breadcrumb watchlist_remove:48902
watchlist_removed show_id=48902 source=watchlist
task_complete name=undo_removal_timer
breadcrumb task_complete:undo_removal_timer
watchlist_read_all start
breadcrumb watchlist_read_all
watchlist_read_all complete count=7

Fast:
task_cancel name=undo_removal_timer
breadcrumb task_cancel:undo_removal_timer
task_start name=undo_removal_timer
breadcrumb task_start:undo_removal_timer
task_cancel name=undo_removal_timer
breadcrumb task_cancel:undo_removal_timer
watchlist_write_remove show_id=21209
breadcrumb watchlist_remove:21209
watchlist_removed show_id=21209 source=watchlist
watchlist_read_all start
breadcrumb watchlist_read_all
watchlist_read_all complete count=6

Please diagnose and fix the issue.

## Assistant

I'll dig into the undo toast and removal-timer flow — the logs show a second timer start that sometimes isn't cancelled again, which matches the delayed dismiss.

The logs already point at a timer restart race — reading the pending-removal coordinator next.

The logs show the slow path never cancels the timer—OK’s commit never ran. Likely cause: `.glassEffect(.regular.interactive())` on the whole toast can steal taps (highlight without firing the button), which fits intermittent device-only failures. Fixing hit testing and making confirm dismiss the toast synchronously.

Intended change: stop putting interactive Liquid Glass on the whole toast (it can swallow button taps), enlarge Undo/OK hit targets, and clear pending removal synchronously on OK so the toast dismisses on the tap turn.

Reverting the incomplete positioning change and keeping the glass/hit-target fix — `.position` was fine once interactive glass isn’t stealing taps.

**Diagnosis:** The slow log is the timer committing on its own (`task_complete` with no cancel in between). The fast log cancels the timer before remove. So OK’s commit sometimes never ran — the tap was eaten, not delayed.

**Cause:** The toast chrome used `.glassEffect(.regular.interactive())`. Interactive glass on a container can take the touch for its highlight and never deliver it to the Undo/OK buttons. That matches intermittent, device-leaning failures (finger + glass gestures vs precise simulator clicks).

**Fix** (skills: `swiftui-pro`, `swift-concurrency-pro`):
1. Use non-interactive `.glassEffect(.regular, …)` on the toast chrome
2. Enlarge Undo/OK hit targets with padding + `contentShape`
3. Add `confirmPendingRemoval()` so OK clears the toast on the tap turn, then persists

**What to test on a real phone:** Untrack from the watchlist star, tap OK many times (including quickly after the toast appears). Toast and row should dismiss immediately every time — never wait out the 5s timer.

