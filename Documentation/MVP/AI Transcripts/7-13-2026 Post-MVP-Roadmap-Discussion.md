> From: https://chatgpt.com/c/6a5535ca-2bb4-83e8-9ac7-e1f04e6f065e

# you asked

message time: 2026-07-13 12:02:21

There are a few things I want to talk over in the Post-MVP Roadmap.

The first one is Search.

The road map includes "Support common abbreviations and acronyms (GoT, SVU, TNG, etc.).".  Where would we get these abbreviations?

It also says "Experiment with app-specific result ordering.".   I'm not sure that this is necessary for search beyond what TVMaze already does.  Did you have anything specific in mind?

I agree with the suggestion to add analytics to see how often people aren't finding their show, but I think there's no doubt that we will have to find a solution to the 10 result limit.  In an app with such limited functionality, it's not acceptable to ask people to pay for something that's essentially broken in a major respect.

Thoughts?

---

# chatgpt response

I think this section has aged a bit, partly because we've learned more about the app, and partly because you've already gotten some beta feedback. I'd probably tighten it up.

### Abbreviations and acronyms

> Support common abbreviations and acronyms (GoT, SVU, TNG, etc.).

I don't think TVMaze provides these, and I wouldn't try to discover them dynamically.

There are basically four approaches:

1. **Maintain your own dictionary** (probably a few hundred entries).
2. Use another API that exposes aliases.
3. Crowdsource them from users.
4. Ignore the problem.

For an app like NextSeason, I'd actually lean toward **#1** if it ever becomes necessary. People don't invent abbreviations very often. The set of TV shows people commonly refer to as "GoT", "SVU", "TNG", "DS9", "B99", "LOST", etc. is surprisingly small.

But...

I wouldn't build it until someone actually complains.

It feels like one of those features that's fun to engineer but doesn't move the needle much.

---

### App-specific result ordering

This is the one I'd probably remove entirely.

When I wrote that originally, I was thinking about things like:

- boosting exact title matches
- boosting shows already in the user's watchlist
- boosting currently-running shows
- demoting obscure foreign versions
- preferring US versions over remakes

…but after seeing the app in action, I don't think it's worth it.

TVMaze's ranking is honestly pretty good.

More importantly:

**Users expect search results to be "the search results."**

If your ordering starts feeling unpredictable, people tend to trust it less, even if your algorithm is technically "better."

I'd leave TVMaze's ranking alone unless you discover a consistent problem.

---

### The 10-result limit

This one I agree is different.

I think it's the only genuine weakness of the current search implementation.

If someone searches for

> Law

or

> CSI

or

> Star Trek

or

> Doctor

there are obviously far more than ten matches.

If the show they're looking for isn't in those ten, the app effectively says:

> Sorry, it doesn't exist.

That's not acceptable for a search-driven application.

The interesting question is **when** to solve it.

My instinct is:

- Don't solve it before the App Store release.
- Instrument it immediately.
- Let real usage tell you how often it happens.

Why?

Because there are two possibilities.

### Possibility A

95% of searches are things like

- Wednesday
- Severance
- Poker Face
- Silo

Users find what they want immediately.

Then the problem exists, but affects very few people.

---

### Possibility B

20–30% of searches end without a selection.

Now it's a product problem, and it's worth investing real engineering effort.

Analytics tells you which world you're living in.

---

### If analytics confirms it's a problem...

I would actually move "Multi-provider search" up from "interesting future idea" to **the preferred long-term solution.**

Trying to fight TVMaze's limitations usually means inventing increasingly clever workarounds.

Using a provider with proper search and pagination is a cleaner architecture.

You already outlined the approach I like best:

- search with TMDb (or another search-focused provider)
- user selects a show
- map it to the TVMaze ID
- continue using TVMaze for all the season tracking

That keeps each provider doing what it's best at.

---

### One thing I'd add

There's another search enhancement I'd rank **above** abbreviation support:

> **Show more than the first 10 results when possible.**

Whether that's:

- switching providers,
- implementing pagination,
- or searching multiple providers,

