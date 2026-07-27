> From: https://chatgpt.com/c/6a6628c0-2260-83e8-b54c-df22fe3b38b8

# you asked

message time: 2026-07-26 08:33:47

Please audit the app for conformance to the HIG, especially Liquid Glass.

---

# chatgpt response

I’ll inspect the project’s SwiftUI structure and visual components, then compare them against Apple’s current HIG and Liquid Glass guidance. I’ll focus on concrete issues, not generic style advice.

The first clear Liquid Glass concern is structural: the app forces opaque custom navigation-bar backgrounds and custom card/list surfaces. Those choices can suppress the system’s new glass and scroll-edge behavior rather than letting standard SwiftUI components adopt it automatically.

## HIG / Liquid Glass audit

I audited the SwiftUI source in `NextSeason(32).zip` against Apple’s current HIG and Liquid Glass adoption guidance. This is a code-level audit; I did not run the app in Xcode 26 or inspect every screen on an iOS 26 device, so a final visual pass is still n([Apple Developer](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass?utm_source=chatgpt.com))essment

**NextSeason is fundamentally HIG-conformant.** It uses standard SwiftUI navigation, tabs, lists, search, buttons, sheets, alerts, `ContentUnavailableView`, Dynamic Type fonts, and strong accessibility labeling. Because it uses `TabView`, `NavigationStack`, `.searchable`, system toolbars, and standard controls, much of Liquid Glass should arrive automatically when compiled with the current SDK. Apple explicitly recommends relying on these standard components. c2025/323/?utm_source=chatgpt.com))

The main problem is that the app then **covers some of that standard behavior with opaque custom backgrounds and card treatments**. It does not need a Liquid Glass redesign; it needs selective removal of older visual overrides.

## Findings requiring changes

### 1. Remove the forced navigation-bar background

**Priority: High for Liquid Glass**

`AppScreenBackground.swift` contains:

```swift
.toolbarBackground(colors.background, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
```

Every primary screen applies `.appNavigationChrome()`. This forces an opaque, permanently visible navigation-bar background and is directly contrary to Apple’s Liquid Glass migration guidance to remove custom navigation backgrounds that interfere with the system material and scroll-edge effects. com/documentation/TechnologyOverviews/adopting-liquid-glass?utm_source=chatgpt.com))

I would remove `appNavigationChrome()` from:

- `SearchView`
- `WatchlistView`
- `ShowDetailView`
- any sheets or diagnostics screens using it

Then either delete `AppNavigationChromeModifier` or retain it only as a pre-iOS-26 fallback:

```swift
private struct AppNavigationChromeModifier: ViewModifier {
    @Environment(\.appThemeColors) private var colors

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content
                .toolbarBackground(colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
```

Even that fallback may be unnecessary. The cleanest implementation is to allow the navigation bar to be fully system-controlled on every supported release.

### 2. Reconsider the “every row is a floating card” treatment

**Priority: Medium**

Search and Watchlist rows use:

```swift
.listRowSeparator(.hidden)
.listRowBackground(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(colors.surface)
)
```

This is not a formal HIG violation, but it makes the interface look like a custom pre-Liquid-Glass design system layered on top of a native list. It also weakens the distinction Apple now makes between:

- content, which should generally occupy the main plane;
- navigation and controls, which form the floating glass layer.

Apple describes Liquid Glass as a functional layer for navigation and controls above content, not as a material to apply indiscriminately to every content container. c2025/219/?utm_source=chatgpt.com))

For this app, I would test one of these approaches:

1. Use ordinary list rows with system separators and backgrounds.
2. Keep the inset spacing but remove the rounded opaque background.
3. Reserve card treatment for genuinely distinct elements, such as the notification warning.

I would **not** replace every card with `.glassEffect()`. That would be excessive and contrary to the design hierarchy Liquid Glass is intended to establish.

### 3. Empty states should not paint an opaque surface over the whole content area

**Priority: Medium**

The Watchlist empty and no-results overlays use:

```swift
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(themeColors.surface)
```

That creates a large opaque slab immediately beneath the glass navigation layer. It also differs from the Search empty state, which lets `ContentUnavailableView` sit naturally on the screen background.

Remove those two `.background(themeColors.surface)` calls. The system `ContentUnavailableView` is already the correct HIG component and needs no card behind it.

### 4. The custom undo toast needs modernization

**Priority: Medium**

`UndoToast` uses:

```swift
.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
```

That remains functional, but on iOS 26 it may look visually older than the native glass controls around it. This is one of the few places where a custom glass treatment could be justified because it is a transient, interactive control floating above content.

A conditional implementation would be appropriate:

```swift
Group {
    toastContents
}
.padding(.horizontal, 16)
.padding(.vertical, 12)
.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
```

with the current `.regularMaterial` background retained below iOS 26.

