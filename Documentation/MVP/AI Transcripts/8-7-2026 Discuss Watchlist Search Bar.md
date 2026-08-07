> From: https://chatgpt.com/c/6a7136a1-fd04-83e8-9623-8ce24baf84b9

# you asked

message time: 2026-08-03 17:49:01

One of my beta testers says that he has been getting confused by the search field on the Watchlist page.  He thinks he's searching for a new show instead of searching in his watchlist.  I'm trying to come up with a way to make this clearer, which is not making the one search field do both searches.  Got any ideas?

---

# chatgpt response

I actually think your beta tester may have uncovered something real. The problem isn't that the search field is ambiguous from a UI perspective—it's that users have decades of learned behavior. A search field at the top of a screen almost always means "search for more things." Searching *within* an existing collection is a less common operation.

A few ideas, from least to most intrusive:

### 1. Better placeholder text (my first choice)

Instead of:

> Search

or

> Search watchlist

try something more descriptive:

- **Filter your watchlist**
- **Filter shows in your watchlist**
- **Find in watchlist**
- **Search saved shows**

I particularly like **"Filter your watchlist"** because "filter" immediately suggests that the results are already on the screen rather than coming from somewhere else.

---

### 2. Add a section header

```
Your Watchlist

[ Filter your watchlist ]
```

Instead of having the search field be the first thing users see, they first understand *where they are*.

---

### 3. Empty-state guidance

When the field is empty:

```
Search TVMaze →
```

on the Search tab.

When they're on Watchlist:

```
Filter your saved shows
```

The wording reinforces that these are different operations.

---

### 4. Make the field visually secondary

If the search bar is the very first control, users' eyes go straight to it.

Instead:

```
Watchlist

Airing Now
...

Coming Soon
...

[Filter]
```

or put it after a summary:

```
17 shows

[Filter your watchlist]
```

That subtly says, "Here's your collection; now you can narrow it."

---

### 5. Add a magnifying glass plus label

Instead of just a floating search field:

```
Filter Watchlist

[ Search saved shows... ]
```

A text label can do a surprising amount of work.

---

### 6. Use the system's searchable prompt well

SwiftUI lets you customize the prompt:

```swift
.searchable(
    text: $searchText,
    prompt: "Filter your watchlist"
)
```

or

```swift
prompt: "Find saved shows"
```

I'd avoid the word "Search" in the prompt if you can.

---

## What I probably wouldn't do

I wouldn't try to make the watchlist search also search TVMaze.

You've intentionally separated **Search** and **Watchlist** into two tabs, and I still think that's the right decision. Blurring those responsibilities would undo one of the nice aspects of your design.

---

## One other thought

You told me previously that the app opens directly to the Watchlist once the user has at least one saved show. That's a good choice for returning users, but it means the first screen they see has a search field. If they launch the app thinking, "I want to add a show," they may instinctively type into the only obvious search box before noticing they're on the Watchlist tab.

That suggests the issue may be less about the field itself and more about users not noticing which tab they're on.

One thing I'd consider testing is changing the navigation title from simply:

> **Watchlist**

to something slightly more descriptive, like:

> **My Watchlist**

or leaving the title alone but making the search prompt say **"Filter your watchlist"**. I suspect that alone would eliminate most of the confusion.

My instinctive ranking would be:

1. **Change the placeholder to "Filter your watchlist."**
2. If confusion continues, add a small "Filter Watchlist" label above the field.
3. Leave the Search tab completely dedicated to finding new shows.

That keeps the interface clean while making the user's mental model much clearer.

---

# you asked

message time: 2026-08-03 17:51:58

What about hiding the search field on the Watchlist and instead adding a filter button to the nav bar?  If they tap filter, then the search field appears.

---

# chatgpt response

I actually like that idea more than I expected.

The biggest advantage is psychological rather than visual: it changes the user's interpretation from **"this screen is for searching"** to **"this screen is for viewing my watchlist."** The search field becomes an optional tool instead of the primary call to action.

There are some trade-offs, though.

### Pros

- The primary purpose of the screen becomes obvious: it's a watchlist.
- Users looking to add a new show are less likely to type into the wrong field.
- Filtering is probably an infrequent action for most users, so hiding it until needed reduces visual clutter.
- It follows the mental model that filtering is something you do to an existing list.

### Cons

- It makes filtering a two-tap operation instead of one.
- Power users who filter frequently lose a bit of convenience.
- Some users won't discover the feature unless the button is obvious.

### I'd tweak it slightly

Rather than a generic funnel icon, I'd consider using a text button:

```
Watchlist                     Filter
```

or

```
Watchlist                 🔍 Filter
```

When tapped:

```
Watchlist                     Done

[ Filter your watchlist ]

Airing Now
...
```

When they tap Done (or Cancel), the field disappears and the filter clears.

That interaction says, "I'm entering filter mode," which is exactly what's happening.

### Another variation

Instead of animating the search field in and out, you could present it as a sheet:

```
Filter Watchlist

[ Find saved shows ]

Cancel        Apply
```

I think that's overkill unless you later plan to add other filter options (genres, status, network, etc.).

### My only hesitation

Apple's Human Interface Guidelines generally encourage leaving common controls visible rather than hiding them behind another action. If your watchlists commonly grow to hundreds of shows, I'd probably keep the search field visible because filtering becomes a primary task.

But for **NextSeason**, I don't think that's the typical use case. Most people will probably have somewhere between 20 and 100 shows, and many will rarely filter at all. In that context, a hidden filter feels reasonable.

---

One question I'd want answered before making the change is: **was this just one tester, or is he representative of your audience?**

If everyone else immediately understood the distinction, I'd be cautious about redesigning the UI around a single data point. On the other hand, if even one average user is confused, there are probably others who simply didn't mention it.

