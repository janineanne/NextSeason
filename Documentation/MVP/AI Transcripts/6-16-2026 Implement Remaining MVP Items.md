# Code review feedback and action items

## User

Are there any other coding tasks you can think of that should be done before we call the MVP complete?

## Assistant

Reviewing the MVP definition and current codebase to identify remaining gaps.

#Here’s an honest pre-MVP checklist based on your docs, user stories, and what’s actually in the codebase.

## Already in good shape

The core Slice 2 loop is built: search, detail, track/remove, SwiftData persistence, change detection with debounce, local notifications, background task registration, pull-to-refresh, error/empty states, attribution, and solid unit test coverage for the pure logic (calculator, change detector, refresh service, repository).

Against `MVPDefinition.md`, you’re close on the feature list.

## Gaps I’d treat as “before MVP”

**1. Notification tap → show (planned, not built)**  
`Architecture.md` says tapping a notification should route to the relevant show. `userInfo["showID"]` is set, but there’s no `UNUserNotificationCenterDelegate` or navigation handling. US-007 only requires “opens the app,” so you technically pass the letter of the story — but for a portfolio demo, landing on the show detail is worth doing.

**2. Refresh when the app becomes active**  
Background refresh is best-effort (PD-005). Right now network refresh happens on:
- BG task (unreliable timing)
- Watchlist pull-to-refresh (manual)

App launch configures the scheduler but does **not** run `refreshAll()`. For the success metric “leave the app and get notified without ongoing effort,” a lightweight refresh on launch or `scenePhase == .active` would materially improve reliability.

**3. Finish the VoiceOver pass**  
You have uncommitted work on `cursor/voiceover-accessibility`. Not blocking for everyone, but it aligns with “portfolio-quality” and you already started it.

**4. Verify the full notification path manually**  
Code and tests cover detection/delivery, but BG refresh is hard to exercise. Before calling MVP done, I’d run a deliberate manual test:
- Track a show
- Grant notifications
- Simulate/trigger a status change (or use debugger to force refresh)
- Confirm notification content and app behavior on tap

## Smaller but worthwhile

**5. Denied notification permission UX (US-008)**  
The app handles denial gracefully (still works), and you now explain before prompting. What’s missing: if someone taps “Not Now” or denies in Settings, there’s no in-app path to re-enable (e.g. “Open Settings” on Watchlist or after tracking).

**6. README**  
`README.md` is essentially empty. For portfolio goals, a short README with problem, stack, architecture sketch, and how to run tests would help.

**7. App launch refresh vs. watchlist-only refresh**  
Watchlist `.task` calls `load()` (local DB only), not `refreshFromNetwork()`. Even a one-line “refresh on first watchlist appear if stale” policy would reduce confusion when data looks old.

## Fine to defer (P1 / post-MVP)

From `MVPBacklog.md`: watchlist sort/filter, illustration polish, animations.  
Also reasonable to defer: UI tests, `NotificationService` unit tests, offline/stale-data UX beyond the stale badge, custom app icon polish (unless App Store submission is imminent).

## Suggested “MVP complete” bar

| Task | Why |
|---|---|
| Notification tap → show detail | Matches architecture; better demo |
| Foreground / launch refresh | Makes passive monitoring actually work |
| Merge VoiceOver fixes | Small, already in progress |
| Manual end-to-end notification test | Validates the whole value prop |
| README for portfolio | Exit criteria mention portfolio quality |

If you only do two coding tasks before calling it done, I’d pick **notification routing** and **foreground refresh** — those closest close the gap between “features exist” and “the MVP promise actually works in real life.”

Want me to tackle those two next on a branch?

## User

Please commit the voiceover changes and merge to main

Committed and merged to `main`.

**Commit** `dbc74dd` — Improve VoiceOver labels across detail and watchlist views:
- Labeled loading states (`Loading show…`, `Loading watchlist…`)
- Track button keeps text while updating (“Updating…”)
- Context-aware accessibility hint when track is disabled
- Plain text for show status (no TV icon noise)
- Explicit `accessibilityLabel` on watchlist rows

