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

# App Store Submission Checklist

The application is feature-complete at this point. The remaining work is focused on preparing it for public release and successfully navigating the App Store review process.

Note that unlike most of the roadmap documents, these tasks are in mostly sequential order.

## Legal and Business

* Receive D-U-N-S Number for Trial by Fyre, LLC.
* Convert Apple Developer account to an Organization account.
* Verify company information in App Store Connect.
* Review and complete all tax and banking information.
* Confirm support email address.
* Confirm support website.
* Verify Privacy Policy is published and accessible.
* Decide whether to use a support knowledge base or GitHub Issues for user support.

## App Store Assets

* Design a final production-quality app icon.
    * The current icon is sufficient for development but should be replaced before release.
* Capture App Store screenshots for all supported device sizes.
* Prepare App Preview video (optional).
* Write the App Store description.
* Write promotional text.
* Choose keywords.
* Select App Store categories.
* Prepare copyright information.

## Privacy and Compliance

* Complete the Privacy Nutrition Label.
* Verify App Privacy answers remain accurate.
* Confirm encryption questionnaire answers.
* Review accessibility support.
* Verify required legal acknowledgements and licenses.

## Final Quality Pass

* Complete a full regression test.
* Test on current iOS release.
* Test on the latest beta version of iOS (if available).
* Verify upgrade from previous TestFlight builds.
* Verify clean installation.
* Verify notification permissions flow.
* Verify background refresh behavior.
* Verify behavior with notifications disabled.
* Verify behavior with Background App Refresh disabled.
* Verify Dark, Light, and Midnight themes.
* Verify Dynamic Type.
* Verify VoiceOver.
* Verify localization assumptions (even if English-only).
* Verify app behavior while offline.
* Run Instruments one final time for memory leaks and performance.

## TestFlight

* Create Release Candidate build.
* Invite final external testers.
* Address remaining beta feedback.
* Remove or hide developer-only diagnostics as appropriate.
* Increment version and build numbers for release.

## App Store Connect

* Create production app version.
* Upload Release Candidate build.
* Complete release notes (“What’s New”).
* Upload screenshots.
* Upload app icon.
* Complete pricing information.
* Select availability by country.
* Configure age rating.
* Configure App Review information.
* Provide demo account (if ever required).
* Submit for review.

## Launch

* Decide between automatic release and manual release after approval.
* Publish announcement on LinkedIn.
* Publish announcement on GitHub.
* Publish announcement on the project website.
* Monitor App Review status.
* Respond promptly to reviewer questions.
* Monitor crash reports after launch.
* Monitor user reviews and support emails.
* Prioritize post-launch fixes before beginning major new features.

⸻

There are a couple of things I’d add based on what I know about NextSeason specifically:

* Replace the temporary SF Symbols app icon before submission. We talked about this after realizing App Review might reject an icon composed directly from SF Symbols.
* Remove or gate the diagnostics UI (or at least verify you’re comfortable with what remains visible to end users).
* Verify all GitHub links and documentation point to the public repository and no internal-only notes remain.
* Archive the MVP documentation (roadmaps, transcripts, architecture docs, etc.) as the “v1.0” snapshot before you begin post-launch work. That gives you a clean historical record of the project as it existed when it first shipped.
