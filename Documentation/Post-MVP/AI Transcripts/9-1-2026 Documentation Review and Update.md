> From: https://chatgpt.com/c/6a94c093-08c0-83e8-a14c-f5fd3e9c5206

# you asked

message time: 2026-08-30 16:47:01

Please look through all the files in the Documentation folder except for the AI Transcripts.  Make sure that they describe the project at the appropriate stage (MVP or post-MVP/pre-App Store) and that there's nothing duplicated, missing or inaccurate.

---

# chatgpt response

Yes. I can do that, but I need the current project archive attached to this chat first.

The Library contains a number of older copies of the documentation—including multiple versions of the App Store Readiness and Product Evolution roadmaps—so I don't want to accidentally audit historical copies instead of what's actually in the repository now.  

Please attach a current ZIP of **NextSeason**. I'll review every file under `Documentation/` except `AI Transcripts/` against the current code and against the other documentation, specifically looking for:

- **Stage errors:** MVP-era documents that incorrectly describe later features as part of MVP, or current/pre-App-Store documents that still describe an obsolete MVP implementation.
- **Factual inaccuracies:** architecture, persistence, search providers, notifications/background refresh, analytics, StoreKit, accessibility, diagnostics, supported platforms, etc.
- **Stale statements:** things described as planned that are now implemented, or implementation details that have since changed.
- **Duplication:** documents or sections that now cover substantially the same territory and should be consolidated or removed.
- **Gaps:** important architectural/product/release decisions that ought to be documented but aren't.
- **Organization:** whether each document still has a useful purpose and belongs where it is.
- **Cross-document consistency:** especially the distinction we've established between the completed **MVP**, the current **post-MVP/pre-App-Store** work, and genuinely **post-launch Product Evolution** work.

I'll give you a document-by-document assessment first, followed by a consolidated set of recommended changes rather than editing anything automatically.

---

# chatgpt response

I’ve got the current archive. I’m going to treat the repository itself as the source of truth, inventory `Documentation/` (excluding `AI Transcripts/`), then cross-check the docs against the current implementation and against one another for stage drift, duplication, and gaps.

The folder is nicely separated already: 18 MVP text documents/diagrams plus three post-MVP roadmaps, with design assets/screenshots alongside them. I’m checking the MVP material as a historical snapshot rather than expecting it to describe today’s code; the post-MVP roadmaps, by contrast, need to reflect the current pre-App-Store state accurately.

I’ve found one concrete cleanup issue already: the historical MVP docs contain **10 broken internal links**, mostly to planning files that are no longer in the repository (`MVPBacklog.md`, `FunctionalRequirements.md`, `DecisionLog.md`, `Architecture.md`, `ProductSpec.md`, and an old Post-MVP Roadmap filename). That directly conflicts with the post-MVP Documentation Review checklist’s requirement to verify links and remove references to missing material.

I went through **all of `Documentation/` except the AI Transcripts**, including the diagrams, design files, and MVP screenshots, and cross-checked the documentation against the current source and Git history.

The overall organization is good, and I **would not do a wholesale documentation rewrite**. The MVP/Post-MVP split is the right structure. But there are several real problems to fix before I would call the documentation clean. The biggest one is that the **MVP folder has gradually absorbed some post-MVP history**, so it no longer represents the July 7 MVP milestone consistently.

| File / area | Assessment | What I would change |
|---|---|---|
| `MVP/ProblemStatement.md` | **Good** | Leave it alone. It is product-level and still accurately describes the original problem. |
| `MVP/UserStories.md` | **Good** | Leave it as the original MVP stories. In fact, its omission of later watchlist-search functionality is appropriate. |
| `MVP/ProjectKickoff.md` | **Good historical document** | Its historical disclaimer is appropriate. No substantive change needed. |
| `MVP/MVPDefinition.md` | **Stage error** | Remove **“Search within the watchlist.”** Git history shows that was added July 16, after the July 7 MVP completion. It belongs in the post-MVP/pre-App-Store record, not in the MVP definition. |
| `MVP/Implementation Plan.md` | **Historical status is clear, but links are broken** | Fix/remove links to deleted `MVPBacklog.md`, `FunctionalRequirements.md`, `DecisionLog.md`, and `Architecture.md`. The surviving architecture file is now `InitialArchitecture.md`. There are six broken links in this file. |
| `MVP/InitialArchitecture.md` | **Appropriately historical, but broken references** | Fix four broken links: `ImplementationPlan.md`, `ProductSpec.md`, and two references to the old `Post-MVP Roadmap.md`. Also change its reference to `MVPArchitecture.md` from the “current application architecture” to the **implemented MVP architecture**, since current architecture is now substantially different. |
| `MVP/MVPArchitecture.md` | **Largest MVP problem** | This file was created July 29 and describes the app as it existed then, not the July 7 MVP. It includes post-MVP watchlist search and the later Airing Now / Coming Soon / Returning / Ended section structure. It should either be reconstructed as a true MVP snapshot, or moved/renamed as a later architecture document. It cannot accurately remain the “authoritative architecture reference for the MVP milestone” in its current form. |
| `MVP/MVPAnalytics.md` | **Mostly good historical snapshot** | The local-only/no-third-party description appears appropriate for the MVP. I would add a short historical note saying that anonymous Aptabase telemetry was subsequently added **pre-App-Store**, rather than leaving the “after the initial App Store release” prediction looking like current planning. |
| `MVP/TVMazeResearch.md` | **Mostly good, one stale historical statement** | The search-limit section says fixing the 10-result limitation is tracked in the **Product Evolution Roadmap**. It actually became pre-App-Store work and has already been solved through TheTVDB + the mapping database. Correct that historical annotation. Also fix the typo `tThe networking layer`. |
| `MVP/Diagrams/*` | **Mostly valid architecture diagrams, but snapshot policy is wrong** | The diagrams largely depict the MVP architecture, but several have subsequently been updated to current implementation names. More importantly, the README says they should be kept current as the application architecture changes. That conflicts with their location under `MVP`. Change the policy to say these diagrams preserve the **MVP architecture**. Future architecture changes should get post-MVP diagrams. |
| `MVP/Diagrams/README.md` | **Minor terminology issue** | “Settings/About” should just be **About**; there isn't a Settings screen at this stage. |
| `MVP/Screenshots/*` | **Definitely wrong stage** | These are currently **post-MVP screenshots**, despite being named `MVP-*`. The Search screenshot visibly contains TheTVDB attribution and **Load More Results**, which did not exist in the MVP. Git shows these screenshots were replaced on August 17. Restore the July 7-era screenshots here and put current/release-candidate screenshots somewhere under Post-MVP or the README assets. |
| `MVP/Design/*` | **Fine as historical artifacts** | These appropriately show the earlier icon direction. I would leave them in MVP rather than replacing them with the current crystal-ball icon. |
| `Post-MVP/App Store Readiness Roadmap.md` | **Good structure, several completed sections are written as if work hasn't happened** | Rewrite completed items as brief records of what was actually implemented rather than preserving their original future-tense requirements. |
| `Post-MVP/Monetization Strategy Roadmap.md` | **Materially stale** | This is the other major problem. It repeatedly says StoreKit, tips, and review requests are merely proposed, despite all three now being implemented for testing. Update it to distinguish **implemented pre-release architecture** from still-TBD production pricing/App Store configuration. |
| `Post-MVP/Product Evolution Roadmap.md` | **Good** | This is appropriately post-launch and largely clean. I would make only a couple of naming/clarity refinements described below. |