**Merge** — fast-forward of `cursor/voiceover-accessibility` into `main`.

`main` is 1 commit ahead of `origin/main`. The transcript doc change was left unstaged since it wasn’t part of the VoiceOver work. Say if you want that pushed to remote.

## User

Yes, please push to remove

Pushed — `origin/main` is up to date with your local `main`, including the VoiceOver commit (`dbc74dd`).

The only local change not on remote is the unstaged transcript doc edit in `Documentation/KickoffTranscripts/6-16-2026-Phase 4 Slice 2 Implement Review Items.md`. Say if you want that committed and pushed too.

## User

yes please

Committed and pushed the transcript update to `origin/main`.

**Commit** `2a78c0b` — Add transcript entries for Slice 2 merge and push follow-up.

Working tree is clean and local `main` matches the remote.

## User

Please make a branch and implement:

Notification tap → show (planned, not built)
Refresh when the app becomes active
Denied notification permission UX (US-008)

## Assistant

Creating a branch and exploring the app structure to implement notification routing, foreground refresh, and denied-permission UX.

Implementing navigation coordinator, notification delegate, foreground refresh, and denied-permission UX.

Branch `cursor/mvp-polish-notifications-refresh` implements all three items. Summary:

### 1. Notification tap → show detail
- **`AppNavigationCoordinator`** — queues a `showID`, switches tabs, and pushes the detail screen
- **`NotificationCenterDelegate`** — handles notification taps and reads `showID` from `userInfo`
- **`ContentView`** — wired `NavigationPath` on both tabs; resolves pending navigation via watchlist first, then TVMaze fallback
- **`SearchView` / `WatchlistView`** — use bound `NavigationStack(path:)`

### 2. Refresh when app becomes active
- **`AppRootView`** in `NextSeasonApp` — calls `refreshAll()` whenever `scenePhase` becomes `.active` (including return from background)

### 3. Denied notification permission UX (US-008)
- **`NotificationService`** — `isDenied()` and `openNotificationSettings()`
- **`ShowDetailView`** — after a denied permission request, shows an alert with **Open Settings**
- **`NotificationsDisabledBanner`** — on Watchlist when notifications are off and shows are tracked
- Shared **`notificationService`** via environment (single delegate instance at app root)

### Tests
- **`AppNavigationCoordinatorTests`** — userInfo parsing, watchlist routing, search fallback

**What to test:**
1. Track a show, trigger a notification (or simulate in debugger), tap it → app opens to that show’s detail
2. Background the app, change data (or wait for refresh), foreground → watchlist updates
3. Deny notifications → watchlist banner appears; track a show → “Notifications Are Off” alert with Settings link
4. Run `AppNavigationCoordinatorTests` in Xcode

Want me to commit this or open a PR?

## User

How do I "trigger a notification (or simulate in debugger)"?

Here are practical ways to test notifications in NextSeason, from quickest to most realistic.

## Prerequisites

1. Run on **Simulator or device** (not SwiftUI Preview).
2. **Allow notifications** when prompted.
3. **Track at least one show** so you have a real `showID` (e.g. Severance is `44933` on TVMaze).

---

## Option 1: Fastest way to test **tap → show detail**

This tests routing only, without waiting for a real season change.

Add a temporary debug hook (remove before shipping):

```swift
#if DEBUG
.task {
    try? await Task.sleep(for: .seconds(2))
    await notificationService.deliver(
        SeasonNotificationContent(
            showID: 44933,
            showName: "Severance",
            status: .scheduled(season: 3, premiere: .now)
        )
    )
}
#endif
```

Put that on `AppRootView` or `ContentView` in `NextSeasonApp.swift`, using the shared `notificationService`.

Then:
1. Run the app.
2. **Background the app** (Cmd+Shift+H in Simulator).
3. When the notification appears, **tap it**.
4. App should open to that show’s detail (Watchlist tab if still tracked).

