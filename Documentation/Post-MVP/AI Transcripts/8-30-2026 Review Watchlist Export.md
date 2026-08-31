> From: https://chatgpt.com/c/6a94cba8-1f0c-83e8-bfa8-959258449d5b

# you asked

message time: 2026-08-30 17:32:55

Please review the changes in branch watchlist-export.

---

# chatgpt response

I’ll review this like a code-review pass: identify the branch diff, inspect the export implementation and tests, then call out only issues that are actionable or worth tightening before merge.

I’ve found one concrete UI-state bug already: after an export-preparation failure, dismissing the error alert clears the very state that enables the retry button, leaving “Export Watchlist” disabled with no way to retry. I’m checking the persistence/query path and test coverage now for anything else at the same level.

The data path is otherwise thoughtfully covered: the reverse TVMaze→TVDB lookup is indexed in SQLite, exports include all stored shows regardless of subscription state, and the formatter has tests for quoting, ordering, BOM, and local-date filenames. I can’t execute the Xcode test suite in this environment because Xcode/xcodebuild isn’t installed, so I’m doing the remaining pass statically.

I reviewed the full `watchlist-export` diff against `main`. Overall, the implementation is well structured, and the file/data-format coverage is particularly good. I found **one definite bug I would fix before merging**, plus one worthwhile CSV hardening improvement.

1. **[P2] Export cannot actually be retried after a preparation failure — `ExportWatchlistSection.swift`.** When `prepareExport()` fails, `exportErrorMessage` becomes non-nil, which enables the fallback `Button`. But the alert immediately covers the UI. When the user taps **OK**, the alert action sets `exportErrorMessage = nil`; that makes `.disabled(exportErrorMessage == nil)` true. So after dismissing the error, the Export Watchlist button is disabled permanently unless the view is recreated.

   I’d decouple “we are preparing” from “an error exists”: introduce an `isPreparingExport` state and disable the button only while preparation is in progress. A failure should leave the Export button enabled so tapping it invokes `retryExport()`. This would also be a good place for a small view/model test specifically covering **fail → dismiss → retry**, because the existing tests don’t exercise this state transition.

2. **[P3 / hardening] Protect exported text from CSV/spreadsheet formula injection — `WatchlistCSVFormatter.swift`.** RFC 4180 escaping correctly handles commas, quotes, and line breaks, but quoting does **not** prevent Excel/Numbers from interpreting a field beginning with `=`, `+`, `-`, or `@` as a formula. The main externally sourced field here is the TVMaze show name. A malicious or simply oddly named TVMaze entry could therefore become executable spreadsheet content when the export is opened. I’d sanitize textual values beginning with spreadsheet formula characters—typically by prefixing an apostrophe—and add tests for names such as `=HYPERLINK(...)` and `@SUM(...)`. Since import is planned later, the eventual importer can recognize/remove the protective prefix if preserving the exact title matters. 

Everything else I inspected looks solid: the reverse TVMaze→TVDB lookup has an SQLite index, handles duplicate mappings deterministically, and is represented in the protocol/test double; all stored shows are exported rather than applying the free-tier limit; the CSV uses CRLF and a UTF-8 BOM; dates and filenames have sensible UTC/local-time semantics; fields are properly RFC-style escaped; exports are sorted deterministically; and the new environment dependency is injected in both production and preview composition.

`git diff --check` also reports no whitespace problems. I **couldn't run the Xcode build or test suite here because this environment doesn't have `xcodebuild` installed**, so this was a static review rather than a compile/test verification.

**Recommendation:** fix #1 before merging. I’d also do #2 now because it’s tiny and much easier to establish the safe CSV contract before import support starts. After those, I’d be comfortable with the branch.

---

# you asked

message time: 2026-08-30 17:34:42

Please write a prompt for both

---

# chatgpt response

Here’s a single Cursor prompt covering both changes:

**Document Title: **

Please make the following fixes on the `watchlist-export` branch. Keep the changes focused and preserve the existing architecture, conventions, and formatting.

