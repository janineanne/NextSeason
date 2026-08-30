# StoreKit lifecycle issues

## User

Please fix the two remaining StoreKit lifecycle issues in the storekit-integration branch.

1. Start observing Transaction.updates before refreshing entitlements

In PurchaseService.start(), the current startup order creates a window where StoreKit transaction updates could occur before the transaction observer has been installed.

Change the startup lifecycle so that observation of Transaction.updates begins before the initial refreshEntitlements() call.

Requirements:

* Establish the Transaction.updates listener as early as practical in the purchase-service lifecycle.
* The listener must be active before the initial entitlement refresh.
* Preserve the existing behavior that verified transactions are processed before calling finish().
* Preserve handling of delayed/pending consumable tips.
* Do not introduce duplicate transaction processing or multiple transaction observer tasks if start() can be called more than once.
* Make sure the observer task is correctly owned/cancelled according to the existing PurchaseService lifecycle.
* Do not otherwise restructure the StoreKit implementation unnecessarily.

Add or update tests where practical to verify that startup establishes transaction observation before entitlement refresh and that repeated startup cannot create duplicate observers.

2. Refresh subscription entitlement when the app becomes active

The current implementation does not reliably notice a Plus subscription expiring while the app process remains alive.

Transaction.updates should not be treated as a reliable notification that a subscription has simply expired. The existing entitlementLossWhileRunning() test currently hides this problem by manually emitting a transaction after changing the stub entitlement state.

For NextSeason, use the simpler lifecycle solution rather than adding a Product.SubscriptionInfo.Status.updates observer:

* Whenever the app becomes active, refresh StoreKit entitlements by calling the appropriate PurchaseService entitlement-refresh API.
* Integrate this with the existing SwiftUI/app lifecycle handling rather than creating an unrelated lifecycle mechanism.
* Avoid unnecessary duplicate entitlement refreshes during initial launch if the existing startup sequence and scene activation would cause them back-to-back. If avoiding the duplicate would add substantial complexity, correctness is more important than eliminating one harmless StoreKit query.
* Entitlement loss must update PurchaseService state so the existing free-tier/grandfathering behavior takes effect.
* Do not change the existing product rule for a lapsed Plus subscription.
* Do not rely on receiving a Transaction.updates event to detect expiration.

Fix the tests so that entitlement-loss coverage accurately represents this behavior. In particular, replace or modify entitlementLossWhileRunning() so it does not manufacture an unrelated transaction merely to trigger refreshEntitlements(). Test the actual lifecycle/refresh path that production code will use.

General requirements

Keep the changes narrowly scoped to these two issues. Preserve the StoreKit behavior and fixes already present on this branch, including:

* unresolved initial entitlement state
* waiting for entitlement resolution before enforcing the watchlist limit
* processing verified transactions before finish()
* pending/delayed purchase handling
* consumable tip acknowledgement
* duplicate tip acknowledgement protection
* restore behavior
* existing lapse/grandfathering policy

Run the relevant unit tests and the full test suite after making the changes. Fix any regressions caused by these changes.

Please summarize exactly what you changed and call out any design decisions or test limitations.

## Assistant

I'll start by reading the Swift skills and the current StoreKit purchase-service lifecycle so we can fix observation order and app-active entitlement refresh without widening the change.

Skills used: `swift-concurrency-pro`, `swiftui-pro`, `swift-testing-pro`. Next I’ll inspect PurchaseService startup, the StoreKit client, and how the app becomes active.

I have a clear picture of both lifecycle gaps. Next I’ll start transaction observation before the first entitlement refresh, and refresh entitlements from the existing scene-active path.

I’ll reorder observation ahead of entitlement refresh, then hook that refresh into the existing scene-active path and add tests for both.

Purchase tests first, then the full suite. I’ll look up a simulator destination and run them.

Both StoreKit lifecycle issues are fixed on `storekit-integration`. Observation now starts before the first entitlement read, and Plus is re-checked when the app becomes active instead of waiting for a transaction update.

Skills used: `swift-concurrency-pro`, `swiftui-pro`, `swift-testing-pro`.

## What changed

**1. `Transaction.updates` is observed before the first entitlement refresh**

In `PurchaseService.start()`, the order is now:

1. Install the transaction observer (once)
2. Evaluate grandfathering
3. `refreshEntitlements()`
4. Load products

Previously the observer was installed *after* the first `currentEntitlements` pass, so Ask to Buy completions, unfinished transactions, or delayed tips could arrive in that window and be missed.

