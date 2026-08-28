# StoreKit integration issues

## User

Please fix the StoreKit issues identified in review of the current storekit-integration branch.

Preserve the existing architecture where practical and keep the changes focused. Do not do unrelated refactoring or formatting.

1. Remove purchasable fallback tip products

TipJarSection currently creates fallback StoreProducts when purchases.tipProducts is empty. These contain hard-coded $1, $3, and $5 prices and produce active purchase buttons even though the corresponding StoreKit Products may not have loaded.

This creates two problems:

* A user can tap a fallback product before StoreKit has loaded it, causing StoreKitPurchaseStoreClient.purchase() to fail with PurchaseError.productUnavailable.
* The fallback prices are U.S.-specific rather than localized App Store prices.

Change this so production purchase UI is driven only by products actually loaded from StoreKit.

Requirements:

* Do not display an enabled purchase button for a product that StoreKit has not loaded.
* Do not display hard-coded prices as though they were actual App Store prices.
* Preserve whatever preview/test support is useful, but keep synthetic/fallback products out of the real production purchase path.
* Give the Tip Jar an appropriate loading/unavailable state rather than presenting fake purchasable products.
* If product loading can be retried cleanly, provide a reasonable retry path.
* Keep the behavior consistent with PlusStoreView where appropriate.

2. Eliminate the cold-launch entitlement race

PurchaseService.isStoreEntitled initially defaults to false. The real StoreKit entitlement is resolved asynchronously by start() after the SwiftUI UI is already interactive.

This means an existing Plus customer who launches with three or more tracked shows can attempt to add another show before currentEntitlements has been checked and incorrectly receive the free-tier paywall.

Represent unresolved StoreKit entitlement explicitly rather than treating “not checked yet” as “free.”

A design such as:

enum EntitlementState {
    case loading
    case free
    case unlimited
}

is reasonable, but use whatever design fits the existing code best.

Requirements:

* During cold launch, do not classify the user as free until initial entitlement resolution has completed.
* A known Plus entitlement should continue to permit unlimited additions.
* A known non-entitled user should continue to use the existing free-tier/grandfathering rules.
* Do not simply allow unlimited additions indefinitely when StoreKit fails to load. Distinguish initial resolution/loading from a genuine failure and choose safe, understandable behavior.
* Prefer making the operation that needs entitlement information wait for initial entitlement resolution rather than flashing or presenting an incorrect paywall.
* Avoid introducing noticeable UI blocking for normal launches.
* Make sure all relevant paths use the same resolved entitlement state.

Add tests that deliberately suspend/delay initial entitlement resolution and verify that an existing Plus customer cannot be incorrectly classified as free while StoreKit is still resolving.

Also test the non-entitled case after resolution completes.

3. Correct transaction finishing order

Review the transaction lifecycle in StoreKitPurchaseStoreClient.

Currently a verified transaction is generally finish()ed before PurchaseService has incorporated the resulting entitlement change. StoreKit’s intended lifecycle is:

1. Receive transaction.
2. Verify it.
3. Deliver/unlock the purchased content or otherwise incorporate the transaction.
4. Finish the transaction.

Refactor the StoreKit/client/service boundary as necessary so verified transactions are not considered finished until the application has processed the purchase appropriately.

This applies both to:

* transactions returned directly by purchase()
* transactions received later through Transaction.updates

Do not sacrifice the existing clean separation between StoreKit-specific code and application entitlement logic unnecessarily. Find the smallest clean design that gives the application an opportunity to process the verified transaction before it is finished.

Make sure transactions are eventually finished and cannot get stuck in an endless redelivery loop.

4. Handle deferred/pending tip completion gracefully

A tip can initially return .pending (for example, Ask to Buy) and later arrive through Transaction.updates.

Currently that later transaction is finished, but the application doesn’t know that a consumable tip completed, so the user never receives the normal thank-you acknowledgement.

Make transaction updates distinguish appropriately between Plus purchases and consumable tips.

Requirements:

* A delayed Plus purchase should update entitlement correctly.
* A delayed approved tip should receive the same appropriate acknowledgement as an immediately completed tip.
* Do not treat consumable tips as durable Plus entitlements.
* Do not persist a tip as though it were a non-consumable entitlement.
* Avoid showing duplicate thank-you UI if the same transaction has already been handled during the immediate purchase flow.

5. Expand StoreKit/PurchaseService tests

In addition to the existing tests, add focused coverage for at least:

* Initial entitlement resolution still in progress.
* Existing Plus entitlement after delayed initial resolution.
* Free user after delayed initial resolution.
* StoreKit product loading failure.
* Partial product catalog (for example, Plus products load but tips don’t, or vice versa).
* Restore Purchases causing entitlement to become active.
* Pending Plus purchase later completing through a transaction update.
* Pending consumable tip later completing through a transaction update.
* Entitlement loss/update while the app is running.
* Correct free-tier behavior after a subscription lapses: existing shows remain, but adding another show is blocked while the user is at or above the free limit.
* Transaction processing/finishing behavior to the extent that it can reasonably be tested through the StoreKit abstraction.

