> From: https://chatgpt.com/c/6a8e69b3-93c0-83e8-8b31-2cf1e3c8b3e9

# you asked

message time: 2026-08-25 21:21:33

Please review the StoreKit implementation on branch storekit-integration.

---

# chatgpt response

I’ll inspect the uploaded branch snapshot, focus specifically on the StoreKit architecture and product-state behavior, then check for edge cases around entitlement updates, restores, purchase failures, and subscription lapse handling.

The implementation is nicely separated so far: StoreKit itself is behind a client protocol, while entitlement and watchlist-limit decisions live above it. I’m checking whether that clean separation holds under real StoreKit lifecycle events rather than just the happy path.

I’ve found one concrete UI/StoreKit race already: the tip jar displays fallback products as purchasable before StoreKit has actually loaded them. That can produce an immediate “product unavailable” failure—and can momentarily show hard-coded U.S. prices to users in other storefronts. I’m continuing through entitlement startup and test coverage now.

I reviewed the two commits on `storekit-integration` against `main`. The overall structure is good: StoreKit is isolated behind `PurchaseStoreClient`, `PurchaseService` owns observable entitlement state, and the free-tier rule is centralized in `WatchlistLimitPolicy`. I found **two issues I would fix before merging**, plus one smaller robustness improvement.

### 1. [P1] Don’t make fallback tip products purchasable

`TipJarSection` synthesizes three fallback `StoreProduct`s whenever `purchases.tipProducts` is empty:

```swift
private var displayedTips: [StoreProduct] {
    if purchases.tipProducts.isEmpty {
        return [
            StoreProduct(.tipTrailer),
            StoreProduct(.tipPilot),
            StoreProduct(.tipHitShow),
        ]
    }
    return purchases.tipProducts
}
```

Those buttons are live and call `purchases.purchase(product)`.

But `StoreKitPurchaseStoreClient.purchase()` can only purchase products previously returned by `Product.products(for:)` and stored in `productsByID`:

```swift
guard let product = productsByID[productID] else {
    throw PurchaseError.productUnavailable
}
```

So there are at least two reproducible cases where the UI offers a purchase that cannot work:

- The user opens About quickly while the initial StoreKit load is still running.
- StoreKit product loading fails, or returns the Plus products but no tip products.

They'll see `$1 / $3 / $5` buttons, tap one, and get *“That purchase option is not available right now.”*

There is also a storefront problem: those hard-coded fallback prices are U.S. dollar prices, not the user's localized App Store price.

I'd make the fallback products **preview/test-only**. In production, show a loading state until StoreKit returns the actual tips, and if it fails, either hide the Tip Jar or show an unavailable/retry state. `PlusStoreView` already handles this correctly by refusing to invent purchasable products.

**Files:** `TipJarSection.swift:37–45`, `StoreProductID.swift:46–55`, `StoreKitPurchaseStoreClient.swift:24–27`.

### 2. [P2] Existing Plus users can temporarily be treated as free at cold launch

`PurchaseService` begins with:

```swift
private(set) var isStoreEntitled = false
```

and the real entitlement isn't established until this asynchronous SwiftUI task completes:

```swift
.task {
    let count =
        (try? await composition.watchlistRepository.trackedShowIDs().count) ?? 0
    await composition.purchaseService.start(watchlistCount: count)
}
```

Meanwhile the entire UI is already interactive. `WatchlistTracking.add()` immediately uses:

```swift
guard purchases.canAddToWatchlist(currentCount: currentCount) else {
    return .paywallRequired
}
```

So consider a legitimate annual/lifetime customer who launches with three shows. Before `refreshEntitlements()` finishes, they tap a fourth show. `isStoreEntitled` is still `false`, so NextSeason can present the paywall to someone who already owns Plus.

