# Theme feature modification

## User

I'd like to modify the Theme feature.  I think it should not apply the change until the user presses the Done button.  It doesn't make sense to change the theme and the icon multiple times since the user can't see them until they've exited that sheet anyway.  What do you think?

## Assistant

That makes sense — applying theme and icon only on Done avoids redundant work while the sheet is open. I'll find how Theme is implemented today so we can discuss the change concretely.

### Tool Semantic Search Full

```
{"query":"Theme feature sheet Done button apply theme icon","targetDirectories":[],"explanation":""}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Theme","glob":"*.swift","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"tool_4d4f1d64-697f-4631-9081-e904c08e9ee","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/ThemeSwitcherView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/Theme/AppThemeController.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/Theme/AppThemeIconService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/Theme/AppThemeEnvironment.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"ThemeSwitcher|themeSelected|AppThemeController","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_ae4c19a7-44ca-43b2-86c4-80c8a8e1415","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"theme|Theme|palette","glob":"*UITest*","caseInsensitive":true,"multiline":false,"toolCallId":"tool_ee86475e-9e79-4b00-aa16-169b8eda669","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"AppPaletteVariant","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_72c0a4a2-8555-4dd6-b0fe-4bf349d3a3c","offset":0}
```

## Assistant

I agree — deferring until **Done** is the right call for this sheet.

## Why it fits

Right now, each palette tap immediately:

1. Writes to `UserDefaults` via `AppThemeController.variant`’s `didSet`
2. Re-themes the whole app through `appThemeColors(from:)`
3. Triggers `setAlternateIconName` via `AppThemeIconUpdater`

While the sheet is open, the user mostly can’t see any of that. The icon change is especially wasteful — it can be slow, may show a system confirmation, and gets fired on every tap even if they’re just comparing options.

The sheet already has **Current Swatches** and **Sample UI** sections, so live preview still makes sense — just driven by a **draft** selection inside the sheet, not the global theme.

## Recommended behavior

| Action | Behavior |
|--------|----------|
| Tap a palette | Update draft only; refresh swatches/sample in the sheet |
| Tap **Done** | Commit draft → `themeController.variant`, analytics, icon sync, then dismiss |
| Swipe to dismiss | Discard draft; nothing changes |

That matches a familiar “pick, preview, confirm” pattern and avoids redundant icon churn.

## Small implementation note

This is mostly a `ThemeSwitcherView` change:

- `@State private var draftVariant` initialized from `themeController.variant` on appear
- Row selection and preview sections use `draftVariant`
- **Done** assigns `themeController.variant = draftVariant` and tracks analytics once

No need to change `AppThemeController` or the icon updater — they already react when `variant` changes; they’d just change once on commit instead of on every tap.

One nuance: if the user opens the sheet and taps **Done** without changing anything, you can skip the write/icon sync entirely (`guard draft != committed`).

Want me to implement this?

## User

Yes please

## Assistant

I'll implement deferred theme commit on Done: draft selection in the sheet, apply only when the user confirms. Reading the SwiftUI skill and the theme files first.

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/ThemeSwitcherView.swift"}
```

## Assistant

I'll add draft state in `ThemeSwitcherView` and commit theme + analytics only when Done is tapped.

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/ThemeSwitcherView.swift"]}
```

### Tool Run Terminal Command V2

### Tool Run Terminal Command V2

## Assistant

Done. Theme changes now commit only when the user taps **Done**.

### What changed

In `ThemeSwitcherView`:

- **`draftVariant`** — local state initialized from the current theme when the sheet opens
- **Palette taps** — update the draft only (checkmark, swatches, and sample card update live inside the sheet)
- **Done** — applies `draftVariant` to `themeController` only if it changed, fires analytics once, then dismisses
- **Swipe to dismiss** — draft is discarded; app theme and icon stay unchanged

The footer now reads: *"Tap Done to apply and save your choice on this device."*

No changes were needed in `AppThemeController` or `AppThemeIconService` — they still react when `variant` changes, but only once on commit.

### What to test

1. Open Theme, tap several palettes — main app behind the sheet should **not** change
2. Swatches and sample card **should** update as you tap
3. Tap **Done** — app theme and home screen icon should update once
4. Open again, change selection, swipe to dismiss — theme should stay as before
5. Open and tap **Done** without changing — no icon flash or extra analytics event

## User

Looks good!  While we're at it, the theme sheet says "Current" next to the lavendar theme no matter which one is selected.  That should either say Default or be removed altogether.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Utilities/Theme/AppPaletteVariant.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Current|Default|lavender","glob":"**/Theme/**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_f9725654-c0f4-4dd4-84ae-fa87b7f453c","offset":0}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Lavender \\(Current\\)","caseInsensitive":false,"multiline":false,"toolCallId":"tool_92112b63-2cbb-40ff-9c35-9a490fef6d9","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"AppPaletteVariant.*displayName|\\.displayName","glob":"*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_e7e0b9a5-3399-4f71-8736-260869b1178","offset":0}
```

## Assistant

Replacing the hardcoded `(Current)` on lavender in `displayName` — it was misleading now that selection uses the checkmark.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

The `(Current)` suffix was hardcoded on lavender in `AppPaletteVariant.displayName`, so it never reflected the actual selection. I removed it — lavender is now just **Lavender**, consistent with the other palette names. The checkmark already shows which one is selected in the sheet.

Also updated the analytics counter test that expected the old string.

**What to test:** Open the theme sheet and confirm lavender reads "Lavender" with no suffix, and the checkmark moves to whichever palette you tap.

If you'd rather label it **Lavender (Default)** to signal it's the shipped default, I can switch to that.