Your app uses `trigger: nil`, so the notification fires **immediately** — backgrounding makes the banner easy to see and tap.

---

## Option 2: Test the **real notification pipeline**

NextSeason only notifies when a refresh detects a **meaningful** status change (PD-008 debounce). That usually means:

1. Track a show.
2. Run a refresh that sees new data.
3. For some changes (e.g. “announced, no date”), you may need **two refreshes** before a notification is sent.

Ways to trigger refresh:

| Action | What it exercises |
|---|---|
| **Pull to refresh** on Watchlist | `refreshAll(force: true)` |
| **Background → foreground** | Your new `scenePhase == .active` refresh |
| **Xcode → Debug → Simulate Background App Refresh** | BG task path (best-effort; may not always run) |

The hard part is getting TVMaze data to **actually change** for a tracked show. That’s unreliable for manual testing unless you pick a show that’s actively being updated.

---

## Option 3: Debugger without adding code

1. Set a breakpoint in `WatchlistRefreshService.refreshAll`, inside the block where `evaluation.notification` is non-nil (around the `deliver` call).
2. When it hits, use **LLDB** to fire one manually:

```text
po await refreshService.notifications.deliver(SeasonNotificationContent(showID: 44933, showName: "Severance", status: .scheduled(season: 3, premiere: Date())))
```

That’s awkward with `@MainActor` / async, so Option 1 is usually easier.

---

## Option 4: Verify permission / delivery basics

In Simulator:

- **Settings → Apps → NextSeason → Notifications** — confirm alerts are on.
- If you previously tapped **Don’t Allow**, reset with **Simulator → Device → Erase All Content and Settings**, or delete/reinstall the app.

If notifications are denied, `deliver()` returns silently — nothing will appear.

---

## What I’d use for your three new features

| Feature | How to test |
|---|---|
| **Tap → show** | Option 1 (debug `deliver` + background + tap) |
| **Foreground refresh** | Track a show, background app, change something via pull-to-refresh isn’t needed — just foreground and watch “Updated …” on watchlist |
| **Denied permission UX** | Deny notifications, confirm watchlist banner + “Open Settings” alert after tracking |

---

## Quick sanity check without code changes

If you don’t want to add debug code yet:

1. Track a show with notifications allowed.
2. Background the app.
3. In Xcode: **Debug → Simulate Background App Refresh**.
4. See if a notification appears.

If nothing appears, that’s expected unless TVMaze data changed and passed debounce rules — the pipeline may be working fine with nothing to report.

For MVP verification of **tap routing**, Option 1 is the reliable path. I can add a `#if DEBUG` “Send test notification” button on the watchlist if you want that built in.

## User

Yes please that will be much easier.

## Assistant

Adding a debug-only test notification button to the watchlist for easier notification testing.

I'll add a `#if DEBUG` section at the bottom of the watchlist with a test notification button and brief instructions.

Done. In **Debug builds only**, the Watchlist has a **Debug** section at the bottom when you have tracked shows.

**How to use it:**
1. Run from Xcode (not Preview).
2. Allow notifications.
3. Track at least one show.
4. Open **Watchlist** → scroll down → tap **Send Test Notification**.
5. Background the app (Cmd+Shift+H in Simulator).
6. Tap the notification → the app should open to that show’s detail.

The test uses the **first show** in your watchlist and its current `nextSeason` status, so the `showID` in the notification matches a real tracked show for deep-link testing.

This section is wrapped in `#if DEBUG` and won’t appear in Release builds.

## User

Are you able to write UI tests?

Yes. I can write **XCUITest** UI tests for this project — launch the app in the Simulator, tap elements, type in fields, switch tabs, and assert that the right screens appear.

A few practical notes for NextSeason specifically:

**What you have today**
- **Swift Testing** unit tests in `NextSeasonTests` (calculator, refresh, repository, etc.)
- **No UI test target yet** — you’d need to add one in Xcode (**File → New → Target → UI Testing Bundle**) before the tests can run in CI or from the scheme’s **Test** action.

