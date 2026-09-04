# NextSeason — App Store Readiness Roadmap

## Purpose

This roadmap captures the work remaining before NextSeason’s first public App Store release. It covers product changes required for release, engineering and reliability work, final validation, and App Store submission.

Completed MVP work is documented elsewhere and is not repeated here.

# Product and Engineering Readiness

## Search Coverage (Complete)

TVMaze already provides fuzzy matching, alternate-title support, partial-title matching, punctuation tolerance, and relevance ordering. However, the current ten-result limit must be eliminated before the first App Store release.

- Evaluate one or more search-focused providers that can provide broader result coverage.
- Continue using the most appropriate metadata source for season tracking.
- Preserve TVMaze relevance ordering where it remains useful.
- Map provider identifiers when a show is selected.
- Keep the search layer provider-independent so that providers can be added or replaced with minimal user impact.
- Validate common searches, ambiguous titles, alternate titles, punctuation differences, and older or less-popular shows.

### Search Analytics (Complete)

Add only the analytics needed to evaluate search quality while preserving the app’s privacy approach.

Recommended events and properties:

- `search_performed`
- Query length
- Result count
- Whether a result was selected
- Whether the selected show was already on the watchlist

## Watchlist Section Scrolling (Complete)

The watchlist currently uses `List` with `Section`. Native pinned section headers allow rows to scroll beneath the header, which creates an unattractive text-over-text effect in the current design.

- Preserve the native sectioned `List` behavior, including pinned section headers.
- Ensure pinned section headers remain visually distinct from the content scrolling beneath them.
- Use an opaque app-background treatment on section headers so underlying text does not show through or interfere with readability.
- Verify correct behavior across Dynamic Type sizes, and accessibility settings.

## Watchlist Management (Complete)

- Support swipe-to-delete in the Watchlist, in addition to tapping the star.

## SwiftData Migration Strategy (Complete)

- Add and test a SwiftData migration plan before changing persistent models.
- Verify that upgrades preserve user data.
- Project should be structured to support fixture-based migration testing in the future.

## Persistence Recovery (Complete)

Replace the startup `fatalError` with a user-facing recovery flow before release.

- Log diagnostics before attempting recovery.
- Explain the consequences before resetting local data.
- Allow the user to export diagnostics before resetting.
- Before resetting local data, if watchlist data can still be read, offer the user the option to export it.
- Provide a clear **Reset Local Data** action when recovery is not possible.

## Crash-Loop Prevention (Complete)

- Detect repeated launch failures where practical.
- Offer a safe recovery path rather than repeatedly crashing.
- Preserve useful diagnostics for troubleshooting.
- Verify that recovery does not create a new launch loop.

## Accessibility Review (Complete)

Complete a final accessibility pass and address everything that can reasonably be corrected before release.

- Verify VoiceOver labels, values, hints, traits, and navigation order.
- Verify Dynamic Type at the largest accessibility sizes.
- Verify sufficient contrast throughout the app.
- Verify controls remain usable with Button Shapes, Increase Contrast, Reduce Transparency, and Reduce Motion enabled.
- Verify that state is not communicated by color alone.
- Test empty, loading, error, and recovery states.

## Watchlist Export (Complete)

Give users a way to export their watchlist so that their data is not locked into NextSeason.

### Requirements

- Add an **Export Watchlist** action in an appropriate location in the app.
- Export the complete watchlist as a CSV file using the standard iOS share sheet.
- Include enough information to identify each show independently of NextSeason, including:
  - Show name
  - TVMaze ID
  - TVDB ID, when available
- Consider including other useful human-readable information already stored by the app, such as show status or next-season information.
- Export must include **all shows in the watchlist**, including shows above the free-tier limit after a Plus subscription has expired.
- Export must be available to both free and Plus users and must not require an active subscription.
- Ensure the resulting CSV can be opened successfully in common spreadsheet applications such as Numbers and Excel.

Import and restoration from an exported watchlist are not required for the initial App Store release; see the Product Evolution Roadmap.

## StoreKit (Complete for testing)

See [`../Post-MVP/NextSeason - Monetization Strategy Roadmap`](../Post-MVP/NextSeason%20-%20Monetization%20Strategy%20Roadmap.md) for the proposed pricing and purchase structure.

- Make and Implement a plan to charge users through the App Store.
- Implement RequestReviewAction to arrive a few seconds after the first show notification (per version) has been delivered.
- Implement a Tip Jar for the About page using consumable IAPs.
- Add a link to the App Store's "write a review" page to the About page. 