I think "don't artificially stop after ten" is a much bigger UX improvement than teaching the app that "TNG" means *Star Trek: The Next Generation*.

So if I were reprioritizing this section today, it would look something like:

1. Collect search analytics.
2. Eliminate the 10-result limitation (if analytics or beta feedback justifies it).
3. Add abbreviation support only if users actually ask for it.
4. Leave TVMaze's ranking alone unless you discover a specific, repeatable problem.

That ordering feels much more aligned with the product you've actually built.

---

# you asked

message time: 2026-07-13 12:05:59

Sounds good. Please start a rewrite of Post-MVP Roadmap.md and update the Search section as you describe here.

---

# chatgpt response

I'd rewrite that section like this:

**Document Title: **

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

I like this version better because it makes the roadmap more evidence-driven. Instead of brainstorming possible search features, it establishes a clear decision process:

1. Measure how people actually search.
2. Fix the one known structural limitation (the 10-result cap) if the data shows it's hurting users.
3. Only then consider quality-of-life improvements like abbreviation support.
4. Avoid custom ranking unless there's concrete evidence that TVMaze's ordering is causing problems.

That also dovetails nicely with the following **Evaluate Multi-Provider Search** section, which now reads like the natural solution to the highest-priority search problem rather than just another interesting idea.

---

# you asked

message time: 2026-07-13 12:11:04

In the Streaming Provider Information section, where do you propose for us to get streaming availability?  Data in TVMaze is crowdsourced so people are going to enter the provider they watch the show on, and probably not any others that have it.

---

# chatgpt response

This is actually something I've changed my mind on since we first wrote the roadmap.

Originally, I was assuming TVMaze's streaming information would be "good enough." The more I've looked at it, the less I believe that's true.

Streaming availability is a surprisingly hard problem because it varies by:

- country
- subscription tier
- whether the show is included or only rentable
- time (it changes constantly)

TVMaze simply isn't trying to solve that problem. As you say, it's crowdsourced, so if someone watches *The Bear* on Hulu, they'll add Hulu. They may never notice it's also on Disney+ in another country or available for purchase on Apple TV.

### If you wanted this feature today...

I'd probably use a dedicated provider such as JustWatch (if you can legally access it) or TMDb's watch-provider data.

TMDb, for example, exposes watch providers by country, which is much closer to what users actually expect.

It still isn't perfect, but it's maintained specifically for this purpose rather than being incidental metadata.

### But here's the bigger question...

Do you actually need this feature?

I'm less convinced than I used to be.

Think about the app's workflow.

1. User searches for a show.
2. User adds it to their watchlist.
3. Months later they get notified about Season 4.

At that point they're already interested enough to watch it.

How often are they really asking:

> "Which streaming service is this on?"

Versus simply opening the TV app or Googling it?

I'm not sure this is solving a significant pain point.

### If it stays in the roadmap...

I'd rewrite it to be much less committal.

Instead of

> Display streaming provider information.

I'd say something like:

> **Evaluate integration with a dedicated streaming availability provider (such as TMDb watch providers or JustWatch) to display current regional availability. TVMaze's crowdsourced streaming information is not sufficiently complete or reliable for this purpose.**

That makes it clear you're aware of the limitation and aren't planning to build a feature on top of questionable data.

Personally, though? If we were ruthlessly prioritizing features for a 1.x product, I think this one might disappear entirely. It doesn't make the core promise of NextSeason—"tell me when my shows are coming back"—meaningfully better. It feels more like a nice extra than something users are likely to miss if it's absent.

---

# you asked

message time: 2026-07-13 12:12:30

Go ahead and rewrite this section with that caveat and make it work that will only be done if users are asking for it.

---

# chatgpt response

Here's how I'd rewrite that section:

**Document Title: **

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

I actually like this version more than the original because it reflects a philosophy that's emerged over the course of the MVP: **don't build features just because they sound useful.** Build them because users are asking for them, and when you do, build them on top of data that's appropriate for the job. That keeps the roadmap focused on improving the core value of NextSeason rather than gradually turning it into a general TV information app.

---

