# Undo toast refactor discussion

## User

ChatGPT thinks we should simplify the code for the undo toast.  I asked it to write a prompt for you and this is what it gave me.  Before starting work, please let me know if you agree with these changes and if not, what you would alter.

Please refactor the undo-toast / pending Watchlist removal implementation to reduce architectural complexity while preserving the existing user-visible behavior.
Important constraints:
    •    KEEP the anchored toast placement. The toast should still appear near the specific star/delete control that triggered the removal.
    •    KEEP the existing VoiceOver timing/focus behavior in UndoToast. That timing was added to fix a real VoiceOver problem, so do not simplify or remove it unless absolutely necessary.
    •    KEEP deferred persistence and the Undo period.
    •    KEEP support for removing from Watchlist, Search, and Show Detail.
    •    KEEP the rule that only one pending removal can exist at a time.
    •    KEEP the existing race protection around Undo vs. an in-progress commit.
    •    KEEP existing persistence-failure handling, analytics, and diagnostics behavior unless a change is required by the refactor.
    •    Do not redesign the UI or change the visual appearance of the toast.
The goal is not primarily to reduce line count. The goal is to make the state flow easier to understand and reduce coupling and duplicated mechanisms.
Please focus on these areas:
    1    Make pending-removal outcomes explicit.
Right now some code appears to infer what happened when pendingRemoval.id changes, sometimes by querying the repository to determine whether the removal was undone or committed.
Refactor this so the pending-removal coordinator exposes an explicit result/outcome for important transitions, conceptually something like:
enum PendingRemovalOutcome {
    case undone(showID: ...)
    case committed(showID: ...)
    case failed(showID: ..., error: ...)
}
The exact API is up to you. Do not introduce an enum merely for the sake of matching this example if another design is cleaner.
The important point is that callers should not have to infer whether a disappearing pending ID means Undo, successful commit, or failure by querying persistence.
    2    Establish one authoritative mechanism for updating the Watchlist after commit.
Currently there appear to be multiple overlapping mechanisms, including commit callbacks, explicit commit handling, pending-ID observation, and repository reconciliation.
Simplify this so there is one clear path by which a successful pending removal causes the Watchlist ViewModel/UI to remove the committed show.
Repository reconciliation may still exist as a safety/reload mechanism, but it should not be necessary to interpret the normal pending-removal state machine.
    3    Decouple pending-removal transaction state from presentation state where practical.
The coordinator should primarily own the transaction:
    •    which show is pending
    •    timer/lifetime
    •    Undo
    •    commit
    •    persistence result
The toast presentation layer should own presentation concerns such as its anchor/geometry.
Because the anchored placement must remain, some anchor information obviously still has to travel from the triggering control to the toast. Refactor this only if doing so produces a genuinely cleaner boundary.
In particular, avoid making repository/domain-facing code care about CGRect or other view geometry if that can reasonably be avoided.
Do not introduce a large abstraction solely to accomplish this separation.
    4    Reduce unnecessary coupling between navigation and persistence.
Review the places where changing tabs, opening another screen, refreshing, etc. automatically commits a pending removal.
Where there is no strong functional reason to commit immediately, prefer allowing the existing pending-removal timer/coordinator to continue managing the transaction.
Do not change behavior blindly. If a navigation-triggered commit is required to prevent an actual correctness or UI problem, retain it and explain why in a comment or in your summary.
    5    Preserve the existing VoiceOver behavior.
Do not remove or simplify the timed VoiceOver focus choreography in UndoToast.
This timing was added to fix a specific accessibility bug: when the toast appeared, VoiceOver focused and announced Undo immediately, but skipped the “removed from watchlist” status message. The current sequence deliberately focuses the status first and then moves focus to Undo after the status has had time to be announced.
Please add or improve a comment near that code documenting this reason. Treat the timing as intentional accessibility workaround behavior, not arbitrary delay/animation code.
    6    Keep the implementation proportionate.
Please do NOT turn this into a generalized undo framework, generic transaction framework, event bus, reducer architecture, or elaborate state machine library.
This app needs a clean implementation of one pending Watchlist removal, not infrastructure for hypothetical future features.
After refactoring:
    •    Run the existing tests.
    •    Update/add focused tests where the state flow has changed.
    •    Preserve tests that protect important race conditions and persistence failure behavior.
    •    Check Search, Show Detail, and Watchlist removal paths.
    •    Check Undo.
    •    Check expiration/commit.
    •    Check removing a second show while another removal is pending.
    •    Check VoiceOver behavior is unchanged at the code level.
    •    Check anchored toast positioning still receives the correct triggering anchor.
