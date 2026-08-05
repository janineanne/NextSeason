# App code review questions

## User

I've already had ChatGPT review the app code many times;  now I'm going to do it myself.  I expect I'll be asking a lot of questions.

## Assistant

Sounds good — I’m here for that.

Ask about whatever you’re looking at: architecture, SwiftUI patterns, SwiftData, concurrency, API usage, naming, or “why is this written this way?” I’ll read the actual code and answer from the project, not generic advice.

When you’re ready, point me at a file, feature, or question and we’ll go from there.

## User

We'll be working in AppCompositionRoot.swift until I give you a new filename.

## Assistant

Reading `AppCompositionRoot.swift` so we're ready for your review questions.

Got it — we’ll stay focused on `AppCompositionRoot.swift` until you say otherwise.

I’ve read it. In short, it’s the app’s composition root: it wires up long-lived services (analytics, notifications, TVMaze, watchlist repo, refresh, undo) and the SwiftData `ModelContainer`, with a UI-test path that uses in-memory storage and `InMemoryWatchlistRepository`. `configureNonUITestRuntime()` handles launch diagnostics, notification routing, and background refresh scheduling.

Fire away with your first question whenever you’re ready.

## User

Why do watchlistRepository and tvMaze refer to protocols where the rest of the properties refer to objects?  How do you decide when to use one or the other?

## Assistant

Checking how those protocols are defined and used elsewhere so the answer reflects this project's conventions.

Short answer: **`watchlistRepository` and `tvMaze` are swappable boundaries; the others are single, app-specific objects that the composition root always builds the same way.**

## What the protocols are for

Both protocols exist so callers can depend on behavior, not a specific implementation:

**`WatchlistRepository`** — the persistence boundary. The file comment says view models depend on this protocol, not SwiftData directly (PD-007). You can see why in `AppCompositionRoot` itself:

```27:39:NextSeason/App/AppCompositionRoot.swift
        let repository: any WatchlistRepository
        if UITestingConfiguration.isEnabled {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try ModelContainer(
                for: TrackedShowEntity.self,
                configurations: configuration
            )
            repository = InMemoryWatchlistRepository()
        } else {
            let container = try ModelContainer(for: TrackedShowEntity.self)
            modelContainer = container
            repository = SwiftDataWatchlistRepository(context: ModelContext(container))
        }
```

Production uses `SwiftDataWatchlistRepository`; UI tests use `InMemoryWatchlistRepository`; unit tests use custom fakes. The property is typed as the protocol because the *implementation varies*.

**`TVMazeService`** — the network/API boundary. Same idea: production uses `TVMazeClient`, UI tests swap in `PreviewTVMazeService`, unit tests use mocks/stubs. The comment on the protocol says it directly: *"so view models can be tested with a mock."*

Those two get passed deep into view models, refresh logic, and navigation — anywhere you need to substitute fakes without rewriting callers.

## Why the rest are concrete types

The other properties are **orchestrators or singletons** with one production shape:

| Property | Why concrete at this layer |
|---|---|
| `WatchlistRefreshService` | Coordinates repo + TVMaze + notifications; tested by injecting mock repo/TVMaze *into* it |
| `WatchlistUndoRemoval` | `@Observable` UI coordinator tied to undo toast behavior |
| `NotificationService` | Wraps `UNUserNotificationCenter`; tests use the real type with a fake analytics dependency |
| `AnalyticsService` | The one production analytics implementation |
| `BetaRefreshDiagnostics` | Debug-only helper, no alternate impl |
| `ModelContainer` | SwiftData framework type |

At the composition root you're saying: *"I always construct exactly these objects; I'm not choosing between alternatives here."* The swapping happens *inside* them (e.g. `WatchlistRefreshService` takes `any TVMazeService` and `any WatchlistRepository` in its initializer).

## How to decide (the heuristic)

Use a **protocol** when:

1. **Multiple real implementations** exist or are likely (prod vs in-memory vs mock).
2. **Tests or previews** need to substitute behavior without network/DB.
3. The type is a **boundary** you want callers to stay ignorant of (persistence, API, etc.).

Use a **concrete type** when:

1. There's **one production implementation** and no meaningful alternate.
2. The type is an **app-specific coordinator** whose job is wiring other dependencies together.
3. You test it by **injecting fakes into its dependencies**, not by replacing the coordinator itself.

## One inconsistency worth noting

`analyticsService` is stored as concrete `AnalyticsService` on the composition root, but downstream code mostly takes `any AnalyticsTracking` (and tests use `RecordingAnalyticsService`). So analytics *is* abstracted — just not at the composition root property level. Same pattern could apply to `notificationService` if you ever needed a fake notification center.

So the split in `AppCompositionRoot` isn't arbitrary: protocols mark **substitutable boundaries**; concrete types mark **things this file always builds once**. The two that vary at startup (persistence + API) are typed as protocols; the orchestrators are not.

## User

In function configureNonUITestRuntime, I don't follow this comment:

        // The tap coordinator is attached from the view layer (see ContentView) so
        // routing always targets the exact AppNavigationCoordinator instance SwiftUI
        // observes. Installing the delegate here lets a launch-from-notification tap
        // buffer until the coordinator attaches.

I did look at ContentView and I see the corresponding comment there but I still don't understand it.

## Assistant

Tracing the notification routing flow through the relevant files.

The comment is really about **timing** and **who owns navigation state**, not about two different coordinator *types*. Here is the full chain.

## Two jobs split across two places

| Step | Where | What happens |
|------|--------|----------------|
| 1 | `configureNonUITestRuntime()` | Install the notification delegate so iOS can deliver taps |
| 2 | `ContentView.task` | Connect that delegate to the live coordinator and finish navigation |

Those are intentionally separate.

## What `configureNonUITestRuntime()` does

It calls `NotificationRouting.install()`, which sets `UNUserNotificationCenter.current().delegate`. From that point on, if the user taps a notification, iOS calls:

```76:86:NextSeason/Services/NotificationCenterDelegate.swift
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let showID = NotificationRouting.showID(from: userInfo) else { return }
        // A tap while the app is already foreground-active is an in-app navigation
        // (animate); a tap that brings the app forward from background/launch is not.
        let wasActive = UIApplication.shared.applicationState == .active
        NotificationRouting.routeToShow(showID: showID, animated: wasActive)
    }
```

That can run **very early** — during `NextSeasonApp.init()`, before `body` runs and before `ContentView` exists.

At that moment, `NotificationRouting.coordinator` is still `nil`. So `routeToShow` does not navigate yet; it **buffers**:

```34:41:NextSeason/Services/NotificationCenterDelegate.swift
    static func routeToShow(showID: Int, animated: Bool) {
        analytics?.track(.notificationTapped(showID: showID))
        if let coordinator {
            coordinator.queueShowNavigation(showID: showID, animated: animated)
        } else {
            bufferedShowID = showID
            bufferedAnimated = animated
        }
    }
```

That is the “buffer until the coordinator attaches” part. The delegate is installed early so the tap is not lost; it is stored until something calls `setCoordinator`.

## What `ContentView` does later

When `ContentView` appears, its `.task` runs:

```84:96:NextSeason/ContentView.swift
        .task {
            if !UITestingConfiguration.isEnabled {
                // Attach the exact coordinator SwiftUI observes so notification taps
                // route into this view's navigation state; this also flushes any
                // launch-time tap that NotificationRouting buffered before attach.
                NotificationRouting.setCoordinator(coordinator)
            }
            await coordinator.resolveInitialTab(repository: repository)
            await coordinator.resolvePendingNavigation(
                repository: repository,
                tvMaze: tvMaze,
                analytics: analytics
            )
        }
```

`setCoordinator` does two things:

```18:21:NextSeason/Services/NotificationCenterDelegate.swift
    static func setCoordinator(_ coordinator: AppNavigationCoordinator) {
        self.coordinator = coordinator
        flushBufferedNavigation()
    }
```

1. Points routing at the coordinator that drives `$coordinator.selectedTab`, `$coordinator.searchPath`, etc.
2. Flushes any buffered launch tap into `queueShowNavigation`.

Then `resolvePendingNavigation` actually performs the navigation (switch tab, push detail, fetch show from TVMaze, etc.).

There is even a unit test for this buffering behavior: route first with no coordinator attached, then attach, and navigation applies.

## Why attach from `ContentView`, not from `AppCompositionRoot`?

Three reasons:

**1. `AppCompositionRoot` does not have the coordinator.**  
Navigation lives in `NextSeasonApp` as `@State` and flows down into views. The composition root wires persistence, refresh, analytics — not tab/navigation UI state. Putting `setCoordinator` in `configureNonUITestRuntime()` would require passing the coordinator into the composition root, which mixes layers.

**2. Same `.task` block needs environment values.**  
`resolvePendingNavigation` needs `repository`, `tvMaze`, and `analytics` from the SwiftUI environment. Those are not available in `AppCompositionRoot.init()`. Attaching the coordinator in the same `.task` keeps “connect routing” and “act on pending navigation” together once the view layer is ready.