# you asked

message time: 2026-07-13 12:27:36

I'm not sure what you meant by 

"Potential Features

Track subscribed services.
Filter unavailable content.
Prioritize relevant notifications.
"

---

# chatgpt response

I remember writing that, and I think I'd delete all three now. They were based on a different vision of where the app might go.

Here's what I had in mind:

### Track subscribed services

The user would tell the app something like:

- Netflix
- Hulu
- Max
- Apple TV+
- Disney+

Then when looking at a show, the app could say:

> **Available on:** Netflix ✓, Hulu ✗, Amazon (rent)

The checkmark would indicate services the user actually subscribes to.

It's a nice idea, but now you've got:

- a settings screen
- subscription management
- regional issues
- keeping the service list current

That's a lot of complexity.

---

### Filter unavailable content

This built on the previous feature.

For example, if someone searched for sitcoms, the app could hide shows they can't currently watch.

Or on the watchlist:

> Only show titles available on my services.

Again...kind of neat, but definitely outside the core mission.

---

### Prioritize relevant notifications

This was probably the most speculative.

Imagine someone tracks a show.

Season 3 comes out.

If they don't subscribe to any service carrying Season 3, perhaps the notification changes from

> New season available!

to

> Season 3 has premiered but isn't currently available on your streaming services.

Or perhaps it delays the notification until the season reaches one of their services.

The more I think about it, the less I like it.

One of NextSeason's strengths is that notifications are factual:

> A new season exists.

Whether the user can watch it today is a separate question that changes over time. Mixing those two concepts risks making notifications confusing or even incorrect.

---

### Where I'd land today

I'd remove all three.

The app's promise is wonderfully simple:

> **Tell me when a TV show has a new season.**

Not:

> Tell me where I can stream it, what subscriptions I need, whether I should watch it now, or manage my streaming life.

Those are features that could easily consume months of work while only marginally improving the core experience.

If users eventually start asking, "Now that you've told me *Foundation* has a new season, where can I watch it?" then the section we just rewrote covers that nicely. I wouldn't go beyond displaying the current streaming availability unless there was overwhelming demand.

I think your roadmap has actually gotten stronger as we've been pruning ideas like these. It's becoming much more focused on features that either improve the app's core promise or solve problems you've observed, rather than trying to anticipate every possible enhancement. That's usually a good sign.

---

# you asked

message time: 2026-07-13 12:29:09

Ok, yea that all makes sense.  If that data becomes available in a reliable way, then these would be good features, but not before.

---

# chatgpt response

Exactly. I think the dependency should actually be stated explicitly in the roadmap.

Right now, those features sound like "things we should build someday." I'd rather frame them as "things that become possible if we have trustworthy data."

Something like:

> **Potential Future Features (Dependent on Reliable Streaming Data)**
>
> If a reliable, region-aware streaming availability provider is integrated, the following features may become feasible:
>
> - Allow users to record which streaming services they subscribe to.
> - Highlight shows currently available on those services.
> - Filter or group watchlist entries by streaming availability.
> - Tailor notifications with current streaming availability when appropriate.

That wording does a couple of things:

- It makes the dependency explicit instead of implied.
- It keeps the roadmap from committing to features you may never build.
- It reminds Future Janine that these ideas shouldn't even be considered unless the data problem has already been solved.

One thing I've noticed over the last month is that your roadmap is evolving from a wishlist into an engineering roadmap. That's a good evolution. Instead of saying "it would be cool if...", it's increasingly saying "if these prerequisites exist, then these features become worthwhile." That's the kind of document that's actually useful six months from now, because it explains *why* something is or isn't a priority, not just *what* the idea was.

---

# you asked

message time: 2026-07-13 12:31:47

