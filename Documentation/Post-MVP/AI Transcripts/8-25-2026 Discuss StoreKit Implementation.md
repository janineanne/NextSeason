> From: https://chatgpt.com/c/6a8cc80c-5778-83e8-a026-fecfbf8708cb

# you asked

message time: 2026-08-24 15:39:11

I asked Cursor what info it needed to implement StoreKit.  These are the questions I was unsure of;  let me know what you think.

“Should we allow Family Sharing?”

 I think we probably should, but I would kind of like not to.

“What happens if Plus lapses and they already have more than 3 shows. This is the most important product rule. Options:
Keep tracking all existing shows, but block adding more until they re-subscribe or remove down to 3
Keep all shows visible, but stop refreshing / notifying on the extras
Ask them to pick 3 shows to keep active”

I’m really not sure here;  I haven’t run into this situation often enough to know what is usually done.

---

# chatgpt response

I’d make two different calls here.

For **Family Sharing**, I’d lean toward **not enabling it at launch**. The biggest reason is that Apple makes this a one-way decision: once you enable Family Sharing for a subscription, you cannot turn it off. ([Apple Developer](https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app?changes=_1&language=objc&utm_source=chatgpt.com)) Since you already have some reluctance about it, there’s very little upside to committing now. You can always enable it later once you know what your pricing and conversion look like.

And your reluctance is economically reasonable. Family Sharing can mean one subscription provides Plus to as many as six people. Apple pitches that as increasing value, conversion, engagement, and retention, and it may well do that—but for a small inexpensive utility app, I wouldn’t assume that giving five additional people free access is automatically a good trade. ([Apple Developer](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases?utm_source=chatgpt.com))

So I’d tell Cursor:

> **Family Sharing: No for 1.0. We may enable it later. Do not build any product logic that assumes it is enabled.**

The **subscription lapse** question is more interesting. I strongly prefer:

> **Keep tracking all existing shows, but prevent the user from adding additional shows until they are back at 3 or re-subscribe.**

That is both the least hostile and the simplest rule for the user to understand.

Suppose somebody has 17 shows, cancels Plus, and comes back six months later. I would leave all 17 exactly as they were: visible, refreshing, and eligible for notifications. They simply can't add show #18. If they voluntarily delete shows, they don't regain an available slot until they get below the free-tier limit. Thus at 17 → 16 they still can't add; at 4 → 3 they can add again normally.

I would **not** stop refreshing or notifying on 14 arbitrary "extra" shows. That creates a weird partially broken watchlist and forces you to decide *which* three are active. It also undermines one of NextSeason's main promises: *you put a show here and I'll remember it for you.*

And I particularly dislike **"pick 3 shows to keep active."** That's effectively holding the user's existing data/functionality hostage when they stop paying. It's more work for you, more UI, more state, and a considerably harsher cancellation experience.

There is one subtle distinction worth giving Cursor: **expiration isn't necessarily the same as cancellation.** Someone who turns off auto-renew remains Plus through the paid-through date. And if you eventually enable Apple's Billing Grace Period, StoreKit can continue treating someone as entitled while Apple is trying to recover a failed payment. Apple specifically distinguishes `subscribed` and `inGracePeriod` as entitled states from genuinely `expired`/`revoked` states. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions?utm_source=chatgpt.com)) So the downgrade rule should happen when the user actually **loses the Plus entitlement**, not merely when StoreKit says auto-renew has been turned off.

So my two answers to Cursor would be:

- **Family Sharing:** No at launch; revisit later. It can be enabled later but cannot be disabled once enabled.
- **Plus entitlement ends with >3 shows:** Preserve the entire watchlist and continue normal tracking/notifications. Block adding shows while count is ≥3. Existing shows are never removed or deactivated solely because Plus ended.

That second policy also has a nice marketing side effect: an ex-subscriber never comes away thinking, *"I stopped paying and NextSeason deliberately broke my watchlist."* Instead they retain what they built while subscribed, but Plus is required to expand it again. That feels very appropriate for the kind of product you're building.

---

# you asked

message time: 2026-08-24 15:41:40

Ok, sounds good.

You just reminded me of something else I had wanted to ask about.  Seems like we should allow some way for the user to export their watchlist?

