# Watchlist section overlay bug

## User

I've noticed that since we added sections to the watchlist, the section name is appearing over the show rows as they are scrolled upward.  Is this how it's supposed to be?  To me it looks like a mistake.  (see Airing Now overlaying the Real Housewives of Atlanta in the screenshot)

What do you suggest to fix this?

## Assistant

That overlay on scroll usually means the section header isn’t getting a proper background or safe area when it pins — I’ll inspect how the watchlist sections are built and what styling they use.

You're right — that's a bug, not intended behavior.

## What's happening

The watchlist uses a plain `List` with a hidden scroll background (`.appPlainListStyle()`), and custom collapsible section headers in `WatchlistCollapsibleSection`:

```368:390:NextSeason/Features/Watchlist/WatchlistView.swift
        } header: {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.tight) {
                    Text(title)
                        .font(.headline)
                        .appPrimaryText()
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // ...
        }
```

In a plain list, section headers **pin** while you scroll — standard iOS behavior, and useful for a long watchlist. The problem is that your header is just text and a chevron with **no opaque background**. Once `.scrollContentBackground(.hidden)` removes the list's default fill, row content scrolls underneath the pinned header and shows through. That's why "Airing Now" looks like it's floating over "The Real Housewives of Atlanta."

Headers further down (e.g. "Waiting for a Date") can look fine when they're not pinned; the overlap shows up when a header sticks under the search bar.

## Recommended fix

**Give section headers an opaque background** that matches the screen. Smallest, most consistent change with your existing styling:

```swift
} header: {
    Button { ... } label: {
        HStack(spacing: AppSpacing.tight) {
            Text(title)
                .font(.headline)
                .appPrimaryText()
            Spacer()
            Image(systemName: "chevron.down")
                // ...
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.background)
    }
    .buttonStyle(.plain)
    // accessibility modifiers...
}
```

That keeps sticky headers (helpful when you have many shows) and stops rows from bleeding through.

**Optional polish:**
- A bottom divider on the header for clearer separation from rows
- Slightly taller vertical padding so the pinned bar matches the grey strip look of the other headers

## Alternatives (if you want different behavior)

| Approach | Tradeoff |
|---|---|
| **Disable sticky headers** | No overlap, but you lose section context while scrolling. SwiftUI doesn't expose this cleanly; it usually means UIKit work or replacing `List` sections with a `ScrollView` + `LazyVStack`. |
| **`.headerProminence(.increased)`** | Might help with system chrome, but less predictable with custom headers and a hidden list background. |
| **Switch to inset grouped list style** | Different visual language for the whole screen — probably not what you want here. |

I'd go with the opaque `AppColor.background` on the header — one focused change in `WatchlistCollapsibleSection`, no architecture changes.

Want me to apply that fix?

## User

Let's try it and see how it looks.

## Assistant

I'll add an opaque background to the collapsible section headers so pinned titles no longer show row content through them.

Section headers now use an opaque `AppColor.background` fill so pinned titles no longer show row content through them.

**What changed:** In `WatchlistCollapsibleSection`, the header label got vertical padding, a full-width frame, and an opaque background matching the screen.

**What to test:**
1. Open the Watchlist with multiple sections (especially "Airing Now" with several shows).
2. Scroll up so "Airing Now" pins under the search bar — row content should stay hidden behind the header.
3. Collapse and expand a section — the header should still look and behave the same.
4. Check in light and dark mode if you support both.

If the background doesn’t reach the screen edges, or you want a subtle divider under the header, say how it looks and we can tweak it.

## User

That looks ok, but it looks like a bit of a workaround. I've stashed that change so we can go back to it if we want to.

ChatGPT suggested "Replace List with ScrollView + LazyVStack, where section headers remain unpinned unless you explicitly request pinnedViews: [.sectionHeaders]."  Can we try that?

## Assistant

Replacing the watchlist `List` with `ScrollView` + `LazyVStack` should stop headers from pinning by default — I'll inspect the current list setup and what we need to preserve (swipe delete, refresh, search, etc.).

Replacing `List` with `ScrollView` + `LazyVStack` (no pinned headers) and moving delete to `.swipeActions` on each row.

Removing extra top padding on the first section so spacing matches the old list.

The watchlist now uses `ScrollView` + `LazyVStack` instead of `List`, so section headers scroll away naturally and no longer pin under the search bar.

**What changed**

1. **`List` → `ScrollView` + `LazyVStack`** — No `pinnedViews`, so headers are not sticky. That removes the overlay issue without a background workaround.

2. **Collapsible sections** — `Section(isExpanded:)` was replaced with a manual `VStack` that shows/hides rows based on `isExpanded`.

3. **Swipe-to-delete** — `.onDelete` (List-only) was replaced with `.swipeActions` on each row. Behavior is unchanged: immediate removal + undo toast.

4. **Row styling** — Added horizontal/vertical padding and inset dividers between rows to approximate the old list look.

**What to test**

1. Scroll through sections — headers should scroll off with content (no "Airing Now" overlay).
2. Swipe-to-delete on a row — row disappears immediately, undo toast appears.
3. Collapse/expand section headers.
4. Pull-to-refresh and in-list search.
5. Delete the last show in a section or the whole watchlist — confirm no crash or layout glitch.
6. Compare row spacing/separators to the old list — we can tune padding if it feels off.