## 1. Fix retry behavior after export preparation fails

There is a state-management bug in `ExportWatchlistSection`.

Currently, when export preparation fails:

- `exportErrorMessage` becomes non-nil.
- This enables the fallback **Export Watchlist** button.
- The error alert appears.
- When the user dismisses the alert with **OK**, the alert action clears `exportErrorMessage`.
- Because the button's disabled state depends on `exportErrorMessage`, clearing it disables the Export Watchlist button again.
- The user therefore has no way to retry the export without recreating the view.

Fix this so that:

- Export availability is not coupled to whether an error message currently exists.
- Introduce explicit preparation/in-progress state if appropriate (for example, `isPreparingExport`).
- The Export Watchlist control should be disabled only when there is a legitimate reason it cannot be used, such as while export preparation is actively in progress.
- After an export preparation failure and dismissal of the error alert, the user must be able to tap Export Watchlist again and retry.
- A retry should invoke the existing export preparation path rather than duplicating export logic.
- Successful behavior should remain unchanged.

Add or update tests to cover the complete state transition:

1. Export preparation begins.
2. Preparation fails.
3. Error is presented.
4. User dismisses the error.
5. Export remains available.
6. User retries.
7. Export preparation is attempted again.

If testing this cleanly requires extracting a small amount of state/logic from the SwiftUI view into a testable type, do so only if it improves the design; don't introduce unnecessary abstraction.

## 2. Protect CSV exports against spreadsheet formula injection

`WatchlistCSVFormatter` currently performs normal RFC-style CSV escaping, but quoting a value does not prevent spreadsheet applications such as Excel or Numbers from interpreting values beginning with formula characters as formulas.

Harden user/external textual data written to the CSV.

At minimum, protect text fields whose first character is one of:

- `=`
- `+`
- `-`
- `@`

The show title is the primary externally sourced field that needs this protection.

Use a conventional CSV/spreadsheet-safe approach, such as prefixing dangerous values with an apostrophe before performing normal CSV escaping.

For example, a title beginning with:

`=HYPERLINK(...)`

should be exported as textual content rather than something a spreadsheet could execute as a formula.

Keep formula sanitization separate from ordinary CSV escaping so that the responsibilities remain clear:

- Formula sanitization makes the cell safe for spreadsheet applications.
- CSV escaping handles commas, quotes, CR/LF, etc.

Do not alter ordinary show titles unnecessarily.

Add unit tests covering at least:

- a title beginning with `=`
- a title beginning with `+`
- a title beginning with `-`
- a title beginning with `@`
- an ordinary title remains unchanged
- a dangerous title that also requires normal CSV quoting/escaping is both sanitized and escaped correctly

Please run the relevant tests after making the changes and fix any failures caused by the implementation. Do not make unrelated cleanup or formatting changes.

Once Cursor has made these, send me the updated branch and I can do another review.

---

# you asked

message time: 2026-08-30 17:43:11

Better?

---

# chatgpt response

Yes. Both changes address the issues I found.

The **retry fix is good**. Extracting `WatchlistExportPreparation` was reasonable rather than over-engineered: it makes the state transition explicit and testable. The new test verifies the important sequence—failure → alert/error → dismissal → control remains enabled → retry → success—and also verifies that the control is disabled while preparation is actually underway.

The **CSV hardening is also implemented correctly**. It sanitizes only the externally sourced show name, keeps sanitization separate from CSV escaping, handles all four formula prefixes, and tests the interaction between formula protection and ordinary CSV quoting.

I also checked the new changes with `git diff --check`; they're clean.

One minor observation, **not something I'd hold the merge for**: `sanitizeForSpreadsheet` is internal rather than private solely because it's potentially testable, but the tests actually exercise it through `csv()` rather than calling it directly. It therefore could be `private`. That's purely an encapsulation nit and I wouldn't bother sending Cursor back for it unless you're already making another change.

**I don't see any new actionable problems. I'd merge this.**