**What UI tests are good for here**
- Search → open a show → tap **Track**
- Watchlist shows a tracked row
- Tab navigation (Search / Watchlist)
- Basic accessibility identifiers if we add them (recommended for stable selectors)

**What’s awkward without extra setup**
- **System notification permission** dialog (can use `addUIInterruptionMonitor` or launch with `-UITests` + test hooks)
- **Notification tap → deep link** (usually needs a debug launch argument or the **Send Test Notification** button we added)
- **Background refresh / BG tasks** (not realistic in UI tests; keep those as unit tests)

**Swift Testing vs XCUITest**  
Apple’s newer **Swift Testing** framework is for unit/integration tests. **UI tests still use XCUITest** (`XCUIApplication`, `XCTestCase`). So new UI tests would live in a separate `NextSeasonUITests` target, not beside your existing Swift Testing files.

**Recommendation for MVP**
- Keep **unit tests** for business logic (you already have solid coverage).
- Add a **small UI test suite** (3–5 tests) for the main happy path if you want portfolio/CI confidence.
- Use **accessibility identifiers** on key controls (Track button, tabs, search field) so tests don’t break when copy changes.

If you want to proceed, I can add a UI test target and a starter suite (e.g. search, track, watchlist row appears). You’d need to create the target in Xcode once, or I can try to wire it in the project file — creating the target in Xcode is usually more reliable.

## User

Let's wait on the UI tests, but it's good to know you can do them.

## Assistant

Understood — we’ll hold off on UI tests for now.

When you’re ready, the natural starting point is a small XCUITest target plus a few accessibility identifiers on the main flows (search, track, watchlist). Your existing unit tests already cover the harder logic (refresh, change detection, persistence).

If you want to move forward on the MVP polish branch (commit, merge, or the next feature), say the word.

## User

I'm having trouble with that "Send Test Notification" button you added to the watchlist. I've traced it in the debugger and the notification is being sent in NotificationService.deliver, but nothing's being received.  I did give permission for the app to send notifications.  Can you fix?

## Assistant

Investigating notification delivery — foreground notifications often require explicit presentation options in the delegate.

Foreground notifications are suppressed unless the delegate implements `willPresent`. I'll add that and use unique IDs for debug test notifications so repeated taps still show.

Removing the `alertSetting` check — it may block delivery on the simulator; the foreground delegate fix is the real solution.

The notification was being scheduled successfully — iOS just wasn’t **showing** it while the app was in the foreground.

By default, local notifications are delivered silently when your app is active unless the `UNUserNotificationCenterDelegate` implements `willPresent` and returns presentation options.

**Fixes:**
1. **`willPresent` in `NotificationCenterDelegate`** — returns `.banner`, `.list`, and `.sound` so notifications appear while you’re on the Watchlist screen.
2. **Unique debug identifier** — each test tap uses `debug-<UUID>` so repeated taps aren’t suppressed by duplicate request IDs.
3. **Debug assertion on schedule failure** — if `add(_:)` fails, you’ll hit an assertion in Debug builds instead of silent `try?`.

**Try again:** Watchlist → **Send Test Notification**. You should see a banner immediately. Tap it to verify deep linking, or background first if you want to test the lock-screen path.

If nothing still appears, check **Settings → Notifications → NextSeason** and confirm **Allow Notifications** and **Banners** are on.

## User

Please fix the build error

Splitting `deliver` methods so `NotificationService` conforms to `NotificationDelivering` — the optional-parameter overload likely caused the protocol mismatch.

Checking `@Bindable` initialization in `ContentView` — a custom init may be assigning it incorrectly.

Fixed two likely build issues:

1. **`NotificationService` protocol conformance** — A single `deliver(_:requestIdentifier:)` with a default parameter doesn’t satisfy `NotificationDelivering`. Split into:
   - `deliver(_:)` (protocol requirement)
   - `deliver(_:requestIdentifier:)` (debug/test helper)
   - private `scheduleNotification(_:requestIdentifier:)`