### The MVP screenshots are the clearest example of the stage drift

Those three files are named `MVP-Search-Results.png`, `MVP-Show-Detail.png`, and `MVP-Watchlist.png`, but they were replaced in August. The current Search screenshot includes TheTVDB search, pagination, and TheTVDB attribution. That's unequivocally pre-App-Store/post-MVP functionality.

I would **restore the screenshots from the July 7 commit** rather than trying to find or recreate them manually. The current screenshots can then become release-candidate screenshots elsewhere.

### `MVPArchitecture.md` needs a deliberate decision

This isn't just a wording cleanup. It currently claims:

> “This document describes the architecture of the completed MVP implementation…”

and calls itself the authoritative MVP architecture.

But the file itself didn't exist until July 29, and it describes functionality added after July 7. For example, it documents watchlist search, which landed July 16, and the four watchlist sections introduced later in July.

I think the cleanest solution is to **retain the concept of `MVPArchitecture.md`, but reconstruct it against the July 7 source state**. That makes the whole MVP folder an honest milestone snapshot.

Then create a new:

`Documentation/Post-MVP/AppStoreReleaseArchitecture.md`

That document should describe the actual architecture heading toward 1.0.

That would also solve what I think is the most important **missing documentation** in the repository right now. The current application has changed substantially since MVP:

- TheTVDB provides search.
- The local ID-mapping database bridges TheTVDB → TVMaze.
- TVMaze remains the season/detail source.
- Aptabase now receives a small whitelist of anonymous analytics events.
- SwiftData has an explicit migration plan.
- Persistence recovery and crash-loop protection exist.
- StoreKit 2 handles Plus, lifetime purchase, and consumable tips.
- The three-show free-tier policy is enforced.
- Review-request coordination exists.
- Watchlist export is currently being implemented.

The roadmaps say *that* those things happened, but nowhere outside the code is there currently one authoritative description of **how the pre-App-Store application fits together**. That's exactly what the MVP architecture document used to provide for the earlier milestone.

### The Monetization Strategy needs the most updating among the roadmaps

Several statements are simply obsolete now:

> “This document describes the planned monetization structure…”

> “Whether to use StoreKit 2 directly or a service such as RevenueCat should be decided…”

> “NextSeason may include an optional Support NextSeason section…”

> “App Store review requests should be implemented…”

> “**Proposed — not yet implemented.**”

Those all need to change. Native StoreKit 2 is now the architecture; annual Plus, lifetime Plus and the three tip products exist in the StoreKit test configuration; the free limit is implemented; the tip jar exists; restore purchases exists; and review requests exist.

There are also **three important product rules implemented in code that aren't adequately captured in the strategy document**:

1. If Plus expires while somebody has more than three shows, **all existing shows remain tracked and continue working**. They simply can't add another until they re-subscribe or reduce the list below the free limit.
2. Existing beta users can be **grandfathered into unlimited access**.
3. The current StoreKit products have **Family Sharing disabled**.

Those are material monetization decisions and deserve to be in the strategy document.

The test StoreKit file currently has $10 annual, $20 lifetime, and $1/$3/$5 tips. Since you've said final pricing is still undecided, `Pricing: TBD` is fine—but I would explicitly say the `.storekit` prices are **development/test placeholders and not final pricing**, so nobody later mistakes them for a settled decision.

### The App Store Readiness roadmap is basically sound, but some completed entries should become historical records

For example, `Search Coverage (Complete)` currently begins by saying the “current ten-result limit must be eliminated.” That isn't current anymore. The section should instead say something like: the MVP's TVMaze-only search was limited to roughly ten results; pre-release work replaced search discovery with paginated TheTVDB results, filters them through the local mapping database, and resolves selected shows to TVMaze.

Likewise, `Watchlist Section Scrolling (Complete)` says the watchlist **currently uses `List` with `Section`** and then proposes replacing it. Since it's complete, that should be written in past tense.

The StoreKit subsection can also be much shorter after the monetization document is corrected: mark StoreKit implementation/testing complete and link to the monetization strategy for the actual design. Right now the two documents partially duplicate one another because the strategy document hasn't caught up.

`Watchlist Export` is fine being unfinished in this archive. I can see the export implementation in the working tree, but it is still uncommitted/in progress, so the roadmap should not prematurely claim completion.

### Duplication is actually not a major problem

I would **keep** `ProblemStatement`, `MVPDefinition`, `UserStories`, `Implementation Plan`, `InitialArchitecture`, and the final architecture document. Although they cover some of the same territory, they serve different purposes: problem, scope, behavioral requirements, implementation history, initial design, and implemented design.

Likewise, the Mermaid diagrams are useful visual companions rather than unnecessary duplication.

The one area where duplication currently feels messy is **StoreKit/monetization**, and fixing the status of the Monetization Strategy largely eliminates that.

The Product Evolution Roadmap also has `Notification Enhancements` and later `Monitoring & Notifications`. They aren't actually duplicates—the first is about user-facing capabilities and the second about server architecture—but I'd rename the second one to something like **Server-Side Monitoring & Push Delivery** so the distinction is obvious.

### Two genuinely missing pieces

The first is the **App Store Release Architecture** described above.

The second is already acknowledged by your roadmap: the **AI-Assisted Development Workflow** document still doesn't exist outside the transcripts. `ProjectKickoff.md` describes the original plan for using AI, but it doesn't serve the same purpose. Before release, you still need the retrospective document explaining what ChatGPT/Cursor actually did, how you reviewed their work, and how decisions remained under human control.

So my overall verdict is: **the documentation set is fundamentally well organized and I wouldn't delete much. But it is not yet internally consistent enough to call the documentation review complete.** The primary cleanup is to enforce the milestone boundary:

**MVP = frozen July 7 historical snapshot.**  
**Post-MVP/App Store Readiness = everything implemented between MVP and 1.0.**  
**Product Evolution = genuinely after the first App Store release.**

