# NextSeason -- Product Evolution Roadmap

This document captures enhancements planned after the initial App Store release. Features are grouped by area rather than priority, and will be implemented based on user feedback, technical dependencies, and product direction.

## Purpose

This document captures enhancements planned after the initial App Store release. Content has been preserved from the original roadmap and reorganized by release timing rather than topic.

# Core Product Improvements

## Search Improvements

- Support common abbreviations and acronyms if users demonstrate a need.
- Continue refining search quality based on analytics and user feedback.

## Watchlist Management

- Support swipe-to-delete in the Watchlist, in addition to tapping the star.
- User-selectable sorting.

Continue to favor fast, predictable title matching over discovery-oriented fuzzy search.

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

## AI-Assisted Show Insights

Evaluate Apple’s on-device Foundation Models as the primary implementation for concise, privacy-preserving viewing insights.

Potential capabilities:

- Generate a brief "Why you might like this" summary.
- Highlight the types of viewers the show is best suited for.
- Describe tone and pacing in a few concise bullet points.
- Produce consistent, spoiler-free summaries that fit naturally within the existing UI.

Implementation principles:

- Use Apple's on-device Foundation Models when available.
- Cache generated insights so each show is processed only once.
- Gracefully fall back to the standard TVMaze description on unsupported devices or OS versions.
- Clearly identify this as a feature available only on supported versions of iOS, ensuring the app continues to provide a complete experience on older devices.
- Keep AI optional, unobtrusive, and focused on helping users decide whether to add a show to their Watchlist.
- Preserve user privacy by performing generation on-device whenever possible.

## Continuous Improvement

- Refine the user experience based on App Store reviews and user feedback.
- Continue improving accessibility.
- Improve performance and battery efficiency.
- Reduce maintenance burden through ongoing codebase simplification.

# Platform Features

## Cross-Device Sync

-   Cloud sync.
-   Cross-device watchlists.
-   Backup and restore.
-   Device migration.

## Apple Platform Expansion

Potential platforms:

Planned after Cloud Sync is implemented:

- iPad
- Mac
- Apple TV companion app

Vision Pro is not currently planned.

## Monitoring & Notifications

- Move season monitoring to a backend service.
- Deliver reliable push notifications even when the app is not running.
- Reduce dependence on background app refresh.
- Keep notification delivery consistent across all of a user’s devices.
- Minimize battery impact by performing monitoring on the server whenever possible.

## Identity & Accounts

Introduce user accounts only if they become necessary to support Cloud Sync or backend monitoring.

# Reliability and Error Handling

## Audit and eliminate production-reachable fatalError calls

Review every use of fatalError, preconditionFailure, and similar deliberate crash mechanisms. Replace any that could be reached because of malformed data, persistence problems, API responses, migration failures, or other runtime conditions with recoverable error handling, safe fallback behavior, and appropriate logging. Retain deliberate crashes only for genuinely impossible programmer errors, and document why each remaining use is safe.

# Product Analytics

Transition Diagnostics into a production support feature while retaining diagnostic report generation. Continue using lightweight, privacy-preserving analytics to guide future product decisions.

# Business Options

-   One-time purchase.
-   Premium upgrade.
-   Subscription.
-   Affiliate revenue.
-   **Initial release**: One-time paid purchase. Future pricing models (including free, freemium, subscriptions, or optional purchases) will be evaluated based on user feedback, adoption, and operating costs.

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
