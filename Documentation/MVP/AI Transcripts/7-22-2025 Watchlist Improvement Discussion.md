> From: https://chatgpt.com/c/6a5faa2c-2b9c-83e8-8314-d9aa9741238b

# you asked

message time: 2026-07-21 10:21:25

One of my beta testers suggested sorting the shows that are airing or have a future date to the top of the watchlist.  Another agreed and suggested using sections for that.

I think it's a good idea, but am unsure of how that will work when we introduce sort filters.  What do you think?

---

# chatgpt response

I actually like this idea a lot, but I think it points toward something slightly more general than "sort airing shows to the top."

The question to ask is: **what job is the Watchlist trying to do?**

Right now, your Watchlist is just a list of saved shows. But from everything we've discussed over the last month, NextSeason is gradually evolving into a "what do I need to know?" app. The user isn't opening it to admire their collection—they're opening it to see whether anything has changed.

With that in mind, the most important information is:

1. Something new happened.
2. Something is happening soon.
3. Everything else.

So I think sections are actually a better fit than simply moving items to the top.

For example:

```
Coming Soon
────────────
Foundation
Season 4 • Aug 14

Silo
Season 3 • Sep 19

Watching
────────────
The Bear
Season 5 • TBA

Slow Horses
Renewed • Date unknown

Completed
────────────
Ted Lasso

Firefly
```

or perhaps

```
Upcoming
Watching
Ended
```

depending on exactly what metadata you have available.

That has several advantages:

- It explains *why* something is at the top.
- It stays stable instead of items jumping around unexpectedly.
- It scales as more status types are added.
- It feels more like a dashboard than a database.

---

## The interaction with sorting

This is where I'd be careful.

I would not let user-selected sorts completely destroy these sections.

Instead, I'd treat the sectioning as the primary organization and the sort as secondary.

For example:

```
Upcoming
    (sorted by release date)

Watching
    (sorted alphabetically)

Completed
    (sorted alphabetically)
```

If the user chooses "Sort by Name":

```
Upcoming
    Foundation
    Silo

Watching
    Andor
    Severance
    Slow Horses

Completed
    Firefly
    Ted Lasso
```

If they choose "Sort by Date":

```
Upcoming
    Foundation
    Silo

Watching
    Slow Horses
    Severance
    Andor
```

The sections remain; only the ordering within each section changes.

That's a pattern users see in lots of apps.

---

## The alternative

If you instead make sorting global, then choosing "Alphabetical" suddenly buries upcoming shows in the middle of the list.

```
A
Andor

B
Breaking Bad

...

S
Silo (airs tomorrow)
```

That feels like losing useful information just because the user wanted alphabetical ordering.

---

## I'd also think about whether sorting needs to exist at all

This is something we've bumped into several times.

Your app isn't Plex or IMDb. It's not a media catalog.

The user probably has 20–100 shows, not 5,000.

Most of the time they're opening the app to answer one question:

> "Do I have anything to watch soon?"

Sections answer that better than sort options.

The only sort I think users will genuinely care about is alphabetical when they're trying to find a particular show.

---

## My long-term preference

I think I'd lean toward this progression:

**MVP / App Store**
- Simple alphabetical list (what you have today).

**First major post-launch update**
- Intelligent sections:
  - Upcoming
  - Watching (renewed/in production/TBA)
  - Ended/Completed
- Optional collapse/expand if the list becomes long.

**Later**
- Within-section sorting options (Name, Date Added, Release Date, etc.).

That gives you the usability win your beta testers are asking for without introducing a complicated interaction between sections and global sorting.

One more thought: I wouldn't add this until you're no longer limited by the TVMaze search cap. Once users can build substantially larger watchlists, surfacing the most relevant shows becomes much more valuable. On a list of ten shows, alphabetical is perfectly adequate; on a list of fifty or a hundred, intelligent grouping starts to make a real difference.

---

# you asked

message time: 2026-07-21 17:35:15

We decided in another chat to implement the sections now, so let's discuss.  There are a number of categories:
- currently showing
- announced with start date (premieres on X)
- returning without start date
- ended

Are there any I have forgotten, and do you think it's appropriate to have one section for each, in the order I listed them?  Of course any empty sections would be omitted.

---

# chatgpt response

I think you're very close, but I'd make one change to keep the sections meaningful from the user's perspective.

