> From: https://chatgpt.com/c/6a72aa4e-5c4c-83e8-b227-4850f7dd106a

# you asked

message time: 2026-08-06 18:29:01

There it is;  please review.

---

# chatgpt response

I’ll review the catalog itself and the Swift changes around localization, looking especially for missed user-facing strings, things that shouldn’t have been cataloged, bad interpolation/plural handling, and any unnecessary code churn.

The change set is nicely constrained: one new `Localizable.xcstrings` plus localization edits across the expected UI/service files. I’m comparing the modified literals against the catalog now, rather than doing a generic whole-project code review.

One notable implementation choice looks good: Cursor left ordinary SwiftUI literals such as `Text("Search")` alone and put the matching keys in the catalog, while wrapping strings produced as plain `String` values in `String(localized:)`. That is exactly the distinction I’d want here.

I reviewed the localization change specifically, and overall I think Cursor did a good job. I would **not** undo or redesign this approach. The catalog has 207 entries, the changes are limited to the places that actually need explicit localization, and ordinary SwiftUI literals were generally left readable in place.

There is **one real issue I would ask Cursor to fix** before committing it.

In `DiagnosticsView.swift`, several strings have been added to `Localizable.xcstrings`, but the code still turns them into ordinary `String` values before SwiftUI sees them. In those cases, merely having a matching catalog entry does **not** make them localized.

For example:

```swift
Text(
    launchDiagnostics.previousLaunchEndedUnexpectedly
        ? "Ended unexpectedly ⚠️" : "Clean or not detected"
)
```

Because the conditional expression produces a `String`, SwiftUI treats the result as text rather than as a localizable string key.

The same problem occurs with the fallback diagnostics messages:

```swift
Text(
    betaRefreshDiagnostics?.lastBackgroundFetchResult
        ?? "No background refresh recorded yet."
)
```

and with the helper that takes these as `String`:

```swift
notificationActionButton(
    isLoading: isSendingTestNotification,
    loadingTitle: "Sending…",
    title: "Send Test Notification",
    ...
)
```

The affected group I noticed is essentially:

- “Ended unexpectedly ⚠️” / “Clean or not detected”
- the four “No background/foreground … yet” fallback messages
- “Refreshing…” / “Force Refresh Now”
- “Sending…” / “Send Test Notification”
- “Scheduling…” / “Schedule Pipeline Test Notification”
- “Running…” / “Run Simulated Update Scenario”

Cursor should either explicitly localize these with `String(localized:)`, or preferably change helper parameters such as `loadingTitle` and `title` to `LocalizedStringKey`/`LocalizedStringResource` where appropriate.

Everything else I checked looks sensible. In particular:

- `FirstRunCopy` correctly uses `String(localized:)` because those properties return `String`.
- `NextSeasonStatus.headline`, error descriptions, notification content, watchlist section titles, accessibility strings, etc. were correctly converted.
- Interpolated catalog entries such as `Season %lld premieres %@` and `Updated %@` appear correctly represented in the catalog.
- The long Diagnostics documentation was sensibly given semantic keys such as `diagnostics.help.overview` rather than using enormous paragraphs as keys.
- The `.xcstrings` JSON is valid.
- I found no whitespace/diff-format problems.
- The catalog does not need an explicit `project.pbxproj` entry because this project is using Xcode's file-system-synchronized groups.

I also found one uncataloged visible-looking string in `AppScreenBackground.swift`:

```swift
"Season 2 premieres Jan 1, 2027"
```

but that appears to be preview/sample material, so **I agree with leaving it out**.

So my verdict is: **good implementation, with one small Diagnostics localization hole.** I would tell Cursor something like:

> Please fix the remaining localization issue in `DiagnosticsView.swift`: several cataloged strings are being converted to ordinary `String` values by ternary/nil-coalescing expressions or passed through `String` helper parameters, so they won't actually use the String Catalog. Make those strings genuinely localized, preferably using `LocalizedStringKey`/`LocalizedStringResource` for SwiftUI-facing helper parameters where appropriate. Do not make any other localization changes.

After that, I'd be comfortable committing this.

---

# you asked

message time: 2026-08-06 21:09:26

Please take another look and make sure you're satisfied.

---

# chatgpt response

I’ll re-check the localization pass against the previous issue, then do a broader sweep for any remaining strings that are cataloged-but-not-localized or user-facing strings that were missed.