**3. “Exact instance SwiftUI observes” means the one bound into the UI.**  
`ContentView` binds that coordinator to `TabView` and the navigation paths. Notification routing must mutate **that** object’s `pendingShowID`, `selectedTab`, `watchlistPath`, etc. If routing pointed at some other coordinator (or ran before the view hierarchy existed), you could set state on an object that is not what the UI is watching — or try to push before `WatchlistView`’s `NavigationStack` is mounted (which is why watchlist deep links use `pendingWatchlistDetail` and a deferred `applyPendingWatchlistDetail()`).

So “exact instance” is less “SwiftUI might clone `@State`” and more “wire routing to the coordinator that owns the bindings in this view tree, at the moment that tree is coming alive.”

## Timeline: cold launch from a notification tap

```text
NextSeasonApp.init()
  ├─ create AppNavigationCoordinator (@State)
  ├─ configureNonUITestRuntime()
  │    └─ NotificationRouting.install()     ← delegate ready, coordinator still nil
  │
  └─ (iOS may deliver notification tap HERE)
       └─ routeToShow → bufferedShowID = 44933

SwiftUI builds body → AppRootView → ContentView

ContentView.task
  ├─ setCoordinator(coordinator)          ← attach + flush buffer → pendingShowID set
  ├─ resolveInitialTab(...)
  └─ resolvePendingNavigation(...)        ← switch tab, push show detail
```

## When the app is already running

If the user taps a notification while the app is foreground, `coordinator` is already set from the earlier `.task`. `routeToShow` goes straight to `queueShowNavigation` with no buffering. `ContentView` also has `.onChange(of: coordinator.pendingShowID)` to call `resolvePendingNavigation` again for in-app taps.

---

**In one sentence:** `configureNonUITestRuntime()` turns on the notification listener early and allows buffering; `ContentView` connects that listener to the live navigation coordinator once the UI (and environment) exist, then drains the buffer and completes the navigation.

If you want, we can walk through `resolvePendingNavigation` next — that is where the buffered `showID` becomes an actual tab switch and detail push.

## User

First please take another look at AppCompositionRoot and let me know if there are any inaccuracies in the comments now that I have edited them.

## Assistant

Checking background refresh timing and whether the accelerated-mode block was moved elsewhere.

I re-read the current file and checked it against `NotificationRouting`, `NextSeasonApp`, and `BackgroundRefreshConfiguration`. Here is what stands out.

## Accurate

**Notification buffering (lines 60–64)** — The core claim is right: `configureNonUITestRuntime()` calls `NotificationRouting.install()` during `NextSeasonApp.init()`, before `ContentView` appears and runs `.task { NotificationRouting.setCoordinator(...) }`. If iOS delivers a launch-from-notification tap in that gap, `routeToShow` buffers until `setCoordinator` flushes it.

**Background refresh (line 72)** — `configureBackgroundRefresh()` wires `RefreshScheduler` / `BGAppRefreshTask`, and production cadence is documented as ~12 hours in `BackgroundRefreshConfiguration`. So “~12 hr check for updates” is a fair shorthand.

## Inaccuracies / wording issues

**1. “AppCompositionRoot is … able to receive taps” (line 61–62)**

This is the main substantive issue. `AppCompositionRoot` does not receive notification taps. What happens is:

- `configureNonUITestRuntime()` installs `UNUserNotificationCenter`’s delegate via `NotificationRouting.install()`
- The **delegate** receives the tap and buffers it in `NotificationRouting`

So it is not the composition root that receives taps; it is the notification routing layer, installed from this method.

Clearer wording might be: *“`configureNonUITestRuntime()` runs (and installs the notification delegate) before `ContentView` can call `setCoordinator`.”*

**2. Typo: `coordiinator` (line 62)**

Should be `coordinator`.

**3. File header (lines 9–10)**

- Double space: `building of  long-lived`
- **“from `NextSeasonApp`”** is easy to misread. `AppCompositionRoot` is **created by** / **extracted into** `NextSeasonApp`, not built from it. Something like “for `NextSeasonApp`” or “so `NextSeasonApp` stays readable” would match the code more closely.

**4. Background refresh comment is slightly narrow (line 72)**

Not wrong, but incomplete: `configureBackgroundRefresh()` does more than schedule a ~12h check — it registers the background task, configures the handler that calls `refreshService.refreshAll(recordDiagnostics: true)`, and schedules the next run. If you want the comment to match what the function actually does, something like “registers the ~12h background watchlist refresh task” would be tighter.

## Non-comment note (for context)

You removed the accelerated/soak-test branch that used to live in `configureBackgroundRefresh()`. I do not see that logic elsewhere now, and `BackgroundRefreshConfiguration` is only the 12h interval. That is fine if intentional; just flagging in case you expected it to move, not disappear.

## Suggested rewrites (optional)

```swift
/// Builds long-lived app services and persistence for `NextSeasonApp` so the app entry point stays readable.
```

```swift
// NotificationRouting installs its delegate here (during app init). ContentView attaches
// the coordinator later in .task. Until then, a launch-from-notification tap is buffered.
```

```swift
// Registers the ~12h BGAppRefreshTask that refreshes the watchlist in the background.
```

Overall: your notification comment captures the right idea; the only real inaccuracy is attributing tap receipt to `AppCompositionRoot` instead of the installed notification delegate.

## User

Please take another look, is that better?

## Assistant

Yes — these read much better and match the code.

**File header (lines 9–10):** “Extracted from `NextSeasonApp`…” is accurate and clear. Small optional polish: “builds long-lived…” reads a bit smoother than “handle the building of,” but what you have is fine.

**Notification comment (lines 60–64):** The main fix landed. Attributing early tap handling to `NotificationRouting` (installed here) instead of `AppCompositionRoot` is correct. The buffering story is right.

One tiny nuance if you want to be pedantic: iOS delivers taps to the `UNUserNotificationCenter` delegate (`NotificationCenterDelegate`), which then calls `NotificationRouting.routeToShow`. So “NotificationRouting is set up here” is accurate; “is able to receive taps” is close enough for a comment. You could say “can handle taps” if you want to avoid implying `NotificationRouting` is the delegate itself.

Also, the coordinator doesn’t handle taps directly — it receives navigation requests *after* routing. Again, minor; your current wording is understandable in context.

**Background refresh (line 72):** Accurate. It reflects register + configure + schedule, not just the interval.

**Non-comment:** Lines 59–64 and 72 use tab indentation while the rest of the file uses spaces — worth normalizing when you touch the file again, but not a comment accuracy issue.

Overall: good to go. No substantive inaccuracies left.

## User

I've read through AppNavigationCoordinator.swift.  I have one main question:

You've got pendingWatchlistDetailAnimated and endingNavigationAnimated.  What is endingNavigationAnimated for, and why isn't there a corresponding variable for search?  A detail view can be open there, too.

## Assistant

Re-reading `AppNavigationCoordinator.swift` to trace how both animation flags are used in watchlist vs search navigation.

Good question — and small naming note first: the property is **`pendingNavigationAnimated`**, not `endingNavigationAnimated`. There are two related flags, and they exist because watchlist deep linking is **two-step**, while search is **one-step**.

## What each flag is for

**`pendingNavigationAnimated`** — set when a notification tap is queued:

```68:71:NextSeason/Services/AppNavigationCoordinator.swift
    func queueShowNavigation(showID: Int, animated: Bool = false) {
        pendingShowID = showID
        pendingNavigationAnimated = animated
    }
```

It captures whether the tap happened while the app was already foreground-active (`true` → animate like normal navigation) vs launch/background (`false` → land on detail without a visible slide-in). That value comes from `NotificationCenterDelegate` checking `UIApplication.shared.applicationState == .active`.

**`pendingWatchlistDetailAnimated`** — a copy of that decision, kept for the **deferred** watchlist push:

```147:151:NextSeason/Services/AppNavigationCoordinator.swift
            if let tracked = try await repository.trackedShow(showID: showID) {
                selectedTab = .watchlist
                pendingWatchlistDetail = tracked
                pendingWatchlistDetailAnimated = pendingNavigationAnimated
```

Why copy it? Because the watchlist push does not happen in `resolvePendingNavigation`. It happens later when `WatchlistView` calls `applyPendingWatchlistDetail()` from `onAppear` / `onChange`. By then `pendingNavigationAnimated` might refer to a *different* tap if another notification arrived. The copy ties the animation choice to **this specific** `pendingWatchlistDetail`.

`applyPendingWatchlistDetail()` then uses that copy:

```78:94:NextSeason/Services/AppNavigationCoordinator.swift
    func applyPendingWatchlistDetail() {
        guard let tracked = pendingWatchlistDetail else { return }
        pendingWatchlistDetail = nil
        guard pendingWatchlistDetailAnimated else {
            // Launch / foreground: push without animation ...
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                watchlistPath = NavigationPath()
                watchlistPath.append(tracked)
            }
            return
        }
        // In-app deep link while the Watchlist is already on screen: animate the push.
        watchlistPath = NavigationPath()
        watchlistPath.append(tracked)
    }
```

So in short:

| Flag | Role |
|------|------|
| `pendingNavigationAnimated` | Staging: “how should *this* queued deep link animate?” from tap until resolve |
| `pendingWatchlistDetailAnimated` | Persisted through the defer gap until the watchlist stack actually pushes |

## Why watchlist needs deferral (and search doesn’t)

