# Lock Teal Theme

## User

Please set the theme color to .teamUtility and remove the theme switcher button from all screens.  Leave the code behind as I may want to bring this back in the future, but if if it is all in one or more self-contained files, remove the files from the build target and add comments to the top explaining the status.  Any related code that is in a file with other code, comment it out and add an explanatory comment.

## Assistant

I'll find the theme switcher and where theme colors are applied, then lock the app to `.teamUtility` and park the switcher code (exclude self-contained files from the target, comment out the rest).

Using `.tealUtility` (the enum case — likely what you meant by `.teamUtility`). Next I'll lock the default to that, park `ThemeSwitcherView` out of the target, and comment out its call sites.

Intended changes: lock the palette to `.tealUtility`, exclude `ThemeSwitcherView.swift` from the app target (with a status comment), and comment out its toolbar call sites.

Simulator destination failed; rebuilding for a generic iOS device to confirm compilation.

Done. The app is locked to **`.tealUtility`** (assuming that’s what you meant by `.teamUtility`).

### What changed
- **Default palette** is `.tealUtility` in `AppThemeController`, environment defaults, and previews. UserDefaults restore is commented out so a prior beta selection can’t override it.
- **Theme switcher UI removed** from Search, Watchlist, and Show Detail (call sites commented out with notes).
- **`ThemeSwitcherView.swift`** kept on disk but excluded from the NextSeason target, with a status comment at the top explaining how to restore it.

### What to test
- Launch the app and confirm Teal Utility colors (no palette button in nav bars).
- Flip light/dark mode and check Search, Watchlist, and Show Detail still look correct.
