> From: https://chatgpt.com/c/6a765f0a-bbe8-83e8-9a6f-f33873f95f4d

# you asked

message time: 2026-08-07 15:42:15

I'm wondering whether we've done the right thing having an info button for about and diagnostics on almost every page.  It seems like we've given it a very significant place for a button that won't be used very often, if ever, by most people.  How/where else could we do this?

---

# chatgpt response

I actually think this is one of the last "beta-ism" things left in the app.

During TestFlight, having Diagnostics one tap away is extremely valuable. After release, it's much harder to justify giving it prime navigation bar real estate.

Here are the options I'd consider, roughly in order of preference.

### Option 1: A single "Settings" or "More" screen (my favorite)

Instead of an info button everywhere, add a third tab or a navigation destination containing:

- About
- Diagnostics (possibly hidden unless enabled)
- Appearance
- Version number
- Privacy Policy
- Contact/Feedback
- Acknowledgements

This is what users expect. They know where to look for app information, and the feature doesn't compete with your primary tasks (Search and Watchlist).

For diagnostics, you could even make it conditional:

- TestFlight builds: Diagnostics visible.
- App Store builds: Diagnostics hidden behind a gesture or developer mode.

---

### Option 2: Put it only on one screen

For example:

- Keep the info button only on Watchlist.
- Remove it everywhere else.

If someone wants About, they can always get there from the main screen.

I actually like this better than duplicating it everywhere.

---

### Option 3: Toolbar menu

Instead of

ⓘ

have

⋯

or

☰

with

- About
- Diagnostics
- Theme

This still takes toolbar space, but it's more justified because it's a menu rather than a single rarely-used destination.

---

### Option 4: Long-press the app version

This is common in developer-oriented apps.

For example:

About screen:

```
NextSeason TV
Version 1.0 (12)

(long press)

→ Diagnostics
```

Regular users never discover it.

Testers do.

---

### Option 5: Shake gesture / secret gesture

Many apps hide diagnostics behind:

- three-finger tap
- shake
- five taps on the logo

I would avoid this.

It saves space, but it also means *you* forget how to get there six months later.

---

## What Apple tends to do

Apple generally keeps:

- Settings
- About
- Legal
- Diagnostics

in one place.

Very few Apple apps have an information button on every screen.

---

## Thinking specifically about NextSeason

Your app is intentionally simple.

The two primary tasks are:

- search for shows
- manage your watchlist

Anything else is secondary.

An always-visible info button gives About/Diagnostics nearly the same visual importance as those core actions, which doesn't seem proportional.

I'd rather see the navigation bars dedicated to actions relevant to the current screen.

For example:

**Search**
- search controls only

**Watchlist**
- Edit
- Filter (if you add one later)

**Settings/About**
- About
- Diagnostics
- Theme
- Notification status
- Version

That feels more focused.

### One caveat

I'd probably keep the current design **through the remainder of the TestFlight beta**. Testers occasionally need Diagnostics, and making it instantly accessible reduces friction when you're asking someone, "Can you tell me what the last background refresh says?"

Then, before the App Store release, I'd consolidate everything into a single About/Settings location. That gives you the best experience in both phases.

---
Powered by [AI Exporter](https://saveai.net)