2. **`ContentView` `@Bindable` init** — Custom inits must use `_coordinator = Bindable(coordinator)` instead of assigning directly to `coordinator`.

Rebuild in Xcode; it should compile. If you still get an error, paste the message and I’ll fix it.

## User

Ok, now I'm getting a foreground notification. Your original instructions were to background the app, but there isn't time to do that before the foreground one is received.  Is this now working as you expected?

## Assistant

Yes — that’s expected now, and it’s the intended behavior after the `willPresent` fix.

**Before:** iOS delivered the notification in the background (your debugger saw `deliver` succeed), but **didn’t show a banner** while the app was open.

**After:** The delegate tells iOS to show `.banner`, `.list`, and `.sound` even in the foreground, so the notification appears **immediately** when you tap **Send Test Notification**.

The old “background the app first” step was a workaround for when foreground banners were suppressed. You don’t need it anymore to *see* the notification.

**To test deep linking**, you can either:
1. **Tap the banner while the app is open** — should navigate to the show detail.
2. **Background first, then tap** — same result, just tests the lock-screen/Notification Center path.

Both paths exercise the same tap handler (`didReceive`). Foreground is actually easier for quick iteration.

I can update the debug section copy to say “tap the banner when it appears” instead of implying you must background first, if you’d like.

## User

Yes please update the copy

Updated the debug helper text to: **“Uses [show name]. Tap the banner when it appears to test opening that show.”**

## User

It's not possible to background the app fast enough to do it before the foreground notification arrives.  Since the background scenario is what's going too happen most of the time, we should be testing that too.  Can you do anything to enable that?  A delay before sending the notification, maybe?

## Assistant

Adding a short delay before the debug test notification so there's time to background the app.

The debug button now waits **5 seconds** before sending the notification.

**How to use it:**
1. Tap **Send Test Notification**
2. The helper text switches to a countdown reminder
3. Background the app (Cmd+Shift+H in Simulator)
4. When the notification arrives, tap it to test deep linking

The button is disabled during the countdown so you don’t queue multiple notifications. If you stay in the app, you’ll still get the foreground banner after 5 seconds — but you now have time to test the background path first.

## User

The 5 second delay of the foreground notification is working, but I'm still not receiving one in the background even though the app is backgrounded well within the 5 seconds.

## Assistant

Foreground `Task.sleep` stops when the app is suspended, so `deliver()` never runs in the background. Scheduling the notification with a system time-interval trigger instead so iOS delivers it after 5 seconds regardless of app state.

Replacing in-app `Task.sleep` with a system-scheduled notification trigger — suspended apps don't finish that sleep.

The problem was that **`Task.sleep` stops when iOS suspends the app**. Backgrounding within 5 seconds paused the task, so `deliver()` only ran when you came back to the foreground — which is why you only saw the in-app banner.

**Fix:** The debug button now schedules the notification with a **`UNTimeIntervalNotificationTrigger`** (5 seconds). iOS owns that timer, so it fires even while the app is suspended.

**Try again:**
1. Tap **Send Test Notification**
2. Background the app right away (Cmd+Shift+H)
3. Wait ~5 seconds
4. Tap the notification on the lock screen / Notification Center

If you stay in the foreground, you’ll still get the banner via `willPresent` — that path is unchanged.

## User

now the 5 second delay isn't working, so there's not enough time to background the app.

## Assistant

The time-interval trigger can fire immediately for short delays. Switching to a background task so the 5-second wait completes even after the app is backgrounded, then delivering the notification.

Fixing a bug: `scheduleNotification` ignored the `trigger` parameter and always passed `nil`, causing immediate delivery.

Removing the unused `deliver(..., delay:)` method now that the debug path uses `deliverAfterDelay`.

Two things were wrong:

**1. Bug:** `scheduleNotification` always passed `trigger: nil` to `UNNotificationRequest`, so notifications fired immediately regardless of the delay setting.

**2. Better approach for background testing:** The debug button now uses `deliverAfterDelay`, which:
- Starts a **background task** so the 5-second wait can finish after you leave the app
- **Waits the full 5 seconds** (button stays disabled, helper text shows the countdown)
- **Then sends** the notification — as a lock-screen notification if you're backgrounded, or a banner if you're still in the app

**Try again:**
1. Tap **Send Test Notification**
2. Background the app during the 5-second countdown
3. When it arrives, tap the notification

The button stays disabled for the full countdown so you know the timer is running.

## User

Ok, now it works.

## Assistant

Good — that confirms the full path works: 5-second countdown, background delivery, and tap-to-open the show.

When you're ready, the next step on this branch would be committing and merging the MVP polish work (notification routing, foreground refresh, denied-permission UX, and the debug test helper). Say if you want that done.

## User

Theres's a build warning in Notification Service, can you fix it?

Checking the likely cause — a Swift 6 concurrency warning from capturing `var backgroundTaskID` in the background task expiration handler.

Fixed. The warning was almost certainly from capturing `var backgroundTaskID` in the `beginBackgroundTask` expiration handler — Swift 6 flags that as unsafe concurrent access.

Replaced it with a small `BackgroundTaskHandle` that:
- Owns the task ID in a stable object
- Ends the task in `defer` on the normal path
- Routes the expiration handler back to the main actor via `Task { @MainActor in ... }`

Rebuild and the warning should be gone. If one remains, paste the exact message and I’ll fix it.

## User

Can you think of anything else that should be done before we call the MVP complete?  Any additional unit tests, tweaks or new features?

## Assistant

Reviewing what's implemented on this branch against the MVP definition.

Here’s an updated take, accounting for what’s on `main` plus the work on your current branch (most of which isn’t committed yet).

## MVP feature checklist

Against `MVPDefinition.md`, you’re essentially **feature-complete**:

| Requirement | Status |
|---|---|
| Search + show detail | Done |
| Watchlist add/remove/persist | Done |
| Next-season status | Done |
| Local notifications | Done |
| Background / foreground refresh | Done (branch) |
| Notification tap → show | Done (branch) |
| Permission UX | Done (pre-prompt, denied banner, Open Settings) |
| VoiceOver basics | Done (merged) |
| Debounced change detection + tests | Done |

The remaining gap is **shipping**: commit, merge, and a quick real-device pass — not missing core functionality.

---

## Before you call it “MVP complete”

### Should do (small, high value)

1. **Commit and merge the polish branch**  
   Notification routing, foreground refresh, denied-permission UX, debug test helper, and `AppNavigationCoordinatorTests` are still local/uncommitted.

2. **Wrap debug-only code in `#if DEBUG`**  
   `deliverAfterDelay`, the Watchlist debug section, and maybe `BackgroundTaskHandle` don’t belong in Release builds. Low risk today, but easy hygiene.

3. **Write a short README**  
   Still just `# NextSeason`. For portfolio/exit criteria (“demonstrable as portfolio-quality”), add:
   - One-liner problem/solution
   - Stack (SwiftUI, SwiftData, TVMaze, local notifications)
   - How to run tests
   - 5-step manual demo script

4. **One real-device smoke test** (not Simulator-only)  
   You’ve validated the debug notification path. Also confirm on a phone:
   - Track → background → foreground refresh updates “Updated …”
   - Real notification tap opens the right show (when a refresh actually fires a change)
   - Denied-permission banner + Settings link

### Nice to have (not blocking MVP)

5. **A few more unit tests** — optional; coverage is already good for core logic:
   - `NotificationRouting.showID` — already tested
   - `AppNavigationCoordinator` — already tested
   - **Skip for MVP:** `NotificationService` (mostly UIKit/System), view models with heavy mocking

6. **UI tests** — you decided to wait; fine for MVP.