# Documentation Readiness

## AI-Assisted Development Workflow (Complete)

[`AI-Assisted Development Workflow.md`](../AI-Assisted%20Development%20Workflow.md) documents how AI was used during development, including:

- Why AI-assisted development was used.
- The distinct roles of ChatGPT and Cursor.
- How generated code and recommendations were reviewed and validated.
- Which product, design, and engineering decisions remained mine.
- Links to representative transcripts, such as initial architecture, accessibility review, performance review, analytics, TestFlight preparation, and README review.

## Documentation Review (Complete)

- Verify that documentation reflects the release candidate rather than an earlier MVP state.
- Check all links among documentation files.
- Remove references to diagrams that are no longer included.
- Update README screenshots to match the release candidate.
- Verify that all repository links point to the public repository.
- Remove internal-only notes, temporary instructions, and obsolete planning text.

# App Store Submission Checklist

These tasks are listed in approximately sequential order.

## Legal and Business

- Receive the D-U-N-S Number for Trial by Fyre, LLC.
- Convert the Apple Developer account to an Organization account.
- Sign up for the Small Business Program.
- Verify company information in App Store Connect.
- Complete tax and banking information.
- Confirm the support email address.
- Confirm the support website.
- Publish and verify the Privacy Policy.
- Decide whether user support will use a knowledge base, email, GitHub Issues, or another channel.

## App Store Assets and Metadata

- Export and validate the final production app icon.
- Capture App Store screenshots for every required device size.
- Decide whether to create an App Preview video.
- Write the App Store description.
- Write promotional text.
- Choose keywords.
- Select primary and secondary categories.
- Prepare copyright information.

### App Store search/ASO research

Test natural-language searches a prospective user would use to find NextSeason, including “tv show next season,” “tv show upcoming season,” “new season reminder,” and related variations. Use the results to choose the App Store subtitle and keyword field.

Starting queries:
* tv show next season
* tv show upcoming season
* upcoming tv seasons
* new season reminder
* track tv show new seasons
* when is the next season
* when does my show come back

## Privacy and Compliance

- Complete the App Privacy questionnaire and Privacy Nutrition Label.
- Verify that all privacy answers remain accurate for the release build.
- Confirm encryption questionnaire answers.
- Review required legal acknowledgements and third-party licenses.
- Verify that all external services and data sources are disclosed where required.

## Final Quality Pass

- Complete a full regression test.
- Test on the current public iOS release.
- Test on the latest iOS beta, when practical.
- Verify upgrade from earlier TestFlight builds.
- Verify a clean installation.
- Verify notification permission flows.
- Verify background refresh behavior.
- Verify behavior with notifications disabled.
- Verify behavior with Background App Refresh disabled.
- Verify Dynamic Type and VoiceOver.
- Verify English-only localization assumptions and text expansion.
- Verify offline and poor-network behavior.
- Run Instruments one final time for leaks, memory growth, and performance problems.
- Review all user-facing error messages and recovery paths.
- Include SwiftData migration testing in release validation whenever a schema change is introduced.
- Maintain representative persistent stores from previously shipped schema versions for upgrade testing.

## TestFlight Release Candidate

- Create the release-candidate build.
- Invite final external testers.
- Address remaining beta feedback.
- Remove, hide, or appropriately gate developer-only diagnostics.
- Confirm which diagnostics remain intentionally available to users.
- Increment version and build numbers for release.
- Confirm the release candidate matches the screenshots and App Store description.
- Once the release candidate is accepted as the final v1.0 build, create and push a v1.0 Git tag to preserve the exact code and documentation shipped to the App Store.

## App Store Connect

- Create the production app version.
- Upload and select the release-candidate build.
- Complete “What’s New” release notes.
- Upload screenshots and other assets.
- Complete pricing and availability.
- Select countries and regions.
- Configure the age rating.
- Complete App Review information.
- Provide review notes explaining any behavior that may not be obvious.
- Provide a demo account only if one becomes necessary.
- Submit the app for review.

## Launch

- Decide between automatic release and manual release after approval.
- Publish launch announcements on LinkedIn, GitHub, and the project website.
- Monitor App Review status and respond promptly to reviewer questions.
- Monitor crash reports, reviews, and support messages after launch.
- Prioritize launch-related fixes before beginning major new features.
