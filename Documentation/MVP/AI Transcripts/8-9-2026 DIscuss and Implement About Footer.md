# About footer on tabs

## User

I'd like your advice on what to do about the info button. It currentlly lives in the nav bar and that seems like too prominent a placement for the About/Diagnostics information.  Adding a third tab for it also seems too prominent.  I want it to be available, but subtle, since most users will never need it.  Suggestions?

## Assistant

I'll look at how the info button and navigation are set up so the suggestions fit the current UI.

Agreed — a persistent nav-bar `info.circle` reads like a primary action, and a third tab would oversell it even more. Given that About/Diagnostics is already beta-only and Diagnostics is nested behind About, I’d treat this as **support chrome**, not navigation.

### Recommendation
Put a **subtle footer entry on Watchlist only** — something like `NextSeason · 1.0 (42)` or a quiet “About” text button at the bottom of the list. Tap opens the existing About sheet; Diagnostics stays where it is.

Why this fits NextSeason:
- Watchlist is the “home” surface for returning users
- Footer text is discoverable when needed, invisible in normal use
- You can drop it from Search and Show Detail entirely (detail especially shouldn’t carry app chrome)
- Matches a common iOS pattern for version/about without inventing Settings yet

### Other good options (ranked)
1. **Footer on Watchlist** — best balance of subtle + findable
2. **Shrink first, don’t redesign** — keep the toolbar button, but only on Watchlist root (not Search, not detail). Smallest change if you want minimal work
3. **Ellipsis / “More” menu on one root** — fine if you expect more secondary items later; a bit heavier than a footer for just About
4. **Hidden gesture for Diagnostics only** — e.g. long-press the version in About, or 5 taps. Keep About itself findable (credits/notifications copy shouldn’t be secret)

### What I’d avoid
- Third tab
- Info icon on every screen
- Purely secret entry for About (attribution and notification help should remain reachable)

If you want a default to implement: **Watchlist footer → About sheet, remove the toolbar button everywhere else.** I can wire that up whenever you’re ready.

## User

I like the footer idea, but I'm concerned about it not being available to new users in case they run into a problem.  What do you think about putting the same footer on both Search and Watchlist?

## Assistant

Putting the same footer on both Search and Watchlist is a good call.

New users often land on Search with an empty Watchlist, so a Watchlist-only footer would miss the people most likely to be confused. A quiet version/About line at the bottom of both roots keeps it available without feeling like primary navigation.

I’d still keep it off Show Detail — that’s content, not app chrome — and keep the two footers identical so it doesn’t feel like two different features.

## User

ok, lets do that

## Assistant

I'll move About/Diagnostics to matching footers on Search and Watchlist, and remove the nav-bar info button. Reading the SwiftUI skill and the current About/toolbar wiring first.

I'll replace the toolbar button with a shared subtle footer on Search and Watchlist (via `safeAreaInset` so it stays available on empty/idle states), and remove it from Show Detail.

Done. Skills used: `swiftui-pro`.

**What changed**
- Replaced the nav-bar `info.circle` with a quiet footer: `NextSeason · version (build)`
- Footer appears on **Search** and **Watchlist** (pinned above the tab bar via `safeAreaInset`, so it’s available on idle/empty states too)
- Removed from **Show Detail**
- Still beta/DEBUG-only (same `openAppAbout` gate as before)

**Please test**
1. Search idle — footer visible, tap opens About
2. Search with results — footer still reachable, doesn’t fight the list
3. Watchlist empty and with shows — same behavior
4. Show Detail — no About chrome in the nav bar
5. About → Diagnostics still works from the About sheet

## User

That looks good, except I think it should say "About NextSeason".  Otherwise it looks like a label and no-one will think to look there.

## Assistant

Updated — the footer now reads **About NextSeason** so it reads as a tappable entry, not a version label. Version still shows inside the About sheet.

