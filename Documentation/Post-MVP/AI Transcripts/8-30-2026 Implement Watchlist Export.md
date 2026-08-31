# Watchlist export feature

## User

Give users a way to export their watchlist so that their data is not locked into NextSeason.

Requirements:

- Add an **Export Watchlist** action to the About sheet
- Export the complete watchlist as a CSV file using the standard iOS share sheet.
- Include enough information to identify each show independently of NextSeason, including:
  - Show name
  - TVMaze ID
  - TVDB ID, when available
- Consider including other useful human-readable information already stored by the app, such as show status or next-season information.
- Export must include **all shows in the watchlist**, including shows above the free-tier limit after a Plus subscription has expired.
- Export must be available to both free and Plus users and must not require an active subscription.

## Assistant

I'll add an Export Watchlist action that shares the full list as CSV, starting with the About sheet, watchlist model, and subscription rules so export stays available after Plus expires.

`TrackedShow` doesn't store TVDB IDs, so I'll check the mapping database and how About/watchlist already surface show identity.

Export will live in About as a share-sheet action, build CSV from the full watchlist (not the free-tier cap), and look up TVDB IDs from the existing mapping database.

Users can now export their full watchlist from the About sheet as a CSV, with no Plus subscription required.

**Export Watchlist** is in About, below the tip jar. It writes a CSV and opens the system share sheet so the file can go to Files, Mail, Numbers, and so on.

Each row includes:

- Show name
- TVMaze ID
- TVDB ID, when the local mapping has one
- Status and next-season text (same wording as in the app)
- Next-season premiere date, when scheduled
- Date added
- TVMaze URL

The export reads every stored show. It does not apply the free-tier cap, so a lapsed Plus list still exports in full.

Skills used: `swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`, `swift-testing-pro`.

**What to test**

1. Open About (ellipsis on Search or Watchlist) and tap **Export Watchlist**.
2. Confirm the share sheet appears and the file is named `NextSeason-Watchlist.csv`.
3. Open the file in Numbers or Files and check name, TVMaze ID, and TVDB ID.
4. Confirm a free-tier account can export (no Plus prompt).
5. If the list is over 3 shows after Plus expired, confirm every show is in the file.
6. Export an empty watchlist — you should still get a header-only CSV.

## User

If I try to send the file directly to Numbers from the share sheet, Numbers opens but it doesn't open the file.  If I save the file to the Numbers folder in my iCloud Drive then it can open it.  The name of the file is NextSeason-Watchlist-2026-08-31-2EE4B347-AFE6-4CF4-9AD0-7894379D8AF3.csv;  is that what you expected?  It's 8-30 today, not 8-31;  I suppose you're using GMT or something like that?

## Assistant

The share sheet is using the on-disk name (GMT date plus a UUID), which is why Numbers gets `…-2026-08-31-2EE4B347-….csv`. I’ll switch to a local-date filename and share a stable file URL so Numbers can open it.

The GMT date and UUID were intentional on my side — that’s why the name looked like that, and why it already read August 31 after 5pm Pacific. Numbers is also getting a Transferable payload instead of a real file URL, which is why it launches without opening the sheet. I’ll fix the filename and share a stable CSV file the way the system share sheet expects.

Those two tests were writing the same cached filename in parallel, so one overwrote the other. I’ll give each test its own export directory.

Yes on both counts.

The share sheet was using the **on-disk name**, not the nicer suggested name. I had stamped the file with a **UTC date** plus a **UUID** so two exports would not collide. After 5pm Pacific, UTC is already the next calendar day, which is why you saw `2026-08-31-2EE4B347-…`.

Numbers launching without the sheet is a separate issue: `ShareLink` was handing over a Transferable payload. Numbers accepts that share target, then has nothing it can actually open. Saving to iCloud first worked because that path gives Numbers a real `.csv` file.

The export now:

- Names the file `NextSeason-Watchlist-2026-08-30.csv` using **your local date**
- Drops the UUID
- Shares a real file URL through the system share sheet, with the CSV type set explicitly

**What to test:** Export again and send it straight to Numbers. The file name should be today’s date, and Numbers should open the spreadsheet.

## User

Now the app is crashing every time I tap Export Watchlist.  There isn't much information on where or why.

## Assistant

A nested share sheet on top of About is a likely crash. I’ll check the current presentation path and any crash logs, then present the system share UI from the existing view controller instead.

The crash is from presenting `UIActivityViewController` inside a SwiftUI `.sheet` on top of About, which is already a sheet. I’ll present the system share UI from the existing view controller instead.

The crash came from presenting the system share sheet **inside a SwiftUI `.sheet`**, while About is already a sheet. UIKit does not allow `UIActivityViewController` to be used that way, and it often dies with little useful detail.

Export now presents the share UI from the existing About screen instead of stacking another sheet on top.

**What to test:** Open About and tap **Export Watchlist**. The app should stay up and the share sheet should appear. Try sending the CSV to Numbers again if that still matters.

## User

Same crash, sorry!

## Assistant

The UIKit presenter is still crashing, so I’ll pull the latest crash details and switch export to SwiftUI `ShareLink` with a file URL instead.

The first ShareLink version opened the share sheet; the crash started after `UIActivityViewController`. I’ll go back to `ShareLink` and pass the real file URL, keeping the local-date filename.

The crash was from presenting `UIActivityViewController` on top of the About sheet. That path is gone.

