# NextSeason -- App Store Readiness Roadmap

## Related Documentation

The current implementation architecture is documented in the Mermaid diagrams under `Documentation/Diagrams/`. Those diagrams describe the existing codebase and are updated as implementation changes. This roadmap intentionally focuses on planned work rather than current architecture.

The diagrams most relevant to this roadmap are:

- 01 – App Architecture
- 03 – Refresh & Notifications
- 04 – Data & Persistence
- 05 – Search Flow
- 08 – Background Refresh Scheduling



## Purpose

This document captures the work that should be completed before the first App Store release. Content has been preserved from the original roadmap and reorganized by release timing rather than topic.

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

Continue using TVMaze's relevance ordering where appropriate, while allowing another provider to supply broader search results if it improves discoverability.

## Search Provider Independence

Reduce dependence on a single metadata provider while improving search coverage.

-   Use one or more search-focused providers.
-   Continue using the most appropriate metadata provider for season tracking.
-   Map provider IDs when a show is selected.
-   Design the search layer so providers can be added or replaced with minimal user impact.