Once you apply that rule, nearly every questionable item has an obvious home.

If you want, the next useful step is for me to write **one Cursor prompt that makes all of these documentation corrections**, including reconstructing the MVP screenshots/docs from Git history and creating the App Store Release Architecture without touching the AI transcripts.

---

# you asked

message time: 2026-08-30 17:16:15

I'm not sure why you're using 7/7 as the milestone.  According to my local git history, I created that tag on 8/9.

---

# chatgpt response

You're right. **I used the wrong milestone.** I treated July 7—the point when we had been calling the initial MVP “complete” in our discussions—as though it were the formal Git MVP milestone. I should not have done that when auditing historical documentation.

If the actual `mvp` tag was created on **August 9**, then the correct question is:

> **Does `Documentation/MVP` accurately describe the code and product as of the commit tagged `mvp` on August 9?**

That materially changes several of my conclusions. In particular:

- **Watchlist search is not a stage error** if it landed July 16 and was present in the August 9 tag. It belongs in `MVPDefinition.md`.
- **`MVPArchitecture.md` being created July 29 is perfectly reasonable**. In fact, that's exactly when you'd expect a final architecture document to be written if the MVP wasn't formally frozen until August 9.
- The later watchlist section structure can likewise legitimately be part of the MVP if it existed at the tagged commit.
- My recommendation to reconstruct the MVP architecture against July 7 is therefore **wrong**.
- The screenshots need to be judged against the **August 9 tagged state**, not July 7. August 17 replacements may still be wrong, but I need to determine whether they actually depict post-tag functionality rather than relying on their replacement date.

The broken links and the stale post-MVP/monetization observations aren't dependent on that date, so those findings likely stand. But the **entire stage-boundary portion of my review needs to be redone against the actual `mvp` tag**.

And since you gave me the Git repository, I really should have derived the milestone from the repository rather than inferring it from our conversational history. That's an important methodological mistake on my part.

I should redo the audit using **the tagged `mvp` commit as the definitive MVP baseline**, and current `main` as the post-MVP/pre-App-Store baseline.

---

# you asked

message time: 2026-08-30 17:20:22

Go ahead

---

# chatgpt response

I redid the audit using the repository's **`MVP` tag itself as the boundary**. That changes my earlier assessment substantially.

One Git detail explains the date discrepancy: the annotated `MVP` tag was apparently **created/re-created on August 20**, but it points to commit `c3ae0f2`, whose commit date is **August 9, 2026 at 10:38 PM**. So for documentation purposes, **August 9 / commit `c3ae0f2` is the correct MVP snapshot**.

## Revised conclusion

The `Documentation/MVP` folder is actually in **very good shape**. Nearly every text document and diagram in it is **byte-for-byte identical to the version at the MVP tag**.

That means my previous concerns about watchlist search, the four watchlist sections, `MVPArchitecture.md` being written July 29, etc. were incorrect. **Those really are MVP features.**

I would **not reconstruct `MVPArchitecture.md`** and I would **not create an App Store Release Architecture document merely to fix a supposed historical problem**. The MVP architecture document is doing exactly what its title says.

There are, however, some genuine cleanup items.

### 1. The MVP screenshots are post-MVP

This finding survives, but for much better evidence.

The three files:

- `MVP-Search-Results.png`
- `MVP-Watchlist.png`
- `MVP-Show-Detail.png`

**do not exist at all in the `MVP` tag.** They were added later. The Search screenshot in particular depicts the post-MVP TheTVDB search system.

So calling them `MVP-*` and storing them under `Documentation/MVP/Screenshots` is inaccurate.

I would **move these to a post-MVP/release screenshot location and rename them accordingly**. I would *not* try to restore July screenshots as I previously suggested; there were no corresponding screenshot files at the tagged MVP commit.

### 2. One MVP diagram has accidentally been updated with a post-MVP implementation name

Everything in `MVP/Diagrams` is identical to the MVP tag **except** `02-navigation-and-screens.md`.

At MVP it said:

```text
BetaDiagnosticsPresentationModifier
```

It now says:

```text
AppAboutPresentationModifier
```

That change happened after MVP. Since the folder is serving as an MVP snapshot, I recommend **reverting those two lines to the tagged version**.

This also reveals a small problem with `Diagrams/README.md`: it currently says the diagrams should be updated whenever the application architecture changes. That was sensible while MVP development was ongoing, but now that they're archived under `MVP`, it would cause exactly this kind of historical drift.

I'd change that section to say that the diagrams represent the architecture **at the MVP milestone and should remain frozen except for corrections to the historical record**.

### 3. The broken internal links are real

I found **11 broken Markdown links**.

`Implementation Plan.md` references files that no longer exist:

- `MVPBacklog.md`
- `FunctionalRequirements.md`
- `DecisionLog.md`
- `Architecture.md` — twice
- `DecisionLog.md` — a second time

`InitialArchitecture.md` has:

- `ImplementationPlan.md` — wrong filename; actual file contains a space
- `ProductSpec.md` — missing
- two links to the old `Post-MVP Roadmap.md`

And the App Store Readiness roadmap has a broken link to the Monetization Strategy because the filename contains spaces but the relative URL doesn't resolve as written.

Some of the missing MVP files were evidently consolidated/deleted during development. That's fine; **the prose can remain historical while the navigation should point to surviving documents or stop pretending a deleted document is available.**

### 4. `Implementation Plan.md` has stale status text

This is a genuine internal inconsistency within the MVP archive.

At the top it correctly says:

> **Historical Document:** ... The MVP has since been completed.

But §9 still says:

> Phase 4 — Implementation: **in progress**. Slice 1 = done. Next: Slice 2.

That's the state of the *plan at that moment*, rather than the final MVP milestone.

Because the document explicitly presents itself as historical, I don't think that text should simply be overwritten. I'd annotate it instead, e.g. that the status below reflects the point at which the implementation plan was written and that Slice 2 was subsequently completed before the MVP tag.

That preserves useful history without confusing a reader.

### 5. `InitialArchitecture.md` has one misleading phrase

Its opening says:

> See `MVPArchitecture.md`, for the authoritative description of the **current application architecture**.

At the MVP tag that was true. It isn't anymore.

Since this whole folder is now historical, change that to:

> authoritative description of the **implemented MVP architecture**

That's enough. No larger rewrite is necessary.

### 6. `MVPAnalytics.md` is correctly historical

I withdraw my previous recommendation to modify its remote-analytics discussion.

At MVP, it accurately says:

> The current app does not use a third-party analytics SDK.

And:

