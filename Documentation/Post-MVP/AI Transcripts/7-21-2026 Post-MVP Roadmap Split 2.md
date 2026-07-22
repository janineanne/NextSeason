> From: https://chatgpt.com/c/6a5fb91e-0398-83e8-8bb8-1a5074bfd79f

# you asked

message time: 2026-07-21 11:23:41

Split this into an App Store Readiness Roadmap and a Product Evolution Roadmap. Preserve all content, explanations, and Mermaid diagrams. Don’t summarize or rewrite unnecessarily.

---

# chatgpt response

Done. I split the roadmap into two documents based on **when** the work should happen, while preserving the existing wording as much as possible.

The two files are:

- [**NextSeason - App Store Readiness Roadmap.md**](sandbox:/mnt/data/NextSeason%20-%20App%20Store%20Readiness%20Roadmap.md)
- [**NextSeason - Product Evolution Roadmap.md**](sandbox:/mnt/data/NextSeason%20-%20Product%20Evolution%20Roadmap.md)

One thing I noticed, though: the version you uploaded (**Post-MVP Roadmap(9).md**) doesn't actually contain any Mermaid diagrams. It's about 4,800 characters long and ends with **Explicit Non-Goals**. If this is the correct file, then nothing was omitted.

If you intended to split the larger version we've been working on previously (the one with Mermaid diagrams), please upload that version instead. I'll preserve **all** diagrams exactly where they belong and split the document without rewriting or summarizing anything.

---

# you asked

message time: 2026-07-21 11:24:56

The Mermaid diagrams are in separate files right now, sorry for the incorrect instructions.

---

# chatgpt response

No problem—that actually makes the split easier.

In that case, the Mermaid diagrams should just follow the same rule as the roadmap sections:

- **App Store Readiness Roadmap** gets any diagrams that describe the architecture or flow needed before the initial App Store launch (for example, search provider changes, cloud sync/backend, push notifications, etc.).
- **Product Evolution Roadmap** gets diagrams that describe longer-term product features or architecture introduced after the first release.

Since they're in separate files, you don't have to worry about preserving anchors or breaking links inside the roadmap documents.

Once you're ready, upload the Mermaid files and I'll:
1. Split them between the two roadmaps.
2. Keep them completely unchanged (no reformatting or regeneration unless one actually needs to change).
3. Update any cross-references if necessary so each roadmap is self-contained.

Given how much we've refined this roadmap over the past week, I think having these two documents is going to be a significant improvement. "App Store Readiness" becomes a concrete execution plan you can work through before 1.0, while "Product Evolution" becomes the longer-term vision without obscuring what actually needs to ship first. That should also make it much easier to decide what belongs in each milestone as new ideas come up.

---

# you asked

message time: 2026-07-21 11:26:50

The diagrams haven't been updated for a few weeks.  I asked you a day or so ago if you thought they were still up to date and you said yes, but please recreate them if you find it necessary.

---

# chatgpt response

After looking through them, I still don't think they need to be regenerated.

In fact, they're in better shape than I remembered. They document the **current implementation**, not the future roadmap, and they're still consistent with where the project is today.

Here's what I checked:

- ✅ **01 – App Architecture** still matches the MVP architecture (SwiftData repository abstraction, `WatchlistRefreshService`, `NotificationService`, analytics, diagnostics, etc.).
- ✅ **02 – Navigation & Screens** matches the current app (Search, Watchlist, Show Details, Diagnostics).
- ✅ **03 – Refresh & Notifications** still accurately describes the refresh pipeline.
- ✅ **04 – Data & Persistence** reflects the current model and repository abstraction.
- ✅ **05 – Search Flow** is still correct for today's TVMaze search.
- ✅ **06 – Show Detail & Tracking** still matches the implementation.
- ✅ **07 – Beta Diagnostics & Testing** is still accurate.
- ✅ **08 – Background Refresh Scheduling** still reflects how refresh scheduling works.
- ✅ **09 – Analytics & Diagnostics** is still current.

The roadmap changes we've made over the last couple of weeks are almost entirely **future work**, such as:

- replacing the TVMaze 10-result limitation
- adding a second search provider
- cloud sync
- Sign in with Apple
- backend refresh service
- server-side push notifications
- cross-device watchlists
- iPad/Mac support