`startObservingTransactionsIfNeeded()` still uses the existing `didStartObserving` flag, so a second `start()` does not create another observer. The live `StoreKitPurchaseStoreClient` still owns the `Transaction.updates` task and cancels it if observation is started again. Verified transactions are still processed before `finish()`, including delayed consumable tips.

**2. Entitlements refresh when the scene becomes active**

`AppRootView` now calls `purchaseService.handleSceneBecameActive()` from the existing `scenePhase == .active` handler (the same path that already refreshes the watchlist). That re-reads `currentEntitlements` so a lapsed annual subscription is noticed when the user returns to the app, without relying on `Transaction.updates` and without adding a `Product.SubscriptionInfo.Status.updates` observer.

`handleSceneBecameActive()` skips the query while entitlement state is still `.loading`, so it does not pile a second StoreKit read on top of `start()`. After the first resolution, later activations always refresh. Lapse still uses the existing rule: keep tracked shows, block new adds above the free limit.

## Tests

`PurchaseServiceTests` now covers:

- Observation is installed before the first entitlement read, and a delayed tip is still processed during that in-flight refresh
- Calling `start()` twice does not install a second observer
- Entitlement loss via `handleSceneBecameActive()` (no manufactured transaction)
- Scene activation does not start a second entitlement query while startup is still loading

`entitlementLossWhileRunning()` no longer emits a fake Plus transaction to force a refresh. It flips the stub entitlement and calls the same `handleSceneBecameActive()` path production uses.

## Design decisions

- Observation still starts in `start()` (from the existing SwiftUI `.task`), not in `PurchaseService.init()`. That keeps previews/tests that never call `start()` from spinning up a StoreKit listener. There is still a short window between composition-root creation and that `.task`.
- Foreground refresh is a small `PurchaseService` API used by the existing scene-phase handler, not a new lifecycle system.
- Duplicate launch refresh is avoided only while state is `.loading`. If `start()` has already resolved and then the first `inactive → active` fires, one extra StoreKit query is possible and accepted.

## Test limitations

- Unit tests cover `handleSceneBecameActive()`, not SwiftUI delivering `scenePhase` itself. `AppRootView` is a private scene host, so that wiring is not exercised by `NextSeasonTests`.
- Expiration while the app stays continuously in the foreground is still unnoticed until the next activation. That matches the chosen simpler approach.

## Verification

- `PurchaseServiceTests`: **20 passed**
- Full `NextSeasonTests`: **269 passed**
- `git diff --check` is clean for these files

Nothing was committed.

**What to try in the app:** launch, confirm Plus still resolves; background and return after changing sandbox subscription state, and confirm the free-tier cap applies without needing a new transaction.

## User

One more thing to fix:

PurchaseStoreClient has stopObservingTransactionUpdates(), and the live client stores its observer Task, but nothing ever explicitly calls stopObservingTransactionUpdates(). Because the production PurchaseService is effectively app-lifetime this isn’t a functional problem. If a composition root were discarded and rebuilt in-process, the abandoned task could remain suspended until another transaction arrives; its [weak self] prevents it from incorrectly processing the transaction once its client is gone. A deinit cancellation would make ownership mathematically tidy.

## Assistant

I'll add deinit cancellation so the observer task is owned for the client's full lifetime, and check the MainActor/`deinit` constraints before changing it.

I’ll cancel observation in `deinit` on both the service (protocol stop) and the live client (the stored `Task`), using Swift 6.2 `isolated deinit` so MainActor teardown is valid.

Observation is now stopped when the purchase objects go away. That was a teardown-ownership gap, not a launch bug: production `PurchaseService` lives for the whole app, so the missing stop never showed up in normal use.

Skills used: `swift-concurrency-pro`, `swift-testing-pro`.

**`PurchaseService`** now calls `store.stopObservingTransactionUpdates()` from `isolated deinit`. That is the explicit protocol stop that was missing.

**`StoreKitPurchaseStoreClient`** also cancels its stored `Transaction.updates` task from `isolated deinit`. If a composition root is discarded in-process, the task is cancelled immediately instead of sitting suspended until the next StoreKit event (when `[weak self]` would have made it a no-op anyway).

Both use Swift 6.2 `isolated deinit` so teardown can touch MainActor state. The live client still cancels any previous task if observation is started again.

**Test:** `releasingPurchaseServiceStopsObservation()` checks that dropping `PurchaseService` after `start()` clears the stub observer. It cannot prove live StoreKit task cancellation; that stays on the real client.

`PurchaseServiceTests` (21) and full `NextSeasonTests` (270) both passed.

