# Aptabase SDK integration

## User

Please install the Aptabase SDK into the project as a Swift package.  My key is XXXXXXX;  store that in Secrets.xcconfig along with the TVDB api key.

Then wire it into AnalyticsTracking so that the only direct references to Aptabase live there, and the rest of the app uses AnalyticsTracking only.

Then add tracking for the following events and values:
- search_performed
- Query length
- Result count
- Whether a result was selected
- Whether the selected show was already on the watchlist

Don't change any of the data being collected by AppDiagnosticLogger.

## Assistant

I'll start by reading the Swift skills and locating the current analytics, secrets, and search code so Aptabase can be wired in without changing diagnostic logging.

The project already has an `AnalyticsTracking` abstraction and xcconfig secrets. Next I’ll read those files and how search currently reports events.

Search already fires `search_performed` with query length and result count. I’ll inspect secrets, package setup, and how a result is selected so the new watchlist fields can be added without touching diagnostics.

I’ll add the Aptabase package and store the app key next to the TVDB key, then keep all Aptabase calls inside `AnalyticsService` so the rest of the app only talks to `AnalyticsTracking`.

Next I’ll extend `search_performed` with selection and watchlist fields, and send those events through Aptabase from `AnalyticsService` only.

Package resolved. Next I’ll compile and run the analytics and search tests.

The failures are just a wrong query-length assertion (`severance` is 9 characters). I’ll correct those tests.

Aptabase is installed and wired so feature code still only talks to `AnalyticsTracking`. The SDK itself is referenced only in `AnalyticsService`.

