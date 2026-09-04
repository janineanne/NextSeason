> From: https://chatgpt.com/c/6a9a3866-5104-83e8-b0c2-707e0b180ec7

# you asked

message time: 2026-09-03 20:19:15

I'm going through my beta tester feedback.  One commented on the search button on the watchlist, saying "Hide the icon from accessibility. It currently says “optical equipment” before it says search.".  I can't reproduce that;  for me it always says just Search.  Can you think of a way this might happen?

---

# chatgpt response

Yes — and I think your tester's comment is plausible even though your code looks correct.

I checked the current `WatchlistView`. The button is essentially:

```swift
Button {
    toggleWatchlistSearch()
} label: {
    Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
}
.accessibilityLabel(
    isSearchPresented
        ? String(localized: "Close watchlist search")
        : String(localized: "Search watchlist")
)
.accessibilityIdentifier(AccessibilityID.Watchlist.searchButton)
.accessibilityElement(children: .ignore)
```

So **your explicit accessibility label is correct**, and `.accessibilityElement(children: .ignore)` should normally prevent VoiceOver from separately announcing the SF Symbol.

The interesting part is **"optical equipment."** That sounds very much like an automatically generated accessibility description for the `magnifyingglass` SF Symbol. In other words, their device appears to be exposing the `Image` as an accessibility element *in addition to* the `Button`, despite your attempt to combine/ignore its children.

That could be OS-version-dependent. SwiftUI's accessibility tree around toolbar/navigation-bar items has had plenty of implementation details that vary between iOS releases. It might also depend on where VoiceOver focus lands or how the navigation toolbar is represented on their particular device. So you could get:

> Optical equipment. Search watchlist. Button.

while your device only gives:

> Search watchlist. Button.

### I would make the fix they suggested

Explicitly hide the image:

```swift
Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
    .accessibilityHidden(true)
```

I'd **keep the button's `.accessibilityLabel`**. The button remains accessible; only the decorative image inside it disappears from the accessibility tree.

In fact, once you do that, `.accessibilityElement(children: .ignore)` is probably redundant. I'd be inclined to simplify it to:

```swift
Button {
    toggleWatchlistSearch()
} label: {
    Image(systemName: isSearchPresented ? "xmark" : "magnifyingglass")
        .accessibilityHidden(true)
}
.accessibilityLabel(
    isSearchPresented
        ? String(localized: "Close watchlist search")
        : String(localized: "Search watchlist")
)
.accessibilityIdentifier(AccessibilityID.Watchlist.searchButton)
```

That is more explicit about your intention: **the image is decorative; the button supplies the accessible meaning.**

And this is exactly the sort of thing having multiple human accessibility testers is good for. Your automated accessibility audit could happily pass this, and your own VoiceOver testing could sound perfect, while somebody else's OS/device combination exposes a subtly different accessibility tree.

So I'd mark this feedback **valid and worth fixing**, even though you can't reproduce it.

---

# you asked

message time: 2026-09-03 20:24:33

Ok, will do.  We're using the same version of iOS (26.6.10. He has an iPhone 17 while I only have a 16 -it would be pretty strange for this to differ on hardware, but I don't have a better explanation.

---

# chatgpt response

Yeah, I agree — I’d be surprised if the iPhone 17 vs. 16 itself were the cause. VoiceOver’s accessibility tree is overwhelmingly driven by iOS and SwiftUI, not the hardware model.

A few other differences could explain it even on the same iOS version: his VoiceOver verbosity/settings may differ from yours; he may be navigating with a different gesture or rotor mode that lands on the image child first; or there could be some state-specific SwiftUI accessibility-tree weirdness when the toolbar item is created or updated. “Optical equipment” strongly suggests VoiceOver is somehow seeing the SF Symbol’s own semantic classification, though.

That makes `.accessibilityHidden(true)` on the `Image` a particularly good fix: it removes the ambiguity rather than relying on SwiftUI to correctly suppress the child because of `.accessibilityElement(children: .ignore)`.

I also wouldn’t spend much time trying to reproduce it before fixing it. It’s a harmless, semantically correct change even on devices where the problem never occurs.

---

# you asked

message time: 2026-09-03 20:25:12

Do you see any other images which should be similarly hidden?

---

# chatgpt response

I’ll scan the SwiftUI image usage for decorative SF Symbols inside already-labeled controls versus images that carry meaningful content. I’ll focus especially on toolbar buttons and icon-only buttons, since those are the likeliest to produce duplicate VoiceOver announcements.

Yes. I found **two other places where I’d make the same change**, plus a few places I would leave alone.

The strongest candidates are:

- **Diagnostics → Help button** (`questionmark.circle`). It is another icon-only toolbar button with its own `.accessibilityLabel("Diagnostics help")`. I’d add `.accessibilityHidden(true)` to the `Image`, for exactly the same reason as the Watchlist search button.
- **Watchlist collapsible section chevron** (`chevron.down`). The containing button already has a complete accessibility label and an expand/collapse hint. The chevron is purely visual state decoration, so I’d hide it too. That prevents VoiceOver from ever trying to announce something like “down chevron” in addition to the section title.

You’ve already done this correctly in several places: the trash icon in the Undo toast, notifications-disabled bell, TheTVDB logo, the track/untrack star, the Show Detail poster/status icon, and progress indicators are explicitly hidden.

