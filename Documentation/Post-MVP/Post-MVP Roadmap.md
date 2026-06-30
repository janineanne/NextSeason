# NextSeason - Post MVP Roadmap

## Purpose

This document captures potential future enhancements after the initial beta release.

Items here are intentionally lower priority than release readiness work.

Future priorities should be informed by user behavior, beta feedback, and analytics.

---

# Data Persistence & Recovery

## SwiftData Migration Strategy

Before making future changes to `TrackedShowEntity` or other persistent models:

- Add and test a SwiftData migration plan.
- Verify that upgrades from previous TestFlight and App Store versions preserve user data.
- Include migration testing in release validation whenever the persistent schema changes.
- Keep representative stores from older app versions to validate real-world upgrade scenarios.

## Persistence Recovery

The MVP intentionally terminates if the SwiftData `ModelContainer` cannot be created because the application cannot function meaningfully without persistence.

Before App Store release, replace the startup `fatalError` with a user-facing recovery flow.

Potential recovery options:

- Log detailed diagnostics before presenting recovery options.
- Allow users to reset local data and recreate the persistent store if it becomes corrupted.
- Explain the consequences of resetting local data before proceeding.
- Offer users the option to export diagnostic information before resetting the persistent store.

## Crash Loop Prevention

Prevent users from becoming permanently locked out of the application because of a damaged persistent store.

Potential approaches:

- Detect repeated launch failures.
- Offer a "Reset Local Data" recovery option.
- Preserve diagnostic information to help investigate failures before resetting.

# Core Product Improvements

## Search

TVMaze already provides fuzzy matching, alternate-name (AKA) support,
partial-title matching, punctuation tolerance, and relevance-based ranking.

Future work should therefore focus on features that add value beyond the
underlying API rather than duplicating its behavior.

Potential improvements:

- Support common abbreviations and acronyms (GoT, SVU, TNG, etc.).
- Experiment with app-specific result ordering.
- Collect beta analytics before investing additional engineering effort.

### Recommended Analytics

Before investing in significant search work, instrument the search flow to
measure whether users are actually experiencing problems.

Suggested events:

- `search_performed`
- query length
- result count
- `show_selected` (yes/no)

If searches with 10 results frequently end without a selection, that provides
evidence that the TVMaze API limit is hurting usability. If almost all searches
lead to a selection, additional search work can remain a low priority.

## Evaluate Multi-Provider Search

TVMaze's public search API is limited to 10 results with no pagination.

If search quality becomes a meaningful user pain point, investigate a
multi-provider architecture:

- Use TMDb (or another search-focused provider) for user-facing search.
- Continue using TVMaze for season, episode, and next-airing metadata.
- Map provider IDs when a show is selected.

Benefits:

- Unlimited paginated search results.
- Better discovery of obscure shows.
- Preserve the existing notification and season-tracking implementation.

Pursue only if beta feedback and analytics demonstrate that the current TVMaze
search limitations materially impact users.


---

## Watchlist Management

### Potential Features

- Sorting options.
- Filtering options.
- Grouping options.
- Hide ended shows.

Priority: High

---

## Notification Enhancements

### Potential Features

- Notification settings.
- Per-show notification preferences.
- Quiet hours.
- Notification history.
- Different notification types.

Examples:

- Season announced.
- Release date announced.
- Season available.

Priority: High

---

# Streaming Availability

## Streaming Provider Information

### Motivation

Knowing where a season is available is often more valuable than knowing that it exists.

### Potential Features

Display availability on:

- Netflix
- Hulu
- Disney+
- Max
- Apple TV+
- Prime Video

Priority: High

---

## Preferred Services

### Potential Features

- Track subscribed services.
- Filter unavailable content.
- Prioritize relevant notifications.

Priority: High

---

# Product Intelligence

## Recommendations

### Potential Features

- Similar shows.
- Genre recommendations.
- Watchlist-based suggestions.

Priority: Medium

---

## Actor Tracking

### Potential Features

- Follow actors.
- Actor-based discovery.
- Notifications for new projects.

Priority: Medium

---

## Network and Studio Tracking

### Potential Features

- Follow networks.
- Follow streaming providers.
- New series announcements.

Priority: Medium

---

# Platform Features

## User Accounts

### Motivation

Allow synchronization across devices.

### Potential Features

- Sign in with Apple.
- Cloud sync.
- Cross-device watchlists.

Priority: Medium

---

## Cloud Backup

### Potential Features

- Backup and restore.
- Device migration support.

Priority: Medium

---

# Product Analytics

## MVP State (Local Logging Only)

The MVP implements analytics behind an `AnalyticsTracking` abstraction
(`AnalyticsService`), with a default provider that logs structured events via
`os.Logger` on the user's device. Events are anonymous (query length, not search
text; show IDs; error categories — see Release Readiness.md).

**What this is good for today:**

- Verifying instrumentation during development and internal testing
- Debugging flows on devices you control (Xcode console, Console.app)
- Keeping call sites stable before a remote provider is chosen

**What it does not provide:**

- Aggregate behavior across beta testers or production users
- Answers to product questions unless logs are manually captured from a device

For multi-user beta, treat TestFlight crash reports and the structured feedback
form as primary inputs until remote collection is added.

## Post-MVP: Remote Collection

To make analytics useful for prioritization after beta, add a second
`AnalyticsTracking` implementation that sends the same `AnalyticsEvent` payloads
to a centralized service. No changes should be required at instrumentation call
sites.

Candidate approaches (evaluate privacy, cost, and maintenance):

- Privacy-focused SDKs (e.g. TelemetryDeck)
- General analytics platforms (e.g. Firebase Analytics, Mixpanel)
- A minimal first-party backend (event name + parameters only)

Keep the existing privacy constraints: no search text, show titles, or other PII
in event payloads.

Remove the beta-only analytics tap target from show summaries before portfolio
release (see Release Readiness.md, Portfolio Readiness).

## Future Investigation

Use analytics and feedback to answer questions such as:

- What are users searching for?
- What shows are most tracked?
- Which notifications are most useful?
- Which features are requested most often?

Future development should be driven by observed user behavior whenever possible.

---

# Business Options

Evaluate only after validating user demand.

## Possible Models

- One-time purchase.
- Premium upgrade.
- Subscription.
- Affiliate revenue.

No monetization strategy should compromise the simplicity of the product.

---

# Explicit Non-Goals

The following are not currently aligned with the product vision:

- Social networking.
- User reviews.
- Episode tracking.
- Discussion forums.
- Complex media database features.

NextSeason should remain focused on helping users know when new seasons of shows become available.
