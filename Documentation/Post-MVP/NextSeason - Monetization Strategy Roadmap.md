# NextSeason Monetization Strategy

## Purpose

This document describes the planned monetization structure for NextSeason.

The goal is to create a simple and sustainable revenue model that fits the app's core promise: NextSeason quietly remembers the shows a user cares about and lets them know when something changes.

The monetization experience should be similarly simple. It should avoid unnecessary tiers, advertising, artificial feature restrictions, and frequent prompts to spend money.

Specific prices have not yet been determined.

## Guiding Principles

The monetization model should:

- Allow users to experience the core value of NextSeason before paying.
- Provide ongoing revenue to support maintenance of the app and its third-party data integrations.
- Keep the distinction between free and paid service easy to understand.
- Avoid adding features or complexity merely to justify a subscription.
- Avoid advertising and the privacy, maintenance, and user-experience costs associated with ad networks.
- Avoid repeatedly interrupting or pressuring users to make purchases.
- Provide an option for users who strongly prefer not to maintain another subscription.

## Free Tier

NextSeason will be free to download and use with a limited watchlist.

### Planned limit

**Up to 3 shows**

The free tier does not expire. Shows on the free watchlist continue to receive the same tracking and notification functionality as shows on a paid watchlist.

This replaces the previously considered seven-day trial.

A permanent free tier is preferable because the value of NextSeason may not become apparent within a short trial period. A user may add a show and wait weeks or months before NextSeason discovers and reports a meaningful update.

The free tier allows users to experience that value naturally before deciding whether they need the paid version.

## Paid Tier

The paid tier removes the watchlist limit.

### NextSeason Plus

**Unlimited show tracking**

There should be only one paid feature level rather than separate 5-, 10-, and 20-show plans.

A single paid entitlement:

- Is easier for users to understand.
- Avoids forcing users to predict how many shows they will want to track.
- Eliminates complicated upgrade and downgrade behavior between capacity levels.
- Keeps the purchasing and entitlement implementation simpler.
- Fits the overall philosophy of keeping NextSeason focused and uncomplicated.

## Purchase Options

The current preferred structure is:

### Annual Subscription

NextSeason Plus may be offered as an annual auto-renewing subscription.

An annual subscription fits the nature of the service better than a monthly subscription because NextSeason provides value over long periods. A user may wait many months or more than a year for information about a future season.

The subscription supports the continuing service involved in maintaining NextSeason, including:

- Monitoring and processing television data.
- Maintaining compatibility with third-party APIs and services.
- Maintaining the show's data-mapping infrastructure.
- Keeping the app compatible with future versions of iOS.
- Fixing bugs and maintaining reliability.
- Continuing to deliver season information and notifications.

A subscription does **not** imply that NextSeason must continually add new features. The ongoing value is the continuing tracking service itself.

### Lifetime Purchase

A non-consumable lifetime purchase should also be considered.

This would permanently unlock NextSeason Plus for users who prefer a one-time purchase rather than a subscription.

The lifetime price should be high enough that it does not undermine the sustainability of the annual subscription.

### Monthly Subscription

A monthly subscription remains an option but is not currently preferred.

The long-term nature of NextSeason makes annual billing a more natural fit, and eliminating a monthly option would further simplify the purchase decision.

A monthly option can be added later if user feedback indicates that it would be valuable.

## Optional Developer Support

NextSeason may include an optional **Support NextSeason** section, most likely within the About screen.

This would provide a small tip jar using consumable StoreKit in-app purchases.

Possible choices could include several tip amounts, with exact amounts and wording to be determined later.

Tips:

- Do not unlock functionality.
- Are entirely optional.
- Are available to both free and paid users.
- May be purchased more than once.
- Should not be promoted through repeated prompts or interruptions.

The purpose is simply to give users who appreciate the app another way to support its continued development.

The tip jar should be implemented as part of the overall StoreKit purchasing architecture rather than as a separate third-party service.

## Advertising

NextSeason will **not** use advertising.

Advertising is a poor fit for the app because successful use of NextSeason should require very little time in the app. Users should be able to add shows to their watchlist and rely on NextSeason to work quietly in the background.

Low expected ad impressions do not justify the additional:

- Third-party dependencies.
- Privacy considerations.
- Maintenance burden.
- User-interface clutter.
- Potential degradation of the user experience.

## StoreKit Architecture

The final StoreKit implementation should be designed as one purchasing system capable of supporting:

- The NextSeason Plus entitlement.
- Annual subscriptions.
- A lifetime non-consumable purchase.
- A monthly subscription if one is eventually offered.
- Consumable tips.

Whether to use StoreKit 2 directly or a service such as RevenueCat should be decided when the purchasing architecture is designed.

Native StoreKit 2 is preferred if it can handle NextSeason's requirements cleanly without introducing unnecessary complexity or infrastructure.

## Review Request

App Store review requests should be implemented separately from monetization but should follow the same non-intrusive philosophy.

NextSeason should request a review only after it has demonstrated meaningful value to the user—for example, after successfully detecting a season update for a watched show and after the user has had an opportunity to see that information.

Review requests should not interrupt an active task or appear simply because the app has been launched a certain number of times.

A persistent **Rate NextSeason** option may also be provided in the About screen.

## Pricing

Specific prices for NextSeason Plus, the lifetime purchase, and optional tips are **TBD**.

Pricing should be decided closer to implementation after considering:

- Comparable App Store products.
- Expected customer behavior.
- Apple's commission structure, including Small Business Program eligibility.
- The relationship between annual and lifetime pricing.
- Expected ongoing operating and maintenance costs.
- The value of keeping the purchasing decision simple.

## Current Proposed Structure

| Offering | Watchlist | Payment |
| --- | --- | --- |
| NextSeason Free | Up to 3 shows | Free, no expiration |
| NextSeason Plus | Unlimited | Annual subscription |
| NextSeason Plus Lifetime | Unlimited | One-time purchase |
| Support NextSeason | No additional functionality | Optional consumable tips |

A monthly NextSeason Plus subscription remains under consideration but is not part of the preferred initial structure.

## Status

**Proposed — not yet implemented.**

The overall structure may change in response to implementation considerations, beta feedback, App Store requirements, or experience after launch.
