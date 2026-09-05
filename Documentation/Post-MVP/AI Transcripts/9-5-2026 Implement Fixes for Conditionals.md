# SwiftUI conditional rendering cleanup

## User

Please clean up SwiftUI conditional rendering where doing so improves readability and keeps business/state interpretation out of the view layer. Do not attempt to eliminate conditionals indiscriminately—ordinary state-driven and optional-content rendering is idiomatic SwiftUI.

Please make the following changes:

1. Simplify StoreKit presentation state

Review PlusStoreView and TipJarSection.

These views currently interpret combinations of StoreKit state such as:

* isLoadingProducts
* hasCompletedProductLoad
* whether annual/lifetime products are nil
* whether tip products are empty
* isPurchasing

In particular, avoid making views reason about combinations such as:

purchases.annualProduct == nil && purchases.lifetimeProduct == nil
    && !purchases.isLoadingProducts && purchases.hasCompletedProductLoad

Introduce small semantic/derived presentation state(s) so the views can reason in terms such as:

* loading
* available
* unavailable

The exact implementation is up to you. This can be an enum or derived properties on/near PurchaseService. Prefer the smallest clean solution; do not introduce a generic abstraction unless it genuinely simplifies the code.

Keep isPurchasing separate if that represents a different concern from product availability.

The goal is for PlusStoreView and TipJarSection to describe what should be displayed rather than reconstructing StoreKit state from several correlated booleans.

Preserve all existing behavior, loading indicators, disabled states, error states, purchase behavior, accessibility, and tests.

2. Simplify loaded-state presentation in WatchlistView

Keep the existing top-level:

switch viewModel.state

That is good state-driven SwiftUI and should not be replaced.

Within the .loaded UI, simplify the cluster of related conditions that determines whether to show:

* the notification-disabled banner
* the normal list
* the empty-watchlist state
* the no-search-results state
* associated spacing/attribution where applicable

In particular, the view currently has to interpret combinations involving:

* notificationStatus.showsDisabledBanner
* viewModel.shows.isEmpty
* viewModel.filteredShows.isEmpty
* viewModel.pendingRemoval
* search state

Introduce small, semantically named derived presentation state/properties where they make the rendering code easier to understand.

Because some of this presentation state depends on both WatchlistViewModel and view-owned/environment state such as notificationStatus, do not force it into WatchlistViewModel merely to remove conditionals from the view. A private presentation enum/computed property/helper in WatchlistView is fine if that is the cleaner ownership boundary.

Do not change Watchlist behavior, scrolling, search behavior, deletion/undo behavior, notification banners, accessibility, or attribution placement.

3. Minor Search idle-state cleanup

In the Search idle UI, the first-run and subsequent-use descriptions currently conditionally construct two Text views.

Where cleanly possible, derive the description string first and render a single Text, e.g. conceptually:

Text(searchIdleDescription)

Keep the conditional around the “Try an Example” button because that control genuinely exists only in the first-run state.

Do not split either localized description into sentence fragments or construct localized prose by concatenating strings. Each complete user-facing sentence/paragraph should remain a complete localization unit.

Explicitly leave these patterns alone

Do not refactor these merely to reduce the number of SwiftUI conditionals:

1. SearchView’s state-driven switch viewModel.state.
2. ShowDetailView’s switch viewModel.loadState.
3. Small optional-content rendering such as:
    * if let network
    * if !genres.isEmpty
    * if let summary
    * if let url
4. Small focused component state such as if isUpdating in ShowRowTrackButton.
5. Imperative conditionals inside .task, .onChange, button actions, bindings, callbacks, etc. Those are not the SwiftUI structural-conditional issue we’re addressing.

Important: preserve WatchlistSearchPresentationModifier

Do not replace the conditional application of .searchable in WatchlistSearchPresentationModifier.

Although conditional modifiers can sometimes create SwiftUI identity concerns, this implementation is intentional: the .searchable modifier must actually be absent when search is not presented in order to preserve the desired navigation-drawer/UI behavior. Using .searchable’s isPresented: API changes that behavior.

Keep the existing implementation and its explanatory comments unless you discover an actual bug.

General constraints

