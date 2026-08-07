> From: https://chatgpt.com/c/6a72506d-89f4-83e8-ac76-d090c445b40f

# you asked

message time: 2026-08-04 14:16:10

What about ProfileFlow?  It seems to be only used for running Instruments.  It seems like a good thing to have, but as I'm looking through the feature file it seems to be sprinkled throughout the views, and I wonder if that's a good idea.

---

# chatgpt response

You’re reading it correctly: **ProfileFlow is useful, but it should not be visibly woven through the production UI architecture.**

The ability to run a repeatable Instruments scenario is valuable. The problem is not that ProfileFlow exists; it’s that the implementation may be making normal views aware of a profiling-only workflow.

A good boundary would be:

- Production views expose ordinary user actions and state.
- ProfileFlow coordinates those actions externally.
- Profiling-specific code is compiled only into debug or profiling builds.
- Removing ProfileFlow should not require editing numerous feature views.

If you are seeing checks such as:

```swift
if profileFlowRunner.isRunning {
    ...
}
```

or profile-specific callbacks, identifiers, delays, navigation commands, or injected dependencies scattered through `SearchView`, `WatchlistView`, `ShowDetailView`, and other feature files, then I would consider that architectural pollution.

Some instrumentation in views is reasonable. Accessibility identifiers, for example, can serve UI tests as well as profiling automation and are usually harmless. But views should not contain logic whose only purpose is to steer a profiling script.

## What I would keep

Keep the concept of a repeatable profiling flow, especially if it lets you consistently measure:

- Launch
- Search
- Opening show details
- Adding and removing a show
- Navigating the watchlist
- Refreshing data
- Memory after repeated navigation

That is much more reliable than manually reproducing a sequence each time you use Instruments.

## What I would change

I would move toward a structure like this:

```swift
#if DEBUG
@MainActor
final class ProfileFlowRunner {
    func run(using app: AppAutomationInterface) async {
        // Coordinate the profiling scenario here.
    }
}
#endif
```

The runner would interact with a narrow automation interface rather than directly influencing each view:

```swift
@MainActor
protocol AppAutomationInterface {
    func selectSearchTab()
    func search(for query: String) async
    func openFirstSearchResult()
    func addCurrentShowToWatchlist()
    func selectWatchlistTab()
}
```

The production navigation or app coordinator could implement that interface. ProfileFlow would then sit above the app rather than inside every feature.

For actions that cannot be triggered cleanly through app-level state, UI automation may be an even better fit. An XCUITest performance flow can operate the app as a user would without placing profiling machinery in the application target at all. That has trade-offs—it can be slower and occasionally less deterministic—but it provides the cleanest separation.

## My recommendation for NextSeason

I would not simply delete ProfileFlow. I would classify it as **development tooling that needs isolation**.

The desired end state is:

> Keep the repeatable Instruments workflow, but remove profiling-specific conditionals and dependencies from production feature views wherever possible.

Any remaining hooks should meet at least one of these tests:

1. They are also useful for accessibility or UI testing.
2. They are generic application actions rather than ProfileFlow-specific behavior.
3. They are enclosed in `#if DEBUG`.
4. They impose essentially no complexity on the production code.

So yes, your discomfort is justified. “Sprinkled throughout the views” is the part I would treat as a code-review issue—not because profiling support is bad, but because development tooling should have a much cleaner boundary.

---
Powered by [AI Exporter](https://saveai.net)