Before making changes, inspect the complete existing implementation and trace the current state flow so that behavior added for previous bug fixes is not accidentally removed.
When finished, give me:
    1    A concise description of the old state flow.
    2    A concise description of the new state flow.
    3    A list of files changed.
    4    Any existing complexity you deliberately kept and why.
    5    Any behavior you changed, even if you believe the change is an improvement.

## Assistant

I'll inspect the undo-toast and pending removal implementation first, then give you a concrete assessment of ChatGPT's proposed refactor against what's actually in the codebase.

I'll read the core coordinator and view files to validate the proposed refactor against the actual implementation.

I agree with the overall direction — the prompt correctly identifies the real pain points — but I would narrow scope and push back on a few items so the refactor does not accidentally undo deliberate behavior.

## Verdict

**Yes, this refactor is worth doing**, but I would treat it as a **targeted state-flow cleanup**, not a broad architectural pass. The current code works and has good test coverage; the main problem is that callers **infer outcomes** from `pendingRemoval?.id` disappearing plus repository queries, while **three parallel paths** can update the Watchlist after commit.

---

## Where I agree

### 1. Explicit outcomes — strongly agree

This is the highest-value change. The clearest smell is in `handlePendingRemovalIDChange`:

```223:238:NextSeason/Features/Watchlist/WatchlistViewModel.swift
    func handlePendingRemovalIDChange(from oldID: Int?, to newID: Int?) async {
        guard let oldID, newID == nil else { return }
        if await showWasRemoved(showID: oldID) {
            removeShowAnimated(showID: oldID)
            return
        }
        guard !shows.contains(where: { $0.id == oldID }) else { return }
        do {
            if let tracked = try await repository.trackedShow(showID: oldID) {
                restoreShowAnimated(tracked)
            } else {
                await reload()
            }
        } catch {
            await reload()
        }
    }
```

That cannot distinguish **undo** vs **navigation cancel** vs **commit still in flight** without guessing from persistence. An explicit outcome (enum, delegate, or async stream — whatever fits best) would simplify Watchlist, Search, and Detail.

I would extend the prompt’s example to include at least:

- `.committed(showID:)`
- `.undone(showID:)`
- `.cancelled(showID:)` — detail navigation dismiss; show stays tracked
- `.failed(showID:, error:)` — already partially modeled via `removalErrorMessage`
- `.replaced(showID:)` — when a second pending removal commits the first

**Undo and cancel are not the same thing**, and the refactor should preserve that.

### 2. One authoritative Watchlist update path — strongly agree

Today there are overlapping mechanisms:

| Path | When it runs |
|------|----------------|
| `onCommitted` callback at `requestRemoval` time | Timer, OK, replace, some commits |
| `handlePendingRemovalIDChange` | Any `pendingRemoval?.id` → nil |
| `commitPendingRemovalIfNeeded` on ViewModel | Pull-to-refresh, tab leave |

These overlap by design for resilience, but they are hard to reason about. After explicit outcomes, **one handler** in `WatchlistViewModel` should react to `.committed` / `.undone` / `.failed`. Repository reload can remain as a safety net, not part of the normal state machine.

### 3. Decouple transaction from presentation — agree, but keep it small

`toastAnchor` living on the coordinator is mild coupling, not a disaster:

```186:191:NextSeason/Features/Watchlist/WatchlistPendingRemoval.swift
    private func performRequestRemoval(
        _ tracked: TrackedShow,
        anchor: CGRect
    ) {
        pendingRemoval = tracked
        toastAnchor = anchor
```

I would **only** split this if the outcome refactor naturally creates a cleaner boundary — e.g. anchor passed into the app-root toast modifier separately, coordinator owns transaction only. I would **not** introduce a second coordinator or presentation service for one toast.

### 5 & 6. VoiceOver + proportionate scope — fully agree

The VoiceOver timing is intentional and should stay as-is, with a comment explaining why:

```145:155:NextSeason/Features/Watchlist/UndoToast.swift
                Task { @MainActor in
                    // Let the toast enter the accessibility tree before focusing.
                    try? await Task.sleep(for: .milliseconds(150))
                    guard isPresented else { return }
                    toastFocus = .message

                    // Read the message, then move focus to Undo for quick access.
                    try? await Task.sleep(for: .milliseconds(1_800))
                    guard isPresented else { return }
                    toastFocus = .undo
                }
```

No generic undo framework, event bus, or reducer.

---

## Where I would alter the prompt

### 4. Navigation-triggered commits — push back on “prefer timer continues”

