> From: https://chatgpt.com/c/6a5e898c-4b3c-83e8-ab8b-1a38bb69fe8f

# you asked

message time: 2026-07-20 13:50:38

One of my beta testers has pointed out something that I have been thinking about myself.  Using TVMaze with it's 10 result limit on search is fine for the MVP as far as my portfolio goes, but it isn't going to cut it when the app goes into the store, especially if I end up deciding to charge money for it.  I'd like to know your thoughts on this, and if you agree, should we be splitting the post-MVP roadmap into two pieces, one for before the first App Store release and one for after?

---

# chatgpt response

I actually think this discussion exposes something important: **your MVP and your first commercial release are no longer the same thing.**

Originally we treated them as synonymous:
- MVP = prove the concept
- Beta = validate it
- App Store = ship it

But over the last week we've already drifted away from that model. Watchlist Search, for example, started life as a post-MVP feature and then we decided it really belonged before launch because it materially affects the user experience. 

I think the TVMaze search limit falls into exactly the same category.

## The 10-result limit isn't just "another feature"

There are lots of things users can forgive in version 1.0:

- no widgets
- no iPad support
- no cloud sync
- no Siri
- no streaming services
- no recommendations

Those are all missing capabilities.

Search is different.

If someone searches for a common title and the show simply isn't in the first ten results, they'll conclude:

> "This app can't find my show."

That's not perceived as a missing feature.

It's perceived as the app not working.

That's a much bigger problem.

## Charging money changes the standard

This is the part I think you've been feeling.

When the app is free, people are surprisingly tolerant.

When they're paying—even $2.99—they expect the fundamentals to be solid.

The core promise of NextSeason is:

> Search for a TV show, add it to your watchlist, and we'll tell you when another season appears.

If the search routinely fails to find shows because of an arbitrary API limit, then the core promise starts to break down.

## So should multi-provider search happen before launch?

Today, I'd say **probably yes.**

Not necessarily because you need TVDB specifically.

But because you need **a search experience you're willing to stand behind**.

That might mean:

- switching APIs entirely
- combining TVMaze with TVDB
- combining TVMaze with TMDb
- implementing progressive search ("Show more")
- caching results
- something else

The implementation is a technical decision.

The product requirement is simply:

> Users should almost always be able to find the show they're looking for.

## I think it's time to split the roadmap

Originally I argued against organizing by release numbers because we didn't know what users would actually want.

I still believe that for the long-term roadmap.

But we're in a different situation now.

There is now a very natural boundary:

### Phase A — Before First Public App Store Release

This isn't MVP anymore.

It's "minimum commercially acceptable."

Things that directly affect first impressions or core functionality belong here.

Examples:

- Better search experience
- Reliable notification strategy (likely involving a backend rather than depending on the app running in the background)
- App icon replacement (using original artwork rather than SF Symbols)
- Final onboarding/release polish
- Any App Store review blockers

### Phase B — After Launch

Everything that makes the product richer rather than merely trustworthy.

Examples:

- Widgets
- Siri
- iPad
- Mac
- Apple TV
- Cloud sync (if not already required by the notification architecture)
- Streaming providers
- Swipe actions
- Analytics-driven enhancements
- Anything users request after release

## One interesting consequence

This also changes how you think about risk.

Until now we've mostly asked:

> "Does this belong in MVP?"

The more useful question becomes:

> "Would a reviewer notice this during their first week?"

If the answer is yes, it's a candidate for the pre-launch roadmap.

If the answer is no, it can probably wait until version 1.1 or later.

## My recommendation

I would rename the roadmap sections to something like:

1. **Pre-Launch Enhancements** (everything required before the first App Store release)
2. **Post-Launch Roadmap** (everything after customers begin using it)

That gives you a clean planning boundary without committing yourself to arbitrary version numbers. The long-term roadmap can still stay organized by product area—as we've discussed before—but everything above the line becomes "this is what makes NextSeason ready to sell."

I also suspect that if we go through your existing roadmap with this mindset, only a handful of items will migrate upward. Most of the roadmap is still exactly where it belongs. It's just that we've now identified a small set of issues—search quality, notification reliability, and a few release-readiness items—that affect the app's credibility on day one. Those deserve to be treated differently from ordinary future enhancements.

---
Powered by [AI Exporter](https://saveai.net)