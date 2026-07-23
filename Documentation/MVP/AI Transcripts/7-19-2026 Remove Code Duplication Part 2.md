# Shared notification status

## User

Please fix this code duplication found by ChatGPT:

Notification status presentation is still partially duplicated

The service action is shared, but About and Watchlist separately retrieve and derive status.

## Assistant

I'll find where About and Watchlist each retrieve/derive notification status so we can consolidate that shared presentation logic.

Checking Diagnostics and related helpers to see how status is derived elsewhere, and whether a shared presentation type already exists.

Extracting a shared `NotificationStatusPresentation` so About, Watchlist, and Diagnostics load and derive status from one place, then wiring the existing scene-active refresh to that model.

The presentation type is picking up MainActor isolation from the service API — I'll mark the pure value/derivation as `nonisolated` so tests can use it.

Notification status is now loaded and derived in one place.

**What changed**
- Added `NotificationStatusPresentation` with shared labels, symbols, banner visibility, and enablement button title, plus `load(using:)`.
- About, Watchlist, and Diagnostics all use that model instead of separate `canDeliverVisibleAlerts` / `authorizationStatus` derivation.
- Replaced the Bool-only scene-active refresh with `.refreshNotificationStatus(_:)`.
- Added unit tests for the derived presentation fields.

**What to test**
1. Watchlist with notifications off → banner shows; title is **Enable Notifications** (never asked) or **Open Settings** (denied).
2. About → Notifications row shows Enabled/Disabled; tap still prompts or opens Settings; status updates after returning from Settings.
3. Diagnostics → “Notifications enabled” and test-action enablement still track permission correctly.
