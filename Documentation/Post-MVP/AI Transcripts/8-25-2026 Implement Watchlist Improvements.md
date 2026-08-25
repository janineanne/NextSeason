# Watchlist section row count

## User

When a watchlist section is closed, please display the number of rows in that section in parentheses after the section name.  For example, instead of "Ended", the section label might be "Ended (4)"

## Assistant

I'll look at how watchlist sections are labeled and collapsed so we can show the row count in parentheses when a section is closed.

I'll check section titles, localization, and tests so the collapsed count stays consistent with VoiceOver and existing coverage.

I'll check the existing watchlist diffs and localization patterns so this count only appears on collapsed section headers.

I'll add a header-title helper that appends the row count only when a section is collapsed, then wire it into the watchlist section header (including VoiceOver).

The tests need MainActor isolation to match `WatchlistSection`, so I’ll mark the suite `@MainActor` and rerun them.

Collapsed watchlist sections now show how many rows they contain, for example **Ended (4)**. Expanded sections still show just the name.

VoiceOver uses the same label, and Voice Control can still target the section by its name alone (for example “Ended”).

**Please test:** open Watchlist, collapse a section, and confirm the header shows the count. Expand it again and confirm the count disappears. If a search is active, the count should match the filtered rows in that section.

## User

Looks good!  Now, please store the user's Watchlist configuration (ie, which sections are closed) in UserDefaults and restore the saved configuration when the app is launched.

## Assistant

I'll look at how preferences are stored today, then persist collapsed watchlist sections in UserDefaults and restore them on launch.

I'll persist collapsed sections in UserDefaults with a small preferences helper, restore them when Watchlist appears, and reset them for UI tests so rows stay visible.

I'll simplify the tests to match the project's isolated UserDefaults pattern, then run them.

Collapsed watchlist sections are now saved in UserDefaults and restored the next time the app launches. Sections that were never collapsed still open expanded.

UI tests reset this setting on launch so collapsed sections from a previous run cannot hide rows.

**Please test:** collapse one or more Watchlist sections, force-quit the app, reopen it, and confirm those sections are still closed (with their row counts). Expand them, relaunch again, and confirm they stay open.