Before changing it, test whether a system presentation such as an alert, confirmation dialog, or bottom safe-area action is actually more appropriate. The current anchored toast is well engineered for VoiceOver, so I would not discard it merely for visual fashion.

### 5. Avoid coloring all primary content text with the app accent

**Priority: Medium**

`appPrimaryText()` applies the palette accent to:

- show names;
- section headings;
- empty-state labels;
- status lines;
- other primary content.

This creates a heavily tinted content plane. In Liquid Glass, tint is most useful for identity and interactive emphasis; body content should generally preserve clear system hierarchy. Apple’s updated design emphasizes content first and restrained use of color in controls and glass elements. om/videos/play/wwdc2025/356/?utm_source=chatgpt.com))

I recommend:

- show names and major titles: `.primary`;
- status and metadata: `.secondary`;
- tint color: track buttons, links, selected controls, and occasional emphasis;
- warnings: semantic warning color, preferably with text or an icon rather than color alone.

For example:

```swift
Text(name)
    .font(.headline)
    .foregroundStyle(.primary)

Text(subtitle)
    .font(.subheadline)
    .foregroundStyle(.secondary)
```

Your custom colors appear thoughtfully chosen, but semantic system styles will adapt more reliably to increased contrast, glass backgrounds, accessibility settings, and future OS changes.

## Findings that are already good

### Tab-based Search and Watchlist structure

Your two-tab design is entirely defensible. `TabView` automatically receives the current Liquid Glass tab-bar appearance, and Apple continues to treat a dedicated Search tab as an appropriate design for apps where search is a primary destination. terface-guidelines/tab-bars?utm_source=chatgpt.com))

This supports your decision not to collapse the app into a Watchlist screen with an ambiguous search button. Search is not merely filtering the watchlist; it searches an external catalog, so a distinct destination communicates scope accurately.

Do not build a custom tab bar.

### Standard navigation and search APIs

The app correctly uses:

- `NavigationStack`;
- `NavigationLink(value:)`;
- `.navigationDestination`;
- `.searchable`;
- `.navigationBarDrawer` for persistent Watchlist filtering;
- native toolbar items;
- system alerts and sheets.

These are precisely the components most likely to adopt current design behavior without custom work. c2025/323/?utm_source=chatgpt.com))

### Touch targets

The star control explicitly provides a 44×44-point hit area:

```swift
.frame(width: 44, height: 44)
```

That is correct. The list rows are also broadly tappable through their navigation-link labels, while the star remains a separate control.

### Empty, loading, and error states

The use of:

- `ContentUnavailableView`;
- labeled `ProgressView`;
- retry actions;
- skeleton placeholders hidden from accessibility;
- clear empty-Watchlist call to action

is consistent with native iOS conventions.

### Accessibility

Accessibility work is substantially better than average:

- semantic Dynamic Type fonts rather than hard-coded point sizes;
- combined row labels;
- decorative poster images hidden;
- explicit hints for tracking and navigation;
- VoiceOver-specific placement and focus handling for the undo toast;
- section-header traits;
- identifiers for UI testing;
- notification status communicated in words, not just color.

I found no obvious widespread HIG accessibility failure in the inspected views.

One small improvement: the track button always says:

> “Adds or removes this show from your watchlist”

Use state-specific hints:

```swift
.accessibilityHint(
    isTracked
        ? "Removes this show from your watchlist"
        : "Adds this show to your watchlist"
)
```

You could also expose the state with `.accessibilityValue(isTracked ? "Tracked" : "Not tracked")`.

## App icon

The asset catalog supplies normal and dark icons but no explicit tinted or clear appearance. That is not necessarily invalid; iOS can derive alternate appearances. Still, Apple’s current icon system includes light, dark, tinted, and clear contexts, and Apple recommends evaluating icons under all of them. om/design/whats-new/?utm_source=chatgpt.com))

Before submission:

- test the icon in light, dark, tinted, and clear modes;
- check that the SF Symbol-derived artwork does not become too thin or muddy;
- verify that highlights and dimensional effects do not distort it;
- consider rebuilding it in Icon Composer only if the generated appearances are unsatisfactory.

This is a testing requirement, not evidence that the current icon must be replaced.

## Recommended implementation order

1. Remove the forced navigation-bar background.
2. Remove the full-screen `surface` backgrounds behind Watchlist empty states.
3. Run the app on iOS 26 and inspect native tabs, search, scroll edges, sheets, and toolbar buttons.
4. Test plain or less-card-like list rows.
5. Convert ordinary content text to `.primary` and `.secondary`, retaining tint for controls.
6. Optionally adopt custom Liquid Glass only for the undo toast.
7. Test the app icon in every iOS 26 appearance.
8. Repeat the visual pass with Dark Mode, Increased Contrast, Reduce Transparency, Reduce Motion, and large accessibility text.