> After the initial App Store release ... Potential enhancements include optional anonymous aggregate telemetry.

Aptabase was subsequently introduced during pre-App-Store development. That makes the *prediction* wrong, but it doesn't make the historical MVP document wrong.

I'd leave it alone. The MVP folder should tell us what the app and plans looked like on August 9, not retroactively rewrite them in light of later decisions.

The same principle applies to most of `TVMazeResearch.md`.

### 7. One actual typo remains in `TVMazeResearch.md`

There is:

> **Contingency:** tThe networking layer...

Change `tThe` → `The`.

That's just a typo, so fixing it doesn't compromise the historical snapshot.

---

## Post-MVP documents

Here my earlier assessment largely stands.

### App Store Readiness Roadmap

The roadmap has the right **scope**. I don't see a meaningful missing pre-release workstream based on the current code.

But several `(Complete)` sections still read as future instructions. For example:

> the current ten-result limit must be eliminated

and:

> Replace the sectioned `List` with `ScrollView` and `LazyVStack`

Both have already happened.

I think completed sections should remain in the roadmap, because they're useful history, but be changed to **brief implementation summaries**. That makes the distinction very clear:

- unchecked/incomplete = work still required before submission;
- `(Complete)` = what was actually done.

This is especially useful now that quite a lot of substantial engineering has happened after MVP.

### Monetization Strategy Roadmap

This is definitely the **most inaccurate document currently in Documentation**.

It still says:

> Whether to use StoreKit 2 directly or a service such as RevenueCat should be decided...

and ends with:

> **Proposed — not yet implemented.**

But Git history shows StoreKit was implemented after MVP, followed by purchase-page work and a final StoreKit review. The current code contains the complete native StoreKit 2 purchasing architecture, Plus entitlement handling, lifetime purchase, tips, restore, transaction observation, grandfathering, and free-tier enforcement.

The review-request section is stale for the same reason: review requests and the persistent About option are now implemented.

**This document needs a proper current-state update.**

It should also record the important policy decisions embodied in the implementation, particularly:

- free tier = three shows;
- Plus = unlimited;
- annual subscription + lifetime purchase;
- consumable tips;
- native StoreKit 2;
- existing shows aren't disabled when Plus expires;
- additions are blocked while the user remains over the free limit;
- eligible existing beta users are grandfathered;
- Family Sharing is disabled;
- current `.storekit` prices are test configuration, while production pricing remains TBD;
- review prompting is implemented separately from monetization.

That isn't unnecessary implementation detail; those are product/business rules.

### Product Evolution Roadmap

This is in good shape and is correctly scoped **after the first App Store release**.

I don't see anything significant in it that belongs in MVP instead.

I still like one small naming improvement: rename:

> **Monitoring & Notifications**

to something like:

> **Server-Side Monitoring & Push Notifications**

because there's already a separate `Notification Enhancements` section. They're conceptually different, but the headings make them initially look duplicative.

Otherwise I'd leave this roadmap alone.

---

## Is anything missing?

After using the correct MVP boundary, **much less is missing than I originally thought**.

I no longer think a new architecture document is necessary *for documentation correctness*. `MVPArchitecture.md` gives us the frozen architecture at MVP, while the code is the source of truth during active pre-release development.

The one explicitly missing document remains the item already listed in App Store Readiness: **AI-Assisted Development Workflow**. That's intentionally outstanding work, so it's not a documentation defect yet.

I also don't see a need to create separate documents for StoreKit, TheTVDB, persistence recovery, SwiftData migrations, or accessibility. The roadmaps plus source documentation are sufficient unless you specifically want a more extensive architecture record.

## So the actual cleanup is fairly modest

I would make these changes:

1. Move/rename the three post-MVP screenshots out of `Documentation/MVP`.
2. Revert the post-MVP change in `MVP/Diagrams/02-navigation-and-screens.md`.
3. Change the diagram README so MVP diagrams are explicitly frozen historical artifacts.
4. Repair/remove the 11 broken internal links.
5. Clarify the stale Phase 4 status in the historical `Implementation Plan.md`.
6. Change “current application architecture” → “implemented MVP architecture” in `InitialArchitecture.md`.
7. Fix `tThe` in `TVMazeResearch.md`.
8. Convert completed App Store Readiness sections from future-tense requirements into concise implementation records.
9. Substantially update the Monetization Strategy to reflect the StoreKit and review-request implementation.
10. Optionally rename Product Evolution's `Monitoring & Notifications` heading for clarity.

**And importantly: leave `MVPDefinition.md`, `MVPArchitecture.md`, `MVPAnalytics.md`, User Stories, and the actual MVP feature descriptions alone.** With August 9 as the milestone, they're doing their jobs.

This is a considerably smaller and safer cleanup than what I recommended the first time.

---

# you asked

message time: 2026-09-01 12:00:28

So regarding #2 - is it your intention that I make a Post-MVP/Diagrams folder which is a copy of the MVP one with that one change?

---

# chatgpt response

No. **I would not create a Post-MVP/Diagrams folder just to preserve that one change.** That would create exactly the kind of duplication you asked me to look for.

My intent for #2 was simply to **revert `MVP/Diagrams/02-navigation-and-screens.md` to the version at the MVP tag**:

`AppAboutPresentationModifier` → `BetaDiagnosticsPresentationModifier`

The newer name does **not** need to be documented in a parallel diagram right now. The current source code already documents the current implementation, and one renamed architectural component isn't enough reason to maintain a second complete set of diagrams.

I think the clean model is:

- **`MVP/Diagrams/`** — frozen snapshot of the architecture at the MVP tag.
- **No `Post-MVP/Diagrams/` for now.**
- If the architecture changes enough before App Store release that a new architectural snapshot becomes valuable, *then* create a new set representing the 1.0 architecture rather than incrementally cloning MVP diagrams every time something changes.

In fact, that's why changing the README is important. Right now it apparently encourages keeping the MVP diagrams synchronized with current code, which is what caused `AppAboutPresentationModifier` to leak backward into the MVP snapshot. The README should instead make explicit that **after the MVP tag, these diagrams are historical and should only be changed to correct an error in what the MVP actually contained.**

So #2 and #3 really belong together: **revert that one diagram, then freeze the entire MVP diagram set.**

---

# you asked

message time: 2026-09-01 12:01:36

What about the screenshots, which are included in the project README?  Seems like there should be a post-MVP set of those.

---

# chatgpt response

Yes — **for screenshots, I do think a post-MVP set makes sense**, because they serve a different purpose than the architecture diagrams.

The README screenshots are effectively **current product documentation / marketing-facing visuals**. If they now show post-MVP features, they should not live under `Documentation/MVP/Screenshots` while also being used to represent the current app.