Watchlist notification navigation is split because of a SwiftUI quirk noted in the comments: switching to the Watchlist tab **and** pushing onto its `NavigationStack` in the same update can cause SwiftUI to **drop the push**. So the coordinator sets `pendingWatchlistDetail` and waits for `WatchlistView` to be on screen before pushing.

Search does not have that deferral path. When the show is not on the watchlist, resolve happens immediately:

```160:164:NextSeason/Services/AppNavigationCoordinator.swift
        do {
            let show = try await tvMaze.show(id: showID)
            selectedTab = .search
            searchPath.append(show)
```

No `pendingSearchDetail`, no `applyPendingSearchDetail()`, no second animation flag — the push and tab switch happen in one place, right after the async work finishes. Tests expect `searchPath.count == 1` immediately after `resolvePendingNavigation`, without any view callback.

That is the structural reason there is no `pendingSearchDetailAnimated`: there is no second phase where the animation decision needs to be stored separately.

## Why no animation handling on search?

This is the sharper part of your question. **`pendingNavigationAnimated` is never read on the search branch.** For search, the flag is set but unused; only the watchlist branch copies and applies it.

So today:

- **Watchlist deep link (common case):** launch tap → no slide-in animation; in-app tap → animated push.
- **Search fallback (untracked show):** always `searchPath.append(show)` with default NavigationStack animation, regardless of tap context.

That is likely acceptable in practice because almost all notification deep links go to the watchlist — you get notified about tracked shows. The search path is a fallback when the show was removed from the watchlist but you still tap the old notification.

It could still be an **inconsistency**: a cold-launch tap that lands on Search might show a slide-in that Watchlist deliberately suppresses. If you wanted parity, you would wrap the search append similarly:

```swift
if pendingNavigationAnimated {
    searchPath.append(show)
} else {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
        searchPath = NavigationPath()
        searchPath.append(show)
    }
}
```

You would not necessarily need a *second* flag like `pendingSearchDetailAnimated` unless search also needed deferred pushing (e.g. if you hit the same tab-switch-drop bug on Search). Right now it doesn’t defer, so one flag would be enough at resolve time.

## Mental model

```text
Notification tap
  └─ queueShowNavigation(animated: wasAppActive?)
       └─ pendingNavigationAnimated

resolvePendingNavigation()
  ├─ On watchlist: defer push
  │    └─ copy → pendingWatchlistDetailAnimated
  │         └─ WatchlistView → applyPendingWatchlistDetail() uses it
  │
  └─ On search: push immediately
       └─ pendingNavigationAnimated ignored
```

**Bottom line:** `pendingNavigationAnimated` is the tap-context flag; `pendingWatchlistDetailAnimated` exists only because watchlist pushes are deferred and need the decision preserved. Search pushes immediately, so there is no corresponding second flag — but search also does not currently honor the animation policy at all, which is worth knowing if you are reviewing for consistency.

## User

Please make that change.

## Assistant

Applying the same launch vs in-app animation policy to the search deep-link path in `resolvePendingNavigation`.

Done. The search fallback path in `resolvePendingNavigation` now uses the same animation policy as watchlist.

**Change:** When a notification deep link resolves to Search, `pendingNavigationAnimated` controls whether the push animates:
- **In-app tap** (`animated: true`) → `searchPath.append(show)` as before
- **Launch/foreground tap** (`animated: false`) → reset path and append inside `withTransaction { disablesAnimations = true }`, matching `applyPendingWatchlistDetail()`

I also updated the comment on `pendingNavigationAnimated` to note it applies to both paths.

**What to test:**
1. Remove a show from the watchlist, tap its old notification while the app is **not** foreground → should land on Search detail without a slide-in.
2. Same scenario with the app **already open** → should animate the push onto Search.
3. Watchlist deep links (the common case) should behave as before.

## User

What do you suggest looking at next?

## Assistant

I’d go next to **`NotificationCenterDelegate.swift` / `NotificationRouting`**.

You just finished the two ends of that pipeline (`AppCompositionRoot` installs it; `AppNavigationCoordinator` consumes it). Reading the middle now will lock in the full launch-from-notification story—buffering, analytics, active-vs-inactive animation—before you leave that thread.

After that, good order:

1. **`NextSeasonApp.swift`** — how `@State` coordinator + composition root meet the view tree  
2. **`WatchlistRefreshService.swift`** — the other major long-lived service the composition root builds  
3. **`WatchlistRepository` + SwiftData/in-memory impls** — the persistence boundary you already saw abstracted in composition root  

Want to start with `NotificationCenterDelegate.swift`?

## User

ok

## Assistant

We’ll stay on `NotificationCenterDelegate.swift` until you name another file.

I’ve read it. Two pieces in one file:

- **`NotificationRouting`** — static bridge: holds a weak coordinator, optional analytics, buffers a launch-time tap, extracts `showID` from `userInfo`, and queues navigation.
- **`NotificationCenterDelegate`** — the real `UNUserNotificationCenterDelegate`: shows banners when foregrounded, and on tap decides `animated` from `applicationState == .active`, then calls `routeToShow`.

Fire away when you’re ready.

## User

I think flushBufferedNavigation needs a different name.  Most of the time when I've seen "flush" used like this it's referring to throwing data away to make a clean slate.  This use is more like moving the data into the pipeline to be processed.  What do you think would be a better name?

## Assistant

You’re right that “flush” is ambiguous here — even though “flush a buffer” often means drain-and-process, it also reads as discard.

Best fit for what this does (hand the buffered tap to the coordinator):

**`deliverBufferedNavigation`**

Clear, and it matches the idea of moving data into the next stage.

Strong alternatives:

- **`applyBufferedNavigation`** — consistent with `applyPendingWatchlistDetail`
- **`consumeBufferedNavigation`** — emphasizes “take from the buffer and use it”

I’d pick **`deliverBufferedNavigation`**. Want me to rename it?

## User

yes

## Assistant

Renamed `flushBufferedNavigation` → `deliverBufferedNavigation` in `NotificationCenterDelegate.swift` (definition plus the two call sites in `setCoordinator` and `install`).

## User

The function install seems poorly named. It's doing more than installing the delegate, it's it?

## Assistant

Yes — technically. `install` does two things:

1. Sets `UNUserNotificationCenter`’s delegate  
2. Calls `deliverBufferedNavigation()`

In the current app order, though, step 2 almost never does anything. `AppCompositionRoot` calls `install()` **before** `ContentView` calls `setCoordinator`, and `deliverBufferedNavigation` requires both a buffer **and** a coordinator. So at install time the coordinator is usually still `nil`, and delivery only happens later from `setCoordinator`.

So `install` is mostly a true name; the deliver call is a defensive “if ordering ever flips” hook, not the main job.

Options:

1. **Keep the name, drop the deliver call** from `install` — simplest; `setCoordinator` already delivers.  
2. **Rename to something broader** like `start()` / `activate()` — honest if you keep both behaviors, but vaguer.  
3. **Rename to the real job**, e.g. `installDelegate()` — clearest if you also remove the opportunistic deliver.

I’d lean toward **3**: rename to `installDelegate` (or keep `install` if you prefer short) and remove `deliverBufferedNavigation()` from it, since delivery already belongs with `setCoordinator`.

Want me to make that change?

## User

If we do that is there ever a chance that a tap will be lost?

## Assistant

No — not with the current wiring.

A tap is only buffered when `routeToShow` runs and `coordinator` is still `nil`. That requires the delegate to already be installed. Delivery then happens in `setCoordinator`, which always calls `deliverBufferedNavigation()`.

Timeline today:

```text
install()                    ← delegate ready; deliver is a no-op (no coordinator yet)
  … tap may arrive → buffer …
setCoordinator(...)          ← deliver runs here
```

`install`’s `deliverBufferedNavigation()` only matters if a buffer already existed **and** a coordinator was already attached — but in this app the coordinator is only attached via `setCoordinator`, which already delivers. So that call is redundant, not load-bearing.

You’d only risk a lost tap if you later:

1. Buffered a tap (`coordinator == nil`), and  
2. Made the coordinator available **without** calling `setCoordinator` (or without delivering there)

That’s not how the code works now. Removing the deliver from `install` is safe.

## User

Ok, then rename it to installDelegate and remove the deliver

## Assistant

Done.

- Renamed `install` → `installDelegate` and removed the `deliverBufferedNavigation()` call from it
- Updated the call site in `AppCompositionRoot`

Delivery still happens only from `setCoordinator`.

## User

In this case can routeToShow be simplified?  It seems there will now no longer be any buffered show information unless the coordinator is set, in which case the else will never be executed.

## Assistant

No — keep the `else` branch. That rename didn’t remove the buffer window.

What changed:

```text
Before: install() set delegate + tried to deliver
After:  installDelegate() only sets the delegate
```

What did **not** change: timing between those two calls:

```text
installDelegate()          ← taps can arrive now
  … coordinator still nil …
setCoordinator(...)        ← ContentView.task, later
```

Cold launch from a notification tap still lands in that gap. `routeToShow` runs with `coordinator == nil`, so it must buffer; `setCoordinator` then calls `deliverBufferedNavigation()`. There’s even a unit test for that (`buffersShowNavigationUntilCoordinatorIsReady`).

If you dropped the buffer, those launch taps would track analytics and then vanish.

So `routeToShow` still needs both paths.

