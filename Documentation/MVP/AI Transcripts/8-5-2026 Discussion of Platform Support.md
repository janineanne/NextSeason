> From: https://chatgpt.com/c/6a73dbcb-3720-83e8-bb27-656a5dcd12e4

# you asked

message time: 2026-08-05 17:57:44

Right now only portrait orientation is supported.  Do you see any reason to support others on iPhone?

---

# chatgpt response

For **NextSeason TV on iPhone**, I don’t see a compelling reason to support landscape right now.

The app is primarily lists, search results, show details, and settings-style screens—all naturally suited to portrait. Landscape would give you less vertical space, make the keyboard more intrusive during search, and require additional testing for little practical benefit.

I’d keep the iPhone app portrait-only unless one of these changes:

- You add a video or full-screen media experience.
- A screen contains wide charts, timelines, or dense side-by-side information.
- Testers specifically report needing landscape for accessibility or device mounting.
- You build a more iPad-like multi-column layout.

One minor caveat: portrait-only can inconvenience people who use an iPhone mounted horizontally or who rely on landscape because of mobility needs. That does not necessarily justify the engineering and QA cost for this app, but it is the strongest argument against locking orientation.

So my recommendation would be:

**Keep iPhone portrait-only for launch, document it as an intentional product decision, and reconsider it only if real usage or accessibility feedback creates a reason.**

For iPad, I would make a different recommendation: supporting all standard orientations would be expected.

---

# you asked

message time: 2026-08-05 17:59:04

The project file currently claims support for iPad, Mac and Apple Vision.  Any reason for me to not remove those at this time?

---

# chatgpt response

I'd remove them now.

In fact, I think it's slightly better from a portfolio standpoint to accurately declare what the app supports than to leave platforms enabled "for someday."

Here's how I'd approach each one:

- **iPad:** Remove it for now. The UI is clearly designed for iPhone, you've intentionally optimized for that experience, and supporting iPad well would mean revisiting things like navigation, split view, larger layouts, and multitasking. An iPhone app can still run on iPad in compatibility mode if you ever decide to allow that later.

- **Mac (Designed for iPad):** Definitely remove it. If you don't support iPad, supporting Mac via iPad compatibility doesn't make much sense. Mac users expect menus, keyboard shortcuts, window resizing, drag and drop, etc. A phone UI on macOS rarely makes a good impression.

- **Apple Vision:** Remove it. visionOS support should be intentional. While many iPad apps can run there, users expect spatial behaviors and appropriate window sizing. It doesn't add anything to your portfolio to claim support you haven't tested.

The only reason I'd leave any of them enabled is if you were planning to ship on those platforms in the next few weeks. From our previous discussions, your priorities are:

1. Ship a polished iPhone MVP.
2. Get it into the App Store.
3. Use it as a portfolio piece.
4. Explore additional platforms later if the app gains traction.

That argues strongly for a focused iPhone target.

One thing I would check before removing them is **why** they're enabled. Sometimes Xcode creates a project with multiple destinations selected by default, but if your `UIDeviceFamily` only contains iPhone (`1`), then those platforms may not actually be shipping targets. It's worth confirming in the project settings before changing anything.

Overall, I think the cleanest App Store listing is simply:

- ✅ iPhone
- ✅ Portrait
- ❌ iPad
- ❌ Mac
- ❌ Apple Vision

When you eventually add iPad support, I'd recommend treating it as a genuine feature with layouts that take advantage of the larger screen, rather than just checking a compatibility box. Given your goal of using NextSeason TV as a portfolio piece, that will make a much stronger impression than nominal multi-platform support.

---

# you asked

message time: 2026-08-05 18:01:15

We used to have a document for decisions made along the way, but it looks like we got rid of that.  Which of the remaining docs is appropriate for this?

---

# chatgpt response

I think this falls into one of two categories, depending on whether you want to preserve *why* you made the decision or just record the current state.

For the examples we've been discussing (portrait only, iPhone only), I'd put them in **MVP Architecture.md** under an "Implementation Constraints" or "Platform Support" section. These are architectural/product constraints rather than temporary project decisions.

For example:

```markdown
## Platform Support

Current MVP supports:
- iPhone only
- Portrait orientation only

The app intentionally does not support iPad, Mac, or Apple Vision at this stage. Those platforms will be evaluated after the iPhone MVP has shipped and user demand is better understood.
```

That tells a future reader (or interviewer) that this was an intentional decision, not an oversight.

---

If you find yourself making lots of "we considered A, chose B because..." decisions again, I would actually bring back a lightweight decision log. I wouldn't recreate the old comprehensive one—we removed it because it had become stale—but something like:

```text
ArchitectureDecisionLog.md
```

with entries such as:

- ADR-001: iPhone-only MVP
- ADR-002: Portrait-only orientation
- ADR-003: TVMaze as initial search provider
- ADR-004: Local notifications instead of a backend

would age much better. Architecture Decision Records (ADRs) are a well-known practice, and they document *why* a decision was made rather than just *what* the code currently does.

Given the amount of thoughtful design work you've been doing on NextSeason TV, I actually think a small ADR document would be more valuable than the old catch-all decision log we deleted. It gives reviewers insight into your engineering judgment without becoming another document that duplicates the architecture or product specification.

---

# you asked

message time: 2026-08-05 18:02:53

Do you object to me leaving the ADR for the next project, or at least the post-App Store phase?  Right now it would be very incomplete and there's no good way to reconstruct it.

---

# chatgpt response

No, I don't object at all. In fact, I think that's the better choice.

An ADR system is most valuable when it's used consistently from the beginning of a project. Trying to reconstruct it after the fact usually results in a handful of obvious decisions while missing dozens of smaller but important ones. That can actually make the documentation feel arbitrary.

For **NextSeason TV**, I'd simply document the *current state* in the appropriate design documents:

- **MVP Architecture.md**: architectural constraints (iPhone-only, portrait-only, notification architecture, persistence choices, etc.).
- **Product Evolution Roadmap.md**: future plans (iPad support, Mac, visionOS, backend, etc.).
- **App Store Readiness Roadmap.md**: release-specific decisions.

That keeps the documentation coherent without pretending you have a complete historical record.

Then, for your next project—or even the post-MVP evolution of NextSeason if it becomes substantial—you can introduce ADRs from day one. At that point, every significant decision gets recorded as it's made, which is exactly how they're intended to be used.

I also don't think the absence of ADRs hurts your portfolio. Reviewers are much more likely to look for:
- Clear architecture documentation.
- Readable code.
- Good commit history.
- Sensible project organization.

A half-complete ADR collection is less valuable than a concise, accurate architecture document. If you decide to adopt ADRs later, it can simply be because the project reached the point where recording design decisions became worthwhile, not because you were trying to retrofit process onto an existing codebase.

---
Powered by [AI Exporter](https://saveai.net)