Use test doubles rather than making unit tests depend on the live App Store.

6. Preserve existing intended behavior

Do not change these product rules:

* Plus annual subscription grants unlimited tracking while entitled.
* Plus lifetime purchase grants unlimited tracking.
* Tips are consumable and grant no entitlement.
* Existing users who qualify for grandfathering remain grandfathered according to the current rules.
* If Plus lapses while the user has more than the free limit, keep all existing tracked shows but prevent adding more until the user resubscribes or removes enough shows.
* Restore Purchases remains explicitly user initiated.
* Family Sharing remains disabled for these products.

Please inspect all affected call sites rather than patching only the specific lines mentioned above.

After making the changes:

1. Run the relevant unit tests and the full test suite if practical.
2. Run/build with the StoreKit configuration where appropriate.
3. Check for compiler warnings and concurrency/sendability issues.
4. Run git diff --check.
5. Review the final diff for accidental formatting or unrelated changes.
6. Summarize what you changed, any design decisions you made, and the tests you added.
7. Do not commit the changes; leave them in the working tree for review.

## Assistant

I'll start by reading the Swift skills and inspecting the StoreKit/purchase code so the fixes stay aligned with the current architecture.

I'll read the purchase/StoreKit files and every call site that depends on them so the fixes stay consistent.

I have a clear picture of the races and the StoreKit lifecycle issues. Next I’ll keep the current service/client split and make the smallest changes that fix product fallbacks, entitlement loading, and transaction finishing.

I'll start with the StoreKit client boundary so purchases are processed before they're finished, then thread that through the service and UI.

I'll run the purchase-related unit tests first, then the full suite.

StoreKit review issues are fixed on the current branch. Nothing was committed.

Skills used: `swiftui-pro`, `swift-concurrency-pro`, `swift-testing-pro`.

## What changed

**Tip Jar no longer sells fallback products.** `TipJarSection` only shows StoreKit-loaded tips. While the catalog is loading it shows a progress row; if loading finishes with no tips it shows an unavailable state and **Try Again**. Hard-coded $1/$3/$5 prices are no longer presented as live App Store prices. Stub/preview `StoreProduct` fallbacks remain for tests and previews only.

**Cold-launch entitlement is no longer treated as free.** `PurchaseService` now uses `StoreEntitlementState` (`loading` vs `resolved(isEntitled:)`). Watchlist adds wait for that first StoreKit read instead of showing the paywall. About does not flash “Up to 3 shows” / Unlock while status is still loading. A known Plus customer stays unlimited; a resolved free user still uses the existing cap and grandfathering rules. If StoreKit never answers, the app stays in `loading` rather than granting unlimited access.

**Transactions are processed, then finished.** `PurchaseStoreClient` delivers a verified `StoreTransaction` to the app before the client calls `Transaction.finish()`. That applies to both `purchase()` and `Transaction.updates`. Duplicate transaction IDs are ignored for tip thank-yous so Ask to Buy / updates cannot show the alert twice.

**Delayed tips are acknowledged.** A pending consumable that later arrives through `Transaction.updates` sets the same thank-you message as an immediate tip. Tips still never grant Plus.

## Design decisions

- Kept the StoreKit-vs-app split: the client verifies and finishes; `PurchaseService` applies entitlement / thank-you using a StoreKit-free `StoreTransaction`.
- `canAddToWatchlist` is now `async` and waits for initial resolution, so Search, Show Detail, and any other add path share one answer. Grandfathered users skip the wait because that flag is already local.
- Product-load failure resolves entitlement independently: a catalog error does not leave the user stuck as “loading,” and it does not invent Plus.

## Tests added

`PurchaseServiceTests` and `WatchlistTrackingTests` now cover delayed Plus and free resolution, product load failure, partial catalogs, restore, pending Plus/tip completion via updates, duplicate tip acknowledgement, entitlement loss, process-before-finish, and lapse behavior (existing shows remain; another add is blocked). All of that uses `StubPurchaseStoreClient`, not the live App Store.

## Verification

- `NextSeasonTests`: **266 tests passed**
- No Swift concurrency/compiler warnings in these changes (`git diff --check` is clean)
- Built/tested with the NextSeason scheme, which uses `NextSeason.storekit`

## What to test in the simulator

1. Launch with StoreKit Configuration on, purchase Plus, force-quit, relaunch, and add a 4th show — it should not hit the paywall.
2. Open About before products load — Tip Jar should show loading, then real prices, never $1/$3/$5 stand-ins.
3. Airplane mode / failed catalog — Tip Jar and Plus store should offer **Try Again**, with no enabled fake buttons.
4. Ask to Buy or a pending tip — after approval, the thank-you alert should appear, without unlocking Plus.

