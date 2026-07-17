# Notifications section message

## User

Please add this message in the Notifications section of the Detail screen:

How notifications work

NextSeason periodically checks your watchlist for new seasons and will notify you when one is found. iOS decides when apps may perform background checks, so opening the app occasionally helps keep your watchlist up to date.

## Assistant

I'll find the Detail screen and its Notifications section first.

### Tool Glob File Search

```
{"globPattern":"**/*Detail*.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

## Assistant

This Detail screen doesn't currently have a Notifications section. Let me search for where a "Notifications" section might exist.

### Tool Ripgrep Raw Search

```
{"pattern":"Notifications","glob":"*.swift","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01198HZ68ve3CLX3WwvBu74H","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"\"Notifications\"","glob":"*.swift","outputMode":"content","context":3,"caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01GDwCBaKb5sbmarmCrAohJj","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/AppAboutView.swift"}
```

## Assistant

Let me check whether there's a Settings screen with a Notifications section, since the About screen also has one.

### Tool Glob File Search

```
{"globPattern":"**/*Settings*.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Detail screen|Detail Screen|detail screen","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01CpvVDGsYyget4iofotZ4j2","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Documentation/MVP/AI Transcripts/7-13-2026 Improve Notifications.md","limit":80}
```

## Assistant

The only screen in the app with a "Notifications" section is the About sheet (`AppAboutView`, titled "About") — it has a Notifications row plus a footer. The per-show detail screen (`ShowDetailView`) doesn't have a Notifications section. Since the message you provided is a general explanation of how notifications work (not show-specific), I want to confirm placement before editing.

### Tool Ask Question

## Assistant

Placing it in the About sheet's Notifications section. Let me look at the `FirstRunCopy` referenced there to match the copy style/location.

### Tool Ripgrep Raw Search

```
{"pattern":"notificationsSettingsReminderMessage|struct FirstRunCopy|enum FirstRunCopy","outputMode":"content","context":3,"caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01Ab7v2ToMaZpJiiQtFN5Yza","offset":0}
```

## Assistant

I'll add the message inside the Notifications `Section`, below the enable/disable row, with a bold heading and the explanatory body.

### Tool Edit File V2

## Assistant

Now I'll add the `notificationsExplanation` string near the other computed copy properties.

### Tool Edit File V2

## Assistant

Let me verify the edited section reads correctly.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Debug/AppAboutView.swift","offset":38,"limit":40}
```

## Assistant

The change is in place. Here's what I did.

## What changed
In `AppAboutView.swift` (the About sheet, which contains the app's only Notifications section), I added the "How notifications work" message directly below the Notifications enable/disable row:

```53:63:NextSeason/Features/Debug/AppAboutView.swift
                    VStack(alignment: .leading, spacing: AppSpacing.tight) {
                        Text("How notifications work")
                            .font(.subheadline.weight(.semibold))
                            .appPrimaryText()
                        Text(notificationsExplanation)
                            .font(.subheadline)
                            .appSecondaryText()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("How notifications work. \(notificationsExplanation)")
```

I stored the copy in a `notificationsExplanation` property (matching how the other notification copy in this view is organized) with your exact text.

Design notes:
- Placed it as a row within the existing Notifications `Section`, above the section footer, so it sits with the notification controls.
- Used `.appPrimaryText()`/`.appSecondaryText()` and `AppSpacing.tight` to match the app's existing styling for headings/body.
- Combined it into a single accessibility element so VoiceOver reads the heading and body together.

## What to test
- Open the About sheet (info button, e.g. from the Show Detail toolbar) and confirm the "How notifications work" heading and paragraph appear in the Notifications section, below the Enabled/Disabled row and above the footer.
- Check both light and dark mode for correct text colors.
- Run VoiceOver over the new block to confirm it reads as one combined element.

One note: you referred to this as the "Detail screen," but this Notifications section actually lives in the About sheet (`navigationTitle("About")`). Let me know if you'd instead like it renamed or moved.

## User

No,  I just mistyped.

## Assistant

Got it, no problem. The change is in the right place then. Let me know if you'd like any tweaks to the wording or styling.

## User

Do any tests need to be added or updated?

## Assistant

Let me check whether the About screen is covered by any existing unit or UI tests.

### Tool Ripgrep Raw Search

```
{"pattern":"AppAbout|About NextSeason|How notifications work|notificationsExplanation|notificationsFooterText","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01UW5Fuqf93kL6nhz5UDRKCY","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"About|about","glob":"**/{NextSeasonTests,NextSeasonUITests}/**/*.swift","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_019PxpsP8CdEvW1axYzZvdnU","offset":0}
```

## Assistant

The About sheet has no existing unit or UI test coverage. Let me check whether copy strings like these are tested elsewhere (e.g. `FirstRunCopy`) to match any established pattern.

### Tool Ripgrep Raw Search

```
{"pattern":"FirstRunCopy|notificationPromptMessage|notificationsSettingsReminderMessage","glob":"**/NextSeasonTests/**/*.swift","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01DjUir4qRdEaTyZGXqijQYj","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"FirstRunCopy","glob":"**/NextSeasonTests/**/*.swift","outputMode":"content","context":3,"caseInsensitive":false,"multiline":false,"toolCallId":"toolu_01H3cHJhcGM3x3zDxtnYGVSs","offset":0}
```

## Assistant

No tests are strictly required for this change, and here's my reasoning:

- **The change is static, non-functional text.** I added a hardcoded copy string (`notificationsExplanation`) and rendered it in `AppAboutView`. There's no logic, branching, or view-model behavior to assert.
- **`AppAboutView` has zero existing test coverage** — no unit tests and no UI tests navigate to the About sheet. So there's no existing test that's now stale or broken by this change.
- **The project's unit tests target view models/services**, not SwiftUI view copy. The only copy that's referenced in tests (`FirstRunCopy.exampleSearchQuery`) is used as a shared constant to *drive* behavior, not to assert exact wording. There's no established pattern of asserting literal display strings, and doing so tends to be brittle.

So: nothing needs to be updated, and I'd recommend against adding a unit test that just re-asserts the literal sentence.

The one thing that *would* add value, if you want a regression guard, is a **UI test** that opens the About sheet and confirms the "How notifications work" text is present — but that'd be net-new scope (there's currently no About-sheet UI test to extend, and the text would likely need an accessibility identifier to query reliably).

Want me to add that UI test, or leave it as is?

## User

No, leave it as is.

## Assistant

Sounds good. The change is complete as is — the "How notifications work" message now appears in the Notifications section of the About sheet, with no test changes needed.