## Bottom line

I would not describe NextSeason as nonconforming or visually obsolete. Its architecture is already positioned to receive Liquid Glass automatically. The principal correction is to **stop overriding the native chrome**:

```swift
.appNavigationChrome()
```

is the biggest thing standing between the current app and a convincing Liquid Glass presentation. After removing that and toning down a few opaque surfaces, the app should feel native to iOS 26 without a risky visual rewrite.

---

# you asked

message time: 2026-07-27 13:05:25

I'm curious, you suggested having the list contents scroll under the nav bar, why not the tab bar as well?

---

# chatgpt response

It **should scroll under the tab bar too**. I singled out the navigation bar only because your code explicitly overrides the navigation bar’s background:

```swift
.toolbarBackground(colors.background, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
```

I did not find an equivalent custom override for the tab bar. Since you use a standard `TabView`, iOS 26 should already let the tab bar float above the content, with the content visible beneath its Liquid Glass background. That is now the intended HIG behavior. ([Apple Developer](https://developer.apple.com/documentation/uikit/uitabbar/scrolledgeappearance?utm_source=chatgpt.com))

So the desired arrangement is symmetrical:

- The list scrolls beneath the navigation bar at the top.
- The list scrolls beneath the tab bar at the bottom.
- SwiftUI applies scroll-edge effects to preserve legibility where the content meets each glass surface. ([Apple Developer](https://developer.apple.com/videos/play/wwdc2025/219/?utm_source=chatgpt.com))

There is one important distinction: **scrolling beneath the tab bar does not mean the final row should remain trapped behind it.** The scroll view still respects the bottom safe area so the user can scroll the last row fully above the tab bar. Earlier rows may pass visibly beneath the glass while scrolling.

In other words, I was not recommending different behavior at the two ends. My recommendation was really:

> Let the system manage both bars and allow the content to extend beneath both.

The navigation bar required a code change because NextSeason was preventing that. The tab bar probably does not—unless there is another appearance modifier or bottom overlay elsewhere in the project that I missed.

You may also choose whether the iOS 26 tab bar minimizes as the user scrolls. Apple supports that behavior, but it is optional rather than necessary for Liquid Glass conformance. For a quiet two-tab app such as NextSeason, I would first test the default fixed floating tab bar before adding minimization. ([Apple Developer](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass?utm_source=chatgpt.com))

---

# you asked

message time: 2026-07-27 13:07:06

There is a text field above the tab bar (TVMaze attribution) and the scrolling area ends above that.  How would you suggest handling this?  Is it acceptable to have the content scroll underneath the text too?

---

# chatgpt response

I would **not** let the list scroll directly underneath bare attribution text.

The tab bar is designed as a separate translucent navigation layer, so content peeking through it is intentional. A plain text label is different: overlapping moving rows would reduce its legibility and make it look as though the attribution were accidentally floating over the list. Apple describes navigation components like tab bars as sitting above the content plane; the attribution is content, not navigation. ([Apple Developer](https://developer.apple.com/design/human-interface-guidelines/tab-bars?utm_source=chatgpt.com))

The best treatment is to make the attribution part of the scrolling content itself—ideally as a list footer:

```swift
Section {
    // Search results
} footer: {
    Text("TV data provided by TVMaze")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
}
```

That gives you this behavior:

- Rows scroll naturally toward and beneath the tab bar.
- The attribution appears after the final result.
- The final content can still be scrolled fully above the tab bar.
- There is no permanent strip consuming screen space.
- The attribution remains clearly associated with the data it describes.

My second choice would be a **bottom safe-area inset** containing the attribution. That keeps it permanently visible and moves the scrollable content above it:

```swift
.safeAreaInset(edge: .bottom, spacing: 0) {
    Text("TV data provided by TVMaze")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.background)
}
```

That is approximately what your current layout is doing, although using `safeAreaInset` makes the relationship explicit. I would choose this only if TVMaze requires the attribution to remain visible continuously. It does sacrifice some vertical space and prevents the list from visually reaching the tab bar.

A third possibility is placing the attribution inside a custom glass footer above the tab bar, but I **would not recommend it**. It would create two stacked floating layers—a glass attribution bar and the glass tab bar—for a line of legal or informational text. That gives the attribution too much visual importance and works against Liquid Glass’s goal of keeping content prominent. Apple recommends applying custom glass selectively rather than treating every overlay as glass. ([Apple Developer](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass?utm_source=chatgpt.com))

So my recommendation for NextSeason is:

> Put the TVMaze attribution at the bottom of the list and allow the results to scroll beneath the tab bar.

The exception is if TVMaze’s license or branding terms specifically require persistent, always-visible attribution. In that case, retain a fixed opaque or material-backed safe-area footer and accept that the list should end above it.

---
Powered by [AI Exporter](https://saveai.net)
