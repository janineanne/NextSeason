# Search fallback UX implementation

## User

You mentioned above eventually adding a UI test for empty search.  Is that something we should do now?  Are any other UI tests missing?

## Assistant

Let me look at the existing UI tests to assess coverage before recommending anything.

Let me check how the stubbed network behaves during UI testing, to know if an empty-search test is even feasible.

I dug into the test infrastructure to give you a grounded answer rather than a guess. Here's what I found.

## The key blocker for an empty-search test

Right now the UI-testing stub can't produce an empty result. When launched with `-UITesting`, search is backed by `PreviewTVMazeService`, whose search ignores the query entirely:

```82:82:NextSeason/Previews/Show+Preview.swift
    func searchShows(matching query: String) async throws -> [Show] { [stub] }
```

So every query returns "Severance" — there's no way to drive the `.empty` state (or the `.failed` state) from a UI test today. To test the new fallback UX, we'd first need to make the stub query-aware, e.g. return `[]` for a sentinel query like `"zzzznoresults"` (and ideally throw for a `"zzzzfail"` query). That's a small, low-risk change and arguably improves test fidelity anyway.

So: **yes, it's worth adding, but it requires a tiny stub change first.** Not a one-liner test against the current setup.

## Other gaps I noticed

Current UI test coverage:
- Launch → search idle prompt
- Tab switching
- Watchlist empty state
- Search → open detail
- Track → show appears on watchlist

Notable missing flows, roughly in priority order:

1. **Remove from watchlist** (swipe-to-delete). The logic exists (`onDelete` → `viewModel.remove`) but isn't UI-tested — and it's explicitly one of your beta validation tasks ("Remove a show from the watchlist").
2. **Empty / no-results search** — the new fallback UX (needs the stub change above).
3. **Search failure state** — the "Something Went Wrong" / "Try Again" path is never exercised (stub never throws; same stub change enables it).
4. **"Already tracked" detail state** — that the Track button reflects tracked status / doesn't double-add.

1, 3, and 4 are real behavior gaps; 2 protects the copy we just wrote.

## My recommendation

Do a small, focused batch: make the stub query-aware, then add tests for **empty search** and **remove-from-watchlist** (the two highest-value gaps). I'd hold off on the failure-state and "already tracked" tests unless you want full coverage now.

How would you like to proceed?

## User

c

## Assistant

Your "c" didn't map to one of the options, so I don't want to guess on scope (and I noticed the workspace path just changed to none, which may also affect whether I can edit files).

Could you let me know which you'd like?
- Recommended: stub change + empty-search test + remove-from-watchlist test
- Just the empty-search test (plus required stub change)
- All four (empty, remove, failure, already-tracked)
- None for now

Also, if you intended to send something else, just resend it.

## User

Sorry, I meant all four

## Assistant

The workspace path changed, so let me first confirm I can still access the project files, and read the detail view + error type I'll need for the failure and already-tracked tests.

Now let me read the error type and how rows are labeled, plus the ShowDetailViewModel's failure handling.

Let me read the detail view model to understand the notification prompt behavior during tracking (so the already-tracked test doesn't get blocked by an alert).

The notification prompt could interfere with tests. Let me check how `NotificationService` behaves under UI testing.

I now have everything I need. The plan:

1. **Stub change** (`Show+Preview.swift`): make the UI-test search stub query-aware so it can return empty or throw, based on sentinel queries.
2. **Sentinels** (`UITestingConfiguration.swift`): define the sentinel query strings (co-located with the launch argument).
3. **Test helpers** (`NextSeasonUITestCase.swift`): mirror the sentinels + accessibility IDs, add element accessors.
4. **Tests** (`SearchAndTrackUITests.swift`): add empty-search, failure, remove-from-watchlist, and already-tracked tests.

Let me start with the app-side changes.

Now the test target: mirror the sentinels and accessibility IDs, and add element accessors.

Now add the four tests, reusing the existing `search(for:)` helper in `SearchAndTrackUITests`.

Let me verify everything compiles by building for testing. First, find the project/scheme.

No new files were added (all edits were to existing files), so the project membership is intact. Let me compile-check both targets with a build-for-testing.

`xcodebuild` is pointing at CommandLineTools. Let me check if a full Xcode is installed so I can build.

Xcode 26.5 is installed. Let me build for testing using it (this needs to run outside the sandbox for the toolchain/simulator).

No iPhone 16 simulator; let me use iPhone 17.

Build succeeds. Now let me run the new UI tests (the whole search test class) to verify they actually pass, reusing the build.

The four new tests all live in `SearchAndTrackUITests`, but to avoid narrowing scope I'll run the full UI test target instead (covers all four new tests plus the existing navigation tests).

Five of six new/existing pass; only `testRemoveShowFromWatchlist` failed. Let me get the exact failure reason from the result bundle rather than guess.

The result bundle wasn't finalized (simulator cloning hiccups), so I'll reason from the test itself. The most likely cause is tapping the swipe "Delete" button before it's revealed. Let me make that step wait for the button, which is the robust pattern.

Now I'll rebuild and run the full UI test target with parallel testing disabled (the earlier clone parallelism corrupted the result bundle and added noise).
