> From: https://chatgpt.com/c/6a8dfcfa-f690-83e8-ae81-9f1a3ca45c1e

# you asked

message time: 2026-08-25 13:39:10

I had something go really wrong with the watchlist earlier.  The first screenshot shows the Search page and all the shows that were selected to be on the watchlist.  The second screenshot shows the actual contents of the Watchlist page at that time.  Exiting and restarting the app fixed the problem, and I haven't been able to replicate it.  Can you see anything wrong that might cause this, and/or a way to make it happen?

---

# chatgpt response

I think I can explain this one, and it looks much less scary than a persistence failure.

In the second screenshot, **the “Ended” section is collapsed**. The chevron at the far right points sideways rather than down. Of the six starred shows visible in Search, four are marked **Ended** there:

- *The Murdoch Mysteries*
- *Power Games: The Packer-Murdoch Story*
- *Dynasty: The Murdochs*
- *The Murdochs: Empire of Influence*

The two that aren't ended are exactly the two visible under **Waiting for a Date**: *Macy Murdoch* and *Murdoch Mysteries*. So the screenshots are actually perfectly consistent: all six appear to be in the watchlist; four of them are simply hidden in the collapsed Ended section.

That also explains why quitting and restarting “fixed” it. `collapsedSections` is just `@State` in `WatchlistView`, initialized to an empty set. It isn't persisted. So restarting the app reconstructs the view with **every section expanded again**. Your architecture documentation also confirms that the watchlist groups tracked shows into status sections rather than storing a separate subset for display. 

I looked through the current source ZIP as well. The relevant code is essentially:

```swift
@State private var collapsedSections: Set<WatchlistSection> = []
```

and the section header is itself a full-width button:

```swift
Button {
    withAnimation(.easeInOut(duration: 0.2)) {
        isExpanded.toggle()
    }
} label: {
    ...
    .contentShape(Rectangle())
}
```

So tapping **anywhere across the Ended header row** collapses it. I suspect that's what happened, possibly without you noticing. You can reproduce the screenshot very easily:

1. Put those six shows on the watchlist.
2. Go to Watchlist.
3. Tap anywhere on the **Ended** header.
4. You'll be left looking at exactly those two Waiting-for-a-Date shows and an empty-looking Ended header.
5. Kill and relaunch the app; Ended will be expanded again.

I don't see evidence here of the watchlist getting corrupted or Search and Watchlist disagreeing.

There is one UX issue worth considering, though: **a collapsed section gives no indication of how many shows it is hiding**. In this case “Ended” can look almost like an empty category, especially since your normal design suppresses empty sections entirely. I think something like **“Ended (4)”** when collapsed—or perhaps all the time—would have made this instantly understandable. It might also be worth making the chevron a bit more conspicuous, but the count would do more to prevent this particular confusion.

---

# you asked

message time: 2026-08-25 13:46:05

Ah, ok.  That begs another question, though - shouldn't we be preserving the user's customization of their layout?

---

# chatgpt response

Yes. I think we should preserve that.

Collapsing a section is a user preference about how they want the Watchlist arranged, not just a transient interaction. If they deliberately collapse Ended because they rarely care about those shows, reopening the app and expanding it again is mildly annoying—and, as you just discovered, it can also make the app look inconsistent because the state silently resets on launch.

For this particular preference, I would **not** put it in SwiftData with the watchlist itself. It belongs in something lightweight like `@AppStorage`/`UserDefaults`, because it is UI state rather than domain data. The persisted value could simply be the set of collapsed section identifiers. Then `WatchlistView` initializes from that and updates it whenever a section is toggled.

I’d preserve it across ordinary launches, but I would not worry about syncing it through iCloud or including it in watchlist export/import. It is exactly the sort of device-local presentation preference that `UserDefaults` is good for.

And I’d still add the count to collapsed sections. Persistence fixes the reset, but **“Ended (4)”** makes the current state much more legible even when the user intentionally collapsed it.

---
Powered by [AI Exporter](https://saveai.net)