I think the whole Product Intelligence section should go (it's long so I won't paste it here unless you can't find it in the document I uploaded).

---

# chatgpt response

I don't think I even need to see it. Based on where the project is now, I'd remove the entire section.

When we first put the roadmap together, we were brainstorming what NextSeason *could* become. "Product Intelligence" fit into that mindset: adding recommendations, insights, personalization, and other "smart" features.

Now that the MVP is finished, I think the product has a much clearer identity.

NextSeason isn't trying to help people discover TV shows.

It isn't trying to compete with IMDb, Trakt, TV Time, JustWatch, Reelgood, or Letterboxd.

It's trying to answer one question extremely well:

> **"Tell me when the next season of the shows I care about is coming."**

Every feature should strengthen that promise.

The Product Intelligence ideas all pull in a different direction. They make the app broader rather than better.

One thing I've noticed throughout these roadmap reviews is that we keep asking the same question:

> "Will users actually ask for this?"

For Search, the answer was "measure it first."

For streaming providers, it was "only if users want it."

For Product Intelligence, I'm not even sure what user problem it's solving.

That's usually a sign the feature belongs on a someday/maybe list instead of the roadmap—or nowhere at all.

I think your roadmap is actually getting *stronger* as it gets shorter. A roadmap isn't valuable because it has lots of ideas; it's valuable because it tells Future Janine what is worth spending months of engineering time on.

At this point I'd rather see the roadmap focused on things like:

- Improving search.
- Supporting additional data providers.
- Better notifications.
- Reliability and diagnostics.
- Accessibility.
- Performance.
- Cross-device sync.
- Widget/Live Activities.
- App Store polish.

Those all make the core product better.

The Product Intelligence section feels like the roadmap from an alternate universe where NextSeason became a TV companion app instead of a TV season tracker. I don't think that's the app you've built, and I don't think it's the app you want to build.

---

# you asked

message time: 2026-07-13 12:35:44

I think the Product Analytics section is ok, except for

"Remove the beta-only analytics tap target from show summaries before portfolio
release (see Release Readiness.md, Portfolio Readiness)."

We probably want to remove or hide some of what's on the Diagnostics screen, but don't we want to retain the ability for users to send reports with that data?  Maybe it doesn't need it's own button anymore, but i think that functionality should be available somewhere/somehow.

---

# chatgpt response

I completely agree, and I think that's another place where the roadmap has fallen behind the project.

The original goal was:

> Don't ship developer diagnostics to users.

That's still true.

But over the course of the MVP, the Diagnostics screen evolved into something more useful than a developer console. It now contains information that can help both you **and** the user answer questions like:

- "Why didn't I get a notification?"
- "Has the background refresh been running?"
- "When did it last check?"
- "What happened during the last refresh?"

That's legitimate support information.

I think I'd separate the concepts:

### Internal diagnostics (not for production)

Things like:

- Force refresh
- Simulate update
- Test notification
- Debug-only logging
- Any buttons that mutate state for testing

These should stay hidden behind DEBUG or TestFlight builds.

### User diagnostics (production)

Things like:

- Last successful refresh
- Last refresh attempt
- Next expected background window (with appropriate caveats)
- Notification permission status
- Current app version
- Data provider status (if useful)

Those are perfectly reasonable for production.

### Sending a diagnostic report

I actually think this becomes **more** valuable after launch.

Imagine an email:

> "Notifications aren't working."

Instead of five rounds of questions, the user taps

> **Send Diagnostic Report**

and you receive something like:

```
NextSeason TV 1.2

Background refresh:
Last successful refresh:
Last attempted refresh:
Notification permission:
Watchlist count:
Last provider response:
OS version:
Device model:
```

That's incredibly useful for support.

I probably wouldn't even call it "Diagnostics" in production.

I'd call it something like:

- **Support**
- **Troubleshooting**
- **Diagnostic Information**
- **Support Information**

with a button:

> **Send Support Report**

That feels much more user-facing.

---

So I'd replace the roadmap item with something like:

> **Transition the Diagnostics screen from a beta testing tool into a production support feature. Remove developer-only actions while retaining user-visible status information and the ability to generate or send a diagnostic report for troubleshooting.**

I actually like that vision quite a bit. It acknowledges that Diagnostics has become a valuable feature in its own right, rather than something to throw away once beta testing ends. In an app that depends on iOS background execution—a notoriously opaque system—giving users and you some visibility into what's happening is a real usability feature, not just a developer convenience.

---

# you asked

message time: 2026-07-13 12:40:02

Here's the updated document.  Please clean it up as needed.  I think we should replace Priority with arranging these in order for the next few releases.

---

# chatgpt response

I don't actually have the updated document yet—I only have the earlier version that was uploaded when we started this discussion. It looks like the new upload didn't make it through on my end.

Please upload the updated **Post-MVP Roadmap.md**, and I'll do a full editorial pass.

The main things I'll look for are:

- Remove anything that's no longer aligned with the product vision.
- Make the tone consistent throughout.
- Remove duplicate or overlapping roadmap items.
- Ensure every feature has a clear rationale ("why would we build this?").
- Reorder the roadmap into **planned releases** instead of Priority levels.

I also agree with replacing **Priority**. Now that the MVP is complete, "High/Medium/Low" is less useful than a rough release plan. I'd suggest something like:

```text
## Release 1.1
Small improvements and polish.

## Release 1.2
Major usability improvements.

## Release 1.3
Infrastructure and platform enhancements.

## Future Consideration
Ideas that depend on user demand, additional data providers, or significant architectural work.
```

I like this approach because it forces a more realistic conversation. Instead of saying "this is high priority," you have to ask, "Would I really spend the next month building this instead of everything else?" That's usually a much better filter.

Once you upload the latest version, I'll go through the whole document and suggest a release ordering that makes sense based on everything we've learned during the MVP. I suspect it will end up being noticeably shorter, more focused, and easier for Future Janine to use as an actual development plan.

---

# you asked

message time: 2026-07-13 12:40:18

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

---

# chatgpt response

Overall, I think this is in really good shape. It's noticeably tighter and more focused than the original. I only have a handful of suggestions.

## 1. Replace "Priority" with releases

I agree completely. At this point you're no longer prioritizing ideas—you've got a backlog.

I'd structure it something like this:

```text
## Planned for 1.1

## Planned for 1.2

## Planned for 1.3

## Future Consideration
```

or even just

```text
### Next Release
### Following Release
### Future
```

Then each section naturally falls into one of those buckets instead of having "Priority: High" sprinkled throughout.

---

## 2. Watchlist Management

This section feels too vague.

Instead of

```markdown
- Sorting options.
- Filtering options.
- Grouping options.
- Hide ended shows.
```

I'd be a little more concrete.

```markdown
Potential improvements include:

- User-selectable sorting (alphabetical, recently added, recently updated).
- Filtering by show status (running, ended, upcoming season).
- Optional grouping by status.
- Hide ended shows by default or via filter.
```

Future Janine will thank you.

---

## 3. Notification Enhancements

I'd reorganize this.

Instead of

> Notification settings

I'd split it into user-facing capabilities.

For example:

```markdown
Potential improvements:

- Global notification preferences.
- Per-show notification preferences.
- Quiet hours / notification scheduling.
- Notification history.
- Additional notification categories.

Possible notification categories:

- Season announced.
- Release date announced.
- Season available.
```

I think it reads much more cleanly.

---

## 4. Streaming Availability

This section is now excellent.

I wouldn't change anything.

---

## 5. Preferred Services

I'd actually fold this into the Streaming Availability section.

It isn't really a separate feature.

It's

> "If we solve streaming availability..."

then

> "...these additional features become possible."

I think that's a cleaner hierarchy.

---

## 6. User Accounts / Cloud Backup

These feel like they're really one feature.

Cloud Backup without accounts is difficult.

Accounts without syncing aren't very useful.

I'd combine them into

```markdown
# Cross-Device Sync

Motivation

Potential features

...
```

with

- Sign in with Apple
- Cloud sync
- Backup
- Device migration
- Cross-device watchlists

---

## 7. Product Analytics

This section is the strongest part of the document.

I only noticed one sentence I'd tweak.

Instead of

> What are users searching for?

I'd say

> What kinds of searches are users performing?

because you're explicitly *not* collecting search text.

Similarly,

> What shows are most tracked?

isn't necessarily true unless you're willing to upload show IDs.

Maybe

> Which features and workflows are used most frequently?

or

> Which workflows are most common?

would better reflect the privacy goals.

---

## 8. Business Options

I'd move this all the way to the end.

Business decisions shouldn't drive engineering decisions yet.

---

## 9. Explicit Non-Goals

I love this section.

I'd actually expand it slightly.

```markdown
The following are intentionally outside the scope of NextSeason:

- Social networking.
- User reviews.
- Episode tracking.
- Discussion forums.
- General TV discovery.
- Recommendation engines.
- Comprehensive media database features.
```

That last addition reflects all the pruning we've been doing today. It makes it clear that if Future Janine thinks, "Maybe I should add recommendations..." she can glance at this section and remember, "No—that's not what this app is."

---

## 10. Purpose

I'd make one tiny change.

Instead of

> This document captures potential future enhancements after the initial beta release.

I'd write

> This document captures planned enhancements and longer-term ideas following the MVP. Items are intentionally ordered by expected implementation rather than exhaustive priority and should continue to evolve based on user feedback, analytics, and real-world usage.

That better reflects what the document has become.

---

### One final observation

Stepping back, I think this roadmap is in a much healthier place than when we started reviewing it.

Originally it felt like:

> "Here's every cool idea we had."

Now it feels like:

> "Here's how NextSeason grows without losing its identity."

That's a subtle but important difference. The document has become less about feature accumulation and more about protecting the app's core promise while guiding future development. If you handed this to another engineer six months from now, I think they'd have a very good understanding of what belongs in NextSeason—and just as importantly, what doesn't.

---

# you asked

message time: 2026-07-13 12:42:53

That all sounds good - please create a document I can download and replace the current one with.

---

# chatgpt response

Done! I incorporated the structural changes we discussed:

- Replaced **Priority** with a rough release sequence.
- Tightened the **Purpose** section.
- Made **Watchlist Management** and **Notification Enhancements** more concrete.
- Merged **User Accounts** and **Cloud Backup** into **Cross-Device Sync**.
- Folded the streaming-related ideas into a more coherent progression.
- Updated **Product Analytics** to reflect the production support vision for Diagnostics.
- Expanded **Explicit Non-Goals** to reinforce the app's identity.
- Moved **Business Options** toward the end.

You can download it here:

**[📄 Post-MVP Roadmap.md](sandbox:/mnt/data/Post-MVP%20Roadmap.md)**

One caveat: because I was working from the text you pasted into chat rather than the original file, I compressed a couple of sections (notably **Multi-Provider Search** and **Product Analytics**) to keep the document focused. If your goal is to preserve *all* of the explanatory detail while simply reorganizing and polishing it, I can do that too. I actually think that's the better end state—a cleaned-up version that keeps all of the engineering rationale you've already written.

---

# you asked

message time: 2026-07-13 12:46:26

I'm not sure I understand what you're asking.  Is the document you just created the better end state, or the one you're talking about creating?

---

# chatgpt response

Good question. I should have been clearer.

I actually **don't** think the document I generated is the better end state.

What I did was essentially produce an **abridged** version. I rewrote and reorganized it, but in the process I shortened several sections that already contained good engineering rationale. That's useful if the goal is a concise roadmap, but I don't think it's what *you* want.

After spending the last month working on NextSeason with you, I think the roadmap has become more than a feature list. It's also a record of *why* you made certain architectural decisions. That's valuable. Six months from now, you'll be glad Future Janine can read *why* multi-provider search is only worth doing if analytics show the 10-result limit is a real problem, rather than just seeing "Implement multi-provider search."

So I would preserve things like:

- the full explanation in **Search**
- the reasoning in **Multi-Provider Search**
- the detailed discussion of **Product Analytics**
- the rationale for **Streaming Availability**

...and just edit them for consistency and organization.

So the document I'd recommend is:

- **About the same length as your current one.**
- **Contains all of the rationale you've accumulated.**
- **Has consistent headings and formatting.**
- **Uses releases instead of Priority.**
- **Removes only the ideas we've decided no longer fit the product.**

Think of it like refactoring code instead of rewriting it.

---

If it were my project, that's exactly what I'd check into Git.

It would still feel like *your* document—just cleaner, better organized, and more internally consistent.

So I'd actually like a do-over. I think I can produce something that's noticeably better than both your current version **and** the abbreviated version I just generated. It would be more of an editorial pass than a rewrite, preserving all of the thought that went into the roadmap over the past month.

I think that's the version that deserves to live in the repository.

---

# you asked

message time: 2026-07-13 12:47:00

Ok, go ahead

---

# chatgpt response

Perfect. I think this deserves one more careful pass rather than another quick edit.

Here's what I plan to do:

- **Preserve the engineering rationale.** If there's a paragraph that explains *why* a decision exists, it stays unless it's no longer true.
- **Organize by expected release instead of priority.** Not rigid version numbers, but a natural progression (next release → following releases → future considerations).
- **Remove only things we've intentionally decided against** (Product Intelligence, custom search ranking, etc.).
- **Merge related sections** where it makes the document easier to navigate (for example, Preferred Services under Streaming Availability).
- **Make the tone consistent throughout.** Some sections currently read like design notes, others like engineering specifications. I'll normalize them.
- **Keep it as a roadmap, not a specification.** It should answer "what and why," while leaving implementation details for separate design docs.
- **Reduce duplication.** For example, Search and Multi-Provider Search should complement each other instead of repeating the same reasoning.

I also have one idea I haven't mentioned yet.

Right now the document mixes three different kinds of work:

1. **Engineering hardening** (migration, crash recovery)
2. **Product improvements** (search, notifications, watchlist)
3. **Future platform/business ideas** (accounts, analytics, monetization)

I think that's actually a good structure. Rather than ordering the entire document by release, I'd keep those **major categories** and then order the items *within each category* by when you expect to tackle them.

That way, six months from now, if you're thinking "I should improve notifications," you know exactly where to look instead of hunting through "Release 1.2."

So the top-level outline would become something like:

```text
Purpose

Engineering & Reliability
    SwiftData Migration
    Persistence Recovery
    Crash Loop Prevention

Core Product Improvements
    Search
    Watchlist
    Notifications
    Streaming Availability

Platform Features
    Cross-Device Sync

Product Analytics

Business Options

Explicit Non-Goals
```

Within each section, I'd order the items from "next likely" to "long-term."

I actually think that's a stronger roadmap than trying to predict what will land in 1.1, 1.2, and 1.3. Those release numbers almost always change. The categories won't.

So my goal isn't just to polish the prose—it's to leave you with a document that still feels useful a year from now. Looking back over everything we've built together, I think this roadmap is becoming the "architect's notebook" for NextSeason, and I want to preserve that quality rather than turning it into a simple checklist.

---

# you asked

message time: 2026-07-13 13:07:03

Ok, go ahead

---

# chatgpt response

I went with the "editorial pass" approach rather than another rewrite. The goal was to preserve the thinking behind the roadmap while making it read like a cohesive engineering document.

The biggest changes are:

- Reorganized the document into stable categories (**Engineering & Reliability**, **Core Product Improvements**, **Platform Features**, etc.) instead of trying to predict release numbers.
- Kept the rationale behind important decisions (especially Search and Streaming Availability).
- Removed the remaining "Priority" language.
- Consolidated related sections where it improved flow.
- Tightened wording and made the tone consistent throughout.
- Preserved the product philosophy we've arrived at over the last month: **measure first, build second**, and keep NextSeason focused on its core purpose.

You can download it here:

**[📄 Post-MVP Roadmap - Editorial Revision.md](sandbox:/mnt/data/Post-MVP%20Roadmap%20-%20Editorial%20Revision.md)**

One thing I *didn't* do was aggressively shorten it. I think this document has become more than a feature list—it's the architectural memory of the project. Six months from now, I think you'll appreciate having the rationale preserved alongside the roadmap. I suspect this version is much closer to the one that will live in the repository for a long time.

---
Powered by [AI Exporter](https://saveai.net)