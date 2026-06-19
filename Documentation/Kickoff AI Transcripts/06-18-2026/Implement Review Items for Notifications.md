# Notification issues and improvements

## User

Please address these issues with notifications, found by ChatGPT:

1. Possible cold-launch routing race

NotificationRouting.install() happens inside a .task on the root view. If the app is launched from a notification tap, there is a risk the notification response arrives before the delegate/coordinator is ready.

I’d move notification delegate installation earlier, ideally during app startup, and make sure pending navigation is resolved on initial appearance as well as on change.

2. “Not Now” may prompt repeatedly

If the user adds a show, sees “Stay in the Loop,” and taps Not Now, the OS permission status remains .notDetermined. So the next tracked show may show the same prompt again.

I’d persist a lightweight “user deferred notification prompt” flag and avoid nagging too often.

3. Background refresh errors are swallowed

RefreshScheduler.scheduleNextRefresh() uses try?, so failures are invisible. That’s okay for MVP, but for beta/release I’d at least log failures in DEBUG.

4. Background task cancellation doesn’t mark failure

If the background refresh expires, the task is cancelled but setTaskCompleted(success: false) is not called in the expiration path. I’d fix that.

## Assistant

I'll locate the notification routing, permission prompt, and background refresh code so we can fix all four issues.

### Tool Semantic Search Full

```
{"query":"NotificationRouting install delegate coordinator","targetDirectories":[],"explanation":""}
```

### Tool Ripgrep Raw Search