---

# chatgpt response

Yes. I think you should, and I’d treat it as a **basic data-ownership feature**, not a Plus feature.

For NextSeason, the watchlist is user-created data. Even though it’s not especially sensitive, it’s good practice to give people a way to get it back out. It also fits nicely with the persistence/recovery work you’ve already done: “your list belongs to you; the app doesn’t trap it.”

I’d keep the first version very simple. My preference would be **Export Watchlist** in Settings/About, producing a shareable file through the standard iOS share sheet. For the file format, I’d probably use **CSV** because users can open it in Numbers, Excel, Google Sheets, or even a text editor. Something like:

`Show Name, TVMaze ID, TVDB ID, Status, Next Season Date/Status, Date Added`

You don't necessarily need every one of those columns; the important things are the **show name and stable IDs**. Including IDs means the export could potentially become useful for a future import/restore feature rather than merely being a human-readable list.

There are really two separate possible purposes:

**Human export:** “Here are the shows I follow.” CSV is ideal.

**Backup/restore export:** “Give me enough information to reconstruct my NextSeason watchlist exactly.” JSON or some proprietary NextSeason backup format would be better.

For 1.0, I would **only implement the human export**, but design it so it doesn't paint you into a corner. An export containing the show name plus TVMaze/TVDB identifiers is already pretty close to what you'd need for a later import.

And I would make one product rule explicit:

> **Export is available to everyone, regardless of subscription status or watchlist size.**

So if someone had 40 shows while subscribed, cancels Plus, and later wants to leave NextSeason entirely, they can still export all 40. I would not put their own data behind the paywall.

One other thought: **don't automatically pair Export with Import yet.** Import sounds like the natural companion, but it introduces conflict handling, missing shows, identifier changes, duplicates, free-tier limits, malformed files, versioning, etc. Export by itself is almost trivial and provides most of the user-respect benefit.

So I’d add to the roadmap something like: **“Watchlist export — CSV via share sheet; all users; includes stable show identifiers. Import/restore deferred.”**

---

# you asked

message time: 2026-08-24 15:51:57

Let's add export to App Store Readiness Roadmap and import to product evolution roadmap.  Please write sections to add to each.

---

# chatgpt response

I’d make the App Store Readiness item fairly concrete, while leaving the Evolution item broader because import has several product decisions we don’t need to make yet.

### App Store Readiness Roadmap

**Document Title: **

## Watchlist Export

Give users a way to export their watchlist so that their data is not locked into NextSeason.

### Requirements

- Add an **Export Watchlist** action in an appropriate location in the app.
- Export the complete watchlist as a CSV file using the standard iOS share sheet.
- Include enough information to identify each show independently of NextSeason, including:
  - Show name
  - TVMaze ID
  - TVDB ID, when available
- Consider including other useful human-readable information already stored by the app, such as show status or next-season information.
- Export must include **all shows in the watchlist**, including shows above the free-tier limit after a Plus subscription has expired.
- Export must be available to both free and Plus users and must not require an active subscription.
- Ensure the resulting CSV can be opened successfully in common spreadsheet applications such as Numbers and Excel.

Import and restoration from an exported watchlist are not required for the initial App Store release; see the Product Evolution Roadmap.

### Product Evolution Roadmap

**Document Title: **

## Watchlist Import and Restore

Allow users to import a previously exported NextSeason watchlist, providing a straightforward way to restore or transfer their data.

### Considerations

- Support importing the watchlist format produced by NextSeason's export feature.
- Use stable show identifiers where possible to match imported shows to current show data.
- Define behavior for:
  - Shows already present in the watchlist
  - Shows that can no longer be found or matched
  - Older export formats
  - Invalid or malformed files
  - Imports that would exceed the current free-tier watchlist limit
- Provide a clear summary of the import result, including shows that could not be restored.
- Preserve compatibility with exports created by earlier versions of NextSeason where practical.

Before implementation, determine whether import is intended primarily as a user-controlled backup/restore mechanism, a way to move data between devices, or both. Reevaluate the appropriate export/import format at that time; CSV may remain sufficient, or a versioned structured format such as JSON may be preferable for reliable restoration.