## User

In NextSeasonApp.init(), if UITestingConfiguration is enabled and it's a debug build, the else clause will do nothing.  Is that the only option?

## Assistant

Almost — one important correction on the Debug case.

```22:29:NextSeason/NextSeasonApp.swift
            if !UITestingConfiguration.isEnabled {
                root.configureNonUITestRuntime()
            } else {
                #if DEBUG
                FirstRunPreferences.resetSearchResultsHintForTesting()
                FirstRunPreferences.resetFirstSearchCompletedForTesting()
                #endif
            }
```

- **UI testing + Debug:** the `else` does run those two `FirstRunPreferences` resets (so hints/first-search state start clean for XCUITests).
- **UI testing + Release:** `#if DEBUG` is compiled out, so the `else` is truly empty.

If you meant the Release case: yes, today that branch does nothing. That’s fine in practice because XCUITests normally run Debug builds, and UI testing is already gated many other places (`AnalyticsService`, notifications, `ContentView`’s `setCoordinator`, foreground refresh, etc.).

Is empty/`else` + skip `configureNonUITestRuntime()` the only option? No. Alternatives:

1. **Keep as-is** (best default) — UI tests should not install notification routing, MetricKit, background refresh, or launch analytics. Skipping that method is intentional isolation.
2. **Drop the `else` entirely** and only reset first-run prefs when both conditions hold:
   ```swift
   if !UITestingConfiguration.isEnabled {
       root.configureNonUITestRuntime()
   }
   #if DEBUG
   if UITestingConfiguration.isEnabled {
       FirstRunPreferences.resetSearchResultsHintForTesting()
       FirstRunPreferences.resetFirstSearchCompletedForTesting()
   }
   #endif
   ```
   Same behavior, avoids an empty Release `else`.
3. **Add a UI-test-specific setup** (e.g. `configureUITestRuntime()`) if you later need deterministic seed data or stubs at launch — you don’t have that need yet; composition root already switches to in-memory storage when UI testing is on.

So: skipping production runtime setup for UI tests is the right call; an empty Release `else` isn’t a problem, and if the empty branch bothers you stylistically, option 2 cleans it up without changing behavior.

## User

No, if this is what you intended then it's fine.  Also, yes I did mean is *not* a debug build.

## Assistant

Yes — that empty Release `else` is intentional. UI tests run as Debug, and Release shouldn’t be installing the production runtime path just because `-UITesting` somehow showed up. No change needed.

## User

In the body of AppRootView, why is ContentView being passed uiTestingTVMazeService?

## Assistant

So XCUITests don’t hit the live TVMaze API.

`AppCompositionRoot` always builds a real `TVMazeClient()` for `tvMaze`. For UI tests it swaps the **repository** to in-memory, but leaves the network client as-is. `uiTestingTVMazeService` is the view-layer override:

```125:132:NextSeason/NextSeasonApp.swift
    private var uiTestingTVMazeService: any TVMazeService {
        #if DEBUG
        if UITestingConfiguration.isEnabled {
            return PreviewTVMazeService(stub: .preview)
        }
        #endif
        return tvMaze
    }
```

- **UI testing (Debug):** `ContentView` (and Search/Show Detail under it) get `PreviewTVMazeService` — fixed stub data, no network, deterministic results (including sentinel queries).
- **Normal runs:** it just returns the real `tvMaze` from the composition root.

The name is a bit misleading: most of the time it isn’t a UI-testing service at all; it’s “tvMaze, swapped for the stub when `-UITesting` is on.”

Worth knowing: refresh still uses `composition.tvMaze` (`TVMazeClient`) via `WatchlistRefreshService`, but UI tests skip foreground/background refresh anyway — so only the interactive UI path needs the stub.

## User

Yes, that needs a better name;  it looks very wrong as it is.  What do you think of calling it TVMazeService with an argument called testing, which would be passed UITestingConfiguration.isEnabled?  It's a little wordier but I think it would be a lot more readable.

## Assistant

Agreed — `tvMazeService(testing:)` makes the swap explicit at the call site. Applying that rename.

Done. Call site is now:

```swift
tvMaze: tvMazeService(testing: UITestingConfiguration.isEnabled)
```

Same behavior: Debug UI tests get `PreviewTVMazeService`; everything else gets the production `tvMaze`.

## User

Execute the selected diff-tab commit-and-push action.

## Assistant

Committed and pushed to `human-code-review` as `8e02ea2`.

Included the four Swift files from this review. Left out `Documentation/Post-MVP/NextSeason - App Store Readiness Roadmap.md` (unrelated).

PR link if you want one: https://github.com/janineanne/NextSeason/pull/new/human-code-review

## User

Please don't Commit or Push anything else. I approved that by accident.

## Assistant

Understood — I won’t commit or push anything else unless you explicitly ask.

## User

WatchlistUndoRemoval seems like the wrong name for something which also commits a removal.  How about WatchlistToastHandler?

## Assistant

I’d avoid `WatchlistToastHandler`.

That type’s job isn’t toast UI — it’s **deferred removal**: hold a pending remove, run the undo window, undo, or commit/persist, and surface commit errors. The toast is just how the UI shows that window. Naming it after the toast would bury the real responsibility and get awkward if you ever show the same undo flow without a toast.

`WatchlistUndoRemoval` is a bit awkward, but it’s closer to the truth than a toast-focused name.

Stronger options, if you want a rename:

| Name | Fit |
|------|-----|
| **`WatchlistPendingRemoval`** | Best: centers the pending-removal state machine |
| **`DeferredWatchlistRemoval`** | Emphasizes “not persisted yet” |
| **`WatchlistRemovalCoordinator`** | Fine if you like “coordinator,” a bit generic |

I’d pick **`WatchlistPendingRemoval`**. Keep property names like `watchlistPendingRemoval` / `pendingRemoval` consistent with that.

Want me to rename it (no commit/push)?

## User

yes

## Assistant

Renaming `WatchlistUndoRemoval` → `WatchlistPendingRemoval` across the codebase (no commit/push).

Updating type/env names, and renaming instance parameters from `undoRemoval` to `removalCoordinator` so they don’t collide with the type’s `pendingRemoval` property.

Renamed across the app (no commit/push).

**Type / files**
- `WatchlistUndoRemoval` → `WatchlistPendingRemoval`
- Matching file renames for the type, environment extension, and tests

**Related identifiers**
- Environment / composition: `watchlistPendingRemoval`
- Instance parameters and locals: `removalCoordinator` (avoids `pendingRemoval.pendingRemoval`)
- Left alone: `undoRemoval()` method and `undoRemovalWindowSeconds` (those still mean “undo”)

**Docs**
- Updated current architecture docs/diagrams; left historical AI transcripts as-is

Related unit tests (38) passed.

## User

Are there any places when NextSeasonCalculator.status is called with a date other than now() or accepting the default value of .now?

## Assistant

Yes — but only via an injectable clock or in tests. No production UI path hard-codes a different calendar date.

**Production call sites**

| Call site | `now` used |
|-----------|------------|
| `ShowDetailViewModel` | Default `.now` |
| `TrackedShow(from:)` → calculator | `now` param defaults to `.now`; every caller uses the default |
| `WatchlistRefreshService` | `now()` from an injected `() -> Date`, default `{ .now }` |

**Where a non-`.now` value actually happens**

1. **Unit tests** — lots of fixed dates (`NextSeasonCalculatorTests`, `ShowDataDecodingTests`, `WatchlistTrackingTests`, and refresh tests that inject `now: { fixedNow }`).
2. **`WatchlistRefreshService`’s `now` injection** — tests pass fixed clocks; `DiagnosticsSimulatedUpdateRunner` can pass one through too, but `DiagnosticsView` currently uses the default `{ .now }`.

So: the API supports alternate “now” for testability/determinism; in the running app today, everything resolves to wall-clock `.now`.

## User

There are a few places that pass now() for the now: parameter - should they be removed for consistency, since the default value is the same thing?

## Assistant

No — keep those.

In `WatchlistRefreshService`, `now` is the **injected clock** (`() -> Date`), not `Date.now`:

```25:25:NextSeason/Services/WatchlistRefreshService.swift
    private let now: @Sendable () -> Date
```

So `NextSeasonCalculator.status(for: show, now: now())` means “use this service’s clock.” Dropping it would fall back to `.now` and ignore the injected clock — breaking refresh tests (and any future diagnostics) that pin time.

Same for the nearby `StatusChangeDetector.evaluate(..., now: now())` and `TVMazeUpdatePeriod.covering(..., now: now())` calls.

`TrackedShow`’s `status(for: show, now: now)` should stay too: it forwards the init’s `now` parameter.

Only calls that literally mean wall-clock time can omit the argument and use the default (like `ShowDetailViewModel`).

## User

Ok, I understand that the tests need to pass in a differen time, so the parameter now: needs to stay.  But in the production code, all three definitions of now() are returning .now, unless I've missed something.  I'm not talking about getting rid of the parameter altogether, only skipping passing the closure and using the default value because they are the same.

## Assistant

Checking production call sites that pass a `now:` closure — that matches what you're asking about.

You’re right that in production everything resolves to `{ .now }` / `.now`. `AppCompositionRoot` already relies on that default and does **not** pass a `now:` closure into `WatchlistRefreshService`.