```
{"pattern":"RefreshScheduler|scheduleNextRefresh","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_15a07f98-67b4-4b56-86dc-8633ee47da4","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Not Now|Stay in the Loop|notDetermined","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_05c8cd4b-836a-4b0b-8513-47ba607df21","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"setTaskCompleted|BGAppRefreshTask","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_378eed49-dd4d-4a8b-8298-8f8f833ce0e","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Notification*"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshScheduler.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Ripgrep Raw Search

```
{}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationCenterDelegate.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"shouldPromptForNotifications|dismissNotificationPrompt|queueShowNavigation|pendingShow","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_61cb65ad-77af-4773-88a0-6fcd094745d","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/AppNavigationCoordinator*"}
```

### Tool Glob File Search

```
{"globPattern":"**/ShowDetailViewModel*"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AppNavigationCoordinator.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonTests/AppNavigationCoordinatorTests.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"UserDefaults|@AppStorage","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_cf1a9933-e695-458e-8976-9f264415b15","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*ShowDetail*Test*"}
```

### Tool Read File V2

```
{"path":"/Users/janine/.claude/skills/swiftui-pro/SKILL.md","limit":80}
```

### Tool Ripgrep Raw Search

```
{"pattern":"Logger|os\\.log|print\\(","glob":"**/*.swift","caseInsensitive":false,"headLimit":30,"multiline":false,"toolCallId":"tool_8001ca01-96fd-49fc-b450-f4016808370","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"NotificationRouting|RefreshScheduler|NotificationCenterDelegate","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason.xcodeproj/project.pbxproj","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_147a8ab7-b796-4541-9f93-ec2f3fa233b","offset":0}
```

### Tool Glob File Search

```
{"globPattern":"**/*Test*.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"needsAuthorizationPrompt|NotificationService","glob":"**/*.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_fee55e7a-405b-4a08-93cb-b1c69e8c422","offset":0}
```

## Assistant

I'll implement all four fixes: install notification routing at startup, persist a deferred-prompt flag, add DEBUG logging for refresh scheduling, and mark background tasks failed on expiration.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Adding tests for buffered routing and clearing static state between tests.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationCenterDelegate.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/NextSeasonApp.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/RefreshScheduler.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"]}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationCenterDelegate.swift"}
```

## Assistant

All four issues are addressed. Summary of what changed and what to verify:

### 1. Cold-launch routing race
- **`NotificationRouting.install()` and `setCoordinator()`** now run in `NextSeasonApp.init()`, alongside background task registration — before any SwiftUI `.task`.
- **`NotificationRouting`** buffers a show ID if a tap arrives before the coordinator exists, then flushes when the coordinator is attached.
- **`ContentView`** resolves pending navigation on first appearance (`.task`), not only via `.onChange` — so cold-launch taps aren’t missed when `pendingShowID` is already set.

### 2. “Not Now” repeated prompts
- Tapping **Not Now** on “Stay in the Loop” calls **`deferAuthorizationPrompt()`**, which persists a `UserDefaults` flag.
- **`needsAuthorizationPrompt()`** returns `false` when that flag is set, so tracking another show won’t re-show the prompt while OS status stays `.notDetermined`.

### 3. Background refresh scheduling errors
- **`RefreshScheduler.scheduleNextRefresh()`** replaces `try?` with a `do/catch` that **`print`s failures in DEBUG** builds.

### 4. Background task expiration
- The expiration handler now calls **`setTaskCompleted(success: false)`** after cancelling work.
- The success path checks **`!Task.isCancelled`** so completion isn’t reported twice if expiration wins the race.

### What to test
1. **Cold launch from notification** — tap a notification when the app isn’t running; it should open the correct show detail.
2. **Track a show → Not Now → track another show** — the “Stay in the Loop” alert should not appear again.
3. **Background refresh** (DEBUG) — if scheduling fails (e.g. missing BGTask identifier in Info.plist during dev), check the Xcode console for the log line.
4. **Existing unit tests** — run `NextSeasonTests`; a new test covers buffered notification routing.

I couldn’t run `xcodebuild` here (only Command Line Tools are active, not full Xcode). Please run the test suite locally in Xcode to confirm.

## User

I tapped the test notification button, then killed the app.  No notification was received.  Should it be?  I don't remember if local notification are sent when the app is dead, not just in the background.

## Assistant

I'll trace how the test notification button schedules delivery and whether it survives app termination.

### Tool Ripgrep Raw Search

```
{"pattern":"test notification|deliverAfterDelay|testNotification","glob":"**/*.swift","caseInsensitive":true,"multiline":false,"toolCallId":"tool_b5ee3231-94b1-445a-b4fd-4feb9ed83f5","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"DEBUG.*notification|notification.*DEBUG","glob":"**/*.swift","caseInsensitive":true,"multiline":false,"toolCallId":"tool_2997a9de-87d7-40f7-abff-bab1508d769","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":100,"limit":60}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","offset":73,"limit":50}
```

## Assistant

Yes — **local notifications can arrive when the app is fully killed**, but **your debug test button does not work that way today**.

### How iOS local notifications work

When you add a `UNNotificationRequest` to `UNUserNotificationCenter` with a **trigger** (e.g. `UNTimeIntervalNotificationTrigger`), the **system** owns the schedule. It can fire even if:

- the app is in the background
- the app is suspended
- the app was force-quit from the app switcher

That’s how real “notify me in 10 seconds / on release date” alerts are meant to work.

### What your test button actually does

The debug path uses `deliverAfterDelay`, which:

1. `Task.sleep`s for 10 seconds **inside the app process**
2. uses `beginBackgroundTask` so that sleep can finish if you **background** the app
3. only then calls `scheduleNotification(..., trigger: nil)` — immediate delivery

So the notification is **not scheduled with the system until after that sleep finishes**. If you kill the app during the countdown:

- the process dies
- the sleep/task is cancelled
- `scheduleNotification` never runs
- **no notification**

That matches the UI copy, which says to **background** the app, not kill it.

### Expected behavior for your test

| App state during 10s wait | Should notification arrive? |
|---|---|
| Foreground | Yes |
| Background (home button / swipe up to leave, app still in switcher) | Yes, usually (background task) |
| Force-quit / killed from app switcher | **No** with current implementation |

### Production notifications

Season-change alerts from refresh/polling should still work when the app is dead, **as long as** they’re added via `UNUserNotificationCenter` while the app is running (foreground or background refresh). They don’t depend on the app staying alive at delivery time.

If you want the debug button to survive a force-quit, it should schedule upfront with something like:

```swift
UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
```

instead of sleeping in-process. I can change the test button to do that if you want.

## User

Go ahead

## Assistant

I'll switch the debug test notification to a system-scheduled `UNTimeIntervalNotificationTrigger` so it can fire after the app is killed.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":105,"limit":55}
```

## Assistant

Replacing in-process sleep with a system `UNTimeIntervalNotificationTrigger`, and updating the debug UI copy.

### Tool Edit File V2

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift"]}
```

## Assistant

The test notification now uses a **system-scheduled trigger** instead of an in-app timer.

### What changed
- **`deliverAfterDelay`** schedules a `UNTimeIntervalNotificationTrigger` via `UNUserNotificationCenter` and returns immediately — no `Task.sleep`, no background task.
- **Debug copy** now says you can background **or quit** the app during the countdown.

### How to test
1. Watchlist → **Send Test Notification**
2. Immediately background or force-quit the app
3. After ~10 seconds, the notification should still arrive
4. Tap it to confirm deep-link routing still works

Note: notification permission must already be granted; scheduling still fails silently if alerts are off (same as before).

## User

Can you add that caveat about notifications needing to already be allowed to the instructions?

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Watchlist/WatchlistView.swift","offset":125,"limit":40}
```

### Tool Edit File V2

## Assistant

Done. The debug instructions now end with: **“Notifications must already be allowed in Settings.”**