I **wouldn’t bother hiding the icons inside `ContentUnavailableView`/`Label`** — the magnifying glasses, warning triangles, empty-watchlist star, etc. Those are being used as part of a native `Label` rather than as children of an independently labeled icon-only button, and SwiftUI should expose the `Label` as one semantic element. Likewise the `Label` icons in Diagnostics actions such as “Force Refresh Now” should be fine.

One small thing I noticed that isn't the same problem: the **search-result poster placeholder `tv` icon** in `ShowRow` isn't individually hidden, but I'd leave it because the entire image/poster view may already be treated appropriately by its containing row. It isn't an actionable icon with a separate accessibility label, so it doesn't present the same risk.

So I’d make this a very small cleanup: **Watchlist search, Diagnostics help, and collapsible-section chevrons explicitly hidden from accessibility.** That's enough; I wouldn't go through the app indiscriminately putting `.accessibilityHidden(true)` on every SF Symbol.

---

# you asked

message time: 2026-09-03 20:35:00

Ok, please review the changes in branch beta-test-feedback.

---

# chatgpt response

I’ll compare `beta-test-feedback` against its base, then review the touched code for correctness, accessibility behavior, regressions, and whether the changes match the tester feedback.

So far the accessibility changes themselves look appropriately narrow. I’m also checking the other beta-feedback edits in this branch, because there are a couple of unrelated UI/string changes bundled into the same commit.

I found one thing worth separating from the actual beta-feedback code: Xcode rewrote the screenshot group references in the project file. I’m verifying whether that is a harmless correction or accidental project churn before I give you the verdict.

I reviewed `beta-test-feedback` against `main`. The branch is in good shape; I don’t see any production-blocking issues in these changes.

The three accessibility fixes are exactly what I’d want: the Watchlist search icon, Diagnostics help icon, and collapsible-section chevron are now explicitly `.accessibilityHidden(true)`, while their containing controls retain meaningful labels/hints. Removing `.accessibilityElement(children: .ignore)` from the Watchlist search button is also cleaner now that the image itself is explicitly hidden.

The other beta-feedback changes look sensible too. Retiring **Try an Example** after the user has successfully completed a search is implemented correctly using the existing persistent `hasCompletedFirstSearch` flag, and the replacement idle-state copy correctly stops telling an experienced user to try the example. The Show Detail card’s change from padding on all sides to vertical-only padding is straightforward and doesn’t raise any code concerns.

I found **one small cleanup item**, not something I’d hold the branch for: the new experienced-user search copy,

> “Search for a show to see its next-season status. Use the search field above.”

was extracted into `Localizable.xcstrings`, but the corresponding entry is currently empty rather than having an explicit English localization. That will still fall back to the source string, so it won’t break the app, but for consistency with the catalog I’d populate the English value.

There’s also an accessibility-test maintenance detail: `AccessibilityAuditUITests` has the old first-run description in its known `ContentUnavailableView` false-positive lists, but not the new post-first-search description. **The current audit suite doesn’t appear to exercise the Search idle screen after a completed search**, so this shouldn’t cause a test failure today. Still, I’d add the new string to `knownStyledCopyLabels` and `contentUnavailableCopy`; that keeps the allowlist correct if you later add coverage for that state.

Finally, the seemingly unrelated `.pbxproj` churn is actually legitimate. Xcode corrected the screenshot groups so **MVP points to the `.jpeg` MVP screenshots and Post-MVP points to the `.png` Post-MVP screenshots**. The files on disk match those references. I would keep that change.

I couldn’t run `xcodebuild` in this environment because Xcode isn’t installed here, but `git diff --check` is clean and the code-level review found no functional defects.

**Verdict: approved, with the two tiny localization/test-allowlist cleanup items above.** I’d make those while you’re in the branch, but I wouldn’t consider either a serious problem.

---

# you asked

message time: 2026-09-03 20:43:01

Question about the Search Idle screen.  Is it better to do what I did, which is to duplicate the string and edit it, or should I have broken it up so there's no duplicated text?  (so the first run case would combine two strings). That's what I've usually seen done at work, but it can make for some really janky code at times.

---

# chatgpt response

I’d keep what you did: **two complete localized strings**, even though they duplicate some text.

The “combine two strings” approach often looks cleaner in English code, but it’s worse for localization. Translators may need to change word order, punctuation, sentence boundaries, or phrasing entirely. If you split this:

> Search for a show to see its next-season status. Try an example below or use the search field above.

into something like:

```swift
"Search for a show to see its next-season status."
+
"Try an example below or use the search field above."
```

you’ve implicitly assumed those pieces can always be translated independently and then safely joined. That’s not necessarily true.

For your two states, I’d prefer something like:

```swift
if hasCompletedFirstSearch {
    Text("Search for a show to see its next-season status. Use the search field above.")
} else {
    Text("Search for a show to see its next-season status. Try an example below or use the search field above.")
}
```

That gives each UI state a complete thought and gives a translator freedom to phrase each one naturally.

The rule I’d use is:

- **Duplicate localized prose freely when the complete sentence/message differs by state.**
- Reuse strings when they are genuinely standalone UI concepts: `"Cancel"`, `"Search"`, `"Watchlist"`, etc.
- Avoid building user-facing sentences by concatenating localized fragments unless you’re using a localization mechanism specifically designed for interpolation/plurals.

So yes, the pattern you saw at work is common, but I think your instinct that it can produce janky code is justified. In this particular case, **the duplication is preferable to clever reuse**.

One tiny improvement I might make is give the two catalog entries descriptive comments/context such as “Search empty state, first use” and “Search empty state, returning user.” That makes the apparent duplication much less confusing to a future translator or developer.