Several navigation hooks are **intentional product/correctness decisions**, not accidental coupling:

| Trigger | Behavior | Keep? |
|---------|----------|-------|
| Leave Watchlist tab | Commit deferred removal | **Yes** — user left the context; `onDisappear` falsely fires on push-to-detail |
| Open Show Detail | Cancel deferred / hide toast for immediate | **Yes** — toast covered About text |
| Pull-to-refresh | Commit first | **Yes** — refresh must reflect committed state |

I would **not** ask the agent to relax these unless a concrete bug is found. The prompt’s “prefer timer continues” is fine in principle, but in this codebase most navigation commits **do** have strong reasons. I would reword to:

> *Review navigation-triggered commits; retain any that prevent a documented correctness or UX problem. Do not change tab-leave commit, detail dismiss, or refresh commit without explicit justification.*

### Preserve the two-mode model (deferred vs immediate)

This is not accidental complexity — SwiftUI `List.onDelete` requires synchronous row removal:

```148:150:NextSeason/Features/Watchlist/WatchlistViewModel.swift
    /// Swipe-to-delete: drops rows from the list immediately, then persists and
    /// shows an informational undo toast. Must run synchronously inside
    /// `.onDelete` so `List` item counts stay consistent.
```

Any outcome API must account for both modes. For immediate swipe, `.committed` means “already persisted at request time”; undo restores rather than canceling a pending delete.

### Preserve race protection as non-negotiable

Clearing `pendingRemoval` before `repository.remove` is deliberate:

```227:236:NextSeason/Features/Watchlist/WatchlistPendingRemoval.swift
        // End the undo window as soon as commit begins so Undo cannot race with
        // an in-flight `repository.remove`.
        //
        // Note for future cloud / suspending persistence: clearing `pendingRemoval`
        // here means Search/Detail may refresh while the show is still persisted
        // and briefly treat it as tracked again.
        clearPendingPresentation()
```

The refactor should **not** “fix” that brief Search/Detail flash by keeping pending state longer — that would reintroduce the undo-vs-commit race. Outcomes should make that window explicit instead.

### Replace-pending path needs explicit treatment

When the user untracks show B while show A is pending, A is committed via fire-and-forget `Task` in `finalizeReplacedPendingRemoval`. That path bypasses normal commit flow and is a good candidate for emitting `.replaced(showID:)` so Watchlist does not rely on repository inference.

### Search/Detail are in scope too

The prompt focuses on Watchlist ViewModel, but Search and Detail also observe `pendingRemoval?.id`:

- `SearchView` — `.task(id: pendingRemoval?.id)`
- `ShowDetailView` — `onChange` + `refreshTrackedState`

They would benefit from the same explicit outcomes, not just Watchlist.

---

## What I would actually do (proposed scope)

If you want me to proceed, I would aim for something like this:

1. **Add explicit outcome delivery** on `WatchlistPendingRemoval` (property, callback, or small delegate — not a framework).
2. **Consolidate Watchlist list updates** into one outcome handler; remove or slim `handlePendingRemovalIDChange` and redundant `onCommitted` duplication.
3. **Wire Search/Detail** to outcomes instead of inferring from ID changes where practical.
4. **Optionally** move `toastAnchor` out of the coordinator if it falls out naturally.
5. **Add VoiceOver comment** only — no timing changes.
6. **Leave navigation commit/dismiss behavior unchanged** unless investigation finds a bug.
7. **Run and extend tests** for outcomes, replace-pending, races, and persistence failure.

Estimated touch: ~6–8 files, moderate diff. Not a rewrite.

---

## Complexity I would deliberately keep

- **App-root toast** — survives tab switches
- **Tab-leave commit vs detail dismiss** — different lifecycle signals, different product intent
- **Clear pending before persist** — race protection
- **Unstructured persist `Task`** — survives tab-switch cancellation
- **Deferred vs immediate modes** — SwiftUI constraint
- **Repository reload as fallback** — safety net, not primary path

---

## Summary

| Prompt item | My take |
|-------------|---------|
| Explicit outcomes | ✅ Do it — highest value |
| One Watchlist update path | ✅ Do it |
| Decouple presentation | ✅ Small move only if natural |
| Relax navigation commits | ⚠️ Mostly keep as-is |
| VoiceOver | ✅ Comment only |
| Stay proportionate | ✅ Agree |

Want me to proceed with this narrowed version of the refactor?

## User

Yes

## Assistant

I'll implement the narrowed refactor: explicit pending-removal outcomes, a single Watchlist update path, and minimal presentation decoupling while preserving existing behavior.

