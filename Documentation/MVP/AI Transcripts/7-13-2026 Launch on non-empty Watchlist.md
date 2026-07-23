# Cold Start Behavior

## User

I'd like to modify how the app starts up:
- on a cold launch, start on the Watchlist if there is at least one show on it, otherwise start on Search.
- when returning from the background, stay on the current screen, whatever that is.

## Assistant

I'll explore the navigation and startup flow before making changes.

## Assistant

Let me look at how launch-time notification navigation and the composition root set things up, to make sure the cold-launch default doesn't fight a deep link.

## Assistant

The scene-phase handler never changes the tab, so "stay on current screen when returning from background" is already the behavior — I just need to add a one-time cold-launch tab decision without disturbing that. Let me check the repository API for a count/fetch method.

## Assistant

The repository exposes `trackedShowIDs()`, which is a light way to check for any saved shows. Let me check the UI tests and profile-flow expectations so the new launch behavior doesn't break them.

## Assistant

Let me confirm the `ProfileFlowConfiguration.isEnabled` API before wiring the guard.

## Assistant

The `-UITesting` launch uses an empty in-memory repository, so the launch-to-Search UI test stays valid. I'll guard against profile-flow runs (which drive navigation deterministically). Now implementing the coordinator method.

Now wire it into `ContentView`'s startup task, ahead of the deep-link resolution.

Now build to verify it compiles.

Build succeeds. Here's what changed and how it satisfies both requirements.

## Changes

**`AppNavigationCoordinator.swift`** — added a one-time cold-launch tab resolver:

```59:79:NextSeason/Services/AppNavigationCoordinator.swift
    /// Cold-launch landing tab: Watchlist when it already has at least one show,
    /// otherwise Search. Runs once per launch; it does not override a notification
    /// deep link and is never re-run on a foreground return.
    func resolveInitialTab(repository: any WatchlistRepository) async {
        guard !didResolveInitialTab else { return }
        didResolveInitialTab = true

        // Profile flows drive navigation themselves; leave the default tab alone.
        guard !ProfileFlowConfiguration.isEnabled else { return }
        // A notification deep link picks the tab itself (see resolvePendingNavigation).
        guard pendingShowID == nil else { return }

        do {
            let trackedIDs = try await repository.trackedShowIDs()
            selectedTab = trackedIDs.isEmpty ? .search : .watchlist
        } catch {
            selectedTab = .search
        }
    }
```

**`ContentView.swift`** — the startup `.task` now resolves the landing tab before handling any notification deep link.

## How each requirement is met

- **Cold launch → Watchlist if it has shows, else Search:** `resolveInitialTab` reads the watchlist once at launch and switches to Watchlist only when at least one show is tracked; otherwise it stays on the default Search tab.
- **Return from background → stay put:** The tab is only ever set in this one-time task (guarded by `didResolveInitialTab`), and the scene-phase `.active` handler in `NextSeasonApp` only triggers a data refresh — it never changes the tab. So foreground returns leave the user exactly where they were.

## Safeguards
- **Notification deep links win:** if the app is opened by tapping a notification, `pendingShowID` is set and the landing default is skipped, letting `resolvePendingNavigation` route to the correct show/tab.
- **Profile flows unaffected:** skipped when a `-ProfileFlow` run is active, so Instruments flows keep driving navigation deterministically.
- **UI tests unaffected:** `-UITesting` uses an empty in-memory watchlist, so the app still launches on Search (`testLaunchShowsSearchTab` stays green).

## What to test
- Launch cold with an **empty** watchlist → lands on **Search**.
- Track a show, fully quit the app, relaunch → lands on **Watchlist**.
- On either tab, background the app and reopen → **same tab**, same screen (including a pushed show detail).
- Tap a notification for a tracked show from a cold start → opens directly to that show on **Watchlist** (not overridden by the default).

One note: because the watchlist read is async, there's a theoretical single-frame possibility of Search showing before switching to Watchlist on launch. It's a fast local SwiftData read so it should be imperceptible; if you ever notice a flash, let me know and I can resolve the tab earlier in the launch sequence.