If you prefer sticky headers later, you can add `pinnedViews: [.sectionHeaders]` explicitly — but only when you're ready for that behavior.

## User

The poster image for the first show in the first section is always out of alignment with the others.

## Assistant

The first row in the first section likely has different padding or layout modifiers — I'll compare how that row is built versus the rest.

Suspecting `VStack` centers rows that don't span full width, and the first `NavigationLink` may expand differently — I'll enforce leading alignment and full-width rows.

The first row was sitting in a `VStack` that **centers** children by default. Outside `List`, each row’s `HStack` only sized to its content, so rows with slightly different widths landed at different horizontal positions. The first row’s `NavigationLink` was often wider, so it looked further left than the rows below.

**Fix:** Force leading alignment and full width at every level:
- Row `HStack` → `.frame(maxWidth: .infinity, alignment: .leading)`
- `NavigationLink` label → same frame so the link fills the row
- Section `VStack` → `alignment: .leading` plus full-width frame

Rebuild and check that the "Airing Now" poster lines up with the rows in "Coming Soon" and below. If anything still looks off, tell me which row and we can tune further.

## User

That looks better.  Just out of curiousity, please pin the headers so I can see what that looks like.

## Assistant

I'll enable pinned section headers on the watchlist `LazyVStack` so you can compare that behavior.

Switching to `Section` inside `LazyVStack` with `pinnedViews: [.sectionHeaders]`, and giving pinned headers an opaque background so rows don't show through when scrolling.

Section headers are pinned now. Changes:

1. **`LazyVStack(pinnedViews: [.sectionHeaders])`** — headers stick while you scroll.
2. **`Section(isExpanded:)`** — required for pinning (replaces the manual `VStack` header layout).
3. **Opaque header background** — `AppColor.background` on pinned headers so rows don’t show through (same issue as the original `List`).

**What to try:** Scroll through multiple sections and watch headers like “Airing Now” and “Coming Soon” stick under the search bar as their rows scroll away.

When you’re done comparing, say whether you want to keep pinned headers or go back to unpinned (`pinnedViews: []`).

## User

That looks exactly the same as the first attempt above, the one I stashed in case we wanted to go back to it.  Is that what you would expect?

## Assistant

Yes — that’s expected.

Both approaches end up in the same place visually when headers are pinned:

| | **Stashed fix (List)** | **Current (ScrollView + pinned)** |
|---|---|---|
| Headers stick while scrolling | Yes — `List` pins by default | Yes — `pinnedViews: [.sectionHeaders]` |
| Rows show through pinned header | Fixed with `AppColor.background` | Same fix |
| Header design | Custom button + chevron | Same |

So you’re not imagining it: pinning + opaque background produces the same look either way. The ScrollView change mainly bought you a **choice** — headers scroll away by default, and you only opt into pinning explicitly. Once you turned pinning back on, you recreated the same sticky-header UX the `List` gave you for free.

**Where they still differ (mostly not visible when pinned):**

- **Unpinned mode** — ScrollView lets headers scroll off with no background hack; `List` always pins.
- **Row chrome** — manual padding/dividers vs system list insets (you fixed alignment, so this is subtle).
- **Implementation** — no `List`/`UICollectionView` delete crash; swipe uses `.swipeActions` instead of `.onDelete`.

**Practical takeaway:** If you prefer headers that scroll away, drop pinning (`pinnedViews: []`) and drop the header background. If you prefer sticky section labels while scrolling, either approach works — pick based on whether you want to stay on `List` or keep the ScrollView setup.

Want to revert to unpinned headers as the default?

## User

Yes

## Assistant

Reverting to unpinned headers: removing `pinnedViews` and the opaque header background, and restoring the manual section layout.

Section headers are unpinned again. Changes:

- Removed `pinnedViews: [.sectionHeaders]` from the `LazyVStack`
- Restored the manual `VStack` collapsible sections (instead of `Section(isExpanded:)`)
- Removed the opaque header background (not needed when headers scroll away)

Headers should scroll off with their rows now, with no overlay. Row alignment fixes are unchanged.

**Quick check:** Scroll the watchlist and confirm section titles move up with the content instead of sticking under the search bar.

## User

Since the List solution is simpler, I'm going back to the stashed version.

## Assistant

Checking git state and the stashed changes so we can restore the List-based watchlist cleanly.

That’s a reasonable call. The `List` version is simpler: you keep `.onDelete`, system row styling, and pinned headers without rebuilding layout by hand.

Your tree already matches that direction:

- **`WatchlistView.swift`** is back on `List` + `Section(isExpanded:)` + `.onDelete`
- **Staged change** is only the header fix (padding, full-width frame, `AppColor.background`) — the stashed workaround for the overlay bug

Nothing else from the ScrollView experiment remains in the working tree. The ScrollView work lives in `stash@{0}` (`scrollview`) if you ever want to reference it; you can drop that stash when you’re sure you won’t.

**What to verify:** scroll with pinned headers (no row bleed-through), swipe-to-delete, and collapse/expand sections — all should behave as before, with the overlay fixed.
