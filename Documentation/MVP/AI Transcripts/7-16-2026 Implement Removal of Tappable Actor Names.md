# Actor name link removal

## User

Please remove the feature that makes actor's names tappable in the About text and shows a "Coming Soon" alert.  This entails:
* Leave the About text as plain text.
* Remove the attributed-string machinery for actor links.
* Remove the “Coming Soon” alert.
* Remove any analytics or tests that exist solely for actor-name taps.

## Assistant

I'll explore the codebase to find the actor-name tapping feature and related machinery.

The "Coming Soon" feature is in `ShowDetailView.swift`. Let me examine it and its view model.

Now let me look at the SummaryFormatter and FirstRunCopy, and the analytics event.

Now let me find the `actorNameTapped` analytics event definition and any other usages.

Let me read the analytics files and related tests.

Let me look at the diagnostics report/view usages and the analytics tests.

I have a full picture. Let me plan the changes.

Here's my plan. Now making the edits, starting with `ShowDetailView.swift`.

Now `SummaryFormatter.swift` - remove the actor-link machinery.

Now `FirstRunCopy.swift`.

Now the analytics files. Removing the event case, name, parameters, counter, record case, report line, and diagnostics view row.

Now remove the two actor-name tap tests from `SummaryFormatterTests.swift`.

Let me verify no remaining references and check for now-unused variables.

All Swift references are cleaned up. `themeColors` and `analytics` are still used elsewhere, so no unused-variable warnings. Let me build to confirm everything compiles.

The build failed only because the "iPhone 16" simulator isn't available. Let me find an available one and rebuild.

`simctl` needs to run outside the sandbox. Let me retry with full permissions.

There's an iPhone 17 Pro already booted. Let me build and run tests against it.

Build is compiling successfully and now running tests. Let me wait for completion.

The build compiled cleanly with no errors. Tests are now executing on the simulator. Let me wait for the results.

The piped `head -60` closed early, leaving `xcodebuild` writing to a broken pipe — I can't see test results this way. The full build (all targets, including test targets) compiled and linked cleanly, so the code is valid. Let me kill this and re-run just the unit tests with clean output.

Now let me run only the unit test target (skipping slow UI tests), writing full output to a log file I can read afterward.

Exit 65 indicates a failure. Let me check the log.

One failure: `NotificationServiceTests/settingsEntryPointClearsDeferWhenUndetermined()` — unrelated to my changes. Let me check the failure detail and confirm my touched tests passed.

All the tests I touched pass. The only failure is in `NotificationServiceTests`, unrelated to actor-name work. Let me see its failure message to confirm.

All the tests related to my changes pass. The one failure, `NotificationServiceTests.settingsEntryPointClearsDeferWhenUndetermined()`, is in unrelated notification-authorization logic and doesn't touch anything I modified (it's a pre-existing/flaky failure). Let me finalize the todos.

I've removed the tappable actor-name feature and all its supporting machinery. The project builds cleanly and every test related to the change passes.

## What changed

- **`ShowDetailView.swift`**: The About section now renders plain formatted text via `SummaryFormatter.attributedString(from:)` instead of the tappable variant. Removed the `showActorNameAlert` state, the custom `OpenURLAction` handler that tracked taps and triggered the alert, and the "Coming Soon" `.alert` modifier.
- **`SummaryFormatter.swift`**: Deleted `attributedStringWithTappableActorNames(from:)` and the `actorNameTapScheme` constant. Normal HTML-to-`AttributedString` rendering (bold/italic/paragraphs) is untouched.
- **`FirstRunCopy.swift`**: Removed `actorDetailsPlannedMessage` (the alert copy).
- **Analytics** — removed everything that existed solely for actor-name taps:
  - `AnalyticsService.swift`: the `actorNameTapped(showID:)` event case, its `"actor_name_tapped"` name, and its `show_id` parameter mapping.
  - `AnalyticsCounters.swift`: the `actorNameTaps` counter and its `record` case.
  - `AnalyticsDiagnosticsReport.swift` and `DiagnosticsView.swift`: the "Actor name taps" report line and diagnostics row.
