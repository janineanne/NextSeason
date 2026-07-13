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

Future work should focus on addressing real user pain points rather than
re-implementing functionality the underlying API already provides.

### Recommended Analytics

Before investing in additional search work, instrument the search flow to
understand how people are actually using it.

Suggested events:

- `search_performed`
- Query length
- Result count
- Whether a show was selected

If searches that return the maximum 10 results frequently end without a
selection, that is strong evidence that the current API limitation is hurting
usability. If most searches lead to a successful selection, search improvements
can remain a lower priority.

### Potential Improvements

Priority should be guided by analytics and beta feedback.

- Remove the current 10-result limitation if it proves to be a significant user problem.
- Evaluate multi-provider search (see below) as the preferred long-term solution.
- Support common abbreviations and acronyms only if real-world usage demonstrates a need.

TVMaze's relevance ordering is generally good enough that custom result ranking
is unlikely to provide meaningful value. Unless beta feedback uncovers a
specific, repeatable weakness, the application should continue to present
results in the order supplied by the provider.

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



## Intelligent Monitoring Experience

The long-term vision for NextSeason is to quietly monitor the TV shows users care about and let them know when there is something worth knowing. Future enhancements should reinforce user confidence that the app is actively monitoring on their behalf without encouraging unnecessary engagement.

### Monitoring Confidence

- Display a monitoring summary at the top of the watchlist (for example: "Monitoring 18 shows").
- Show the last successful background refresh time.
- Clearly indicate when everything is up to date.
- Surface when background refresh has not run recently so users understand why updates may be delayed.

### Immediate Value

After adding a show to the watchlist, present a richer status summary instead of a simple confirmation.

Examples:

- Current status (Running, Returning, Ended, etc.).
- Latest known season and premiere information.
- A brief explanation that NextSeason will monitor the show and notify the user when its status changes.

### Update Awareness

- Display a "Since your last visit" summary when tracked shows have changed.
- Maintain unread update indicators until the user has acknowledged the changes.
- Consider an update history so users can review previously announced changes.

These features should complement notifications rather than replace them, ensuring users can easily see what changed even if they missed a notification.

### Apple Platform Integration

Investigate deeper integration with App Intents, Siri, Apple Intelligence, and widgets.

Potential features:

- Siri/App Intents to add or remove shows from the watchlist.
- Siri queries about the status of tracked shows.
- Siri summaries describing what has changed since the user's last visit.
- Home Screen widgets that display monitoring status or recent updates.

These capabilities should operate on the user's watchlist and application data rather than attempting to become a general entertainment news assistant.

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

Users occasionally want to know where a show is currently available to stream,
particularly after receiving a notification that a new season has been released.
However, streaming availability changes frequently, varies by country, and is
not reliably represented by TVMaze's crowdsourced data.

Future work in this area should be driven by user demand rather than implemented
proactively.

### Evaluate User Interest

Collect beta feedback and App Store feedback to determine whether users are
actually looking for streaming availability within the app, or whether they
typically use other services to answer that question.

### Potential Improvements

If there is sufficient demand:

- Evaluate integration with a dedicated streaming availability provider (such as TMDb watch providers or JustWatch) that offers regional streaming information.
- Display current streaming availability for the user's region when reliable data is available.
- Consider deep-linking directly to supported streaming services where practical.

TVMaze's streaming provider information should not be used for this feature, as
its crowdsourced nature makes it incomplete and unsuitable as a primary data
source.

---

## Preferred Services

### Potential Features (Dependent on Reliable Streaming Data)

* Allow users to record which streaming services they subscribe to.
* Highlight shows currently available on those services.
* Filter or group watchlist entries by streaming availability.
* Tailor notifications with current streaming availability when appropriate.

Priority: High

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

Transition the Diagnostics screen from a beta testing tool into a production support feature. Remove developer-only actions while retaining user-visible status information and the ability to generate or send a diagnostic report for troubleshooting.

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
