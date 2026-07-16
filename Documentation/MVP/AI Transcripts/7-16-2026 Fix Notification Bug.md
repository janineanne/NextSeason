# Watchlist notification bug

## User

One of my beta testers has found a bug.  If you add a show to the watchlist by tapping its star on the search results list, you will get the "Stay in the Loop?" alert and then the system notificiation permission alert.  But if you do it from the show's detail page, you only get the first one. The system dialog doesn't show up so notifications aren't enabled.

## Assistant

I'll investigate this notification permission bug. Let me explore the relevant code.

### Tool Ripgrep Raw Search

```
{"pattern":"Stay in the Loop","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_01145DJQ2W62FdFD9hMZYR8p","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"requestAuthorization|UNUserNotificationCenter|requestNotification","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_01LQxN9s8GNs98LpgNB5wFxj","offset":0}
```

## Assistant

Let me look at the key files for both flows.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/WatchlistNotificationPromptState.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift"}
```

## Assistant

Now let me look at how the alerts are wired in the detail view versus the search view.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift"}
```

## Assistant

Let me look at the NotificationService implementation.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/NotificationService.swift"}
```

## Assistant

Now let me see how the search flow triggers the prompt, for comparison.

### Tool Ripgrep Raw Search

```
{"pattern":"shouldPromptForNotifications|WatchlistNotificationPromptState|watchlistNotificationPromptAlerts|confirmPrompt","glob":"*.swift","outputMode":"content","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_01A3aEAJ6BNrsKDq122TfK2s","offset":0}
```

## Assistant

I found the bug. Let me explain the root cause before fixing it.

## Root cause

Both flows ultimately call `NotificationService.requestAuthorizationIfNeeded()`, which bails out early if the prompt was previously deferred:

```150:151:NextSeason/Services/NotificationService.swift
    func requestAuthorizationIfNeeded() async -> Bool {
        guard !userDefaults.bool(forKey: Self.deferredPromptKey) else { return false }
```

In the **detail page**, the "Stay in the Loop" alert uses a custom binding whose setter calls `dismissNotificationPrompt()` whenever the alert is dismissed — for *any* reason, including tapping **Enable Notifications**:

```137:144:NextSeason/Features/ShowDetail/ShowDetailView.swift
    private func notificationPromptBinding(viewModel: ShowDetailViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.shouldPromptForNotifications },
            set: { isPresented in
                if !isPresented { viewModel.dismissNotificationPrompt() }
            }
        )
    }
```

And `dismissNotificationPrompt()` records a deferral:

```126:129:NextSeason/Features/ShowDetail/ShowDetailViewModel.swift
    func dismissNotificationPrompt() {
        shouldPromptForNotifications = false
        notifications.deferAuthorizationPrompt()
    }
```

So when the user taps **Enable Notifications**, SwiftUI dismisses the alert and the binding setter runs `dismissNotificationPrompt()` → `deferAuthorizationPrompt()` sets the deferred flag. That runs before/races the `confirmNotificationPrompt()` task, so `requestAuthorizationIfNeeded()` hits the `guard` and returns immediately — the system dialog never appears.

The **search flow** works because it binds directly to the plain property (`$prompt.shouldPromptForNotifications`) and only defers via the explicit "Not Now" button — dismissing for other reasons doesn't defer.

## Fix

Make the detail flow's binding setter only clear the flag (without deferring), matching the search flow. Deferral stays on the explicit "Not Now" button. Let me add a flag-only reset method and use it in the binding.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Let me verify the changes are consistent and check for related tests.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":85,"limit":20}
```

### Tool Ripgrep Raw Search

```
{"pattern":"dismissNotificationPrompt|confirmNotificationPrompt|resetNotificationPromptFlag","glob":"*Tests*.swift","outputMode":"content","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_01SE2CLAoEFrBsGQLCvJS8Yp","offset":0}
```

## Assistant

The changes are complete and consistent. No tests reference the changed methods.

## Summary

**The bug:** On the detail page, the "Stay in the Loop" alert used a custom `isPresented` binding whose setter called `dismissNotificationPrompt()` — which records a *deferral* — on *any* dismissal, including tapping **Enable Notifications**. That deferral flag then short-circuited `requestAuthorizationIfNeeded()`, so the system permission dialog never appeared. The search flow was unaffected because it binds directly to the plain property and only defers via its explicit "Not Now" button.

