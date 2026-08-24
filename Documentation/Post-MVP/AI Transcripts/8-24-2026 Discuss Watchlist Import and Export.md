> From: https://chatgpt.com/c/6a8cc80c-5778-83e8-a026-fecfbf8708cb

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

---
Powered by [AI Exporter](https://saveai.net)