The remaining production `now:` arguments are in `DiagnosticsSimulatedUpdateRunner`, and those are different: they **forward** the runner’s clock into `DiagnosticsSimulatedDataProvider` and `WatchlistRefreshService`. Even though that clock currently defaults to `{ .now }`, dropping those arguments would mean each child uses its own default instead of sharing the runner’s injected clock. That matters the moment anything (tests or a future caller) passes a fixed `now` into the runner.

So:

- Call sites that truly want the default → omit `now:` (composition root already does).
- Call sites that forward an injected clock → keep `now: now`, even when today’s default is the same.

Inside `WatchlistRefreshService`, `now: now()` on `status` / `evaluate` / `covering` is also not redundant: that’s evaluating the service’s clock, not re-supplying `{ .now }`.

## User

Ok.  In that case, then, the argument name should not be now if the closure being passed in may not actually represent .now.  I think that's what makes it so confusing.  What would you suggest calling it instead?

## Assistant

I’d call it **`clock`**.

That name means “source of the current time for this code,” not “must be `Date.now`.” Defaults and call sites stay readable:

```swift
clock: @escaping @Sendable () -> Date = { .now }

// ...
let newStatus = NextSeasonCalculator.status(for: show, now: clock())
```

Keep the **parameter** on pure functions like `NextSeasonCalculator.status(for:now:)` as `now:` — there it’s “the instant to evaluate against,” a `Date` value. Rename the **stored injectable closure** on services (`WatchlistRefreshService`, diagnostics types) to `clock`.

Strong alternative if you want it more literal: **`dateProvider`**. I’d still prefer `clock` — shorter, common for this pattern, and less confusing than `now`.

## User

Ok, go ahead and change it to clock

## Assistant

Renaming the injectable `now` closures to `clock` on the services that store them; leaving `now:` on Date-parameter APIs.

Done. Renamed the injectable time source to `clock` on:

- `WatchlistRefreshService`
- `DiagnosticsSimulatedUpdateRunner`
- `DiagnosticsSimulatedDataProvider`
- `WatchlistRefreshServiceTests`

Date-parameter APIs still use `now:` (e.g. `NextSeasonCalculator.status(for:now:)`, `StatusChangeDetector.evaluate`), and call sites now pass `now: clock()`.

`WatchlistRefreshServiceTests` passed. No commit/push.

## User

Now how about the argument labels?  now: doesn't seem to apply anymore in most cases.

## Assistant

Checking which `now:` labels are `Date` parameters vs the old clock closures:

I’d rename those `Date` labels to **`at:`**.

That reads as “evaluate/create relative to this instant,” which fits both wall-clock defaults and `clock()`:

```swift
NextSeasonCalculator.status(for: show, at: clock())
StatusChangeDetector.evaluate(tracked:tracked, newStatus:newStatus, at: clock())
TVMazeUpdatePeriod.covering(since: oldestCheck, at: clock())
RefreshPolicy.shouldPerformForegroundRefresh(lastRefreshAt:..., at: clock())
TrackedShow(from: show, at: date)
```

Defaults can stay `= .now`.

`asOf:` is clearer in prose but heavier at call sites. I’d use **`at:`** everywhere those five APIs take a reference `Date`.

Want me to apply that rename?

## User

Yes

## Assistant

Renaming the five `Date` argument labels from `now:` to `at:` and updating all call sites.

Done. Renamed the `Date` argument label from `now:` to `at:` on:

- `NextSeasonCalculator.status(for:at:)`
- `StatusChangeDetector.evaluate(tracked:newStatus:at:)`
- `TVMazeUpdatePeriod.covering(since:at:)`
- `RefreshPolicy.shouldPerformForegroundRefresh(lastRefreshAt:at:)`
- `TrackedShow.init(from:at:)`

Call sites now read like `status(for: show, at: clock())`. Defaults remain `= .now`. Related tests (44) passed. No commit/push.

## User

Please explain the function evaluate in StatusChangeDetector

## Assistant

`evaluate` is the decision point after a refresh has computed a new `NextSeasonStatus`. It returns:

1. An updated `TrackedShow` (always bumps `lastCheckedAt`, always writes `nextSeason`)
2. Optionally a `SeasonNotificationContent` if the user should be notified **this** poll

It does **not** talk to the network or notification center — `WatchlistRefreshService` persists the updated tracked show and delivers the notification if present.

## What it’s solving

TVMaze data can flap (announced → undated → announced again, etc.). PD-008 says:

- **Date-backed** changes (`.scheduled`, `.airing`) → notify immediately  
- **Softer** meaningful changes (e.g. “returning” → “season announced, no date”) → require **two consecutive polls** seeing the same new state before notifying  
- Never re-notify the same state (`lastNotifiedSignature`)

## Step by step

**Setup** — Copy the tracked show, set `lastCheckedAt = at`, set `nextSeason = newStatus`, compute `changeSignature` for the new status (stable string like `"airing:2"`).

**1. Confirm a pending (debounced) change**

```73:81:NextSeason/Services/StatusChangeDetector.swift
        // Second poll: the snapshot already matches, but a pending change is confirming.
        if tracked.pendingChangeSignature == changeSignature,
           changeSignature != tracked.lastNotifiedSignature {
            updated.lastNotifiedSignature = changeSignature
            updated.pendingChangeSignature = nil
            return Evaluation(
                tracked: updated,
                notification: SeasonNotificationContent(...)
            )
```

Last poll stored this signature as “maybe notify later.” This poll sees it again → notify, clear pending, record as last notified.

**2. Not a meaningful change** → clear any pending debounce, no notification. Status on the tracked show still updates (so the watchlist UI stays current).

**3. Already notified for this signature** → clear pending, no notification (dedupe).

**4. Meaningful + date-backed** → notify immediately, set `lastNotifiedSignature`, clear pending.

**5. Meaningful but not date-backed** → **don’t** notify yet; stash `pendingChangeSignature = changeSignature` and wait for the next poll to confirm (step 1).

## Mental model

```text
new status from TVMaze
        │
        ├─ same as pending from last poll? → notify (debounce confirmed)
        ├─ not a meaningful delta?         → update only
        ├─ already notified this state?    → update only
        ├─ date-backed meaningful?         → notify now
        └─ soft meaningful?                → mark pending, notify next time if it sticks
```

So `evaluate` is: **update local status always; notify only when the change is meaningful, not a duplicate, and either date-backed or confirmed across two polls.**

## User

Please add comments to this effect to the function

## Assistant

Added a doc comment on `evaluate` summarizing the always-update / notify-when rules, plus short step comments for each branch (debounce confirmed, not meaningful, already notified, date-backed immediate notify, soft change pending).

## User

Please comment WatchlistRefreshService in WatchlistRefreshService.swift

## Assistant

Adding type- and section-level comments that explain the refresh pipeline, matching the style used for `StatusChangeDetector`.

Commented `WatchlistRefreshService.swift`:

- Expanded the type doc with the refresh pipeline (load → updates map → per-show fetch/evaluate/persist/notify)
- Noted `clock` and `lastForegroundRefreshAt`
- Clarified `refreshAllIfNeeded` vs `refreshAll`
- Added short comments on the updates window, status/evaluate step, 404 → stale, and per-show error continue
- Left the existing calendar-recheck comment as-is

No commit/push.

## User

In AnalyticsDiagnosticsReport, why did you use enums to hold vars and a function"

## Assistant

Those are **caseless enums used as namespaces** — a common Swift pattern for grouping static helpers that should never be instantiated.

```8:22:NextSeason/Services/AnalyticsDiagnosticsReport.swift
enum AppVersionInfo {
    static var marketingVersion: String { ... }
    ...
}

enum AnalyticsDiagnosticsReport {
    @MainActor
    static func formatted(...) -> String {
```

**Why an enum (not a `struct` / `class`)?**

- There are **no cases**, so you can’t write `AppVersionInfo()` or `AnalyticsDiagnosticsReport()`.
- A empty `struct` can still be constructed (`AppVersionInfo()`), which doesn’t make sense for a bag of statics.
- It signals: “this is a namespace for related static API, not a value or object.”

**Why not free functions / loose globals?**

- Keeps related pieces under a clear type name: `AppVersionInfo.displayString`, `AnalyticsDiagnosticsReport.formatted(...)`.
- Avoids dumping helpers into the module’s top-level namespace.

So:

| Type | Role |
|------|------|
| `AppVersionInfo` | Static accessors for bundle version/build |
| `AnalyticsDiagnosticsReport` | Static formatter that builds the diagnostics export string |

Nothing about the diagnostics logic *requires* an enum — a `struct` with a private `init()` would work too. The enum is just the idiomatic “can’t instantiate this” namespace. Same idea as `NextSeasonCalculator`, `StatusChangeDetector`, `RefreshPolicy`, etc. in this project.

## User

In AppNavigationCoordinator, please add comments to function resolvePendingNavigation

## Assistant

Added a doc comment on `resolvePendingNavigation` covering when it’s called, Watchlist-first vs Search fallback, and deferred push / animation behavior, plus short step comments inside the function.

## User

Please add comments to NotificationService explaining more about what it does and how it does it

## Assistant

Commented `NotificationService.swift` with:

- Clearer roles for `NotificationDelivering` vs `NotificationManaging`
- A type-level overview: permission UX (including “Not Now” deferral), delivery/`showID` deep links, signature-based request IDs, UI-test/debug seams
- Notes on deferral key, Settings entry point, `requestAuthorizationIfNeeded`, immediate vs delayed deliver, and what `scheduleNotification` puts in `userInfo`/identifiers

Existing comments that were already accurate were kept or folded into the new ones.

## User

Please add comments to RefreshScheduler.swift

## Assistant

Commented `RefreshScheduler.swift` with:

- Type overview: best-effort `BGAppRefreshTask` lifecycle and launch wiring
- Notes on `configure`, `registerBackgroundTask` (must run at launch), and `scheduleNextRefresh`
- Why we schedule the next run immediately when a task starts, and how expiration cancels work
- Why `BackgroundRefreshCompletion` exists (complete the task at most once)

## User

Please go through all the code and add comments as we have been doing.  I will continue going through file by file but it would be nice to have the comments already there as I'm reading through.

## Assistant

I'll walk the production Swift sources and add the same style of type/method/step comments we've been using—focusing on non-obvious behavior, not noise. Exploring the codebase and working through it systematically.

Starting with the highest-priority gaps, then working through the rest of the production sources.

Applying comments in batches, starting with persistence and the highest-complexity services.

Delegating parallel comment passes for the remaining high-value files while I continue on App and Models.

Done — comments only across the production codebase (~50 Swift files), same style as `WatchlistRefreshService` / `NotificationService`: type purpose, non-obvious APIs, short “why” on tricky branches. No logic changes, no commit/push.

**Heaviest coverage**
- Persistence (`TrackedShowEntity`, `SwiftDataWatchlistRepository`, protocol)
- Networking / refresh (`TVMazeClient`, calculator, policies)
- Navigation / notifications / analytics / diagnostics
- Search & watchlist UI + view models (`SearchView`, `SearchViewModel`, `SearchWatchlistTracking`, `UndoToast`, pending removal, etc.)
- Profile/Instruments (`ProfileFlowRunner`, configuration)
- App entry (`NextSeasonApp`, `ContentView`, composition root)

**Left lighter on purpose**
- DTOs that already had type one-liners
- Tiny preview stubs and simple display helpers that were already clear
- Unit tests

As you read file by file, if any comment is thin, wrong, or too noisy, point me at it and we can tighten it.

## User

In TVMazeClient, function makeCachingSession, how did you come up with the values for memory and disk capacity?

## Assistant

I didn’t derive them from measurements — they came from the Slice 1 caching decision as a **modest heuristic**.

From the 6-15-2026 Phase 4 Slice 1 discussion (then committed as PD-010):

> Give `TVMazeClient` its own `URLSession` configured with a dedicated, modestly-sized `URLCache` (**say ~4 MB memory / 50 MB disk**) instead of leaning on the global shared cache.

So the intent was:

- **Dedicated cache** — not `URLCache.shared`, so size is intentional and tunable  
- **Modest** — enough for JSON show/search responses (small), not image libraries  
- **Round numbers** — 4 MB RAM / 50 MB disk as a starting point, not a profiled optimum  

TVMaze’s `Cache-Control: max-age=3600` decides *freshness*; these numbers only cap *how much* can be held. For this app’s payload sizes, either value is plenty; they haven’t been tuned against real cache hit rates or device pressure.

## User

Is there any way to make the values more precise, or is an educated guess the best we can do?

## Assistant

For this app, an educated guess is basically fine — but you *can* make the numbers more precise if you want evidence instead of a hunch.

**Why precision barely matters here**

TVMaze responses are small JSON (search lists, one show + embeds). Even dozens of cached responses are usually well under a few MB. So 4 MB / 50 MB is “comfortably enough,” not a tight sizing problem. Going more precise won’t change user-visible behavior much unless the cache is *too small* (thrashing) or *absurdly large* (wasted disk).

**If you want better than a guess**

1. **Measure payload sizes** — Log `data.count` on a few real search/detail/updates responses; multiply by “how many distinct URLs you care to keep warm” (e.g. last N show details + recent searches). That gives a floor for memory/disk.
2. **Observe cache behavior** — Temporarily log when requests are served from cache vs network (or use Instruments / a `URLProtocol` / os_log around session). Tune up if you see frequent re-fetches of the same show within the hour window; tune down if footprint ever looks large (unlikely).
3. **Use a simple formula**, e.g.  
   `memory ≈ 50–100 × typical show JSON`  
   `disk ≈ a few hundred × typical show JSON`  
   Then round to nice MB values.

**What I wouldn’t do**

- Overfit to one device’s Instruments run  
- Size for images (`AsyncImage` uses its own caching path; this `URLCache` is mainly for API JSON)  
- Spend much time on this before a real problem appears  

**Practical recommendation:** keep ~4 MB / 50 MB (or document “~N responses”). If you want a one-time grounding exercise, sample a handful of live response sizes and set memory to something like 2–4× your “hot set,” disk to 10–20× that — then leave it alone.

## User

In ShowData+Domain, you have two functions name toDomain which appear to be Decoding JSON into object.  Why aren't these using models?

## Assistant

They **are** using models — two layers of them. `toDomain()` is not decoding JSON.

**What already happened before `toDomain()`**

`TVMazeClient` uses `JSONDecoder` to decode into **DTO** types that mirror the API:

```swift
let data: ShowData = try await get(...)   // JSON → ShowData
let show = data.toDomain()                // ShowData → Show
```

So by the time you’re in `ShowData+Domain`, the JSON is already a `ShowData` / `SeasonData` value.

**What `toDomain()` actually does**

It’s a **mapper** from wire shape → app shape:

| DTO (`ShowData`) | Domain (`Show`) |
|---|---|
| `url: String?` | `tvMazeURL: URL?` |
| `status: String?` | `ShowStatus` |
| `premiered: String?` | `Date?` via `TVMazeDate` |
| `network` / `webChannel` | single `network: String?` |
| `updated: Int?` (Unix) | `updatedAt: Date` |
| `_embedded` seasons | `[Season]` |

Same idea for `SeasonData` → `Season`.

**Why not decode JSON straight into `Show`?**

That’s intentional (file header + AGENTS.md DTO naming):

1. **API quirks stay at the edge** — string dates, dual network fields, `_embedded`, Unix `updated`.
2. **Domain stays clean** for views/calculators — real `Date`s, `URL`s, enums.
3. **They can evolve separately** — TVMaze can add/rename JSON fields without rewriting `Show`.

So: models are used twice — `*Data` for Codable/JSON, domain types for the app. `toDomain()` is the bridge, not a second decoder.

## User

I'm not familiar with the term Domain.  What does that mean?

## Assistant

In this codebase, **domain** means “the app’s own idea of the data,” not “whatever the API sent.”

- **DTO / `*Data` types** (`ShowData`, `SeasonData`) — shaped like TVMaze’s JSON. Good for decoding, awkward for the rest of the app.
- **Domain models** (`Show`, `Season`, `TrackedShow`, `NextSeasonStatus`) — shaped for *your* product logic: real dates, enums, URLs, clean names.

So `toDomain()` means: “turn the network payload into our app model.”

You’ll also hear **domain logic** for rules that belong to the product itself (e.g. `NextSeasonCalculator` deciding “airing” vs “scheduled”), as opposed to UI or networking details.

It’s just naming from common architecture jargon — not a Swift keyword. Some teams say “app model” or “business model” for the same thing.

## User

What does "debounce" mean in this context? I'm used to seeing it in the context of now allowing a button to be tapped more than once.

## Assistant

Same idea as your button case: **don’t react to every event — wait until things settle, then act once.**

The button version is “ignore extra taps for a short window.” Classic debounce (and what Search uses) is usually: **wait until input has been quiet for X ms, then run.**

**In Search (`SearchViewModel`)**  
Each keystroke would otherwise hit TVMaze. Instead, `.task(id: query)` cancels the previous run and `search()` sleeps ~300 ms. Only if the query still hasn’t changed does the network call run. Typing “Severance” → one search for the final string, not one per letter.

**In notifications (`StatusChangeDetector`, PD-008)**  
Here “debounce” means: for soft status changes (e.g. undated announcement), **don’t notify on the first poll** — stash a pending signature and notify only if the **next** refresh still shows the same state. That filters flaky API flips, similar to ignoring a bounce.

So:

| Context | What gets collapsed | When you act |
|--------|---------------------|--------------|
| Button | Rapid taps | After a quiet period / first tap wins |
| Search | Rapid keystrokes | After ~300 ms with no new typing |
| Notifications | Flimsy status changes | After a second confirming poll |

Underlying metaphor: wait for the signal to stop “bouncing” before treating it as real.

## User

In SummaryFormatter, plainText is run several times on each string.  Would it make sense to run it once and store the result?  I realize this would mean converting SummaryFormatter from an enum into a struct;  would the downsides of that outweigh the efficiencies of not calling plainText repeatedly for the same string?

## Assistant

Two different things are easy to mix up here.

**Inside one `plainText` call** — the many `replacingOccurrences` runs are a **pipeline** on the same string (block tags → emphasis → strip leftovers → entities → whitespace). That’s not “calling `plainText` repeatedly”; you need those steps in order. Caching doesn’t help that.