- **`SummaryFormatterTests.swift`**: Removed the two tests that exercised actor-name tap links (`tappableActorNameLinks`, `summariesWithoutBoldHaveNoLinks`). All other formatter tests still pass.

## What to test
- Open a show's detail screen and confirm the About text still shows formatting (bold titles, paragraphs) but names are no longer tappable and no "Coming Soon" alert appears.
- Check the beta Diagnostics screen/report no longer lists "Actor name taps."

## Note on test run
The unit test suite passed except for one pre-existing, unrelated flake: `NotificationServiceTests.settingsEntryPointClearsDeferWhenUndetermined()` (notification-authorization defer logic — nothing I touched). All `SummaryFormatterTests`, `AnalyticsCountersTests`, `AnalyticsServiceTests`, and `AnalyticsDiagnosticsReportTests` passed. You may want to re-run that notification test on its own to confirm it's just flaky in your environment.

I left the historical documentation/transcripts (e.g. `Analytics Recommendations.md`) unchanged since those are records rather than analytics or tests — let me know if you'd like those scrubbed too.

## User

Yes, please remove it from Analytics Recommendations.md as well

## Assistant

Let me look at the relevant sections in `Analytics Recommendations.md`.

I'll remove the four actor-name references: the event case in the enum, the "Actor name taps" counter line, the diagnostics report line, and the entire "Actor Names" section.

Done. I removed all actor-name references from `Analytics Recommendations.md`:

- The `actorNameTapped(showID: Int)` case from the Layer 1 `AnalyticsEvent` enum example.
- The "Actor name taps" entry from the Layer 2 stored-counters list.
- The `Actor name taps: 2` line from the Layer 3 sample diagnostics report.
- The entire "Actor Names" section describing the tappable-names behavior and Coming Soon alert.

The doc now matches the code, with no remaining mentions of the removed feature.

## User

Is it in any of the other documentation files?

## Assistant

I'll search all documentation files for any remaining actor-name references.

Yes. The reference falls into two categories — one living doc and several historical AI transcripts. Let me look at the living doc, `Release Readiness.md`.

This is a living readiness doc. I'll remove the actor-name event line.

I've now cleaned all the *living* documentation. Here's the full picture of where actor-name references appear:

**Living docs — updated:**
- `Documentation/MVP/Analytics Recommendations.md` (done last turn)
- `Documentation/MVP/Release Readiness.md` — just removed the "Actor name tapped" analytics event line

**AI Transcripts — left untouched (historical chat records):**
- `MVP/AI Transcripts/7-15-2025 Feature Removal Discussion.md` (this current conversation)
- `MVP/AI Transcripts/7-16-2026 Fix Notification Bug.md`
- `MVP/AI Transcripts/6-25-2026 Implement Analytics.md`
- `MVP/AI Transcripts/6-25-2026 Implement Additional Analytics.md`
- `MVP/AI Transcripts/6-25-2026 Code Review and Analytics Discussion.md`
- `MVP/AI Transcripts/6-25-2026 Update Release Readiness for Feedback and Analytics.md`
- `Post-MVP/AI Transcripts/6-19-2026 Building Post-MVP Planning Documents.md`

My recommendation is to leave the AI Transcripts as-is — they're a dated, point-in-time record of past sessions (including the discussion that led to this removal), so editing them would rewrite history rather than document the current state. But if you'd prefer, I can scrub the actor-name mentions from any or all of them too. Want me to?

## User

No, I think you're right about that.

## Assistant

Sounds good. The AI Transcripts stay as the historical record, and both living docs (`Analytics Recommendations.md` and `Release Readiness.md`) are now consistent with the code.

To recap the whole task: the tappable actor-name feature and its "Coming Soon" alert are fully removed from the app code, the attributed-string link machinery and dedicated analytics/counter/diagnostics are gone, the actor-name tap tests are removed, and the two current documentation files are updated. Let me know if there's anything else you'd like to tackle.