* Preserve existing behavior and visual appearance.
* Preserve accessibility behavior and labels.
* Preserve localization behavior.
* Do not introduce unnecessary architecture or abstractions.
* Do not move purely presentational decisions into view models just to make views contain fewer if statements.
* Prefer semantic state over combinations of correlated booleans when that state represents a real concept.
* Do not refactor unrelated code.
* Preserve the project’s existing formatting/style.
* Update or add tests where the changed state modeling warrants it.

After making the changes, run the relevant test suites and report:

1. what was changed,
2. any conditionals you deliberately retained and why,
3. tests run and their results.

## Assistant

I'll start by reading the SwiftUI skill and locating the views and StoreKit state that currently reconstruct presentation from several booleans.

Skills used: `swiftui-pro`. Next I’ll read the store, watchlist, and search views plus PurchaseService so we can replace boolean combinations with named presentation state.

I’ll inspect WatchlistViewModel, FirstRunCopy, and the purchase/watchlist tests so the derived presentation state matches current behavior.

I'll add semantic catalog availability on `PurchaseService`, then have the store, watchlist, and search views read that presentation state instead of reconstructing it.

Simulator listing was blocked by the sandbox. I’ll rerun the unit tests with full permissions so `xcodebuild` can reach CoreSimulator.

The presentation type was pulled onto the main actor by the module default. I’ll mark it `nonisolated` so the tests can use it as a plain value.

Skills used: `swiftui-pro`, `swift-testing-pro`.

## 1. What changed

**StoreKit presentation.** `PurchaseService` now exposes `StoreCatalogAvailability` (`loading` / `available` / `unavailable`) as `plusCatalogAvailability` and `tipCatalogAvailability`. `isPurchasing` is unchanged.

- **Plus** treats an in-flight or unfinished catalog load as `.loading`, so the paywall overlay can still spin during a retry.
- **Tips** stay `.available` once products exist, so a later reload does not replace the tip buttons with a spinner.

`PlusStoreView` and `TipJarSection` now switch on those values instead of combining `isLoadingProducts`, `hasCompletedProductLoad`, and empty-product checks.

**Watchlist loaded UI.** `WatchlistLoadedPresentation` names the loaded chrome: banner, title-preserving spacer, attribution, and overlay (`none` / `emptyWatchlist` / `noSearchResults`). It lives next to the view (not on `WatchlistViewModel`) because it also depends on `notificationStatus`. `switch viewModel.state` is unchanged.

**Search idle copy.** The idle description is chosen first (`searchIdleDescription`) and rendered as one `Text`. Both strings remain complete localization units. The “Try an Example” button is still first-run-only.

**Tests.** Catalog-availability assertions were added to `PurchaseServiceTests`, plus `WatchlistLoadedPresentationTests` for overlay, spacer, banner, attribution, and the empty-list + pending-removal case.

## 2. Conditionals deliberately kept

These are either out of scope or still idiomatic optional/state rendering:

- `switch viewModel.state` in Search and Watchlist; `switch viewModel.loadState` in Show Detail
- `if let annual` / `if let lifetime` purchase buttons
- Overlay: `isPurchasing` **or** Plus catalog `.loading` (purchase vs catalog)
- `.task` product-load guards (`annual`/`lifetime` nil, empty tips)
- Search idle “Try an Example” button (`if !hasCompletedFirstSearch`)
- Watchlist optional chrome (`if presentation.showsNotificationBanner`, spacer, attribution)
- `WatchlistSearchPresentationModifier` and its comments — `.searchable` is still applied only while search is presented
- Small optional content (`if let network`, genres, summary, URL) and `if isUpdating` on `ShowRowTrackButton`
- Imperative checks in `.task`, `.onChange`, buttons, bindings

## 3. Tests

`xcodebuild test` on **NextSeasonTests** (iPhone 17 Pro, iOS 26.5):

| Suite | Result |
|---|---|
| `PurchaseServiceTests` | Passed |
| `WatchlistLoadedPresentationTests` | Passed |
| `WatchlistViewModelTests` | Passed |
| `SearchViewModelTests` | Passed |

The first full run had **316/317** pass. The only failure was `WatchlistPendingRemovalTests.timerExpiryRemovesShowWithCancellationAwareRepository` (timer/cancellation timing, unrelated). Re-running that suite passed (13/13).

**What to check in the simulator:** Plus sheet loading / unavailable / purchase overlay; tip jar loading / products / retry; Watchlist empty, no-search-results, notification banner, attribution; Search idle first-run vs returning copy and the example button.

