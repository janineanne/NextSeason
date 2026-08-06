> From: https://chatgpt.com/c/6a6a4f2c-d17c-83e8-abe2-37445a0c752b

# you asked

message time: 2026-07-29 12:07:59

I've noticed that since we added sections to the watchlist, the section name is appearing over the show rows as they are scrolled upward.  Is this how it's supposed to be?  To me it looks like a mistake.  (see Airing Now overlaying the Real Housewives of Atlanta in the screenshot)

---

# chatgpt response

Yes. That's actually the default behavior of `List` sections on iOS—they use **pinned section headers**. As you scroll, the current section header sticks to the top until the next section pushes it away.

However, in your screenshot, I agree that it doesn't look very good.

What's happening is:

- The **"Airing Now"** header is pinned to the top.
- The first row of that section scrolls underneath it.
- Because your header has a translucent/light background (thanks to Liquid Glass), the row remains visible beneath it.
- The result is that the text "Airing Now" appears to be drawn directly on top of "The Real Housewives of Atlanta."

From a technical standpoint, this is expected. From a design standpoint, I think it looks like an artifact rather than an intentional effect.

### I would consider a few options

**1. Make the pinned header more opaque (my preference).**

Give the section header enough material or background that the row underneath is obscured. You still get the nice sticky behavior, but it looks intentional.

This is what most Apple apps effectively do.

**2. Disable pinned headers.**

If you're using a `ScrollView` + `LazyVStack`, you can choose not to pin them. If you're using `List`, there isn't a simple API to turn off pinning.

Personally I think losing pinning would be a step backward for usability.

**3. Increase the header height.**

A taller header separates it visually from the row below. This helps, but doesn't completely solve the overlap.

**4. Accept it.**

Some Apple apps do allow content to show through translucent materials. But in your case, because the section title is left-aligned exactly where the show title begins, the two texts compete with each other.

---

### Looking specifically at NextSeason

I think the issue is amplified because:

- your section headers are **gray text**
- your show titles are **teal**
- they occupy almost exactly the same horizontal position

So the eye reads them as overlapping labels rather than "header floating over content."

If this were my app, I'd probably keep the sticky headers but make the header material a bit more opaque so the row underneath isn't readable while it's pinned. I think that would preserve the usability benefit while making the UI feel much more polished.

Out of curiosity, are you implementing this with a native `List` and `Section`, or is this a custom `ScrollView` with `LazyVStack(pinnedViews: [.sectionHeaders])`? The best fix depends on which approach you're using.

---

# you asked

message time: 2026-07-29 12:11:58

List and Section

---

# chatgpt response

That confirms it is **native `List` behavior**, not something your code deliberately requested. With the plain-style list you appear to be using, SwiftUI pins each `Section` header while its rows scroll beneath it. Apple exposes explicit control over pinning for lazy stacks, but not for section headers inside a native `List`. ([Apple Developer](https://developer.apple.com/documentation/swiftui/section?utm_source=chatgpt.com))

I would revise my recommendation, though: **I would not try to preserve the pinned header by manually making it opaque.** That risks fighting SwiftUI and Liquid Glass, and it still leaves the header occupying scarce space beneath your search field.

For this screen, I think the better behavior is for the section titles to scroll away normally. The categories are useful for organizing the watchlist, but users do not need a persistent reminder that they are currently looking at “Airing Now” or “Ended.” Unfortunately, `List` does not provide a supported “do not pin section headers” switch.

Your practical choices are:

1. **Keep `List` and accept the pinning**, while giving the header a solid enough background that the text cannot visibly collide.
2. **Change the list style**, though that will also change the overall visual treatment and may not fit your current design.
3. **Replace `List` with `ScrollView` + `LazyVStack`**, where section headers remain unpinned unless you explicitly request `pinnedViews: [.sectionHeaders]`.

I would choose **option 3 eventually**, because the screenshot does look like a mistake. But I would not necessarily undertake that rewrite immediately unless it is straightforward. `List` is currently giving you row reuse, swipe actions, edit behavior, accessibility, separators, and other native behavior, so replacing it can create substantially more work than fixing this one visual defect.

For the App Store version, the least disruptive fix is likely to keep `List` and make the header background fully opaque while pinned. Something along these lines may be enough:

```swift
Section {
    // Rows
} header: {
    Text(section.title)
        .font(.headline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
}
```

The important part is that the background must cover the **entire header width and height**, not just sit behind the text. Depending on how your header is currently constructed, you may also need:

```swift
.listRowInsets(EdgeInsets())
```

on the header container, then put your desired horizontal padding inside it.

So: **expected framework behavior, but not visually acceptable here.** I would file it under “polish defect caused by native pinning,” rather than treating it as the intended final design.

---
Powered by [AI Exporter](https://saveai.net)