The question isn't "what is the show's production status?" It's "what does the user need to know?"

I'd probably go with these:

### 📺 Airing Now
Shows that currently have episodes being released weekly.

Examples:
- Foundation
- The Bear

These are the shows most likely to prompt, "Oh, I should go watch the latest episode."

---

### 📅 Coming Soon
Renewed or announced **with a known premiere date**, sorted by premiere date.

Examples:
- Silo — Season 3 premieres Sept. 19
- Severance — Jan. 15, 2027

This is probably the highest-value section for NextSeason.

---

### ⏳ Waiting for a Date
Renewed or announced, but no premiere date yet.

Examples:
- Slow Horses
- The Last of Us

This tells the user, "Don't worry, it's coming. We just don't know when."

---

### 🏁 Ended
Cancelled or officially concluded.

Examples:
- Ted Lasso
- Firefly

These are the least interesting day-to-day, so they belong at the bottom.

---

## One category I think you're missing

I think you need an **Unknown** section, although hopefully it will almost never be used.

There are shows where TVMaze simply doesn't know enough to classify them cleanly. You don't want to force them into another section because then users will think the app is wrong.

Examples might include:
- Newly added shows with incomplete metadata
- Rare API inconsistencies
- Very old or obscure shows

If it stays empty 99% of the time, that's fine. It gives you a graceful fallback instead of an impossible switch statement.

---

## One category I *wouldn't* create

I would not separate "Returning" and "Premiering."

For example:

```
Coming Soon

Foundation
Season 4 • Aug 14

Harry Potter
Series Premiere • Nov 2
```

The distinction between a new series and a new season is interesting, but it's not important enough to warrant another section. The important fact is that something is arriving on a known date.

---

## Ordering

I like exactly the order you've proposed:

1. Airing Now
2. Coming Soon
3. Waiting for a Date
4. Ended

That order reflects urgency rather than chronology, which feels right for this app.

---

## One implementation thought

I also wouldn't make these fixed sections. If there are no currently airing shows, the watchlist should simply start with "Coming Soon." Likewise, if there are no ended shows, don't show an empty "Ended" header.

That keeps the list compact and avoids the impression that categories are "missing."

Overall, I think this is going to make the watchlist feel much more intentional. Right now it's a collection of shows; with these sections, it starts becoming a status dashboard, which is much closer to the core value of NextSeason.

---

# you asked

message time: 2026-07-21 17:44:57

How would you order shows within each section?  Cursor is proposing sorting Coming Soon by premiere date (soonest first) and the rest with the last added on top, which is the current sort order.

I'm wondering if all the sections besides Coming Soon should be in alphabetical order, but I'm not sure how that would look when adding a new show.

---

# chatgpt response

This is one of those UX questions where there isn't a single "right" answer, but I do think there are better and worse tradeoffs.

I don't like Cursor's proposal of "Coming Soon by date, everything else by date added."

The problem is that **date added isn't meaningful after the initial excitement of adding a show**. A month from now, why should a show you added last week be above one you added six months ago? It doesn't tell you anything about the shows themselves.

### I'd optimize each section for how users are likely to use it

#### 📅 Coming Soon
**Sort by premiere date (soonest first).**

This one is obvious. The whole purpose of the section is answering "what's next?"

```
Aug 2
Foundation

Sep 14
Silo

Nov 8
Severance
```

---

#### 📺 Airing Now
I'd actually sort this **alphabetically**.

There isn't a universally meaningful date here. One show may have started last week, another six months ago, and TVMaze may not even expose "next episode" consistently enough to rely on.

Alphabetical has nice properties:

- easy to scan
- predictable
- stable
- easy to find a particular show

---

#### ⏳ Waiting for a Date
Again, **alphabetical**.

There's no natural ordering when there isn't a date.

---

#### 🏁 Ended
Also **alphabetical**.

If someone has twenty ended shows, they'll probably be looking for a specific one.

---

## What about adding a new show?

This is the one downside of alphabetical—you lose the "I just added it!" effect.

But I'm not convinced that's actually a downside.

Imagine adding "The Last of Us."

Under date-added:

```
Waiting for a Date

The Last of Us   ← new
Andor
Foundation
Severance
```

A week later...

```
Waiting for a Date

Harry Potter     ← newest
The Last of Us
Andor
Foundation
```

