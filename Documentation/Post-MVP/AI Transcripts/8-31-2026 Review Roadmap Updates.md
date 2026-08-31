> From: https://chatgpt.com/c/6a950aae-ed64-83e8-8a19-cf80d0d0779b

# you asked

message time: 2026-08-30 22:04:38

While going through the list of changes since the last TestFlight build I thought of a couple of things:

- Now that we have the ability to export watchlist data, I think we should offer the option of trying to export the user's data before doing a destructive recovery

- When we implement status report notifications, the feature to ask the user for a review just after they get their first notification should be restricted to just status update notifications.

What do you think?

---

# chatgpt response

I agree with both, and I think the first one is especially important now that export exists.

- **Offer export before destructive recovery.** Once recovery reaches the point where NextSeason is proposing to delete/reset the local store, giving the user a last chance to export whatever can still be read is exactly the right behavior. I’d make it something like **“Export Watchlist” / “Reset Without Exporting” / “Cancel.”** The important wrinkle is that recovery may have been triggered because the store is damaged, so export needs to be explicitly **best-effort**: failure to export shouldn’t prevent the reset, and the UI shouldn’t imply that the exported data is necessarily complete. If the store is so damaged that nothing can be recovered, skip or disable the export option with an appropriate explanation.

- **Limit the post-notification review trigger to status-report notifications.** That makes the review request much better aligned with a moment when the user has actually experienced NextSeason's value. A reminder/repeated notification isn't evidence that the app has done its core job; the first status update telling someone that something meaningful changed for a show they're tracking is. I'd define the eligibility rule around the **notification type**, rather than merely “has received a notification,” so future notification types don't accidentally become review triggers.

There’s also a nice conceptual connection between these: both changes make existing infrastructure more intentional. Export stops being merely a user-invoked convenience and becomes part of **data-loss protection**, while review prompting stops treating all notifications alike and becomes tied specifically to a **successful value event**.

For the review behavior, I would preserve whatever other safeguards you already have—minimum usage, only once, no recent prompt, etc.—and simply change the notification prerequisite from roughly `hasReceivedFirstNotification` to `hasReceivedFirstStatusUpdateNotification`. I would **not** trigger the review immediately from the notification itself; keep the existing mechanism that waits until the user is appropriately back in the app, with the status notification merely establishing eligibility.

Both sound like App Store-readiness changes rather than post-MVP evolution items.

---

# you asked

message time: 2026-08-31 11:01:52

In App Store readiness the only notifications being sent are "show status changed" notifications.  The regular update notifications won't be implemented until the evolution phase.  Unless you think there is something to be implemented ahead of time, I think that one goes in the product evolution roadmap.

---

# chatgpt response

Yes, you're right. I was mentally treating the two notification types as if they already coexisted.

At **App Store readiness**, every real notification is a show-status-change notification, so there's nothing useful to restrict yet. Adding notification-type-specific review eligibility now would just be premature infrastructure for a distinction that doesn't exist.

I'd split the two ideas this way:

- **App Store Readiness:** Before destructive persistence recovery, offer a best-effort watchlist export when recoverable data is available.
- **Product Evolution:** When the new **status report/update notifications** are introduced, make sure those *do not* satisfy the review-prompt notification criterion. Only the existing **show-status-changed** notification should make the user eligible for the post-first-notification review request.

And that second item belongs naturally in the roadmap section where the new notification type is implemented. It isn't really a separate feature so much as an implementation requirement: **adding additional notification types must not broaden the review-request trigger.**

So I wouldn't change the review-request code now unless there's already an obvious, trivial way to encode the semantic distinction without adding complexity. Otherwise, document the requirement for the Evolution work and implement it when there are actually two kinds of notifications to distinguish.

---

# you asked

message time: 2026-08-31 11:16:55

Please review the changes in the two roadmap files only.

---

# chatgpt response

I reviewed **only the uncommitted changes in the two roadmap files**. I think the ideas are in the right roadmaps, but I’d make a few edits before committing.

### App Store Readiness Roadmap

The new requirement is correct, but it appears twice:

> `If local data can be exported, offer that option to the user.`

It’s under both **Persistence Recovery** and **Crash-Loop Prevention**. Since Crash-Loop Prevention ultimately leads into the persistence-recovery mechanism, I think the export requirement belongs only under **Persistence Recovery**. Otherwise it looks like two separate export behaviors need to be implemented.

I’d also make the wording more explicit about *when*:

> **Before resetting local data, if watchlist data can still be read, offer the user the option to export it.**

That captures the actual requirement better than “if local data can be exported.”

One other thing caught my attention: these headings changed from:

> `## Persistence Recovery (Complete)`  
> `## Crash-Loop Prevention (Complete)`

to headings without **(Complete)**. For Persistence Recovery, that makes sense because we just added a new requirement. But I don't think the new export requirement should make **Crash-Loop Prevention** incomplete too, especially if we remove the duplicate bullet. I’d restore **Crash-Loop Prevention (Complete)**.

### Product Evolution Roadmap

The placement is good, and the substance is exactly what we discussed. I would tighten the language to match the roadmap's existing outline style:

> - Offer the user the option to receive a regular status update notification showing the current status of all tracked shows, even when nothing has changed.
>   - Status update notifications must not count toward review-request eligibility. Continue to base that eligibility on the user's first **show-status-change notification**.

That avoids the somewhat implementation-note-like:

> “After this is implemented, asking the user for an App Store review ... will have to be changed...”

and states the intended product behavior directly.

### So: three changes

1. Keep the export requirement under **Persistence Recovery** only.
2. Restore **Crash-Loop Prevention (Complete)**.
3. Tighten the wording of both new roadmap additions as above.

Otherwise, I don't see anything problematic in these two diffs. The scope and roadmap placement now look right.