# NextSeason -- Post-MVP Roadmap

## Purpose

This document captures planned enhancements and longer-term ideas
following the MVP.

The roadmap is organized by area rather than by release number. Within
each area, items are generally ordered from the work most likely to
happen next toward longer-term ideas. Priorities should continue to
evolve based on user feedback, analytics, and real-world usage.

# Engineering & Reliability

## SwiftData Migration Strategy

-   Add and test a SwiftData migration plan before changing persistent
    models.
-   Verify upgrades preserve user data.
-   Include migration testing in release validation.
-   Keep representative stores from older versions for testing.

## Persistence Recovery

Replace the startup `fatalError` with a user-facing recovery flow before
App Store release.

-   Log diagnostics before recovery.
-   Allow resetting the local store.
-   Explain consequences before resetting.
-   Allow exporting diagnostics before reset.

## Crash Loop Prevention

-   Detect repeated launch failures.
-   Offer a **Reset Local Data** option.
-   Preserve diagnostics for troubleshooting.

# Core Product Improvements

## Search

TVMaze already provides fuzzy matching, AKA support, partial-title
matching, punctuation tolerance, and relevance ordering.

### Recommended Analytics

-   `search_performed`
-   Query length
-   Result count
-   Whether a show was selected

### Necessary Improvements

-   Eliminate the current 10-result limitation (must be done before first App Store release).

### Potential Improvements

- Support common abbreviations and acronyms if users demonstrate a need.
- Continue refining search quality based on analytics and user feedback.

Continue using TVMaze's relevance ordering where appropriate, while allowing another provider to supply broader search results if it improves discoverability.

## Search Provider Independence

Reduce dependence on a single metadata provider while improving search coverage.

-   Use one or more search-focused providers.
-   Continue using the most appropriate metadata provider for season tracking.
-   Map provider IDs when a show is selected.
-   Design the search layer so providers can be added or replaced with minimal user impact.

## Watchlist Management

- Support swipe-to-delete in the Watchlist, in addition to tapping the star.
- User-selectable sorting.
- Filtering by show status.
- Hide ended shows.
- Optional grouping by status.

Watchlist search should use simple title matching rather than
discovery-oriented fuzzy search.

## Notification Enhancements

-   Global notification preferences.
-   Per-show preferences.
-   Quiet hours.
-   Notification history.
-   Additional notification categories.

## Streaming Availability

Implement only if users demonstrate meaningful demand.

If sufficient demand exists:

-   Integrate with a dedicated streaming provider.
-   Display current regional availability.
-   Deep-link to supported services.

Do not use TVMaze's crowdsourced provider data.

### Dependent Future Features

-   Record subscribed services.
-   Highlight available shows.
-   Filter/group by availability.
-   Tailor notifications.

# Platform Features

## Apple Platform Expansion

Potential platforms:

After Cloud Sync is implemented:

- iPad
- Mac
- Apple TV companion app

Vision Pro is not currently planned.

## Cross-Device Sync

-   Cloud sync.
-   Cross-device watchlists.
-   Backup and restore.
-   Device migration.

## Monitoring & Notifications

- Move season monitoring to a backend service.
- Deliver reliable push notifications even when the app is not running.
- Reduce dependence on background app refresh.
- Keep notification delivery consistent across all of a user’s devices.

## Identity & Accounts

Introduce user accounts only if they become necessary to support Cloud Sync or backend monitoring.

# Product Analytics

Transition Diagnostics into a production support feature while retaining diagnostic report generation. Continue using lightweight, privacy-preserving analytics to guide future product decisions.

# Business Options

-   One-time purchase.
-   Premium upgrade.
-   Subscription.
-   Affiliate revenue.
-   Validate monetization only after the core product demonstrates user retention.

# Product Principles

-   Remain focused on season tracking.
-   Avoid unnecessary complexity.
-   Favor privacy.
-   Work well without requiring an account.
-   Integrate naturally with Apple's platforms.
-   Earn user trust through reliability.
-   Do one thing exceptionally well before expanding scope.

# Explicit Non-Goals

-   Social networking.
-   User reviews.
-   Episode tracking.
-   Discussion forums.
-   General TV discovery.
-   Recommendation engines.
-   Comprehensive media database features.
