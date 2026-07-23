# Search page button visibility

## User

I think the "Try an Example" button should disappear from the Search page after they've done their first search, which demonstrates that they understand how to do so.

## Assistant

Let me find the Search page and the "Try an Example" button.

Let me look at the `FirstRunPreferences` and the view model to understand existing patterns.

Now I understand the structure. Here's my plan:

1. Add a persistent `hasCompletedFirstSearch` flag to `FirstRunPreferences` (mirroring the existing `searchResultsHintDismissed` pattern).
2. In `SearchView`, read that flag via `@AppStorage`, set it to `true` once a search completes, and only show the "Try an Example" button in the idle state when the user hasn't completed a search yet.

Let me add the preference key first.

Now update `SearchView` to read the flag, mark it when a search completes, and conditionally show the button.

Now add logic to mark the flag once a search produces a result. I'll add an `onChange` observing the view model's state.

Now conditionally show the button in the idle state.

Let me check how UI tests handle first-run state resets, since some tests expect the button to appear.

UI tests reset first-run state on launch, so I should reset the new flag too so the button reliably appears at test launch.

Let me review the UI test helper that taps the example button to ensure the flow still works.

Let me check the UI tests that use the example button to ensure none expect it to reappear after clearing a search.

The changes are consistent with existing patterns. Let me verify the project builds.

No iPhone 16 simulator available. Let me find one that exists.

The simulator service needs to run outside the sandbox. Let me build against the available "My Mac" destination to validate compilation.

Provisioning, not compilation. Let me build with signing disabled to validate the code compiles.

Build succeeded. The code compiles cleanly.

## Summary

I made the "Try an Example" button disappear from the Search page once the user completes their first search, persisting across launches.

Changes:

- `NextSeason/Utilities/FirstRunPreferences.swift` — Added a `hasCompletedFirstSearch` persisted flag (key `hasCompletedFirstSearchKey`), a `markFirstSearchCompleted()` helper, and a DEBUG-only reset helper, mirroring the existing `searchResultsHintDismissed` pattern.
- `NextSeason/Features/Search/SearchView.swift`:
  - Added an `@AppStorage` binding for the new flag.
  - Added `markFirstSearchCompletedIfNeeded(for:)`, invoked via `.onChange(of: viewModel.state)`, which sets the flag once a search reaches a real outcome (`.results` or `.empty`). Network `.failed` and transient `.loading`/`.idle` states don't retire the button.
  - Wrapped the "Try an Example" button in `if !hasCompletedFirstSearch` so it's only shown to users who haven't searched yet.
- `NextSeason/NextSeasonApp.swift` — Reset the new flag on UI-test launches (alongside the existing search-hint reset) so the button still reliably appears at the start of UI tests.

Notes/decisions:
- I only count a completed search (`.results`/`.empty`) as "demonstrating they understand how to search" — a failed request won't hide the button. Tapping the example itself will hide it afterward, since it runs a real search.
- Existing UI tests tap the example at launch before results arrive, so they're unaffected.

What to test:
1. Fresh install → Search tab shows "Try an Example". Perform any search that returns results (or a no-results query) → return to the idle state (clear the query) and confirm the button is gone.
2. Force-quit and relaunch → button stays gone.
3. Confirm the example button still works when tapped on first run (prefills and runs the search).
4. Run the Search/Navigation UI test suites to confirm they still pass.