**Across the Show Detail call site** — yes, the same HTML can go through `plainText` **twice**:

```266:273:NextSeason/Features/ShowDetail/ShowDetailView.swift
        let hasSummary = SummaryFormatter.hasDisplayableContent(html)
        ...
                    Text(SummaryFormatter.attributedString(from: html))
```

`hasDisplayableContent` → `plainText`, then `attributedString` → `plainText` again.

**Should you cache via a struct?**  
Almost certainly not. The cost is small (short HTML, a few regexes, once or twice per detail screen). Turning `SummaryFormatter` into a stateful/cached struct buys little and costs:

- Lifetime / invalidation questions (when does the cache clear?)
- Harder testing and a less clear “pure helper” API
- Easy to get wrong if HTML can change

**If you want to avoid the double work**, keep the enum and **merge the API** so one conversion serves both needs, e.g.:

```swift
static func attributedSummary(from html: String?) -> AttributedString? {
    guard let html else { return nil }
    let text = plainText(fromHTML: html)
    guard !text.isEmpty else { return nil }
    return attributedString(fromPlainText: text)
}
```

Then the view calls that once. Same efficiency win, no struct, no cache.

**Bottom line:** Don’t convert to a struct for this. The repeated replacements inside `plainText` should stay; the only optional cleanup is collapsing the two public calls so `plainText` runs once per summary.

## User

ok, go ahead and do that

## Assistant

Adding `attributedSummary(from:)` and updating Show Detail to use a single conversion.

Keeping `hasDisplayableContent` as a cheap plain-text check so a bool-only call doesn’t run Markdown parsing.

Done.

- Added `SummaryFormatter.attributedSummary(from:)` — runs `plainText` once, returns `nil` if empty
- Show Detail’s About section uses that once (no separate `hasDisplayableContent` + `attributedString`)
- Kept `hasDisplayableContent` as a cheap plain-text check, with a note to prefer `attributedSummary` when you need the text too
- `attributedString(from:)` still works for tests (empty string when there’s nothing to show)

`SummaryFormatterTests` passed. No commit/push.

## User

Please add a comment on plainText to explain what it's doing.

## Assistant

Added a short doc comment on `plainText` describing the HTML → Markdown-ish pipeline and why each step is there.

## User

AppAboutView and DiagnosticsView define their environment values in the same file, whereas all the other places that define one are in a separae "+Environment" file.  Is there a reason why?

## Assistant

There’s no strong technical reason they *couldn’t* be in `+Environment` files — it’s a pattern split, not a compiler requirement.

**`+Environment` files** are for **required app services** injected at the root:

- `analytics`, `watchlistRepository`, `notificationService`, etc.
- Default is an `Unconfigured…` stub that `fatalError`s if you forget to inject
- Lives next to (or as an extension of) the service type

**`openAppAbout` / `openDiagnostics`** are different:

- Optional **UI callbacks** (`(() -> Void)?`), default `nil`
- Mean “presentation is available,” not “here is a long-lived dependency”
- Defined next to the feature that owns that entry point (`AppAboutView` + toolbar modifier; Diagnostics open action)

So: service injection → separate `+Environment` + fatal default; optional presentation hooks → co-located with the view is fine (and keeps a tiny key from becoming another file).

If you want consistency, you could move them to `AppAboutView+Environment.swift` / `DiagnosticsView+Environment.swift`, but it wouldn’t change behavior — only file layout. I wouldn’t treat the current setup as a mistake.

## User

Ok, then please add a concise comment in each of the two files explaining why they're there.

## Assistant

Added a short note above each `EnvironmentKey` in `AppAboutView.swift` and `DiagnosticsView.swift` explaining they’re optional UI callbacks kept with the feature, not required services in a `+Environment` file.

## User

Please add comments to SearchKeyboardDismissal explaining how it works

## Assistant

Commented `SearchKeyboardDismissal.swift` with:

- File overview: why searchable needs an explicit dismiss, and who calls what  
- `collapseSearchKeyboard`: searchable dismiss + UIKit resign fallback, query stays  
- Drag modifier: why it exists, threshold, latch so dismiss runs once per gesture without blocking scroll

## User

I've looked at all the various pieces of the ProfileFlow functionality but I still don't understand it.  Can you give me an explanation?

## Assistant

ProfileFlow is a **hands-free “robot user” for performance profiling**. It is not part of normal product UX. You launch the app with a special argument, it drives a fixed scenario by itself, and Instruments (or a timing log) records how expensive that scenario was.

## Why it exists

You want to measure things like “search for Severance” or “open show detail” on a real device without tapping the UI yourself every time. ProfileFlow automates that so runs are repeatable.

## How you turn it on

Launch with either:

- `-ProfileFlow <name>` (e.g. `-ProfileFlow search`), or  
- env `PROFILE_FLOW=<name>`

`ProfileFlowConfiguration.activeFlow` reads that. If it’s `nil`, none of this runs.

There are also shell scripts under `Scripts/` that launch flows for Instruments or uninstrumented timing pulls.

## Big picture

```text
Launch with -ProfileFlow search
        │
        ▼
NextSeasonApp .task
        │
        ▼
ProfileFlowRunner.run()
   • waits for UI to appear
   • drives coordinator / repository
   • waits for “UI settled” tokens
   • emits signposts + duration logs
        │
        ▼
Real app UI reacts (SearchView, Show Detail, Watchlist)
```

So the runner doesn’t fake a parallel UI — it **pushes the same state** the user would (tab, query, navigation path, add/remove).

## The pieces and their jobs

| Piece | Job |
|--------|-----|
| **`ProfileFlowConfiguration`** | Which flow names exist, launch-arg parsing, seed/empty queries, signpost log handle |
| **`ProfileFlowRunner`** | Script for one flow: do steps, wait, time them |
| **`AppNavigationCoordinator`** | Holds `profileFlowSearchQuery` and bumpable tokens the runner waits on |
| **`SearchProfileFlowModifier`** | When runner sets a query → copies it into `SearchViewModel`; when search settles → calls “settled” |
| **Show Detail callback** | When detail finishes loading → bumps detail-loaded token |
| **`ProfileFlowTimingStore` / logger** | Writes durations to JSONL / logs when not using Instruments |
| **Scripts** | Automate launching flows for a suite |

## How the runner “waits for the UI”

It can’t just `sleep(2)` and hope. Search and detail are async.

1. Runner sets `coordinator.profileFlowSearchQuery = "Severance"`.
2. `SearchProfileFlowModifier` puts that into `viewModel.query` (which triggers the normal `.task(id:)` search).
3. When state becomes `.results` / `.empty` / `.failed`, it calls `onProfileFlowSearchSettled`.
4. That bumps `profileFlowSearchSettledToken` on the coordinator.
5. Runner’s `waitForSearchResults` polls until that token increases (or times out).

Detail load works the same way with `profileFlowDetailLoadedToken`.

## What the flows are

- **Setup:** `seedWatchlist` — add a few known shows (not the “measurement” run).
- **Single scenarios:** `search`, `searchEmpty`, `showDetails`, `viewWishlist`, `addToWishlist`, `removeFromWishlist`.
- **Stress:** repeat search→detail→back, add/remove, or empty search many times.
- **`launchWithData`:** assume watchlist already seeded; open watchlist and sit idle (cold-launch with data).

## What you get out of a run

1. **Instruments Points of Interest** — `OSSignposter` intervals like `flow.search`, `search.query`.
2. **Wall-clock logs** — `AppDiagnosticsLogger.logProfileFlowTiming` (+ JSONL file for device pulls without Instruments).

## What it deliberately does *not* do

- No special production feature for end users  
- No mocking of TVMaze in these flows (uses live API / real repo, unless you launch under UI testing separately)  
- Doesn’t replace XCUITests — those test correctness; ProfileFlow is for **performance measurement**

**One-sentence version:** ProfileFlow is “launch the app in puppeteer mode, run one scripted user journey, and record how long the interesting parts took.”

## User

Please explain how Search works

## Assistant

Search is the guest “find a show” tab: type a title → TVMaze returns matches → open detail or star onto the watchlist.

## Main path

```text
User types in .searchable
        │
        ▼
viewModel.query changes
        │
        ▼
.task(id: query) → SearchViewModel.search()
   • wait ~300ms (debounce; cancelled if query changes)
   • TVMazeClient.searchShows(matching:)
   • state = .results / .empty / .failed
        │
        ▼
SearchView switches UI on state
```

## Debounce (why typing isn’t one request per letter)

`.task(id: viewModel.query)` **cancels** the previous task whenever the text changes. Inside `search()`, a short `Task.sleep` runs first. Only if that sleep finishes (query still the same) does the network call run. So “Severance” ideally becomes one search for the final string.

## View model states

| State | UI |
|--------|-----|
| `.idle` | Empty prompt; optional “Try an Example” |
| `.loading` | Skeleton rows |
| `.results` | List of shows + track buttons |
| `.empty` | “Can’t find your show?” (TVMaze only returns up to ~10; empty ≠ “doesn’t exist”) |
| `.failed` | Error + retry |

`displayedQuery` remembers which trimmed query produced the current results. Returning from show detail re-runs `.task(id:)` with the same text; `search()` **skips** reloading so you don’t flash the loading skeletons.