**The fix (2 small edits):**
- `ShowDetailViewModel.swift`: added `resetNotificationPromptFlag()`, which clears `shouldPromptForNotifications` *without* deferring.
- `ShowDetailView.swift`: the "Stay in the Loop" alert's binding setter now calls `resetNotificationPromptFlag()` instead of `dismissNotificationPrompt()`. Deferral still happens only when the user explicitly taps **Not Now** (which calls `dismissNotificationPrompt()`).

This makes the detail flow behave like the working search flow.

## What to test
1. Fresh state (delete app or reset notification permission so status is "not determined"). From a **show's detail page**, tap the star/track button → "Stay in the Loop" alert → tap **Enable Notifications** → confirm the **system permission dialog now appears**.
2. On the detail page, tap **Not Now** → verify no system dialog, and that you aren't re-prompted on subsequent adds (deferral still works).
3. Regression check the **search results** star-tap flow still shows both alerts as before.
4. Verify the "Notifications Not Enabled" fallback still appears if you deny at the system dialog.

One note: because permission is a one-time system prompt, each manual re-test needs a fresh "not determined" state (reinstall or reset in Settings).

## User

Since both flows do the same thing now, is there any code that should be abstracted out?

## Assistant

Good question — there's meaningful duplication now. Let me look at the search-side plumbing to ground a concrete recommendation.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchWatchlistTracking.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":90,"limit":25}
```

## Assistant

Yes — there's now clear duplication, and an abstraction already exists that the detail flow is essentially re-implementing by hand.

## The duplication

The search flow is built from two reusable pieces:
- `WatchlistNotificationPromptState` — the `@Observable` state + logic (`deferPrompt`, `confirmPrompt`, denied-reminder).
- `WatchlistNotificationPromptAlerts` view modifier (`.watchlistNotificationPromptAlerts`) — both alerts' UI.

The detail flow re-implements all of that inline:

| Concern | Search (shared) | Detail (duplicated) |
|---|---|---|
| Prompt flag | `WatchlistNotificationPromptState.shouldPromptForNotifications` | `ShowDetailViewModel.shouldPromptForNotifications` |
| Denied flag | `.shouldShowNotificationsDeniedAlert` | `ShowDetailViewModel.shouldShowNotificationsDeniedAlert` |
| Defer | `deferPrompt` | `dismissNotificationPrompt` |
| Flag-only reset | (binding sets property directly) | `resetNotificationPromptFlag` |
| Confirm + denied check | `confirmPrompt` | `confirmNotificationPrompt` + `shouldShowNotificationsSettingsReminder` |
| Open settings | (in modifier) | `openNotificationSettings` |
| Alert UI | `WatchlistNotificationPromptAlerts` | two `.alert` blocks + two `Binding` helpers in `ShowDetailView` |

Notably, the bug I just fixed only existed in the detail copy — the shared modifier already had the correct behavior. That's the classic argument for consolidating: the duplicate drifted and grew a bug.

## Recommendation

Have the detail flow reuse the existing pieces:

1. `ShowDetailViewModel` composes a `WatchlistNotificationPromptState` instead of its own flags/methods:
   - In `addToWatchlist`, replace `shouldPromptForNotifications = true` with `notificationPrompt.shouldPromptForNotifications = true`.
   - Delete `shouldPromptForNotifications`, `shouldShowNotificationsDeniedAlert`, `dismissNotificationPrompt`, `resetNotificationPromptFlag`, `confirmNotificationPrompt`, `shouldShowNotificationsSettingsReminder`, `dismissNotificationsDeniedAlert`, `openNotificationSettings`.
2. `ShowDetailView` drops both `.alert` blocks and the two binding helpers, and instead applies `.watchlistNotificationPromptAlerts(prompt: viewModel.notificationPrompt, notificationService: …)` — exactly like `SearchView`.

This deletes ~40 lines of duplicated logic/UI, guarantees both entry points stay behavior-identical, and makes the just-fixed bug structurally impossible to reintroduce in one place.

**One small consideration:** the modifier needs the `NotificationManaging` reference. The VM already holds it privately; I'd expose it (or have the view keep the reference it's already passed in `init`) so the modifier can be attached.

This is a refactor that touches the detail feature's view-model shape, so I wanted to confirm before changing it. Want me to go ahead and implement it?

## User

Yes

## Assistant

I'll implement the refactor. Let me first check how `SearchView` wires up the state and confirm the `NotificationManaging` reference available in `ShowDetailView`.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":1,"limit":40}
```

