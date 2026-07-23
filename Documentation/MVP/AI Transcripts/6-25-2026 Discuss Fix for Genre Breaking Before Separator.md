# Genre list separator display

## User

This is what the detail looks like when the list of genres is long.  There's no way to make it display on one line, but I think it would look better with the dot separator on the end of the first line rather than the start of the second.  What do you think?

## Assistant

Agree—that leading dot on the wrapped line looks awkward. I'll find where genres are formatted in the show detail view and see what we can do about line breaks.

I agree — a leading dot on the wrapped line looks like a stray punctuation mark, not part of the list. Keeping the separator glued to the genre above reads more naturally:

```
Drama · Science-Fiction ·
Mystery
```

instead of:

```
Drama · Science-Fiction
· Mystery
```

That matches how most apps handle inline metadata (tags, credits, breadcrumbs): the separator belongs to the item before it, not the one after.

**Why it happens**

Right now genres are one string:

```136:136:NextSeason/Features/ShowDetail/ShowDetailView.swift
                    Text(viewModel.displayShow.genres.joined(separator: " · "))
```

When the line wraps, the layout engine can break at the space *before* `· Mystery`, which pulls the dot onto the next line.

**Fix options**

1. **Non-breaking space before each dot** (small change) — attach `·` to the preceding genre with a non-breaking space (`\u{00A0}`), then join segments with regular spaces. Breaks happen between genre groups, so the dot stays at the end of the line above.

2. **Separate `Text` segments in a flow layout** — each genre is its own view with a trailing dot. More control and clearer for VoiceOver, but heavier than you need for a caption line.

For this screen, option 1 is probably enough: one small formatter (e.g. `genres.joinedWithMiddleDot()`) reused in `ShowDetailView` and `ShowRow`, no layout changes.

If you want, I can add that formatter and wire it up in both places.

## User

Go ahead

## Assistant

I'll add a small genre formatter with non-breaking spaces before dots, then wire it into the show detail and row views.

Adding a small `[String]` extension and updating both call sites.

## User

The app seems to be crashing while the tests are running.

## Assistant

Investigating the test crash — I'll check the test run output and recent changes that might be causing it.

Found recent crash reports — reading the latest one now.

The crash report points to a Swift 6 actor-isolation issue in `genreDisplayLine`. Checking project settings and fixing it.

The project uses default `@MainActor` isolation, so `genreDisplayLine` was MainActor-only while Swift Testing runs off the main thread. Marking it `nonisolated`.

The crash was caused by the genre formatter I added, not by your existing app code.

**Root cause:** The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so new code in the app target is implicitly `@MainActor` unless marked otherwise. `genreDisplayLine` inherited that isolation, but Swift Testing runs tests on a background cooperative queue. When `GenreDisplayTests/multipleGenres()` called the property off the main thread, Swift 6 hit a runtime isolation check and trapped with `dispatch_assert_queue_fail`.

The crash report pointed straight at it:

```
Array+GenreDisplay.swift → genreDisplayLine.getter
GenreDisplayTests.multipleGenres()
_dispatch_assert_queue_fail
```

**Fix:** Mark the property `nonisolated`, same pattern as `SummaryFormatter` — it's pure string formatting with no UI or shared state:

```12:17:NextSeason/Utilities/Array+GenreDisplay.swift
    nonisolated var genreDisplayLine: String {
        enumerated().map { index, genre in
            index < count - 1 ? "\(genre)\u{00A0}·" : genre
        }
        .joined(separator: " ")
    }
```

**Verification:** `GenreDisplayTests` all pass now (`TEST SUCCEEDED`).

You can re-run the full test suite in Xcode (⌘U) — it should no longer crash the host app. The genre wrapping behavior in the UI is unchanged.

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: error
task_id: 498051
title: Run GenreDisplayTests on iPhone 17 Pro simulator
detail: exit_code=65
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/498051.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: error
task_id: 604980
title: Launch app in simulator and capture console output
detail: exit_code=149
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/604980.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## User

<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: error
task_id: 561490
title: Run GenreDisplayTests and capture full log
detail: exit_code=65
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/561490.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>
