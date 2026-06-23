# NextSeason - Post MVP Roadmap

## Purpose

This document captures potential future enhancements after the initial beta release.

Items here are intentionally lower priority than release readiness work.

Future priorities should be informed by user behavior, beta feedback, and analytics.

---

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