**Package and secrets**
- Added [aptabase-swift](https://github.com/aptabase/aptabase-swift) 0.3.11 to the NextSeason target.
- Stored `APTABASE_APP_KEY = A-US-9194610252` in `Config/Secrets.xcconfig` next to the TVDB key (still gitignored).
- Exposed it to the app as `AptabaseAppKey` in `App-Info.plist`, same pattern as `TVDBApiKey`.

**Analytics wiring**
- `AnalyticsService` initializes Aptabase when analytics is enabled, then forwards every `AnalyticsEvent` to Aptabase.
- UI tests still disable analytics, so nothing is sent during those runs.
- `AppDiagnosticsLogger` is unchanged.

**`search_performed`**
The event now includes:
- `query_length`
- `result_count`
- `duration_ms` (existing)
- `result_selected`
- `already_on_watchlist`

Successful searches wait to fire until the user opens or tracks a result, or starts another search / clears the query. That is what makes the last two fields meaningful. Empty and failed searches still fire immediately with both flags `false`.

**What to test**
1. Build and run (Xcode will resolve Aptabase if needed).
2. Search for a show and open it — Aptabase should get `search_performed` with `result_selected=true` and the correct watchlist flag.
3. Search, then search something else without opening a result — the first event should have `result_selected=false`.
4. Search for nonsense — immediate `search_performed` with `result_count=0`.
5. Confirm Diagnostics still shows the same local counters and breadcrumbs as before.

## User

<timestamp>Friday, Aug 14, 2026, 4:48 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: error
task_id: 195485
title: Build and run analytics and search tests
tool_call_id: call-253baa29-4254-4740-9c9e-a6bd70aaf34f-97
fc_owE5oaR-6jKPYy-a2b3d675af50a6c4_0
detail: exit_code=65
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/195485.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

<timestamp>Friday, Aug 14, 2026, 4:48 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: success
task_id: 195486
title: Re-run updated search analytics tests
tool_call_id: call-659d4622-f76b-48ba-b11f-373ee10e8f5f-104
fc_owE6CkS-6jKPYy-a2b3d85cdda5a6c4_2
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/195486.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

The first test run failed on a wrong query-length assertion (`"severance"` is 9 characters, not 10). That was corrected, and the follow-up search analytics tests passed.

## User

Are there any tests that need to be updated or added as a result of this change?

## Assistant

I’ll check the current test suite against the new `search_performed` fields and Aptabase wiring to see what’s already covered and what’s still missing.

Existing tests that used the old `searchPerformed` signature were already updated, and coverage for the new behavior is already in place. Nothing else **has** to change for the suite to compile or stay accurate.

**Already updated**
- `AnalyticsServiceTests` — new associated values, plus a check that `search_performed` parameters include `result_selected` and `already_on_watchlist`
- `AnalyticsCountersTests` — same event shape; counters still ignore the new flags
- `SearchViewModelTests` — `makeViewModel` can take a `RecordingAnalyticsService`

**Already added**
- Successful search waits until `recordResultSelected`
- A follow-up search flushes the previous one as unselected
- Empty results fire immediately with both flags `false`

**Optional extras, not required**
- Failed search also fires immediately (the failed-state test does not assert analytics)
- Clearing the query flushes a pending search as unselected
- A second selection does not emit another `search_performed`

I would not add tests that talk to Aptabase directly. Feature code stays on `AnalyticsTracking`, and `RecordingAnalyticsService` is the right stand-in. SwiftUI view tests for the open/track tap are also a poor fit here; the view model already covers the outcome.

## User

ChatGPT would like you to make a few changes:

Cursor Prompt – Refine Aptabase Integration

Please refine the recent Aptabase integration. Overall the architecture is good (Aptabase remains behind AnalyticsService), but there are several important issues that should be corrected.

1. Do not change or remove existing local analytics

The existing analytics implementation predates Aptabase and is used for local diagnostics and logging.

Do not remove, delay, or otherwise change any existing calls to analyticsService.track(...).

Specifically:

* Restore the previous behavior where completed searches are logged immediately.
* Do not introduce any pending or deferred search logging mechanism.
* Existing analytics should continue to behave exactly as they did before Aptabase was added.

The Aptabase integration should be layered on top of the existing analytics, not replace or alter it.

⸻

2. Record completed searches immediately

The current implementation delays sending search_performed until either:

* the user selects a result, or
* another search begins.

This loses analytics whenever the user performs a search and then leaves the app without selecting anything.

Examples:

* performs search
* views results
* switches tabs
* backgrounds app
* force quits

These searches currently disappear entirely.

Instead:

* record the completed search immediately when search results are available
* preserve the existing behavior of local analytics
* never require a later event to “flush” a completed search

⸻

3. Separate search completion from search selection

The current implementation combines two different concepts into one event.

Instead, use two independent events:

search_performed

Record immediately after the search completes.

Properties:

* query length
* result count
* search duration

search_result_selected

Record only when the user actually opens a search result.

Properties:

* already on watchlist

Do not include resultSelected as a property of search_performed.

Selection rate can then be computed by comparing the counts of the two events.

This is simpler, more accurate, and avoids special buffering logic.

⸻

4. Restrict Aptabase to the intended production analytics

The current implementation forwards every existing AnalyticsEvent to Aptabase.

That is not what we want.

Existing local analytics should remain untouched.

Remote analytics should initially include only:

* app launched
* search performed
* search result selected

Everything else should remain local only.

Please implement an explicit whitelist (or equivalent design) so it is impossible for future local analytics events to begin being transmitted remotely by accident.

One acceptable design would be for the Aptabase mapping to return nil for events that are not intended for remote transmission.

⸻

5. Avoid misleading properties

If a search result is never selected, there is no selected show.

Therefore:

alreadyOnWatchlist = false

is misleading because there was no selected show.

Using a separate search_result_selected event naturally solves this problem.

⸻

6. Preserve the privacy boundary

Continue following the existing privacy policy.

Never transmit:

* search text
* show titles
* user-entered content
* personally identifying information

Only the minimal properties needed to evaluate search quality should be sent.

⸻

7. Add tests for the remote analytics boundary

Please add tests that verify the production analytics behavior.

At minimum:

* appLaunched is sent remotely.
* searchPerformed is sent remotely with the expected properties.
* searchResultSelected is sent remotely with the expected properties.
* A local-only event (for example, watchlist added) is not sent remotely.

These tests should verify the Aptabase mapping rather than only the local analytics parameters.

⸻

8. Check Package.resolved

Ensure that Package.resolved is committed and not accidentally left untracked.

⸻

9. Restore executable permissions

The following scripts appear to have had their executable bit removed without any content changes.

Please restore their original executable permissions unless there was an intentional reason to change them.

⸻

Please keep the overall architecture exactly as it is now:

* feature code depends only on AnalyticsTracking
* Aptabase remains an implementation detail inside the analytics layer
* no direct Aptabase SDK calls should appear in views or view models

Please also avoid unrelated refactoring while making these changes.

## Assistant

I’ll restore immediate local `search_performed` logging, split selection into its own remote event, and whitelist only the three Aptabase events. First I’m reading the current analytics and search code plus the Swift skills.

Scripts already have their executable bits. I’ll restore immediate local search logging, add a separate `search_result_selected` event, and whitelist only the three Aptabase events.

Local analytics now behave as they did before Aptabase. Remote tracking is a separate, explicit whitelist on top.

**Local analytics restored**
- `search_performed` fires again as soon as a search completes (results, empty, or failed).
- The pending/flush path is gone.
- Existing `analytics.track(...)` call sites and local counters/logging are unchanged.

**Two independent events**
- `search_performed` — `query_length`, `result_count`, `duration_ms`
- `search_result_selected` — `already_on_watchlist` only, and only when a result is opened

**Aptabase whitelist**
`AnalyticsEvent.remoteEvent` returns a payload only for:
- `app_launched`
- `search_performed`
- `search_result_selected`

Everything else, including `watchlist_added`, returns `nil` and stays local. New catalog events stay local unless they are added to that mapping.

**Tests**
`AnalyticsServiceTests` now checks the remote mapping, not just local parameters. Search view-model tests again assert immediate `search_performed`.

**Package.resolved**
Staged at `NextSeason.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (Aptabase 0.3.11). It is no longer untracked; it will be included in the next commit.

**Scripts**
The scripts that are executable in git already had `+x` on disk. I reapplied those bits; there was no mode drift to restore.

**What to test**
1. Search for a show and leave without opening it — local diagnostics and Aptabase should both get `search_performed`.
2. Open a result — Aptabase should also get `search_result_selected` with the watchlist flag.
3. Add a show to the watchlist — that should stay local only.

## User

<timestamp>Friday, Aug 14, 2026, 5:22 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: success
task_id: 195487
title: Run analytics and search unit tests
tool_call_id: call-77258af7-f84e-49bc-8295-b62c904667f4-159
fc_owEGZhY-6jKPYy-a2b409b7ba2df4d9_0
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/195487.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

The analytics and search unit tests finished successfully.

## User

Please make two final refinements to the Aptabase analytics implementation. Keep the current architecture and behavior otherwise unchanged, and avoid unrelated refactoring.

1. Distinguish failed searches from genuine zero-result searches

At the moment, remote analytics can see:

search_performed
query_length = ...
result_count = 0

for both:

* a successful search that genuinely returned zero matches
* a search that failed because of a network/API error

Those cases should be distinguishable so search-quality analytics are not distorted by infrastructure failures.

Please add a coarse outcome property to the remotely transmitted search_performed event.

Use an enum or similarly type-safe representation with these values:

* results
* empty
* failed

Semantics:

* results: search completed successfully and returned one or more results
* empty: search completed successfully and returned zero results
* failed: search did not complete successfully because of an error

Preserve the existing local analytics behavior, including the existing non-fatal-error logging. This new property is specifically to make the remote search-quality event interpretable.

Continue recording the existing:

* query length
* result count
* search duration

For a failed search, keep whatever result-count behavior best preserves the existing local implementation, but the remote outcome = failed must make it unambiguous that this was not a genuine no-results search.

Please add or update tests covering all three outcomes.

2. Reduce visibility of the remote analytics implementation types where practical

Please review RemoteAnalyticsEvent and RemoteAnalyticsValue.

They appear to be implementation details used only by the analytics/Aptabase layer.

If no code outside that implementation needs direct access to them, reduce their visibility appropriately—for example by making them private or fileprivate, or nesting them inside the relevant analytics type if that results in cleaner code.

Do not introduce extra abstractions just to hide them. If broader visibility is genuinely required by the current design or tests, leave them where they are and explain why.

The goal is simply to avoid exposing implementation-detail types unnecessarily.

After making these changes, please run the relevant analytics/search tests and report what changed and whether they pass.

## Assistant

I’ll add a type-safe remote `outcome` on `search_performed` (results / empty / failed) without changing local analytics, then tighten visibility of the Aptabase mapping types if the tests still allow it.

I’ll add a type-safe `outcome` on `search_performed` for Aptabase only, keep local logs/counters the same, and nest the remote mapping types so they stay an analytics-layer detail.

Remote `search_performed` events now include a type-safe `outcome`, and the Aptabase mapping types are nested so they are no longer top-level.

**Search outcome**
`SearchPerformedOutcome` is `results`, `empty`, or `failed`. It is sent only on the remote event, along with the existing `query_length`, `result_count`, and `duration_ms`.

Local Console parameters and counters are unchanged. Failed searches still use `result_count = 0` locally and still record `nonFatalError`.

**Visibility**
`RemoteAnalyticsEvent` and `RemoteAnalyticsValue` are now `AnalyticsEvent.RemoteEvent` and `AnalyticsEvent.RemoteValue`. They stay `internal` because the whitelist tests inspect `remoteEvent` through `@testable import`. `fileprivate` / `private` would hide them from those tests, and adding another abstraction just to hide them did not seem worth it.

**Tests**
`AnalyticsServiceTests`, `AnalyticsCountersTests`, and `SearchViewModelTests` all passed, including coverage for all three remote outcomes and a failed-search view-model case that still logs the non-fatal error.

## User

<timestamp>Friday, Aug 14, 2026, 5:28 PM (UTC-7)</timestamp>
<system_notification>
The following task has finished. If you were already aware, ignore this notification and do not restate prior responses.

<task>
kind: shell
status: success
task_id: 195488
title: Run analytics and search unit tests
tool_call_id: call-38d10fa8-dfb4-4a4e-85c8-043d1f6aa60b-183
fc_owEJSiU-6jKPYy-a2b412abddb1cce5_1
output_path: /Users/janine/.cursor/projects/Users-janine-Documents-TbF-Projects-NextSeason/terminals/195488.txt
</task>
</system_notification>
<user_query>Briefly inform the user about the task result and perform any follow-up actions (if needed). If there's no follow-ups needed, don't explicitly say that.</user_query>

## Assistant

The analytics and search unit tests finished successfully, including the three remote `search_performed` outcomes.