I’d structure it like this:

- `Documentation/MVP/Screenshots/`
  - frozen screenshots representing the app at the MVP tag
- `Documentation/Post-MVP/Screenshots/`
  - current pre-App-Store screenshots used by the README

Then update the README to reference the Post-MVP versions.

That gives you two clean snapshots without unnecessary duplication:
- MVP screenshots = historical record
- Post-MVP screenshots = current app state

The key difference from the diagrams is that the screenshots are **actively surfaced in the README**, so having a current set is genuinely useful. For diagrams, a second set would currently add little value; for screenshots, it directly supports how the project is presented.

If you no longer have the actual August 9 screenshots, I would not fabricate them. In that case, either recover them from Git/history if possible, or remove the misleading `MVP-` naming and treat the existing set as Post-MVP only.

---

# you asked

message time: 2026-09-01 16:36:43

For #3, do you mean just changing the comments about keeping the file updated, or actually locking files so they can't be changed, if such a thing is possible in git?

---

# chatgpt response

I mean **just changing the comments/instructions in `MVP/Diagrams/README.md`**. I would not try to technically lock the files.

Git doesn't really have a useful concept of making tracked files immutable. You could enforce something with hooks or CI, but that would be needless machinery here—and occasionally you'll legitimately want to correct a typo or an inaccurate diagram.

I'd change the README guidance from essentially:

> Keep these diagrams updated as the application architecture changes.

to something along the lines of:

> These diagrams document the application architecture at the MVP milestone. They are historical artifacts and should not be updated to reflect subsequent implementation changes. Changes should be limited to corrections that make the diagrams more accurately represent the tagged MVP.

So “frozen” means **frozen by convention**, not file permissions. Git itself already gives you the protection you really need: if something accidentally changes, the diff/history makes it recoverable.

---

# you asked

message time: 2026-09-01 17:03:23

I would prefer to leave the completed App Store Readiness sections as they are.  They describe what was to be done, and then each is marked Complete as it is done.

---

# chatgpt response

I agree. In that case, **withdraw #8 entirely**.

Your App Store Readiness Roadmap is functioning as a **plan plus completion record**, not as a current-state specification. In that model, the future-tense wording is desirable:

> Here is what we determined needed to be done.

followed by:

> **Complete**

That preserves the original requirement and records that it was satisfied. Rewriting completed sections afterward would actually erase some useful project history.

So I would apply that principle consistently:

- Don't rewrite completed sections merely because their wording is now historical.
- Mark them Complete when their requirements have been satisfied.
- Edit them only if the original description itself was inaccurate, or if the scope changed before completion.
- Keep genuinely new work as a new item rather than retroactively changing a completed one.

That also reinforces the distinction with the **Monetization Strategy Roadmap**: that document *does* need updating because it presents unresolved decisions and proposed features as the current strategy when those decisions have subsequently been made. That's different from a checklist item saying what work was originally required.

So the revised cleanup list is now down to **#1–7, #9, and optional #10**, with #8 removed.

---

# you asked

message time: 2026-09-01 17:04:09

Can you please write an updated Monetization Strategy Roadmap, based on what you see in the code?

---

# chatgpt response

Yes. I’d replace the existing roadmap with the following. I’ve kept its emphasis on **monetization strategy and product decisions**, rather than turning it into StoreKit implementation documentation.

**Document Title: **

# NextSeason Monetization Strategy

## Purpose

This document describes the monetization structure for NextSeason.

The goal is to create a simple and sustainable revenue model that fits the app's core promise: NextSeason quietly remembers the shows a user cares about and lets them know when something changes.

The monetization experience should be similarly simple. It should avoid unnecessary tiers, advertising, artificial feature restrictions, and frequent prompts to spend money.

The initial monetization structure has been implemented using StoreKit 2. Production pricing has not yet been determined.

## Guiding Principles

The monetization model should:

- Allow users to experience the core value of NextSeason before paying.
- Provide ongoing revenue to support maintenance of the app and its third-party data integrations.
- Keep the distinction between free and paid service easy to understand.
- Avoid adding features or complexity merely to justify a subscription.
- Avoid advertising and the privacy, maintenance, and user-experience costs associated with ad networks.
- Avoid repeatedly interrupting or pressuring users to make purchases.
- Provide an option for users who strongly prefer not to maintain another subscription.
- Avoid taking functionality away from users merely because a paid entitlement expires.

## Free Tier

NextSeason is free to download and use with a limited watchlist.

### Watchlist Limit

**Up to 3 shows**

The free tier does not expire. Shows on the free watchlist receive the same tracking and notification functionality as shows on a paid watchlist.

This replaces the previously considered seven-day trial.

A permanent free tier is preferable because the value of NextSeason may not become apparent within a short trial period. A user may add a show and wait weeks or months before NextSeason discovers and reports a meaningful update.

The free tier allows users to experience that value naturally before deciding whether they need the paid version.

## NextSeason Plus

NextSeason Plus removes the watchlist limit.

### Paid Feature

**Unlimited show tracking**

There is one paid feature level rather than separate capacity-based plans.

A single paid entitlement:

- Is easier for users to understand.
- Avoids forcing users to predict how many shows they will want to track.
- Eliminates complicated upgrades and downgrades between capacity levels.
- Keeps purchasing and entitlement behavior simple.
- Fits the overall philosophy of keeping NextSeason focused and uncomplicated.

NextSeason Plus can currently be obtained through either an annual subscription or a lifetime purchase.

## Annual Subscription

NextSeason Plus Annual is an auto-renewing annual subscription that provides an unlimited watchlist while the subscription remains active.

Annual billing fits the nature of the service better than monthly billing because NextSeason provides value over long periods. A user may wait many months or more than a year for information about a future season.

The subscription supports the continuing service involved in maintaining NextSeason, including:

- Monitoring and processing television data.
- Maintaining compatibility with third-party APIs and services.
- Maintaining the show's data-mapping infrastructure.
- Keeping the app compatible with future versions of iOS.
- Fixing bugs and maintaining reliability.
- Continuing to deliver season information and notifications.

A subscription does **not** imply that NextSeason must continually add new features. The ongoing value is the continuing tracking service itself.

A monthly subscription is not part of the initial product structure. It can be reconsidered later if user feedback indicates that it would be valuable.

## Lifetime Purchase

NextSeason Plus Lifetime is a non-consumable one-time purchase that permanently unlocks an unlimited watchlist.

The lifetime option is intended for users who strongly prefer a one-time purchase over an ongoing subscription.

Production pricing should maintain a sensible relationship between the annual and lifetime options so that the lifetime purchase does not undermine the sustainability of the annual subscription.

