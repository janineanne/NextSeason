# String catalog extraction

## User

Please extract all intentional user-facing app copy into a String Catalog. Include SwiftUI text, buttons, labels, alerts, accessibility labels/hints, notification content, user-facing errors, status text, and formatted strings with substitutions. Do not extract logging strings, identifiers, URLs, SF Symbol names, API/raw server values, test fixtures, accessibility identifiers, or other developer-only strings. Preserve the existing visible wording and behavior. Prefer normal String Catalog localization mechanisms rather than creating a separate Strings.swift constants layer.

## Assistant

I'll extract user-facing copy into a String Catalog. First I'm mapping the project structure and locating every intentional UI string in the codebase.

I'll read the key source files and project setup next so we can add the String Catalog and wire up localization correctly.

I'll read the remaining files that need updates and generate the String Catalog.

I'll generate the String Catalog and update non-SwiftUI code to use `String(localized:)`; SwiftUI literals will stay as-is since they auto-localize from the catalog.

Updating Swift files to use `String(localized:)` for non-SwiftUI string returns.

All intentional user-facing copy is now in a String Catalog. Here is what changed:

## String Catalog

Created `NextSeason/Localizable.xcstrings` with **207 entries** covering:

- Search, Watchlist, and Show Detail UI
- Alerts and notification prompts
- Accessibility labels and hints
- Notification body text
- User-facing errors (`TVMazeError`)
- Status headlines and watchlist section titles
- About screen and TVMaze attribution
- Beta diagnostics UI, refresh summaries, and shareable report text
- Diagnostics help (keyed entries like `diagnostics.help.overview`)

The catalog compiles into `en.lproj/Localizable.strings` in the app bundle.

## Code changes

**SwiftUI views** — Left string literals in place (`Text("…")`, `Button("…")`, `.navigationTitle`, `.alert`, etc.). These resolve from the catalog automatically via `LocalizedStringKey`.

**Non-view / computed strings** — Updated to `String(localized:)` in:

- `FirstRunCopy`, `TVMazeError`, `NextSeasonStatus+Display`, `ShowStatus`, `WatchlistSection`
- `NotificationStatusPresentation`, `WatchlistTracking`, `StatusChangeDetector`
- `ShowRow`, `ShowDetailView`, `WatchlistView`, `UndoToast`, `AppAboutView`
- `BetaBuildConfiguration`, `BetaRefreshDiagnostics`, `WatchlistRefreshService`
- `AnalyticsDiagnosticsReport`, `DiagnosticsSimulatedUpdateRunner`, `DiagnosticsSimulatedDataProvider`
- `DiagnosticsDocumentationCopy` (uses keyed catalog entries for long help text)

**Excluded** (as requested): logging strings, `AccessibilityID` values, URLs, SF Symbol names, TVMaze/API data, test fixtures, preview-only copy, and developer identifiers like `"Beta diagnostics / simulated"`.

## Verification

- Build succeeded
- All 137 unit tests passed

## What to test

1. Search idle, empty, and error states — copy unchanged
2. Watchlist sections, empty state, search-no-matches, undo toast
3. Show detail next-season card and watchlist update alert
4. Notification permission prompts and disabled banner
5. About screen and (in Debug/TestFlight) Diagnostics + help sheet
6. Trigger a network error and confirm error messages still read correctly
7. UI tests that match literal strings (e.g. `"Something Went Wrong"`, `"Try an Example"`) should still pass in English

To add another language, open `Localizable.xcstrings` in Xcode and add localizations there.

## User

Please fix the remaining localization issue in DiagnosticsView.swift: several cataloged strings are being converted to ordinary String values by ternary/nil-coalescing expressions or passed through String helper parameters, so they won’t actually use the String Catalog. Make those strings genuinely localized, preferably using LocalizedStringKey/LocalizedStringResource for SwiftUI-facing helper parameters where appropriate. Do not make any other localization changes.

## Assistant

I'll inspect `DiagnosticsView.swift` for strings that lose catalog lookup through ternaries, nil-coalescing, or plain `String` helpers.

Fixing catalog strings that become plain `String` via ternaries, nil-coalescing, and helper parameters—using `LocalizedStringKey` and explicit `Text` branches where SwiftUI needs them.

Fixed the remaining localization issues in `DiagnosticsView.swift` only. Catalog strings were being turned into plain `String` values before they reached SwiftUI, so they skipped the String Catalog.

**Ternary expressions** — Replaced with `if`/`else` branches so each arm uses a string literal directly in `Text`:
- Previous launch status (`"Ended unexpectedly ⚠️"` / `"Clean or not detected"`)
- Force Refresh button label (`"Refreshing…"` / `"Force Refresh Now"`)
- `notificationActionButton` label (via `LocalizedStringKey` parameters + separate `Text` branches)

**Nil-coalescing fallbacks** — Replaced `?? "…"` with `if let` / `else` so fallback copy stays as catalog-backed literals:
- Background/foreground fetch results and notification decisions

**String helper parameters** — `notificationActionButton` now takes `LocalizedStringKey` for `loadingTitle` and `title` instead of `String`.

**Date display** — Replaced `formattedDate()` (which returned `String`) with `formattedDateLabel()` (`@ViewBuilder`), using `Text("Never")` for the nil case and formatted date text otherwise. The next refresh window uses an interpolated `Text` literal for the scheduled case and `Text("Not scheduled yet")` for the nil case.

Build succeeded. In Diagnostics (Debug/TestFlight), confirm launch status, refresh fields, and beta action button labels still look correct in English.

## User

There's 1 build error and 14 warnings.  I think they're all in Localizable.

## Assistant

I'll run a build and inspect the Localizable catalog output to find the error and warnings.

Fixing the empty catalog entry, removing duplicate stale format keys, and marking manual strings so Xcode stops warning.

Fixed the issues in `Localizable.xcstrings`:

**1 build error**
- `"Season %lld announced — date to be confirmed."` had an empty localization block (no `en` value). Added the missing English entry.

**14 warnings** — three causes:
1. **12 stale entries** — Xcode had marked strings as stale because they’re only referenced via `String(localized:)`, not auto-extracted SwiftUI literals. These are now marked `"extractionState": "manual"` (build channel labels like `"Debug"`, `"TestFlight"`, etc.).
2. **5 duplicate format keys** — Auto-extraction had created positional duplicates alongside the canonical keys (e.g. `"Delivered for %1$@: %2$@"` vs `"Delivered for %@: %@"`). Removed the duplicates and kept the canonical keys with positional values for translators.
3. **5 `"new"` state entries** — Normalized to `"translated"`.

Clean build succeeds with no localization errors or warnings from the command line. Rebuild in Xcode and the String Catalog issues should be gone.