The specific Diagnostics problem is fixed correctly: ternary/fallback UI now stays inside `Text(...)`, and the reusable button helper takes `LocalizedStringKey`. That removes the runtime-localization hole I flagged.

The broader sweep is also clean so far: among direct SwiftUI text/button/label/navigation/accessibility literals, the only uncataloged one is the preview/sample “Season 2 premieres Jan 1, 2027,” which I still think should stay out.

Yes. I took a second, broader pass, and I’m satisfied with it now.

Cursor fixed the Diagnostics issue correctly. The strings that were previously being collapsed into ordinary `String` values now remain localizable—for example, the conditional labels use separate `Text(...)` branches, and the reusable diagnostics button helper now accepts `LocalizedStringKey` instead of `String`.

I also checked beyond that specific fix:

- All direct user-facing SwiftUI literals I found are represented in the catalog.
- The one exception is `"Season 2 premieres Jan 1, 2027"` in `AppScreenBackground.swift`, which is preview/sample content and should stay out.
- Strings produced outside SwiftUI—notification bodies, errors, status descriptions, accessibility text, diagnostics report text, etc.—are explicitly localized where necessary.
- Formatted/interpolated strings have corresponding catalog entries with the expected `%@` / `%lld` substitutions.
- The diagnostics help text uses semantic keys with English source values, which is a good solution for those long passages.
- `Localizable.xcstrings` is valid JSON, has 207 entries, and none are missing English values.
- The Xcode project already has String Catalog preference and string extraction settings enabled.
- `git diff --check` reports no whitespace problems.
- I don't see unrelated refactoring mixed into the change.

One thing that initially looked suspicious in an automated check was that source such as:

```swift
String(localized: "Season \(season) is now airing.")
```

doesn't literally match the catalog key:

```text
Season %lld is now airing.
```

But that's expected: Xcode converts Swift interpolation into the catalog's format-specifier representation.

So at this point I have **no changes to recommend**. I think this is ready to commit.

And I like the resulting policy better than the partial approach we initially discussed: essentially all intentional user-facing language is cataloged, while the SwiftUI code can still say the very readable `Text("Watchlist")`. That's a nice outcome.

---

# you asked

message time: 2026-08-06 21:11:57

It doesn't say that, though - its looks like a lot of them use String(localized: "Watchlist") instead.  Why?

---

# chatgpt response

You’re right to question that. I’ll inspect where `String(localized:)` is being used and separate the cases where it’s necessary from places where plain SwiftUI localization would be cleaner.

Mostly because `String(localized:)` is needed when the text has to become an actual `String` before it reaches SwiftUI.

For example, this is ideal and needs no wrapper:

```swift
Text("Watchlist")
```

`Text` has an initializer that treats a string literal as a localizable resource, so Xcode can look it up in `Localizable.xcstrings`.

But this property returns a plain `String`:

```swift
var title: String {
    switch self {
    case .airingNow:
        String(localized: "Airing Now")
    ...
    }
}
```

If Cursor wrote just:

```swift
"Airing Now"
```

then that would be an ordinary Swift `String`, and later:

```swift
Text(section.title)
```

would display that string literally rather than perform a catalog lookup. So `String(localized:)` is appropriate there.

The same applies to things like error descriptions, notification bodies, computed accessibility labels, diagnostics report text, and anything passed through an API whose parameter type is `String`.

I checked specifically for the uglier pattern:

```swift
Text(String(localized: "..."))
```

and I don't see Cursor doing that as a general practice. The `String(localized:)` uses I found are overwhelmingly in places where the surrounding code actually requires a `String`.

So my earlier sentence was a little too broad when I said the code could still say `Text("Watchlist")`. That is true **when the literal is directly in a SwiftUI localization-aware API**. Elsewhere, explicit `String(localized:)` is necessary.

There is still a design choice hiding here, though. Some of those APIs could potentially be changed to use `LocalizedStringResource` or `LocalizedStringKey`, which would reduce the number of `String(localized:)` calls. I don't think that's automatically better. In many of these cases—`ShowStatus.displayName`, notification text, `TVMazeError.errorDescription`, diagnostics strings—returning a real `String` is perfectly natural, and `String(localized:)` is the straightforward modern API.

So after looking at the actual occurrences, **I don't object to the amount of `String(localized:)` in the project**. It isn't Cursor unnecessarily wrapping every cataloged string; it's mostly the consequence of localizing text that lives outside direct SwiftUI literals.

---
Powered by [AI Exporter](https://saveai.net)