If I were iterating the app, I'd probably try the lower-cost change first—rename the prompt to **"Filter your watchlist"**—and see if the confusion disappears. If it doesn't, your "Filter" button idea would be the next thing I'd prototype. It feels like a thoughtful solution rather than a workaround.

---

# you asked

message time: 2026-08-03 17:54:40

If he is confused, I can easily imagine a lot of "normals" also being confused.

I'll think about it some more

---

# chatgpt response

I think that's a fair interpretation.

One thing I've learned from watching usability studies is that **the reason a tester gives for being confused is often wrong, but the confusion itself is real**. In other words, if an experienced iOS developer is repeatedly typing into the wrong search field, it's worth paying attention even if he's more absent-minded than average.

In your case, I think there are two competing mental models:

- **Your model:** "I'm on the Watchlist tab. Everything on this screen operates on my watchlist."
- **A new user's model:** "I want to find a TV show. There's a search field. I'll type there."

That second model is incredibly ingrained. Search fields almost always search "the universe," not "this page."

One thing you could do before changing anything major is ask him a few follow-up questions:

- *Did you notice you were on the Watchlist tab?*
- *Did you expect the search field to search TVMaze?*
- *After it filtered the watchlist, did you immediately understand what happened?*
- *Would different wording have helped, or did you not even read the placeholder?*

The answers might tell you whether this is:
1. A labeling problem.
2. A discoverability problem.
3. A navigation problem.

For example, if he says, "I never even noticed I was on the Watchlist tab," then hiding the search field may not be the best fix—the issue is that the current context isn't prominent enough.

One other thought: you already made what I still think was the right decision by separating **Search** and **Watchlist** into different tabs. If a few users stumble over the watchlist filter, don't let that convince you to merge the two concepts. I think keeping them separate is one of the strengths of NextSeason because each screen has a single responsibility.

So I'd treat this as polishing the UI rather than rethinking the architecture.

And if you do decide to experiment, this is exactly the sort of thing that's easy to A/B informally with your beta testers. A prototype with a "Filter" button instead of a permanent search field could tell you very quickly whether people stop making the mistake—or whether they just stop using the filter altogether.

---

# you asked

message time: 2026-08-05 10:59:31

This was the tester's actual feedback:

Some UX feedback: Several times I have found myself searching for a new show and it returns nothing and then I realize I am in the wrong search bar. Maybe you could move the local search to a less prominent place on the favorites page or at least a different place than it is on the external search page. In my own app, DiscoCat, I solved this by making local search only revealed when dragging down while the search tab (for external search) has the search bar always showing.

I don't really like either of his suggestions, though.  Watchlist uses pull to refresh which isn't compatible with using it to reveal the search bar.

I'm pretty sure he never read the placeholder text, so updating it isn't going to help.

---

# chatgpt response

Thanks for sharing the actual feedback. I think it changes my opinion a bit.

The key sentence isn't:

> "it returns nothing"

It's:

> **"Several times I have found myself searching for a new show..."**

That tells me this wasn't a one-off mistake. He had formed a habit: *launch app → type into search field*. Since your app opens to the Watchlist after the first show is added, the first search field he sees is the *wrong* one for what he intended.

I also agree with your assessment that changing the placeholder probably won't fix this. Most experienced users don't consciously read placeholder text once they know what a search field looks like. They see:

> 🔍 [________]

and start typing.

## I don't love his solutions either

### Pull down to reveal search

As you said, that's off the table because you've already committed that gesture to refresh.

### Move it elsewhere

I'm skeptical.

If the search field is still always visible, moving it from the top to halfway down the page just makes it harder to use for the people who actually want it.

## I think there's a deeper principle

Your Watchlist screen has **two different primary actions** competing:

- Browse your saved shows.
- Filter your saved shows.

But for most users, browsing is the primary task.

On the Search screen:

- Search *is* the primary task.

So it actually makes sense that the Search tab has a permanently visible search field while the Watchlist does not.

That's asymmetry, but it's purposeful asymmetry.

## I think your Filter button idea has merit

The more I think about it, the more I like it.

Imagine:

```
Watchlist                  Filter
-------------------------

Airing Now
...

Coming Soon
...
```

Tap **Filter**

```
Watchlist                   Done

🔍 Filter your watchlist
------------------------

Airing Now
...
```

This communicates that filtering is a mode.

That's very different from presenting the search field as the first thing on the screen.

## Another possibility

Instead of "Filter," what about a magnifying glass in the navigation bar?

```
Watchlist              🔍
```

Tap it.

The search field slides down beneath the navigation bar.

This is actually a fairly common interaction pattern.

It keeps filtering one tap away without visually competing with the Search tab.

## One thing I would not do

I wouldn't move the search field somewhere odd just to differentiate it.

Users have decades of muscle memory that search fields are near the top.

Breaking that convention makes filtering harder without necessarily reducing confusion.

## What I think is happening

I suspect your tester isn't actually confusing **the two search fields**.

He's confusing **the two tabs**.

His mental model is:

> "I opened the app because I want to add another show."

Your app's model is:

> "You probably want to look at your watchlist."

Those are different assumptions.

That doesn't mean your startup behavior is wrong—I still think opening the Watchlist is the right default for an app people primarily use to monitor shows they've already saved. It just means the first control on that screen shouldn't invite the exact action users were expecting to take elsewhere.

So if it were my app, I'd probably prototype the nav-bar Filter button for a few days and hand it back to the same tester. I'd be very curious whether his feedback changes to:

> "I no longer accidentally search my watchlist."

If it does, then you've solved the real problem without making the Search and Watchlist tabs less distinct. I actually think that's a cleaner design than trying to make the watchlist search field look "different enough" while leaving it permanently visible.

---
Powered by [AI Exporter](https://saveai.net)