## Subscription Expiration

If an annual Plus subscription expires, NextSeason does not remove shows or stop tracking shows already on the user's watchlist.

If the watchlist contains more than the free limit when Plus expires:

- All existing shows remain on the watchlist.
- Existing shows continue to be tracked normally.
- Existing notification functionality continues normally.
- The user cannot add another show while the watchlist remains at or above the free limit.
- The user can regain the ability to add shows by renewing Plus or reducing the watchlist below the free limit.

This avoids unexpectedly taking away functionality or data the user already had while still enforcing the free-tier limit for future additions.

A lifetime purchase does not expire.

## Existing Beta Users

Users who were already tracking more than three shows when the watchlist limit was introduced are grandfathered into an unlimited watchlist.

Grandfathering is determined once when the StoreKit-aware version of NextSeason first runs. If the existing watchlist exceeds the free limit at that time, unlimited access is retained.

Grandfathering is permanent. Reducing the watchlist later does not revoke it.

This prevents beta testers and existing users from losing functionality they already had before monetization was introduced.

## Optional Developer Support

NextSeason includes an optional **Support NextSeason** section in the About screen.

The tip jar uses consumable StoreKit in-app purchases. Multiple tip amounts are offered using television-themed names.

Tips:

- Do not unlock functionality.
- Are entirely optional.
- Are available to both free and Plus users.
- May be purchased more than once.
- Are not promoted through repeated prompts or interruptions.

Their purpose is simply to give users who appreciate the app another way to help keep NextSeason running for years to come.

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

NextSeason uses native **StoreKit 2** for purchases and entitlement management.

The purchasing system supports:

- An annual auto-renewing NextSeason Plus subscription.
- A lifetime non-consumable NextSeason Plus purchase.
- Consumable tips.
- Purchase restoration.
- Entitlement refresh at launch and when the app becomes active.
- StoreKit transaction updates.
- Beta-user grandfathering.

Both an active annual subscription and a lifetime purchase provide the same NextSeason Plus entitlement: an unlimited watchlist.

Tips never grant Plus functionality.

The app waits for the initial StoreKit entitlement check before enforcing the watchlist limit so that an existing Plus customer is not temporarily treated as a free user during launch.

### Family Sharing

Family Sharing is disabled for the initial NextSeason Plus products.

This decision can be reconsidered after launch if there is a compelling user or business reason to support it.

## Purchase Experience

Users who reach the free watchlist limit are offered the opportunity to unlock NextSeason Plus.

The Plus purchase screen:

- Explains the three-show free limit and unlimited Plus watchlist.
- Displays pricing supplied by StoreKit rather than hard-coded prices.
- Offers the annual and lifetime purchase options.
- Provides Restore Purchases.
- Includes the required subscription disclosure.
- Provides links to the Terms of Use and Privacy Policy.

The About screen also displays the user's current watchlist entitlement and provides access to NextSeason Plus and Restore Purchases.

Purchase failures or unavailable StoreKit products are handled without changing the user's existing watchlist or entitlement.

## Review Requests

App Store review requests are implemented separately from monetization but follow the same non-intrusive philosophy.

NextSeason becomes eligible to request a review after it has demonstrated meaningful value by successfully delivering the user's first production show-status notification for the current app version.

The review request is delayed briefly so that it occurs while the user is active rather than interrupting the notification itself.

Eligibility is tracked by app version so that review-request behavior can remain appropriately limited.

The About screen also provides a persistent **Rate NextSeason** option that opens the App Store review page directly.

Review requests are not tied to purchases, subscription status, launch counts, or tip activity.

## Pricing

Production prices for NextSeason Plus and optional tips are **TBD**.

The prices currently present in the StoreKit configuration are development and testing values and should not be treated as final pricing decisions.

Production pricing should be decided before App Store submission after considering:

- Comparable App Store products.
- Expected customer behavior.
- Apple's commission structure, including Small Business Program eligibility.
- The relationship between annual and lifetime pricing.
- Expected ongoing operating and maintenance costs.
- The value of keeping the purchasing decision simple.

## Initial Product Structure

| Offering | Watchlist | Payment |
| --- | --- | --- |
| NextSeason Free | Up to 3 shows | Free, no expiration |
| NextSeason Plus Annual | Unlimited | Annual auto-renewing subscription |
| NextSeason Plus Lifetime | Unlimited | One-time purchase |
| Support NextSeason | No additional functionality | Optional consumable tips |
| Grandfathered Beta Access | Unlimited | No purchase required |

A monthly subscription is not part of the initial product structure.

## Status

**Implemented for pre-release testing.**

The StoreKit 2 purchasing architecture, free-tier limit, annual and lifetime Plus options, beta grandfathering, optional tips, purchase restoration, and review-request behavior are implemented.

Before App Store release, production products, pricing, legal links, App Store configuration, and purchase behavior must be finalized and validated in the production App Store environment.

The overall strategy may still evolve in response to beta feedback, App Store requirements, operating costs, or experience after launch.

One small judgment call I made: I documented **Family Sharing as disabled for the initial products**, rather than saying it is a permanent policy. That's what the StoreKit configuration says today, but it doesn't strike me as a product decision that needs to be irrevocably frozen.

I also deliberately did **not** put the `$10/$20/$1/$3/$5` StoreKit test prices into the roadmap; I think explicitly identifying them as test values is enough, and avoids giving those arbitrary numbers more significance than they deserve.

---

# you asked

message time: 2026-09-01 17:06:19

Looks good, thanks!

---

# chatgpt response

You're welcome!

---

# you asked

message time: 2026-09-01 17:18:54

Please re-review documentation

---

# chatgpt response

I re-reviewed the current archive, again treating the `MVP` tag as the MVP boundary and excluding the AI Transcripts. **The documentation itself is much better, but I found a few things that still need attention.**

### Changes we discussed

**1. MVP screenshots — partly done.**

You now have the correct structure:

- `Documentation/MVP/Screenshots/`
- `Documentation/Post-MVP/Screenshots/`

and the two sets are genuinely different images. Good.

However, the **project README still points to the MVP screenshots**:

```html
<img src="Documentation/MVP/Screenshots/MVP-Search-Results.png" ...>
<img src="Documentation/MVP/Screenshots/MVP-Show-Detail.png" ...>
<img src="Documentation/MVP/Screenshots/MVP-Watchlist.png" ...>
```

Those should now point to the three files under `Post-MVP/Screenshots/`, since the README is describing the current project.

**2. MVP navigation diagram — not reverted yet.**

`Documentation/MVP/Diagrams/02-navigation-and-screens.md` still contains:

```text
AppAboutPresentationModifier
```

where the tagged MVP has:

