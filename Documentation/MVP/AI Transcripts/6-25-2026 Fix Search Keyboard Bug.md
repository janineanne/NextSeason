# Search field focus issue

## User

Remember all that work we did getting the keyboard to dismiss when it should?  Well, it turns out that doesn't work so well on a real device. Every time there's a long enough pause it the user's typing to kick off a search, the search field looses focus and the keyboard goes away.  The user has to tap in the search field again to get it back.

This must be a very common problem - what is the standard/usual solution?

## Assistant

This is a classic SwiftUI search + debounce focus issue. I'll inspect how search and keyboard dismissal are wired in your project so we can pinpoint what's stealing focus on device.

Checking the prior implementation and any related docs for full context.

The behavior you’re seeing isn’t a mysterious device-only SwiftUI bug — it’s coming from the auto-dismiss we added after each debounced search finishes.

## What’s causing it

In `SearchView`, every time the debounced search completes, the keyboard is explicitly dismissed:

```64:67:NextSeason/Features/Search/SearchView.swift
				.task(id: viewModel.query) {
					await viewModel.search()
					collapseSearchKeyboardIfSearchFinished()
				}
```

```118:126:NextSeason/Features/Search/SearchView.swift
	/// After a live search completes, tuck the keyboard so results are easier to read.
	private func collapseSearchKeyboardIfSearchFinished() {
		switch viewModel.state {
		case .results, .empty, .failed:
			collapseSearchKeyboard()
		case .idle, .loading:
			break
		}
	}
```

Flow on device:

1. User types and pauses (~300ms debounce).
2. Search runs and results arrive.
3. `collapseSearchKeyboardIfSearchFinished()` runs.
4. Keyboard goes away while they may still be editing the query.

That matches “every time there’s a long enough pause to kick off a search.” Simulator timing can make this feel less annoying than on a real device.

We actually flagged this in the earlier polish pass: auto-dismiss on results conflicts with live search, where people often keep typing to refine the query.

## The standard pattern for live search

For type-as-you-go search (App Store, Settings, Mail, etc.), the usual approach is:

**Keep the keyboard open while the user is searching.** Only dismiss on explicit user actions:

| Trigger | Dismiss? |
|---|---|
| User scrolls the results list | Yes — `.scrollDismissesKeyboard(.interactively)` on the `List` |
| User taps Search/Return on the keyboard | Yes — `.onSubmit(of: .search)` |
| User navigates to a result | Yes — navigation naturally ends editing |
| Search results load | **No** |
| Debounce fires | **No** |

So the fix is mostly **removing** the “dismiss when results arrive” behavior, not adding more focus management.

You already have the right pieces for the standard pattern:

- `.onSubmit(of: .search)` → dismiss on Search key (keep this)
- Scroll gesture + `.scrollDismissesKeyboard(.immediately)` on lists → dismiss when scrolling (keep this)
- **Remove** `collapseSearchKeyboardIfSearchFinished()` from the `.task(id: query)` block

## What people usually avoid

- **`@FocusState` gymnastics** — rarely needed for `.searchable`; the system owns focus.
- **Auto-dismiss after every API response** — works for “search on submit” flows, not live search.
- **`isPresented: false` on `.searchable`** — collapses the search UI and can clear the query; your `resignFirstResponder` approach is better when you do need to dismiss without losing text.

## Optional refinement

If scroll-to-dismiss still feels weak with nav-bar `.searchable` (a known quirk), the scroll drag gesture fallback you added is a reasonable supplement — but it should only run on user scroll, not after every network response.

---

**Bottom line:** For live search, keyboard dismissal should be user-driven (scroll or Search key), not tied to “results loaded.” Removing the post-search auto-dismiss should fix the real-device issue.

Want me to make that change and drop `collapseSearchKeyboardIfSearchFinished()`?

## User

Yes

## Assistant

Removing auto-dismiss after search completes; keeping dismiss on Search key and scroll.

Removed auto-dismiss after search results load. The keyboard now stays up while you type and refine a query.

**What changed**
- Removed the `collapseSearchKeyboardIfSearchFinished()` call from `.task(id: viewModel.query)`
- Deleted that helper entirely

**What still dismisses the keyboard**
- Tapping **Search** on the keyboard (`.onSubmit(of: .search)`)
- Scrolling the results/loading list (scroll gesture + `.scrollDismissesKeyboard`)

**What to test on device**
1. Type a query with pauses — keyboard should stay up as results update
2. Keep typing to refine — no re-tap needed
3. Scroll the results list — keyboard should dismiss
4. Tap Search on the keyboard — keyboard should dismiss