It should resolve itself shortly afterward because `currentEntitlements` is exactly the right mechanism for discovering existing purchases; Apple specifically says StoreKit makes current entitlements available automatically on launch/new devices. ([Apple Developer](https://developer.apple.com/documentation/storekit/appstore/sync%28%29?changes=_1_1&language=objc&utm_source=chatgpt.com)) But there is still a real startup race.

I'd give entitlement resolution an explicit state, something like:

```swift
enum EntitlementState {
    case loading
    case free
    case unlimited
}
```

and don't enforce the free limit while state is `.loading`. You could either briefly disable Add when the user is at the limit, or have the add path await initial entitlement resolution. I prefer the latter because most users would never perceive any delay.

This deserves a unit test with a store whose `hasActivePlusEntitlement()` suspends, verifying that you don't conclude `.free` before it answers.

**Files:** `PurchaseService.swift:13`, `PurchaseService.swift:53–68`, `NextSeasonApp.swift:46–50`, `WatchlistTracking.swift:44–47`.

### 3. [P3] Finish transactions after updating the app's entitlement state

The live client currently does this on a direct purchase:

```swift
let transaction = try checkVerified(verification)
await transaction.finish()
return .success
```

and only afterward does `PurchaseService` call `refreshEntitlements()`.

The update listener does the same:

```swift
if let transaction = try? self.checkVerified(result) {
    await transaction.finish()
}
await onChange()
```

Apple's documented ordering is to validate the transaction, **deliver/unlock the purchased content, then finish it**; `finish()` means the app has enabled the purchased service. ([Apple Developer](https://developer.apple.com/documentation/storekit/finishing-a-transaction?changes=lates_7&language=objc&utm_source=chatgpt.com))

I don't see a likely data-loss bug here because Plus is derived from `currentEntitlements`, rather than stored only locally. A crash between `finish()` and `refreshEntitlements()` would still rediscover Plus next launch. So I would not block the merge solely on this.

Still, the abstraction makes the ideal ordering awkward: the StoreKit client owns the `Transaction`, while `PurchaseService` owns the actual unlock. I'd consider changing that so the transaction is finished only after the service has incorporated it, particularly before StoreKit behavior becomes more complicated.

One related edge case is an Ask-to-Buy/deferred **tip**. When the transaction eventually arrives through `Transaction.updates`, it gets finished, but `PurchaseService` only refreshes Plus entitlements; it never knows that this was a tip, so the later-approved tip receives no “Thank you” acknowledgement. That's mostly UX rather than entitlement correctness.

---

Everything else I examined looks sensible. In particular:

- `Transaction.currentEntitlements` is a good choice; Apple says it contains non-consumables and subscriptions currently subscribed or in grace period, so your annual subscription behavior handles grace periods properly. ([Apple Developer](https://developer.apple.com/documentation/storekit/transaction/currententitlements?changes=_2%2C_2&utm_source=chatgpt.com))
- `AppStore.sync()` is correctly used only behind an explicit Restore Purchases action. Apple specifically recommends that because it can prompt for App Store authentication. ([Apple Developer](https://developer.apple.com/documentation/storekit/appstore/sync%28%29?changes=_1_1&language=objc&utm_source=chatgpt.com))
- The lapse rule is implemented exactly as intended: existing shows remain, but no new additions are allowed while above the free limit.
- Lifetime, annual, and tips are correctly distinguished for entitlement purposes.
- Grandfathering being sticky once awarded is implemented cleanly.
- Both Search and Show Detail funnel through the same limit check, which avoids inconsistent behavior.
- The local StoreKit configuration has the expected annual subscription, lifetime non-consumable, and three consumables, all with Family Sharing off.
- `git diff --check` found nothing significant in the implementation itself—only trailing whitespace in one transcript and an extra EOF blank line in another.

The new unit tests are useful, but they're very happy-path-heavy. I'd add tests for **initial entitlement still loading**, **product-load failure/partial catalog**, **restore changing entitlement**, **pending purchase later becoming entitled**, and **transaction-update entitlement loss**. The latter matters for a subscription expiring while the app is running.

I couldn't execute the Xcode test suite here because this environment doesn't have `xcodebuild`, so this is a source-level review rather than a build/test verification.

**Bottom line:** I would fix **#1 and #2 before merging**. Neither requires rethinking the StoreKit design; the architecture itself is in good shape. #3 is worth cleaning up but could reasonably follow afterward.

---

# you asked

message time: 2026-08-25 21:26:23

Please write a prompt for Cursor to fix everything you found.  Best to clean it up right away.

---

# chatgpt response

Yes. I’d have Cursor fix all three now, including the transaction-finishing order and the deferred-tip UX, rather than leaving small StoreKit lifecycle problems behind.

**Document Title: **

Please fix the StoreKit issues identified in review of the current `storekit-integration` branch.

Preserve the existing architecture where practical and keep the changes focused. Do not do unrelated refactoring or formatting.

## 1. Remove purchasable fallback tip products

`TipJarSection` currently creates fallback `StoreProduct`s when `purchases.tipProducts` is empty. These contain hard-coded `$1`, `$3`, and `$5` prices and produce active purchase buttons even though the corresponding StoreKit `Product`s may not have loaded.

This creates two problems:

- A user can tap a fallback product before StoreKit has loaded it, causing `StoreKitPurchaseStoreClient.purchase()` to fail with `PurchaseError.productUnavailable`.
- The fallback prices are U.S.-specific rather than localized App Store prices.

Change this so production purchase UI is driven only by products actually loaded from StoreKit.

Requirements:

- Do not display an enabled purchase button for a product that StoreKit has not loaded.
- Do not display hard-coded prices as though they were actual App Store prices.
- Preserve whatever preview/test support is useful, but keep synthetic/fallback products out of the real production purchase path.
- Give the Tip Jar an appropriate loading/unavailable state rather than presenting fake purchasable products.
- If product loading can be retried cleanly, provide a reasonable retry path.
- Keep the behavior consistent with `PlusStoreView` where appropriate.

## 2. Eliminate the cold-launch entitlement race

`PurchaseService.isStoreEntitled` initially defaults to `false`. The real StoreKit entitlement is resolved asynchronously by `start()` after the SwiftUI UI is already interactive.

This means an existing Plus customer who launches with three or more tracked shows can attempt to add another show before `currentEntitlements` has been checked and incorrectly receive the free-tier paywall.

Represent unresolved StoreKit entitlement explicitly rather than treating "not checked yet" as "free."

A design such as:

```swift
enum EntitlementState {
    case loading
    case free
    case unlimited
}
```

is reasonable, but use whatever design fits the existing code best.

Requirements:

- During cold launch, do not classify the user as free until initial entitlement resolution has completed.
- A known Plus entitlement should continue to permit unlimited additions.
- A known non-entitled user should continue to use the existing free-tier/grandfathering rules.
- Do not simply allow unlimited additions indefinitely when StoreKit fails to load. Distinguish initial resolution/loading from a genuine failure and choose safe, understandable behavior.
- Prefer making the operation that needs entitlement information wait for initial entitlement resolution rather than flashing or presenting an incorrect paywall.
- Avoid introducing noticeable UI blocking for normal launches.
- Make sure all relevant paths use the same resolved entitlement state.

Add tests that deliberately suspend/delay initial entitlement resolution and verify that an existing Plus customer cannot be incorrectly classified as free while StoreKit is still resolving.

Also test the non-entitled case after resolution completes.

## 3. Correct transaction finishing order

Review the transaction lifecycle in `StoreKitPurchaseStoreClient`.

Currently a verified transaction is generally `finish()`ed before `PurchaseService` has incorporated the resulting entitlement change. StoreKit's intended lifecycle is:

1. Receive transaction.
2. Verify it.
3. Deliver/unlock the purchased content or otherwise incorporate the transaction.
4. Finish the transaction.

Refactor the StoreKit/client/service boundary as necessary so verified transactions are not considered finished until the application has processed the purchase appropriately.

This applies both to:

- transactions returned directly by `purchase()`
- transactions received later through `Transaction.updates`

Do not sacrifice the existing clean separation between StoreKit-specific code and application entitlement logic unnecessarily. Find the smallest clean design that gives the application an opportunity to process the verified transaction before it is finished.

Make sure transactions are eventually finished and cannot get stuck in an endless redelivery loop.

## 4. Handle deferred/pending tip completion gracefully

A tip can initially return `.pending` (for example, Ask to Buy) and later arrive through `Transaction.updates`.

Currently that later transaction is finished, but the application doesn't know that a consumable tip completed, so the user never receives the normal thank-you acknowledgement.

Make transaction updates distinguish appropriately between Plus purchases and consumable tips.

Requirements:

- A delayed Plus purchase should update entitlement correctly.
- A delayed approved tip should receive the same appropriate acknowledgement as an immediately completed tip.
- Do not treat consumable tips as durable Plus entitlements.
- Do not persist a tip as though it were a non-consumable entitlement.
- Avoid showing duplicate thank-you UI if the same transaction has already been handled during the immediate purchase flow.

## 5. Expand StoreKit/PurchaseService tests

In addition to the existing tests, add focused coverage for at least:

- Initial entitlement resolution still in progress.
- Existing Plus entitlement after delayed initial resolution.
- Free user after delayed initial resolution.
- StoreKit product loading failure.
- Partial product catalog (for example, Plus products load but tips don't, or vice versa).
- Restore Purchases causing entitlement to become active.
- Pending Plus purchase later completing through a transaction update.
- Pending consumable tip later completing through a transaction update.
- Entitlement loss/update while the app is running.
- Correct free-tier behavior after a subscription lapses: existing shows remain, but adding another show is blocked while the user is at or above the free limit.
- Transaction processing/finishing behavior to the extent that it can reasonably be tested through the StoreKit abstraction.

Use test doubles rather than making unit tests depend on the live App Store.

## 6. Preserve existing intended behavior

Do not change these product rules:

- Plus annual subscription grants unlimited tracking while entitled.
- Plus lifetime purchase grants unlimited tracking.
- Tips are consumable and grant no entitlement.
- Existing users who qualify for grandfathering remain grandfathered according to the current rules.
- If Plus lapses while the user has more than the free limit, keep all existing tracked shows but prevent adding more until the user resubscribes or removes enough shows.
- Restore Purchases remains explicitly user initiated.
- Family Sharing remains disabled for these products.

Please inspect all affected call sites rather than patching only the specific lines mentioned above.

After making the changes:

1. Run the relevant unit tests and the full test suite if practical.
2. Run/build with the StoreKit configuration where appropriate.
3. Check for compiler warnings and concurrency/sendability issues.
4. Run `git diff --check`.
5. Review the final diff for accidental formatting or unrelated changes.
6. Summarize what you changed, any design decisions you made, and the tests you added.
7. Do not commit the changes; leave them in the working tree for review.