```text
BetaDiagnosticsPresentationModifier
```

So I would still revert that one diagram change.

**3. Diagram README — not changed yet.**

It still ends with:

> These diagrams ... should be updated whenever significant architectural changes are made...

We agreed that the MVP diagrams should instead be historical snapshots. I'd still change that paragraph accordingly.

There's also the minor `Settings/About` wording in that README. The MVP had About, not a Settings screen, so I'd use simply **About**.

**4. Broken links — improved only slightly; 10 remain.**

`InitialArchitecture.md` now correctly says **“implemented MVP architecture,”** which fixes the wording we discussed.

But it still contains three broken links:

- `ImplementationPlan.md`
- `ProductSpec.md`
- `NextSeason - Product Evaluation Roadmap.md`

That last one looks like a simple typo: **Evaluation** rather than **Evolution**.

It also still contains another link to the deleted old `Post-MVP Roadmap.md`.

`Implementation Plan.md` still contains six references to documents that no longer exist:

- `MVPBacklog.md`
- `FunctionalRequirements.md`
- `DecisionLog.md` ×2
- `Architecture.md` ×2

So this is the largest remaining mechanical cleanup.

**5. Implementation Plan historical status — fixed.**

You added:

> (Phase 4 was subsequently finished before the MVP was tagged)

That's exactly the kind of clarification I had in mind. I'd keep it.

**6. InitialArchitecture wording — fixed.**

It now says:

> authoritative description of the implemented MVP architecture

Good.

**7. `tThe` typo — fixed.**

Good.

**8. App Store Readiness — intentionally unchanged.**

Per our discussion, I agree with leaving completed requirements in their original prospective wording and marking the sections Complete.

The roadmap also now marks **Watchlist Export (Complete)**, which agrees with the current implementation.

**9. Monetization Strategy — fixed.**

The replacement roadmap is there and, after comparing it with the current StoreKit-related implementation again, I don't see anything material that needs correction. It accurately captures the free limit, Plus behavior, annual/lifetime options, grandfathering, tips, entitlement behavior, Family Sharing decision, review prompting, and TBD production pricing.

**10. Product Evolution heading — fixed.**

It's now:

> **Server-Side Monitoring & Push Notifications**

which makes the distinction from the earlier Notification Enhancements section much clearer.

### One new issue exposed by moving the screenshots

The **README itself needs a documentation pass**. In addition to pointing to the wrong screenshot set, its bottom links have become stale:

> The longer-term roadmap is available [here](Documentation/Post-MVP/Post-MVP\ Roadmap.md).

That file no longer exists. It should point to:

`Documentation/Post-MVP/NextSeason - Product Evolution Roadmap.md`

Also, under “Helpful links,” it currently links only to the MVP documentation:

> Documentation → `Documentation/MVP`

Now that Post-MVP contains substantial current documentation, that's misleading. I would probably make that section something like **MVP Documentation**, **Post-MVP Documentation**, **MVP Architecture Diagrams**, and **AI Transcripts** rather than using a generic “Documentation” link that goes only to the historical MVP folder.

There's another bit I'd reconsider:

> Version 1.0 is a focused, polished implementation of the core feature set (MVP), suitable for beta testing...

and later:

> Development continues beyond the MVP.

At this point the repository is **post-MVP and preparing for App Store release**, so that wording makes the project sound like it's still sitting at the MVP milestone. The README is current-facing rather than historical, so unlike the MVP documents, I think it should evolve with the project.

### Bottom line

The three substantive documentation files under `Post-MVP` now look properly separated and scoped. **I don't see any remaining significant duplication or a missing roadmap topic.**

What's left is mostly housekeeping:

1. Point README screenshots to `Post-MVP/Screenshots`.
2. Update the README's project-stage language and stale roadmap/documentation links.
3. Revert the one MVP navigation diagram to `BetaDiagnosticsPresentationModifier`.
4. Change the diagram README to say the MVP diagrams are historical snapshots, and change `Settings/About` → `About`.
5. Fix/remove the **10 remaining broken links** in the MVP documents.

After those, I think you can reasonably mark the **Documentation Review** item complete, with the separate **AI-Assisted Development Workflow** item remaining as its own outstanding App Store Readiness task.

---

# you asked

message time: 2026-09-01 17:27:11

Sorry.... I forgot to merge a stash, so you didn't get most of the changes.

---

# chatgpt response

Ah, yes — **this archive has the changes.** I rechecked the items from my last review against this version.

Most of the cleanup is now done:

- **README screenshots:** fixed. They now point to `Documentation/Post-MVP/Screenshots/`.
- **MVP screenshots:** restored as a distinct historical set; the Post-MVP screenshots are separate.
- **MVP navigation diagram:** fixed. `BetaDiagnosticsPresentationModifier` matches the `MVP` tag exactly.
- **Diagram README historical-snapshot language:** fixed.
- **Implementation Plan historical Phase 4 clarification:** fixed.
- **InitialArchitecture “implemented MVP architecture” wording:** fixed.
- **`tThe` typo:** fixed.
- **Monetization Strategy:** updated.
- **Product Evolution heading:** updated to distinguish server-side monitoring/push notifications.
- **App Store Readiness:** appropriately left in its plan-and-completion-record format.

I now find only **three broken internal links**, rather than the ten I reported from the unstashed version:

1. In the top-level `README.md`, the final roadmap link still points to the deleted:
   `Documentation/Post-MVP/Post-MVP Roadmap.md`

   It should point to `NextSeason - Product Evolution Roadmap.md`.

2. In `MVP/InitialArchitecture.md`, there's a link to:
   `NextSeason - Product Evaluation Roadmap.md`

   That's presumably just **Evaluation → Evolution**.

3. Also in `InitialArchitecture.md`, a later reference still points to the old:
   `../Post-MVP/Post-MVP Roadmap.md`

   That should likewise point to the Product Evolution Roadmap.

There's also one **very minor wording cleanup** left in `MVP/Diagrams/README.md`: the list still says:

> Settings/About

I'd change that to simply:

> About

because there wasn't a Settings screen in the MVP.

One thing from my previous review that I **wouldn't insist on anymore** is changing the README's general project-stage prose. Looking at it in the context of the whole README, the historical-development discussion is intentional, and I don't see anything seriously misleading enough to warrant rewriting it as part of this documentation cleanup.

So at this point I think you're essentially down to **three link fixes and one two-word terminology fix**.

After those, I would consider the documentation itself reviewed and clean. The separately planned **AI-Assisted Development Workflow** document can remain an outstanding App Store Readiness task rather than preventing you from calling this documentation cleanup complete.

---

# you asked

message time: 2026-09-01 17:33:59