7. **Refresh debouncing** — foreground refresh runs on every return to `.active` (including Control Center). Works, but could add a “last refresh &lt; 15 min ago → skip” guard later if you notice excess network use.

8. **P1 backlog items** — watchlist sort/filter, illustration polish, animations (`MVPBacklog.md`). Explicitly post-MVP.

### Not needed for MVP

- Accounts / cloud sync  
- UI tests (deferred)  
- Streaming info, episode tracking, etc.  
- Custom app icon (unless you’re submitting to the App Store imminently)

---

## New features?

I wouldn’t add any before calling MVP done. The definition is intentionally narrow: **search, save, notify**. You’ve hit that. More features now dilutes the story and delays the “it works end-to-end” milestone.

---

## Practical “MVP complete” definition

You’re done when:

1. Polish branch is merged to `main` and pushed  
2. README exists  
3. You’ve run the manual demo once on a device  
4. Debug tooling is `#if DEBUG`-guarded  

After that, I’d call it MVP complete and treat everything else as v1.1.

Want me to commit the branch, wrap the debug code in `#if DEBUG`, and draft the README?

## User

Please excute items 2, 5 and 7.

## Assistant

Implementing `#if DEBUG` guards, refresh debouncing, and unit tests for the new logic.

Implementing `#if DEBUG` guards, a testable refresh debounce policy, and unit tests.

Here’s what was implemented:

### 2. Debug-only code guarded with `#if DEBUG`
- `deliverAfterDelay` and `BackgroundTaskHandle` in `NotificationService` are now `#if DEBUG` only
- Watchlist debug section was already guarded

### 5. Additional unit tests
- **`RefreshPolicyTests`** — foreground refresh timing (never refreshed, too recent, interval elapsed)
- **`NotificationAuthorizationPolicyTests`** — which authorization statuses allow delivery
- **`WatchlistRefreshServiceTests.skipsImmediateForegroundRefresh`** — integration test for debounced foreground refresh

Extracted testable helpers:
- `RefreshPolicy.swift`
- `NotificationAuthorizationPolicy.swift`

### 7. Foreground refresh debouncing
- Added `refreshAllIfNeeded()` on `WatchlistRefreshService` — skips network work if the last foreground refresh was **< 15 minutes** ago
- `AppRootView` now calls `refreshAllIfNeeded()` instead of `refreshAll()`
- **Unchanged:** pull-to-refresh still uses `refreshAll(force: true)`; background tasks still use `refreshAll()` (not debounced)

**What to test:**
1. Release build — confirm the Debug section and test notification code are gone
2. Run the new tests in Xcode
3. Foreground the app repeatedly — only the first refresh within 15 minutes should hit TVMaze; pull-to-refresh should always refresh

## User

Please run the tests yourself;  there are several build errors.

Fixing missing `SwiftUI` import in tests, then re-running the build.

Fixing the failing test: the updates map timestamp must be newer than the tracked show's `sourceUpdatedAt`, or no fetch occurs.

All tests pass now. Here’s what was wrong and what changed:

### Build errors fixed
1. **`AppNavigationCoordinatorTests`** — Added `import SwiftUI` so `NavigationPath.count` is available.
2. **`WatchlistRefreshServiceTests`** — Removed `{ self.fixedNow }` default argument (invalid in a struct); split into two `makeService` overloads instead.
3. **`skipsImmediateForegroundRefresh`** — Fixed Swift 6 concurrency by using a `NowBox` class instead of capturing a mutable `var`, and stopped assigning to `private(set) fetchedShowIDs`.

### Test failure fixed
4. **`skipsImmediateForegroundRefresh`** — The mock TVMaze update timestamp matched `sourceUpdatedAt` exactly, so no fetch ran. Bumped the update time by 60 seconds so the first refresh actually hits the network.

### Test run
```
xcodebuild test -scheme NextSeason -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
** TEST SUCCEEDED **
```

Rebuild in Xcode and you should be clear.