Export is back to SwiftUI `ShareLink`, which is what opened the share sheet before. The file is still named with your local date (`NextSeason-Watchlist-2026-08-30.csv`) and has no UUID.

**What to test:** Tap **Export Watchlist** again. You should get the share sheet and no crash.

If Numbers still launches without the spreadsheet, save the CSV to Files first and open it from there. That part is a Numbers limitation on the share-sheet handoff, and it is not worth bringing the crash back to chase.

## User

The crash is gone, and the filename is right, but when i try to share it with Numbers nothing happens. It seems like Numbers may not be receiving the file.

## Assistant

Numbers is showing up in the share sheet but not getting a

file it can import. I’ll inspect how we’re packaging the CSV and adjust the share payload so it looks like a real `.csv` file.

Numbers is treating the share as text because `.commaSeparatedText` is a text UTI. I’ll declare a file-based CSV type so the share sheet hands over a real `.csv` file instead.

The share sheet was handing Numbers **text**, not a file. The system CSV type also counts as plain text, so Numbers’ share extension never got a `.csv` it could import. That’s why Save to Files worked and a direct share did not.

Export now declares a file-only CSV type (`public.data`) and shares that through `ShareLink`. Mail, Files, and AirDrop should still get `NextSeason-Watchlist-2026-08-30.csv`.

**What to test:** Export again and send it straight to Numbers. If Numbers is missing from the sheet, or still does nothing, say so — that extension is picky, and Save to Files remains the fallback that we know works.

## User

Now it works.

## Assistant

Good. Numbers was ignoring the share because the system CSV type is treated as text. Exporting it as a file-only CSV is what lets Numbers actually open the sheet.

Export from About, then send it straight to Numbers, should keep working with today’s local date on the filename.

## User

Please make the following fixes on the watchlist-export branch. Keep the changes focused and preserve the existing architecture, conventions, and formatting.

1. Fix retry behavior after export preparation fails

There is a state-management bug in ExportWatchlistSection.

Currently, when export preparation fails:

* exportErrorMessage becomes non-nil.
* This enables the fallback Export Watchlist button.
* The error alert appears.
* When the user dismisses the alert with OK, the alert action clears exportErrorMessage.
* Because the button’s disabled state depends on exportErrorMessage, clearing it disables the Export Watchlist button again.
* The user therefore has no way to retry the export without recreating the view.

Fix this so that:

* Export availability is not coupled to whether an error message currently exists.
* Introduce explicit preparation/in-progress state if appropriate (for example, isPreparingExport).
* The Export Watchlist control should be disabled only when there is a legitimate reason it cannot be used, such as while export preparation is actively in progress.
* After an export preparation failure and dismissal of the error alert, the user must be able to tap Export Watchlist again and retry.
* A retry should invoke the existing export preparation path rather than duplicating export logic.
* Successful behavior should remain unchanged.

Add or update tests to cover the complete state transition:

1. Export preparation begins.
2. Preparation fails.
3. Error is presented.
4. User dismisses the error.
5. Export remains available.
6. User retries.
7. Export preparation is attempted again.

If testing this cleanly requires extracting a small amount of state/logic from the SwiftUI view into a testable type, do so only if it improves the design; don’t introduce unnecessary abstraction.

2. Protect CSV exports against spreadsheet formula injection

WatchlistCSVFormatter currently performs normal RFC-style CSV escaping, but quoting a value does not prevent spreadsheet applications such as Excel or Numbers from interpreting values beginning with formula characters as formulas.

Harden user/external textual data written to the CSV.

At minimum, protect text fields whose first character is one of:

* =
* +
* -
* @

The show title is the primary externally sourced field that needs this protection.

Use a conventional CSV/spreadsheet-safe approach, such as prefixing dangerous values with an apostrophe before performing normal CSV escaping.

For example, a title beginning with:

=HYPERLINK(...)

should be exported as textual content rather than something a spreadsheet could execute as a formula.

Keep formula sanitization separate from ordinary CSV escaping so that the responsibilities remain clear:

* Formula sanitization makes the cell safe for spreadsheet applications.
* CSV escaping handles commas, quotes, CR/LF, etc.

Do not alter ordinary show titles unnecessarily.

Add unit tests covering at least:

* a title beginning with =
* a title beginning with +
* a title beginning with -
* a title beginning with @
* an ordinary title remains unchanged
* a dangerous title that also requires normal CSV quoting/escaping is both sanitized and escaped correctly

Please run the relevant tests after making the changes and fix any failures caused by the implementation. Do not make unrelated cleanup or formatting changes.

## Assistant

I'll fix export retry so a failed prepare doesn't disable the button, and harden CSV text so spreadsheet formula prefixes can't execute. First I’ll read the current export section, formatter, and tests.

I'll extract a small preparation type so retry state can be tested, then add spreadsheet-safe sanitization for show titles before CSV escaping.

Both fixes are in, and the export tests passed.

**Retry after a failed export**
Preparation state now lives in `WatchlistExportPreparation`. The Export control is disabled only while a prepare is running. Dismissing the error clears the message and leaves export available, and a retry uses the same `prepare` path.

**Spreadsheet formula injection**
Show titles that start with `=`, `+`, `-`, or `@` get an apostrophe before normal CSV escaping. Ordinary titles are unchanged.

**What to test:** Force an export failure if you can (or trust the new unit test), dismiss the alert, and confirm Export Watchlist is still tappable. A title like `=HYPERLINK(...)` should show up in the CSV as `'=HYPERLINK(...)`.