## Assistant

Now I'll refactor `ShowDetailViewModel` to compose the shared state and drop the duplicated members.

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Now remove the duplicated notification methods from the view model.

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift","offset":100,"limit":62}
```

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift","offset":128,"limit":35}
```

### Tool Edit File V2

## Assistant

Now update `ShowDetailView` to use the shared modifier and drop the two `.alert` blocks and binding helpers.

### Tool Edit File V2

## Assistant

Now remove the two now-unused binding helper functions.

### Tool Edit File V2

## Assistant

Let me check for any remaining references to the removed members and confirm the build compiles.

### Tool Ripgrep Raw Search

```
{"pattern":"shouldPromptForNotifications|shouldShowNotificationsDeniedAlert|dismissNotificationPrompt|confirmNotificationPrompt|resetNotificationPromptFlag|dismissNotificationsDeniedAlert|openNotificationSettings|notificationPromptBinding|notificationsDeniedBinding","glob":"*.swift","outputMode":"content","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_01Cm8qLdW4NeZwRQHUwqGo3M","offset":0}
```

## Assistant

Let me check the ShowDetailViewModel tests for any references to the changed API.

### Tool Glob File Search

```
{}
```

### Tool Ripgrep Raw Search

```
{"pattern":"notificationPrompt|ShowDetailViewModel","glob":"**/*Tests*.swift","outputMode":"files_with_matches","caseInsensitive":false,"multiline":false,"toolCallId":"toolu_bdrk_0169BE7BnPcb7fzKq9QUbCx4","offset":0}
```

### Tool Glob File Search

```
{}
```

### Tool Glob File Search

```
{}
```

### Tool Glob File Search

```
{"globPattern":"**/*ShowDetail*.swift"}
```

## Assistant

No dedicated ShowDetail tests reference the changed API. Let me do a final review of both edited files.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailViewModel.swift","offset":1,"limit":50}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/ShowDetail/ShowDetailView.swift","offset":80,"limit":30}
```

## Assistant

Both files look correct. Let me verify it compiles by building the app.

### Tool Run Terminal Command V2

## Assistant

The build failed only due to sandbox restrictions writing to `DerivedData` (outside the workspace) — not a code error. Let me rerun outside the sandbox.

### Tool Run Terminal Command V2

## Assistant

The build succeeds. The refactor compiles cleanly.

## Summary

Consolidated the detail flow onto the existing shared notification-prompt abstraction, eliminating the duplicated state, logic, and alert UI.

**`ShowDetailViewModel.swift`**
- Replaced the hand-rolled `shouldPromptForNotifications` / `shouldShowNotificationsDeniedAlert` flags and the methods `dismissNotificationPrompt`, `resetNotificationPromptFlag`, `confirmNotificationPrompt`, `shouldShowNotificationsSettingsReminder`, `dismissNotificationsDeniedAlert`, and `openNotificationSettings` with a single composed `let notificationPrompt = WatchlistNotificationPromptState()` (the same type search uses).
- `addToWatchlist` now sets `notificationPrompt.shouldPromptForNotifications = true`.
- Added a small `notificationService` accessor so the view can hand the service to the shared modifier.

**`ShowDetailView.swift`**
- Removed both inline `.alert` blocks ("Stay in the Loop" / "Notifications Not Enabled") and the two custom `Binding` helpers.
- Applied the shared `.watchlistNotificationPromptAlerts(prompt:notificationService:)` modifier, exactly like `SearchView`.

Net effect: ~50 lines of duplicated logic/UI deleted, both entry points now share one implementation, and the permission-dialog bug can't diverge between the two paths again.

## What to test
1. **Detail page**, fresh permission state: track a show → "Stay in the Loop" → **Enable Notifications** → system dialog appears (the original bug, still fixed).
2. **Detail page**: **Not Now** defers correctly (no dialog, no re-prompt on later adds); deny at the system dialog → "Notifications Not Enabled" → **Open Settings** opens the right screen.
3. **Search results** star-tap flow still behaves as before (regression check).
4. Confirm the "Coming Soon" actor-name alert on the detail page still works (it was left untouched alongside the removed alerts).

Note: each manual re-test of the system prompt needs a fresh "not determined" state (reinstall or reset in Settings).