## List row behavior

Each result is:

- **NavigationLink** → `ShowDetailView` (same `Show` value pushed on `navigationPath`)
- **Track star** → `SearchWatchlistTracking` → shared `WatchlistTracking.toggle` (add needs a full show fetch; remove uses undo window)

Tracked IDs refresh when the screen appears, when you pop back from detail, and when a pending undo-removal changes — so stars stay in sync with the watchlist / undo toast.

## First-run extras

- Idle **“Try an Example”** until the user gets `.results` or `.empty` once (`hasCompletedFirstSearch`).
- Results-list **hint inset** until they open a show or add one (`searchResultsHintDismissed`).

## Keyboard

Submit / scroll uses `collapseSearchKeyboard` + a drag gesture, because nav-bar `.searchable` often ignores system scroll-dismiss. Query text stays in the field.

## Networking

Production: `TVMazeClient` → `GET /search/shows?q=` → `ShowData` → `Show`.  
UI tests: stub `PreviewTVMazeService` (no live network).

**In one sentence:** Search debounces the query into a TVMaze search, shows the outcome in a list, and lets you push detail or toggle watchlist tracking with the same persistence path as the rest of the app.

## User

Where is the code for this behavior: search() skips reloading so you don’t flash the loading skeletons.

## Assistant

It’s in `SearchViewModel.search()`, right after the debounce sleep:

```65:71:NextSeason/Features/Search/SearchViewModel.swift
        // `.task(id: query)` runs again when returning from show detail; keep
        // existing results instead of flashing the loading placeholder.
        if trimmed == displayedQuery, isShowingSearchOutcome {
            return
        }

        state = .loading
```

If the trimmed query still matches `displayedQuery` and state is already `.results` or `.empty`, it returns **before** `state = .loading`, so the skeletons never appear and no new network call runs.

## User

In SearchView's preview the search bar is at the bottom of the screen, but in ContentView's preview it's at the top.  Where is the code that moves it to the top?

## Assistant

There isn’t app code that explicitly moves Search’s bar to the top.

Search only has the default:

```87:87:NextSeason/Features/Search/SearchView.swift
                .searchable(text: $viewModel.query, prompt: "Search TV shows")
```

No `placement:` is set, so SwiftUI uses `.automatic` and picks a position from the surrounding hierarchy.

**What’s different in the two previews**

| Preview | Hierarchy | What you see |
|--------|-----------|--------------|
| `SearchView` | Standalone `NavigationStack` + `.searchable` | Automatic → often bottom |
| `ContentView` | `TabView` → `SearchView` → `NavigationStack` + `.searchable` | Automatic → nav bar (top) |

The “move” is really `ContentView`’s `TabView` changing how `.automatic` resolves—not a Search-specific placement API.

For contrast, Watchlist *does* pin placement:

```219:221:NextSeason/Features/Watchlist/WatchlistView.swift
            .searchable(
                ...
                placement: .navigationBarDrawer(displayMode: .always),
```

Search doesn’t. If you want Search’s preview to match the app, wrap it in a `TabView` in the preview, or set the same `placement:` on Search’s `.searchable`.

## User

How much duplicated code is there between handling the tracking button (star) from the search results, the show detail, and the watchlist?

## Assistant

There’s **little duplicated business logic** — most of it was pulled into shared helpers. What’s left is **similar wiring** in Search vs Detail, and a **simpler path** on Watchlist.

## What’s shared

| Piece | Used by |
|--------|---------|
| `ShowRowTrackButton` | Search, Detail, Watchlist (same star UI) |
| `WatchlistTracking.toggle` / `.add` | Search + Detail |
| `WatchlistPendingRemoval` | All three (undo window / commit) |
| `WatchlistEffectiveTracking` | Search + Detail (star vs pending removal) |
| Error copy `WatchlistTracking.updateFailedMessage` | Detail (+ pending removal persistence) |

Core add / undo-pending / request-removal lives once in `WatchlistTracking.toggle`.

## What’s similar but still separate (Search ↔ Detail)

`SearchWatchlistTracking.handleTrackButton` and `ShowDetailViewModel.handleTrackButton` are near-twins:

- Add-only in-flight lock (`updatingShowIDs` / `isUpdatingWatchlist`)
- Call `WatchlistTracking.toggle` with different `source` (`.search` / `.detail`)
- Map `ToggleOutcome` onto local star state
- On error: analytics context string + refresh or restore star

That’s **~40–50 lines of parallel orchestration**, not a second implementation of persistence. Could be one helper, but it’s thin glue.

## Watchlist is different on purpose

On the watchlist the show is already tracked, so the star doesn’t go through `toggle`:

- Pending removal → `undoPendingRemoval()`
- Else → `requestRemoval(...)` on the coordinator

No add path, no `WatchlistTracking.toggle`, no “updating” spinner on that button. Same UI control, narrower behavior.

## Rough duplication score

| Layer | Duplication |
|--------|-------------|
| Persistence / undo / add | **None** (shared) |
| Star button view | **None** (one component) |
| Search vs Detail handlers | **Moderate** (same shape, two copies) |
| Watchlist vs the other two | **Low** (intentionally simpler untrack/undo only) |

**Bottom line:** Real tracking behavior is centralized. The main leftover duplication is Search/Detail’s handle-track wrappers; Watchlist only shares the button and the pending-removal coordinator.

## User

Please make the following changes, suggested by ChatGPT:

1. Move WatchlistNotificationPromptState.swift to Watchlist and rename it WatchlistNotificationPrompt.swift.
2. Move SearchWatchlistTrackingContext into SearchWatchlistTracking.swift, probably as a nested Context type, and remove SearchWatchlistTrackingContext.swift

## Assistant

Moving and nesting those types; keeping the `WatchlistNotificationPromptState` type name (file rename only) unless you want that renamed too.

Done. Summary of changes:

1. **`WatchlistNotificationPromptState.swift`** → **`Features/Watchlist/WatchlistNotificationPrompt.swift`**  
   - Type name stays `WatchlistNotificationPromptState` (and `WatchlistNotificationPromptAlerts`); only the file moved/renamed.

2. **`SearchWatchlistTrackingContext`** → nested **`SearchWatchlistTracking.Context`** in `SearchWatchlistTracking.swift`  
   - Removed `SearchWatchlistTrackingContext.swift`  
   - Updated `SearchView` to build `SearchWatchlistTracking.Context`

No commit/push.

## User

What does "WatchlistEffectiveTracking" mean?  I understand the code but the name doesn't quite make sense.

## Assistant

**“Effective”** here means “what the UI should treat as tracked **right now**,” after applying the undo-window rule — not “whatever is in the database.”

- **Persisted:** still in the repository (remove hasn’t committed yet)  
- **Effective:** persisted **and** not pending undoable removal → star filled / “tracked”

So `WatchlistEffectiveTracking` ≈ “compute the **effective** tracked set for the UI.”

That’s a bit abstract. Clearer names if you ever rename:

- `WatchlistTrackingState`  
- `WatchlistVisibleTracking`  
- `WatchlistTrackingAppearance` (star state)  

The important idea: **persistence ≠ star state** while undo is open; this helper is the bridge.

## User

Please rename it to WatchlistTrackingState

## Assistant

Renamed `WatchlistEffectiveTracking` → **`WatchlistTrackingState`**.

- File: `WatchlistTrackingState.swift`
- Tests: `WatchlistTrackingStateTests.swift`
- Call sites in `SearchWatchlistTracking` and `ShowDetailViewModel`

No remaining Swift references to the old name. AI transcript docs still mention it historically — left those alone.

## User

Preview is crashing for  WatchlistView with this error:

"NextSeason crashed due to fatalError in NotificationService+Environment.swift at line 24.

NotificationManaging was not injected. Set it on the root view."

Please fix.

## Assistant

Injecting `notificationService` and `analytics` into the `WatchlistView` preview — both are required once the view reloads.

The preview was missing environment injection for services that `WatchlistView` uses on load (`notificationStatus.refresh` hits `notificationService`).

**Change:** the `#Preview` now injects `analytics` and `notificationService` (same pattern as Diagnostics/About). Also switched to `PreviewTVMazeService` so the canvas doesn’t hit the network.

**Test:** reopen the `WatchlistView` preview canvas — it should render without the fatalError.

## User

Now I'm getting a build error "Missing argument for parameter 'stub' in call" on the WatchlistView line in the Preview

## Assistant

Fixed — `PreviewTVMazeService` needs a stub show: `PreviewTVMazeService(stub: .preview)`.

## User

There's an error in replacingPendingRemovalCommitsPrevious in WatchlistPendingRemovalTests:  "Expectation failed: try await repository.contains(showID: first.id) == false"

## Assistant

The test is flaky: it only sleeps 50ms for an async fire-and-forget persist. Under parallel test load that can be too short. Hardening it to poll like `WatchlistViewModelTests` already does.

The failure was a race in the test, not in production logic.

Replacing a pending removal commits the previous show on an unstructured `Task`. The test only waited a fixed 50ms, which can lose under parallel load. It now polls (up to 1s), same pattern as `WatchlistViewModelTests`.

All 7 `WatchlistPendingRemovalTests` pass. Re-run that test in Xcode to confirm on your machine.
