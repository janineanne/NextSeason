> From: https://chatgpt.com/c/6a73d2f5-1358-83e8-ba03-906fe3b04834

# you asked

message time: 2026-08-05 17:20:35

I asked Cursor to add swipe-to-delete to the watchlist screen.  It chose to reuse the same removal path as the star, so there is an undo toast.  It's not working quite right, but I also don't think that's what we want.  The delete should be immediate after the delete button is tapped right?

---

# chatgpt response

Yes—I agree with you. **Tapping the red Delete action should remove the show immediately**, with no extra confirmation.

The separate question is whether that immediate removal should still offer **Undo afterward**. iOS commonly uses both patterns:

- Swipe → tap **Delete** → item disappears immediately
- A temporary Undo toast appears afterward

So Cursor’s choice is not inherently wrong, but reusing the star-removal path may be wrong **architecturally or behaviorally** if it produces awkward animation, stale rows, or confusing messaging.

For NextSeason, I’d probably keep Undo for both removal methods because accidentally swiping a watchlist row is plausible. But they should share only the underlying reversible removal operation—not necessarily the entire UI path.

The intended behavior should be:

1. User swipes and taps Delete.
2. The row disappears immediately.
3. The watchlist updates and sections reorganize immediately.
4. A brief “Removed from Watchlist — Undo” toast appears.
5. Undo restores it to the correct section and position.

There should be **no second confirmation** and no delay while the toast is showing.

If your instinct is that swipe-to-delete should feel more final than tapping the star, it is also perfectly defensible to omit Undo there. But I would lean toward keeping it, provided it behaves cleanly. The problem sounds less like “Undo is inappropriate” and more like Cursor coupled swipe deletion too tightly to the star’s presentation logic.

---
Powered by [AI Exporter](https://saveai.net)