Implementing explicit outcomes in the coordinator, then wiring Watchlist, Search, and Detail to consume them.

Refactor is done. All 141 unit tests pass.

## 1. Old state flow

Pending removal was driven by `pendingRemoval` and `toastAnchor` on the coordinator. When `pendingRemoval?.id` cleared, callers **inferred** what happened:

- **WatchlistViewModel** used `handlePendingRemovalIDChange` + `repository.contains()` to guess commit vs undo vs immediate restore
- **Watchlist list updates** came from three overlapping paths: `onCommitted` callbacks, `handlePendingRemovalIDChange`, and `commitPendingRemovalIfNeeded` post-commit repository checks
- **Search/Detail** observed `pendingRemoval?.id` changes to refresh star state
- **Search/Detail commits** used per-request `onRemovalCommitted` callbacks to notify the watchlist tab

## 2. New state flow

`WatchlistPendingRemoval` now emits explicit `PendingRemovalOutcome` values:

| Outcome | When |
|---------|------|
| `.committed` | Deferred commit, timer/OK/tab-leave, or immediate persist |
| `.undone` | User tapped Undo |
| `.cancelled` | Detail navigation dismissed a deferred removal |
| `.replaced` | Second pending removal committed the first |
| `.failed` | Persistence failed |

Delivery uses `lastOutcome` + `outcomeGeneration` (for SwiftUI) and `addOutcomeHandler` (for ViewModel).

- **WatchlistViewModel** registers one handler in `init` → `handleOutcome` is the single list-update path
- **SearchView** observes `outcomeGeneration` → refreshes stars; calls `onWatchlistChanged` on `.committed`/`.replaced`
- **ShowDetailViewModel** has `handlePendingRemovalOutcome` for the same pattern
- **`onCommitted` / `onRemovalCommitted` callbacks removed**

Transaction state (pending show, timer, commit, persist) stays on the coordinator; `toastAnchor` remains there for app-root toast binding (minimal, practical coupling).

## 3. Files changed

| File | Change |
|------|--------|
| `PendingRemovalOutcome.swift` | **New** — outcome enum |
| `WatchlistPendingRemoval.swift` | Emits outcomes; removed callback-based commit notification |
| `WatchlistViewModel.swift` | Single `handleOutcome`; removed inference/repository checks |
| `WatchlistView.swift` | Removed `onChange(pendingRemoval?.id)` |
| `WatchlistTracking.swift` | Removed `onRemovalCommitted` parameter |
| `SearchView.swift` | Observes outcomes instead of pending ID |
| `SearchWatchlistTracking.swift` | Removed commit callback |
| `ShowDetailView.swift` | Observes outcomes |
| `ShowDetailViewModel.swift` | Added `handlePendingRemovalOutcome` |
| `UndoToast.swift` | VoiceOver timing comment only |
| `WatchlistPendingRemovalTests.swift` | Outcome-based assertions + new tests |
| `WatchlistViewModelTests.swift` | Updated for outcome flow + failure restore test |

## 4. Complexity deliberately kept

- **Deferred vs immediate modes** — required by SwiftUI `List.onDelete`
- **Clear `pendingRemoval` before persist** — undo vs commit race protection
- **Unstructured persist `Task`** — survives tab-switch cancellation
- **Tab-leave commit, detail dismiss, refresh commit** — unchanged navigation behavior
- **App-root toast + `toastAnchor` on coordinator** — toast survives tab switches; anchor still captured at request time
- **`finalizeReplacedPendingRemoval` fire-and-forget** — still commits replaced show asynchronously (now emits `.replaced`)

## 5. Behavior changes

**None intentionally.** Navigation commits/dismissals, VoiceOver timing, anchored toast placement, single-pending rule, race protection, analytics, and error alerts are preserved.

One subtle implementation difference: Search/Detail no longer refresh on every `pendingRemoval?.id` change (including when a removal *starts*). That is safe because Search/Detail already apply optimistic star updates at tap time via `WatchlistTracking.toggle`; outcomes now drive refresh on terminal transitions only.

---

**What to test manually**

1. Star untrack on Watchlist → row stays, anchored toast, Undo/OK/timer
2. Swipe delete → row gone immediately, Undo restores
3. Untrack on Search/Detail → toast, star updates, tab switch
4. Second star tap undo (without toast)
5. Untrack A, then B → A committed, B pending
6. Untrack on Watchlist, push Detail → toast gone, show still tracked
7. Untrack on Watchlist, switch to Search tab → removal committed
8. VoiceOver: message announced before Undo focus
9. Persistence failure alert still appears