The list constantly shifts for reasons unrelated to the shows.

With alphabetical:

```
Waiting for a Date

Andor
Foundation
Harry Potter
The Last of Us
Severance
```

The user immediately learns where to expect things.

If you've just added a show, they already know where it is because the app can animate the insertion or briefly highlight it. You don't need the sort order itself to communicate that.

---

## One idea I *do* like

If you want to celebrate adding a show without making it the permanent sort order:

- Insert it with animation.
- Briefly flash the row.
- Scroll it into view.

Then leave it in its natural alphabetical position.

The user gets immediate feedback, but the list remains stable afterward.

---

## Looking ahead to user-selectable sorts

This approach also composes nicely with the sort feature you already have on the roadmap.

For example:

**Default**

```
Coming Soon
    by premiere date

Airing Now
    alphabetical

Waiting
    alphabetical

Ended
    alphabetical
```

If the user later chooses **Date Added**, every section changes consistently:

```
Coming Soon
    newest added

Airing Now
    newest added

Waiting
    newest added

Ended
    newest added
```

Or if they choose **Alphabetical**, then even Coming Soon becomes alphabetical.

That gives the user exactly what they asked for while preserving a carefully chosen default experience.

---

I think the key is to distinguish between **the app's default opinion** and **user overrides**.

- The default should optimize for helping someone answer, "What's happening with my shows?" That's why I would make "Coming Soon" date-driven and the others alphabetical.
- If someone explicitly picks a different sort order in the future, it's reasonable to apply that choice uniformly within each section. They're telling the app they value a different organization, and the app should respect that.

---

# you asked

message time: 2026-07-21 17:49:14

Regarding this:
* Insert it with animation.
* Briefly flash the row.
* Scroll it into view.

Then leave it in its natural alphabetical position.

The animation and flash aren't necessary unless it's already in view, so wouldn't it make more sense to scroll the place it's going to go into view, then insert and flash it?

---

# chatgpt response

Yes, I think that's a better interaction.

The purpose isn't to say "this was added"—it's to answer the user's implicit question:

> "Where did my show go?"

If the app inserts the show off-screen and then flashes it, the flash is wasted. The user never sees it.

I'd do something like this:

1. User taps the ⭐.
2. The Search screen updates immediately to show it's on the watchlist.
3. If they navigate to the Watchlist (or if they're already there):
   - Scroll so the insertion point is visible.
   - Insert the row with animation.
   - Briefly highlight it (a subtle background tint fading out over ~1 second is enough).

That sequence tells a clear story:
- "Here's where it belongs."
- "Here's the item that was just added."

### There's another benefit

Suppose someone adds "Severance" to an alphabetical "Waiting for a Date" section.

If the list simply reloads, they may expect it to appear at the bottom (because that's where new items often go), not find it, and momentarily wonder whether the add worked.

If the app automatically scrolls to:

```
...
Silo
← animation →
Severance
Shrinking
```

there's no ambiguity.

### One caveat

I wouldn't *always* scroll.

If the insertion point is already visible, just animate the insertion in place and highlight it. Unnecessary scrolling can be disorienting.

So the logic becomes:

- **Insertion point visible?**
  - Animate insertion + highlight.
- **Insertion point off-screen?**
  - Scroll to insertion point.
  - Animate insertion.
  - Highlight.

That's a pattern users are familiar with from apps that insert items into sorted lists.

One final thought: this is the kind of polish I'd consider post-MVP unless it's essentially free to implement. A simple `ScrollViewReader` with an animated `scrollTo` and a temporary highlight in SwiftUI isn't terribly difficult, but it's also not essential to the core functionality. If you're looking to keep momentum toward the App Store, I'd be comfortable shipping without it initially and adding it later as a quality-of-life enhancement.

---

# you asked

message time: 2026-07-22 11:04:00

I've just realized something... I don't think there's ever a time when a show would be added to the watchlist from the watchlist screen.  And when the user switches to the watchlist screen, it might be a little odd to have an automatic scroll happen to the location of the last added show.  I'm starting to wonder if we should just do the grouping and not worry about the inserting at all.

---

# chatgpt response

I think you've hit on the key point.

You're designing for a scenario that doesn't actually exist.

The flow is always:

1. User searches.
2. User taps ⭐.
3. User continues searching **or**
4. User later switches to the Watchlist.

By the time they get to the Watchlist, they've made a conscious navigation. The app suddenly scrolling to "where the last show went" is actually taking control away from them.

Imagine this sequence:

- Add "Severance."
- Tap the Watchlist tab.
- The list immediately scrolls halfway down to the "Waiting for a Date" section.

My first reaction as a user would probably be, "Wait... where am I?"

I think the Watchlist should simply appear in its natural state.

## I think the sections themselves solve most of the problem

Without sections:

```
Andor
Firefly
Foundation
Severance
Silo
```

"Where did Severance go?"

With sections:

```
📅 Coming Soon
Foundation
Silo

⏳ Waiting for a Date
Andor
Severance

🏁 Ended
Firefly
```

The user only has to think, "It doesn't have a date yet," and they know exactly where to look.

The grouping itself becomes the affordance.

## There's another subtle advantage

A stable watchlist feels more trustworthy.

If the app always opens to the top, users quickly build a mental map:

- "Upcoming is at the top."
- "Ended is at the bottom."
- "Within a section, it's alphabetical."

Every visit is predictable.

Automatic scrolling, even when well intentioned, breaks that mental model.

## I'd actually keep it very simple

I'd implement:

- ✅ Sections
- ✅ Omit empty sections
- ✅ Coming Soon sorted by premiere date
- ✅ Everything else alphabetical
- ✅ No automatic scrolling
- ✅ No insertion animation

That's about as clean and unsurprising as it gets.

---

One small enhancement I *might* consider much later is automatically expanding the relevant section if you ever introduce collapsible sections. But until then, I think the watchlist should simply be a stable dashboard that opens at the top every time.

The more we've talked this through, the more I think the simplest version is also the best one. The sections do the heavy lifting; you don't need extra animations or scrolling to compensate for a problem they largely eliminate.

---

# you asked

message time: 2026-07-22 11:28:32

Can you think of some shows that are airing their current seasons and would properly show up under "airing now"?

---

# chatgpt response

Sure. Here are some well-known examples that, as of late July 2026, would belong in an **Airing Now** section because they have episodes currently being released rather than having completed the season:

- House of the Dragon — Season 3 is currently airing weekly. ([flixtrackr.com](https://www.flixtrackr.com/streaming-now?utm_source=chatgpt.com))
- The Ark — Season 3 begins at the end of July and would move into this section once episodes start airing. ([TVLine](https://www.tvline.com/2201548/july-2026-tv-schedule-what-to-watch-printable-calendar-premieres-finales-list/?utm_source=chatgpt.com))
- American Ninja Warrior — Current season airing weekly. ([Rotten Tomatoes](https://www.rottentomatoes.com/browse/tv_series_browse/sort%3Anewest?utm_source=chatgpt.com))
- Below Deck Mediterranean — Current season airing weekly. ([Rotten Tomatoes](https://www.rottentomatoes.com/browse/tv_series_browse/sort%3Anewest?utm_source=chatgpt.com))
- General Hospital — New episodes airing daily. ([The US Sun](https://www.the-sun.com/tv/16731956/general-hospital-canceled-rescheduled-fans-outrage-new-york/?utm_source=chatgpt.com))

For the kinds of scripted dramas your app is likely to track, examples would be things like:

- House of the Dragon
- The Ark (once its season starts)
- Any Apple TV+, HBO, Netflix (weekly releases), Hulu, etc., show that is midway through its current season.

---

One thing this made me realize is that **"Airing Now" is probably a fairly transient state**. Most scripted streaming shows are only in that state for 6–10 weeks each year. The rest of the year they'll live in "Waiting for a Date" or "Coming Soon."

That actually reinforces the usefulness of the section: when it's non-empty, it's telling the user, "These are the shows you could be watching right now."

I also have one naming suggestion. Instead of **"Currently Showing"**, I'd lean toward **"Airing Now."** It's a term TV fans immediately understand, and it distinguishes ongoing weekly releases from a season that's merely available to binge. For example, if all episodes of a Netflix season drop on the same day, I'd probably classify it as "Coming Soon" until release day, and then move it directly back to "Waiting for a Date" (or whatever the next appropriate state is) rather than keeping it in "Airing Now." The "Airing Now" section feels most valuable when it means, "There are still new episodes arriving."

---
Powered by [AI Exporter](https://saveai.net)