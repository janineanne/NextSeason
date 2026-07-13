# Test notifications show information

## User

There's no way for me to test that tapping on a notification works properly.  The test notifications sent from Diagnostics don't have show information in them.  Can you use the show information for one of the shows on the watchlist for the test notifications, if there are any?

## User

Ok, I think I see the problem.  I was expecting the show detail page to open, not the watchlist with the show on it.  I think that's what should happen, even if that's not what it was written to do.

## User

I'm still landing on the Watchlist

## User

That works, but in both the background and fully quit scenarios you can see the detail page being pushed onto the nav stack as the app comes to the foreground.  Is there any way to prevent this?

## User

Yes, let's have #3 keep its animation.  1 and 2 look good now.

## Assistant

Build and all tests pass. 

## Summary
`applyPendingWatchlistDetail(animated:)` now takes an `animated` flag:
- `WatchlistView.onAppear` → `onApplyPendingDetail(false)`: launch/foreground path, pushed with animations disabled so the detail page is already in place (#1, #2).
- `WatchlistView.onChange(of: pendingDetailToken)` → `onApplyPendingDetail(true)`: in-app deep link while already on the Watchlist, animated like a normal navigation (#3).

```50:69:/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AppNavigationCoordinator.swift
    func applyPendingWatchlistDetail(animated: Bool) {
        guard let tracked = pendingWatchlistDetail else { return }
        pendingWatchlistDetail = nil
        guard animated else {
            // Launch / foreground: push without animation so the detail page is
            // already in place, rather than visibly sliding in.
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

## What to test
1. Backgrounded → tap notification → detail already in place, no slide-in.
2. Fully quit → tap notification → detail in place on launch.
3. On the Watchlist tab, tap a test notification → detail animates in normally.

Want me to commit all of these changes now?

## User

#1 and #3 look good, but the animation is back in #2 and it shouldn't be.

## Assistant

Build and all tests pass.

## What changed
The animation decision no longer depends on which view callback fires (which was racy on cold launch). Instead, it's captured at the moment of the tap and carried through:

- `NotificationCenterDelegate.didReceive` reads `UIApplication.shared.applicationState`. If the app was already `.active` (you tapped a banner while using the app → #3), it routes with `animated: true`; otherwise (launch/background tap → #1/#2) `animated: false`.
- `NotificationRouting.routeToShow(showID:animated:)` carries the flag (and buffers it for cold-launch taps that arrive before the coordinator attaches).
- `AppNavigationCoordinator` stores the intent (`pendingNavigationAnimated` → `pendingWatchlistDetailAnimated`) and `applyPendingWatchlistDetail()` uses it, so whether `onAppear` or `onChange` triggers the push no longer affects the animation.
- `WatchlistView`/`ContentView` reverted to the simple no-argument apply.

This fixes #2: on cold launch the push is always non-animated regardless of whether the notification response arrives before or after the Watchlist tab mounts.

## What to test
1. Backgrounded → tap → detail already in place (no animation).
2. Fully quit → tap → detail in place on launch (no animation) — the one that regressed.
3. Already on the Watchlist tab, tap a foreground banner → detail animates in.

One caveat: this relies on `applicationState` being `.active` only for genuine in-app taps. In my testing reasoning that holds, but since I can't exercise the live foreground/background transitions here, please confirm all three on device/simulator.

Want me to commit everything now?

## User

Ok, that's working now but there's one other problem.  The notifications themselves only have the app name, nothing else.  Shouldn't they say "Show X has been updated" or something like that?

## Assistant

Build succeeds. Two things here — one is copy, and one is likely a device setting worth ruling out.

## Copy change
Notifications now lead with the show name so it's obvious which show updated:

```112:131:/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/StatusChangeDetector.swift
    /// The show name leads the notification so it's clear which show updated.
    var title: String { showName }

    var body: String {
        switch status {
        case .airing(let season):
            return "Season \(season) is now airing."
        case .scheduled(let season, let premiere):
            let date = premiere.formatted(date: .abbreviated, time: .omitted)
            return "Season \(season) premieres \(date)."
        case .announcedUndated(let season):
            return "Season \(season) announced — date to be confirmed."
        case .returningNoSeasonYet:
            return "Returning — watch for next season news."
        case .ended:
            return "This series has ended."
        case .unknown:
            return "There's a next season update."
        }
    }
```

A scheduled example now renders as:

```
NEXTSEASON
Severance
Season 3 premieres Mar 15, 2026.
```

## But note: the code was already setting a title + body
Even before this change, the title was `"Next season update"` and the body included the show name — both non-empty and assigned in `NotificationService.scheduleNotification` (`notification.title` / `notification.body`). So if you were literally seeing **only** the app name with no text under it, that's not the app dropping the content — it's almost certainly one of:

1. **Show Previews is off/limited.** Settings → Notifications → NextSeason → *Show Previews* set to "When Unlocked" (and you're on the lock screen) or "Never" hides the title/body and shows just the app name. Set it to **Always** to verify.
2. **Grouped/stacked notifications** collapsing on the lock screen — expand the stack to see each one's text.

Could you check the Show Previews setting and re-test? After rebuilding you should now see the show's name as the bold title with the update beneath it.

If you confirm it was the previews setting, the copy change still stands as an improvement. Want me to commit everything from this session once you've verified?

## User

You were right, I had previews turned off. Doh!  But the copy changes do seem like an improvement.

## Assistant

Glad that was it — easy to overlook. And good, I'll keep the copy change.

Here's everything from this session, ready to commit whenever you give the word:

- **Notification tap wiring** (`AppCompositionRoot`, `NextSeasonApp`, `ContentView`): register the tap coordinator from the view layer so routing targets the exact instance SwiftUI observes.
- **Deep link opens the detail page** (`AppNavigationCoordinator`, `WatchlistView`, `ContentView`): defer the push until the Watchlist stack is mounted so the show's detail screen actually opens.
- **Animation matches context** (`AppNavigationCoordinator`, `NotificationCenterDelegate`): in-app taps animate; launch/foreground taps land the detail already in place, decided by app-active state at tap time.
- **Notification copy** (`StatusChangeDetector`): lead with the show name.
- **Test update** (`AppNavigationCoordinatorTests`): reflects the two-phase deep-link behavior.

All builds pass and `AppNavigationCoordinatorTests` is green.

Want me to commit these now? If so, I'll stage these changes and write a single commit (I can split into a few commits if you'd prefer — e.g., wiring/navigation vs. copy).