I'm not sure it's valid to point only to the Product Evolution Roadmap at the end of the README.  Shouldn't we also point to the App Store Readiness Roadmap, since they are both MVP?

---

# chatgpt response

Yes. I think you're right, and my suggested replacement was too narrow.

The two roadmaps describe **two different phases after the MVP milestone**:

- **App Store Readiness Roadmap** — work between the tagged MVP and the initial App Store release.
- **Product Evolution Roadmap** — work intended after the initial App Store release.

So a sentence saying:

> The longer-term roadmap is available here.

and pointing only to Product Evolution skips the entire current phase of the project.

I'd replace that final sentence with something like:

> Development beyond the MVP is tracked in the [App Store Readiness Roadmap] and [Product Evolution Roadmap]. The first covers the work required to prepare the MVP for its initial App Store release; the second covers enhancements planned after release.

That also captures an important distinction: **I wouldn't say both roadmaps “are MVP.”** The *product* is based on the completed MVP, but the App Store Readiness roadmap is specifically **post-MVP/pre-release**, while Product Evolution is **post-release**.

And I'd make the corresponding correction in `InitialArchitecture.md`: wherever its old `Post-MVP Roadmap` link was intended as a general pointer to subsequent development, it may be appropriate to point to **both roadmaps**, rather than mechanically replacing every old link with Product Evolution. That's a better fix than what I suggested above.

---

# you asked

message time: 2026-09-01 17:34:29

Sorry, I meant post-MVP

---

# chatgpt response

Yes — then we're completely aligned. **Both are post-MVP roadmaps**, just for different portions of post-MVP development:

- **App Store Readiness:** post-MVP → initial App Store release.
- **Product Evolution:** after initial App Store release.

So the README should point to **both**, rather than treating Product Evolution as *the* post-MVP roadmap.

And that makes the old generic `Post-MVP Roadmap.md` references particularly worth replacing with both roadmaps where the context means “what happens after MVP.”

---

# you asked

message time: 2026-09-01 17:35:40

In retrospect I think we should have placed the MVP tag on the release candidate and folded all the App Store work into it.  But it's too late for that now.

---

# chatgpt response

I think that would have been the cleaner milestone, yes.

What you actually tagged as MVP was essentially **feature-complete MVP**, while the App Store Readiness phase has turned into a fairly substantial hardening/release-engineering phase: StoreKit, export, migration work, recovery behavior, accessibility auditing, review prompts, search improvements, documentation cleanup, and so on. In retrospect, “MVP” as a release-candidate milestone would have made the historical boundary easier to explain.

But I don't think it's worth rewriting history now. The current structure is still coherent if you define it explicitly:

- **MVP tag** = core product feature milestone.
- **App Store Readiness** = post-MVP hardening and commercialization work required for 1.0.
- **Release candidate / 1.0 tag** = actual shippable first-release milestone.
- **Product Evolution** = post-launch enhancements.

That distinction is actually pretty defensible. “Minimum viable product” and “ready for the App Store” are not inherently the same thing; the latter often includes a lot of reliability, compliance, monetization, accessibility, and operational work that doesn't change the fundamental product concept.

So I’d preserve the existing MVP tag and make the **release-candidate/1.0 tag the more important archival snapshot going forward**. That gives you a clean second milestone without muddying the Git history.

---

# you asked

message time: 2026-09-01 17:41:19

Check again, please.

---

# chatgpt response

Much closer. I checked the new archive, and the previous substantive issues are fixed. **There are just a couple of link-editing mistakes left.**

### README

The new closing paragraph has the right idea, but both the **link paths and the first link's displayed name** need fixing.

Right now it effectively says:

> Development beyond the MVP is tracked in the **Product Evolution Roadmap** [but links to App Store Readiness] and **Product Evolution Roadmap**...

Also, because `README.md` is at the repository root, the paths shouldn't begin with `../Post-MVP/`; they need to begin with `Documentation/Post-MVP/`.

So the two links should be:

- `Documentation/Post-MVP/NextSeason - App Store Readiness Roadmap.md`
- `Documentation/Post-MVP/NextSeason - Product Evolution Roadmap.md`

with the displayed names **App Store Readiness Roadmap** and **Product Evolution Roadmap**, respectively.

### `MVP/InitialArchitecture.md`

There's a similar copy/paste error in the new two-roadmap reference.

The first link *points* to the App Store Readiness Roadmap but is *labeled* Product Evolution Roadmap.

So that first label just needs to become **App Store Readiness Roadmap**.

The other Product Evolution link earlier in the file is now correct.

### Everything else

The good news is that everything we were trying to clean up is now where I think it should be:

- MVP navigation diagram matches the `MVP` tag.
- MVP diagram README now explicitly treats the diagrams as historical artifacts.
- `Settings/About` is fixed.
- MVP and Post-MVP screenshots are properly separated.
- README uses the Post-MVP screenshots.
- Old missing planning-document links have been cleaned up.
- Implementation Plan has its historical completion clarification.
- Monetization Strategy is current.
- App Store Readiness remains a historical plan/completion record.
- Product Evolution remains properly post-release.
- I don't see a new duplication or stage-classification problem.

So I'd fix those **three link details**, and then I think the documentation review itself is done.

---

# you asked

message time: 2026-09-01 17:44:59

I must be more tired than I thought.  One more time?

---

# chatgpt response

Yep. 😊 **This time it's clean.**

I checked the new archive, including re-running the internal Markdown-link check:

- **0 broken internal links.**
- README now points to both the **App Store Readiness Roadmap** and **Product Evolution Roadmap**, with the distinction between them explained correctly.
- `InitialArchitecture.md` likewise points appropriately to both roadmaps where it means post-MVP development.
- The other Product Evolution-specific reference in `InitialArchitecture.md` correctly points only to Product Evolution.
- `MVP/Diagrams/README.md` now says **About**, not Settings/About.
- The MVP navigation diagram is back to the tagged-MVP version.
- MVP diagrams are explicitly described as historical artifacts.
- MVP and Post-MVP screenshot sets are properly separated, and the main README uses the Post-MVP set.
- The Monetization Strategy reflects the current implementation.
- I don't see remaining inappropriate duplication, missing documentation, factual inaccuracies, or MVP/post-MVP stage confusion.

There is one purely cosmetic thing I noticed: the Markdown **link text** for App Store Readiness contains two spaces between `Readiness` and `Roadmap`:

`NextSeason - App Store Readiness  Roadmap.md`

That's only the displayed text; the actual link target is correct. The same double space appears in `InitialArchitecture.md`. I'd remove the extra space in those two labels, but it has no functional significance.

**After that cosmetic fix, I'd mark Documentation Review complete.**