## User

I found a few problems:
3. There's no tab switch
7. This works most of the time, but sometimes the removal is cancelled instead
9. How do I make a persistence failure happen?

## Assistant

Investigating the tab-switch and cancellation behavior — item 7 sounds like a race or ordering bug between commit-on-leave and dismiss-on-detail.

Identifying the issue: `ShowDetailView` cancels pending removals on every `onAppear`/`.task` re-run, including when a tab switch re-shows detail already on the stack — that races with tab-leave commit. Moving cancel to navigation push only.

Good catches — here's what's going on with each, and a fix for #7.

## 3. "There's no tab switch"

My test note was misleading. **Untracking from Search or Detail doesn't involve a tab switch** — and it shouldn't need one.

The toast lives at the app root (`AppRootView`), so it stays visible regardless of tab. Star state updates optimistically when you tap untrack. The undo timer keeps running until you tap Undo, OK, or the timer expires.

**Only leaving the Watchlist tab commits a deferred removal.** Leaving Search does not. So the correct manual test for Search/Detail is:

1. Untrack a show → toast appears, star empties
2. *(Optional)* switch tabs → toast should still be there
3. Wait for timer / tap OK → show is actually removed

There is no tab-switch *action* in that flow — I shouldn't have implied there was.

---

## 7. Sometimes cancelled instead of committed — **fixed**

This was a real bug. Repro when it failed intermittently:

1. Open a show's detail on **Search** (leave it on the nav stack)
2. Switch to **Watchlist**, untrack a show (undo toast appears)
3. Switch back to **Search**

What happened:

- Search tab became visible → `ShowDetailView` **`onAppear` / `.task` re-ran**
- That called `dismissPendingRemovalForNavigation()` → **cancelled** the removal
- The tab-leave commit in `ContentView` ran too late (or found nothing to commit)

**Fix applied:**
- Removed cancel from `ShowDetailView`'s `onAppear` and `.task`
- Cancel now only happens on a **fresh push** via `navigationDestination` in `SearchView` and `WatchlistView`
- Tab-leave commit now runs **before** `popSearchToRoot()` in a single ordered task

Please retry #7 with the old repro above — it should commit reliably now. Pushing detail from Watchlist while a removal is pending should still cancel (intentional).

---

## 9. How to make a persistence failure happen

**In the running app today: you basically can't**, and that's expected. Removals go to local SwiftData, which almost never fails in normal use. There's no debug toggle for it yet.

**What already covers it:** unit tests inject a failing repository:

```swift
// WatchlistPendingRemovalTests — FailingRemoveRepository throws on remove()
// WatchlistViewModelTests — failedImmediateDeleteRestoresRow
```

**Manual test path (unit test in Xcode):**
Run `WatchlistPendingRemovalTests/removeFailureExposesErrorAndLeavesShowPersisted` or `WatchlistViewModelTests/failedImmediateDeleteRestoresRow` — those verify the alert, show stays in the list, and `.failed` outcome.

**If you want a manual in-app repro**, I can add a DEBUG-only hook (e.g. triple-tap About → "Simulate watchlist remove failure"). Say the word if you'd like that.

---

**What to retest after the fix**

- #7: Search detail on stack → Watchlist untrack → switch to Search → show should be **removed**
- #6 still works: untrack on Watchlist → **push** detail → removal **cancelled**, show stays tracked
- #3: untrack on Search → toast persists across tab switches without needing a commit

## User

When I double-tap on a star button to remove a show, it reads "add <show>" before reading the toast.  This isn't entirerely wrong, since the star button has changed roles, but it's a little confusing.  Is this how it's supposed to work?

## Assistant

Checking how the track button exposes its accessibility label and how that interacts with the undo toast.

Short answer: **no, that's not intentional** — it's a side effect of how the star button updates while VoiceOver focus is still on it.

## What you're hearing

When you untrack a show, the star empties right away and `ShowRowTrackButton` switches its label based on `isTracked`:

```182:189:NextSeason/Features/Search/ShowRow.swift
    private var trackAccessibilityLabel: String {
        if isUpdating {
            return String(localized: "Updating watchlist for \(showName)")
        }
        return isTracked
            ? String(localized: "Stop tracking \(showName)")
            : String(localized: "Track \(showName)")
    }
```

After the double-tap:

1. VoiceOver is still focused on the star
2. The label flips from **"Stop tracking …"** to **"Track …"** (likely what you're hearing as "add")
3. VoiceOver re-announces the element under focus
4. ~150ms later, the toast focus choreography runs and **"Removed from watchlist"** is read

The VoiceOver timing in `UndoToast` was only tuned so the toast message comes before Undo — not to handle the star relabeling.

## Why it feels confusing

During the undo window, the star looks untracked, but a second tap **undoes** the removal — it doesn't add the show again in the normal sense. So **"Track …"** is misleading for that state: the visual, the label, and the actual action don't line up.

## Is it "wrong"?

It's **understandable but not ideal**. The label change is technically accurate for the empty-star appearance, but it fights the toast and doesn't describe the undo-on-second-tap behavior.

A cleaner approach would be a third accessibility state while removal is pending, e.g. **"Undo removing … from watchlist"**, and optionally moving focus to the toast sooner so the star doesn't re-announce.

If you want, I can implement that pending-removal label across Watchlist, Search, and Detail.

## User

Yes

## Assistant

Implementing a pending-removal accessibility state on the star button so VoiceOver announces undo instead of "Track".

The star button now has a dedicated pending-removal accessibility state on Watchlist, Search, and Show Detail.

## What changed

`ShowRowTrackButton` accepts `isPendingRemoval` and uses a third label/hint pair:

| State | Label | Hint |
|-------|-------|------|
| Tracked | "Stop tracking …" | Adds or removes… |
| Untracked | "Track …" | Adds or removes… |
| **Pending removal** | **"Undo removing … from watchlist"** | **Restores the show to your watchlist** |

When you untrack a show, VoiceOver should now re-announce **"Undo removing …"** instead of **"Track …"**, which matches the second-tap undo behavior and aligns with the toast.

## Files updated

- `ShowRow.swift` — pending label + hint
- `WatchlistView.swift`
- `SearchView.swift`
- `ShowDetailView.swift`

## What to test with VoiceOver

1. Untrack a show (double-tap star) → hear **"Undo removing …"**, then the toast **"Removed from watchlist"**
2. Double-tap the star again during the undo window → removal is undone
3. Repeat on Watchlist, Search, and Show Detail

VoiceOver may still read the updated star label before the toast — that's expected while focus is on the button — but the wording should now make sense.

## User

It says "Undo removing", then gets interrupted by "Removed from watchlist" from the toast.

Is it possible to suppress "Undo removing" completely?

## Assistant

Hiding the star from VoiceOver while a removal is pending so only the toast announces the removal.

Yes — that's possible, and it's now implemented.

While VoiceOver is running and a removal is pending, the star is **hidden from the accessibility tree** (`.accessibilityHidden(true)`). VoiceOver won't read "Undo removing …" at all; the toast owns that moment with **"Removed from watchlist"**, then focus moves to **Undo**.

**VoiceOver flow now:**
1. Double-tap star to untrack
2. Star drops out of the VO tree (no relabel announcement)
3. Toast reads **"Removed from watchlist"**
4. Focus moves to **Undo** after the existing delay

**Undo during the window:** use the toast's **Undo** button (the intended VO path). The star is still visible and tappable for sighted users / second-tap undo, but VoiceOver skips it while the toast is up.

Please retry with VoiceOver and let me know if anything still gets cut off.

## User

The show name is "Call the Midwife".  After double-tapping on the star, VO says "Stop tracking Call" and then starts reading the toast.

## Assistant

VoiceOver is re-reading the star label mid-announcement when state changes. Hiding the button synchronously on tap (before the parent re-renders) and moving toast focus faster.

The truncated "Stop tracking Call" is VoiceOver's double-tap activation read getting cut off when state changes. I'll post the toast announcement immediately from the coordinator and hide the star before the parent re-renders.

What you heard — **"Stop tracking Call"** — is VoiceOver reading the star's **activation label** ("Stop tracking Call the Midwife") and getting **cut off** when the UI updates, not the pending-removal label we added earlier.

## Fix (three parts)

1. **Hide the star immediately on tap** — before the parent re-renders, so VoiceOver drops the button from the tree on the same run loop
2. **Post "Removed from watchlist" via `UIAccessibility.post(.announcement)`** — as soon as removal starts, this should interrupt any partial star speech and speak the toast message once
3. **Skip toast message focus** — when that announcement was posted, the toast goes straight to the Undo focus timer so you don't hear the status twice

## Expected VoiceOver flow now

1. Double-tap star
2. **"Removed from watchlist"** (may briefly overlap with the tail of activation speech, but star label should not complete)
3. Pause, then focus moves to **Undo**

Please retry with "Call the Midwife" and let me know if you still hear any of the star label. A tiny fragment before the announcement can still happen — that's VoiceOver starting the activation read before our code runs — but "Stop tracking Call the Midwife" should not play through anymore.

## User

Now there's a short silence and it starts reading the Undo button,  Skips "Removed from Watchlist".

## Assistant

The announcement path is skipping message focus without reliably speaking the status. Restoring toast message focus and removing the broken announcement/skip logic.

Restoring the 150ms delay before message focus — one run loop wasn't enough for the toast to enter VoiceOver's tree.

That silence happened because the last fix broke the message path: we skipped toast message focus assuming `UIAccessibility.post` had already spoken **"Removed from watchlist"**, but that announcement wasn't reliably heard — so VoiceOver sat through the 1.8s wait and jumped straight to **Undo**.

## What I changed

- **Removed** the `UIAccessibility.post` announcement and the skip-message-focus logic
- **Restored** the original toast focus sequence: wait 150ms → focus status message → wait 1.8s → focus Undo
- **Kept** hiding the star from VoiceOver immediately on untrack (to reduce the "Stop tracking Call…" interruption)

## Expected flow now

1. Double-tap star (you may hear a brief fragment of the star label — hard to eliminate entirely)
2. **"Removed from watchlist"** from the toast
3. Pause, then **Undo**

Please try again with "Call the Midwife." If the status is still skipped, tell me which screen you're on (Watchlist / Search / Detail) and we can try a longer tree-insertion delay or modal focus on the toast container.

## User

Now it says "Favorite Image" and then reads the full toast on the first time I double tap, and "Stop tracking Call' and then the full toast if I undo the removal and then do it again.

## Assistant

Investigating VoiceOver announcements — "Favorite Image" likely comes from the SF Symbol inside the star button.

Fixing the "Favorite Image" leak (SF Symbol exposed when the button is hidden) and simplifying the VoiceOver handoff to the toast.

Here's what was going on:

## "Favorite Image" (first tap)

When we hid the star button from VoiceOver, the **SF Symbol inside the button** (`star.fill`) was still exposed. iOS reads that as **"Favorite Image"**. That only happened on the first tap because hiding the button dropped focus onto the orphaned image.

**Fix:** The star image and progress spinner are now always hidden from VoiceOver (`.accessibilityHidden(true)`), and the label group uses `.accessibilityElement(children: .ignore)` so only the button's **"Stop tracking …"** label is ever spoken — not the icon.

Also removed the `layoutChanged` post, which was jumping focus unpredictably between attempts.

## "Stop tracking Call" (second tap)

On repeat, VoiceOver was reading the button's **activation label** before the toast took focus — standard double-tap behavior we can't fully prevent. It often gets cut off at **"Call"** when the toast appears.

## What to expect now

Both first and repeat untracks should behave more consistently:

1. You may still hear a **brief fragment** of **"Stop tracking …"** (VoiceOver confirming the double-tap — unavoidable with a standard `Button`)
2. Then **"Removed from watchlist"** from the toast
3. Then **Undo** after the pause

**"Favorite Image"** should be gone.

Please try again with Call the Midwife (including undo → untrack again). If you still hear a long star announcement before the toast, tell me which tab you're on and we can look at moving toast focus even earlier.

## User

It's saying "Star" now instead of "Favorite Image", only on the first invokation of the button.  Still says "Stop tracking Call" on subsquent invokations.

Is this possible?  Or should we put it back the way it was in the first place and move on?

Im on the watchlist screen.

## Assistant

Complete suppression isn't reliable with a standard SwiftUI `Button` — hiding it causes symbol leaks ("Favorite Image", "Star"); leaving it visible triggers the activation read ("Stop tracking Call…"). Reverting the VoiceOver-specific star hacks and keeping the image hidden inside the button (standard practice).

**Honest answer: reliably suppressing the star speech isn't worth pursuing.** I've reverted the VoiceOver-specific star hacks.

## Why this is so hard

VoiceOver **always reads the button on double-tap activation** — before our code runs. That happens with any standard SwiftUI `Button`.

Every workaround we tried made things worse:

| Approach | Result |
|----------|--------|
| Hide button from VO | Symbol leaks through ("Favorite Image", "Star") |
| Change label to "Undo removing…" | VO re-reads the new label |
| `UIAccessibility.post` announcement | Skipped the toast message entirely |
| Keep button visible | "Stop tracking Call…" (truncated when toast appears) |

The first vs. subsequent difference was timing luck — whether the button hid before or after VoiceOver started its activation read.

## What I reverted

- Hiding the star from VoiceOver during the undo window
- The "Undo removing…" pending label
- All the tap-time hide/focus tricks

## What I kept

- **Toast focus choreography** — status message first, then Undo (this worked)
- **Icon hidden inside the button** — prevents the star image from becoming a separate VO element (standard practice)
- **The whole outcome/refactor work** from earlier — unrelated to this

## Expected behavior now (Watchlist)

1. Double-tap star → **"Stop tracking Call the Midwife"** (may truncate when toast appears)
2. **"Removed from watchlist"** from the toast
3. Focus moves to **Undo**

For VoiceOver users, **Undo on the toast** is the intended path during the undo window. The star still works for second-tap undo visually, but the toast is the reliable VO affordance.

Moving on is the right call unless you want a larger change later (e.g. a custom rotor action like "Remove from watchlist" on the row, avoiding double-tap on the star entirely).

## User

Now that you mention it, once the toast is visible I can't activate the star button anymore.  I end up activating the whole row instead.

## Assistant

Investigating how the watchlist row and toast overlay interact with VoiceOver focus — the full-screen toast overlay may be blocking reachability of the star button.

Fixing two issues: the full-screen toast overlay is blocking the list behind it, and the star needs a correct label when a removal is pending.

Replacing the row's NavigationLink with a static label while removal is pending so double-tap doesn't open Show Detail instead of undo.

That matches what was going wrong — two separate issues:

## Cause

1. **The toast overlay was a full-screen trap** — the VoiceOver layout used a full-height `VStack` that blocked both touch and VoiceOver from reaching the list/star behind it.

2. **The row was still a `NavigationLink` during the undo window** — so double-tap on the row opened Show Detail (and cancelled the removal) instead of undoing. VoiceOver users naturally land on the big row target, not the small star.

## Fixes

**Toast overlay** — only the toast chrome is interactive and in the accessibility tree; the rest passes through to the list.

**Watchlist row while pending:**
- Row label is **not** a link (can't accidentally navigate away)
- **Rotor action: "Undo removal"** on the row
- Star is still there with label **"Undo removing … from watchlist"** and higher focus priority

## How to undo with VoiceOver (Watchlist)

1. **Toast → Undo** (primary — focus moves there after the status message)
2. **Swipe to the star** → double-tap (should be reachable again)
3. **Focus the row → rotor → "Undo removal"**

Please try on Watchlist with Call the Midwife. You should be able to reach the star again, and double-tapping the row should no longer push Show Detail during the undo window.

## User

That is all working except for one thing - when the row is no longer a navigation link the star jumps to the left, since it's not in the accessory position anymore.

## Assistant

Pinning the star to the trailing edge while pending by giving the row label the same full-width layout as the NavigationLink.

Fixed. The row label now expands to fill available width (`.frame(maxWidth: .infinity, alignment: .leading)`), so the star stays pinned on the right — same as when the row is a `NavigationLink`.

Please untrack a show and confirm the star no longer jumps left during the undo window.

## User

Ok, I think that's working ok now.

## Assistant

Good to hear.

Here's what we landed on:

- **Explicit pending-removal outcomes** — cleaner state flow without inferring from the repository
- **Show Detail push-only cancel** — tab switches commit reliably instead of accidentally cancelling
- **VoiceOver** — toast overlay passes through to the list; row isn't a link during the undo window; rotor **Undo removal** + toast **Undo**
- **Layout** — star stays trailing while pending

If anything else comes up around the undo flow, say the word.

## User

I asked ChatGPT to review what you've done and it wants one additional change:

Remove the duplicate onWatchlistChanged() notification from ShowDetailViewModel.handlePendingRemovalOutcome(). SearchView already handles committed/replaced pending-removal outcomes at the parent level, so Show Detail should only reconcile its own tracked state there. Preserve onWatchlistChanged() for direct add operations.

## Assistant

Removing the duplicate `onWatchlistChanged()` from Show Detail's pending-removal handler; Search already notifies on commit/replace.

Removing the unused `outcome` parameter since all cases now do the same thing.

Done. `ShowDetailViewModel.handlePendingRemovalOutcome()` now only reconciles the local star via `refreshTrackedState()` — it no longer calls `onWatchlistChanged()` on commit/replace.

**Still calls `onWatchlistChanged()`:** direct **add** in `handleTrackButton` (`.added` case).

**Watchlist tab updates on commit:** still handled by `WatchlistViewModel`'s outcome handler (when Detail is opened from Watchlist) and by `SearchView.handlePendingRemovalOutcome` (when opened from Search) — no duplicate notification from Detail anymore.

All unit tests pass.