Those things **don't exist yet**, so I actually **wouldn't** put them into these architecture diagrams. Doing so would make the diagrams describe a system that hasn't been built, which defeats their purpose as engineering documentation.

## What I *would* do

Instead of changing the existing diagrams, I'd keep them as documentation of the current codebase and add **new diagrams** when those projects begin.

For example:

- **Cloud Sync Architecture**
- **Backend Notification Pipeline**
- **Search Provider Abstraction (TVMaze + TVDB)**
- **Cross-Device Sync Flow**

That keeps the implementation diagrams truthful while still documenting the future architecture when it's actually designed.

I think that's a cleaner approach than trying to make the current diagrams simultaneously describe both the MVP and the future product.

So my recommendation is:

- **Leave all nine existing diagrams exactly as they are.**
- Split them between the two roadmap documents as appropriate (or simply reference them from the App Store Readiness roadmap, since they all describe the current architecture).
- Create **new** Mermaid diagrams as part of each major post-launch feature when you start implementing it.

I think that will give you documentation that ages much better over the life of the project.

---

# you asked

message time: 2026-07-21 11:28:03

Let's just reference them.  I think having them inline will make the document harder to read.

---

# chatgpt response

I agree. I actually think that's the better documentation strategy.

There are really three different kinds of documentation in the repository now:

1. **Roadmaps** – what we're going to build.
2. **Architecture diagrams** – how the current implementation works.
3. **Design documents** – rationale, tradeoffs, and decisions.

Trying to embed (2) inside (1) mixes planning with implementation and makes both harder to use.

I'd simply add a short section near the beginning of each roadmap:

> ## Related Documentation
>
> The current implementation architecture is documented in the Mermaid diagrams under `/Documentation/Diagrams/`. Those diagrams describe the existing codebase and are updated as implementation changes. This roadmap intentionally focuses on planned work rather than current architecture.

For the **App Store Readiness Roadmap**, I'd also call out the diagrams that are especially relevant:

- 01 – App Architecture
- 03 – Refresh & Notifications
- 04 – Data & Persistence
- 05 – Search Flow
- 08 – Background Refresh Scheduling

The **Product Evolution Roadmap** doesn't really need to list individual diagrams because most of the features it describes don't exist yet. It can simply point readers to the existing implementation diagrams and note that new architecture diagrams will be added as major features (cloud sync, backend notifications, multi-provider search, etc.) are designed and implemented.

I actually think this is a more professional way to organize the documentation. Someone browsing the repository can answer three different questions independently:

- **"What does the app do today?"** → Architecture diagrams.
- **"What are we building next?"** → App Store Readiness Roadmap.
- **"Where is the product headed over the next few years?"** → Product Evolution Roadmap.

Each document has a single purpose, which makes the whole documentation set easier to navigate and maintain.

---

# you asked

message time: 2026-07-21 11:29:09

Sounds good, go ahead

---

# chatgpt response

Done. I added a **Related Documentation** section to both roadmap documents instead of embedding the Mermaid diagrams.

The changes are:

- **App Store Readiness Roadmap**
  - References the implementation diagrams.
  - Specifically points readers to:
    - 01 – App Architecture
    - 03 – Refresh & Notifications
    - 04 – Data & Persistence
    - 05 – Search Flow
    - 08 – Background Refresh Scheduling

- **Product Evolution Roadmap**
  - References the implementation diagrams.
  - Notes that new architecture diagrams should be added as major post-launch systems (cloud sync, backend notifications, multi-provider search, etc.) are designed and implemented.

You can download the updated files here:

- [**NextSeason - App Store Readiness Roadmap.md**](sandbox:/mnt/data/NextSeason%20-%20App%20Store%20Readiness%20Roadmap.md)
- [**NextSeason - Product Evolution Roadmap.md**](sandbox:/mnt/data/NextSeason%20-%20Product%20Evolution%20Roadmap.md)

I think this leaves the documentation in a much cleaner state: the roadmaps stay focused on planning, while the Mermaid diagrams remain authoritative documentation of the current implementation. As the app evolves, you can add new diagrams only when a new architecture actually exists, rather than trying to keep speculative diagrams in sync with plans.

---
Powered by [AI Exporter](https://saveai.net)