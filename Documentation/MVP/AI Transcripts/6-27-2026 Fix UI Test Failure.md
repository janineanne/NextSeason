# UI test failure on find show button

## User

UI test testFindShowButtonNavigatesToSearch() is failing on the first XCTAssertTrue.   Can you fix please?

## User

Running testFindShowButtonNavigatesToSearch() Gets me a "Test Failed" but no other details, so I can't tell you why it failed.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NavigationUITests.swift"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NextSeasonUITestCase.swift"}
```

### Tool Run Terminal Command V2

## Assistant

The test passed here, so I'll check whether your branch is missing changes and add clearer failure messages so Xcode shows which step broke.

### Tool Run Terminal Command V2

### Tool Ripgrep Raw Search

```
{"pattern":"search\\.result","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_25fdc654-0147-4471-9122-0b24c076a68","offset":0}
```

### Tool Ripgrep Raw Search

```
{"pattern":"accessibilityIdentifier.*result","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","caseInsensitive":false,"multiline":false,"toolCallId":"tool_d7c9d0f8-b714-4d00-932f-39b9e1eecd4","offset":0}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Features/Search/SearchView.swift","offset":230,"limit":30}
```

## Assistant

The test passes here; bare `XCTAssertTrue` calls (no message) likely explain the vague "Test Failed". I'll add step labels, explicit failure messages, and attach a screenshot plus hierarchy on failure.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NextSeasonUITestCase.swift","/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NavigationUITests.swift"]}
```

### Tool Ripgrep Raw Search

```
{"pattern":"showDetailTrackButton","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests","caseInsensitive":false,"multiline":false,"toolCallId":"tool_3d60c4a1-17e3-456e-9f49-ad6dd1a0af1","offset":0}
```

## Assistant

Fixing parameter labels and cleaning up the failure path in `waitForSearchResultRow`.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NextSeasonUITestCase.swift","offset":175,"limit":40}
```

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

The test passes on my end after the latest changes. A bare **"Test Failed"** with no message usually means an assertion ran without a custom message, or Xcode isn't surfacing the report.

Here's what was going on and what to do:

### Why you might see no details
Several checks used plain `XCTAssertTrue(...)` with **no message** (including app launch in `setUp` and the "Find a Show" button wait). When those fail, Xcode often shows only **"XCTAssertTrue failed"** or just **"Test Failed"**.

### What I changed to help
1. **Named steps** via `XCTContext.runActivity` — the Report navigator will show which phase failed:
   - "Search for a show and open its detail"
   - "Switch to empty watchlist"
   - "Tap Find a Show and verify search root"

2. **Explicit failure messages** on every check in this test.

3. **Screenshot + accessibility hierarchy attachments** on failure — in the Report navigator, expand the failing test and look under **Attachments** for:
   - `Screenshot — …`
   - `Accessibility hierarchy — …`

4. **More reliable detail detection** — uses `showDetail.track.{id}` only, so it won't confuse the search-row star with the detail screen.

### Before re-running
This fix needs **both** targets rebuilt — the app adds `search.result.{id}` on search rows:

1. **Product → Clean Build Folder** (⇧⌘K)
2. Run the test again on the **Simulator** (not a physical device, unless you've set that up for UI tests)

### Where to look in Xcode when it fails
1. **Report navigator** (⌘9) → latest test run → expand `testFindShowButtonNavigatesToSearch`
2. Click the red failure line — you should see the full message (e.g. *"Search should return Severance (id: search.result.44933)…"*)
3. Check **Attachments** for the screenshot and hierarchy dump

If it still fails after a clean build, expand the failing activity step and tell me which one it is — the attachments should make the cause clear even if the inline message doesn't show.

## User

It still fails with "NextSeasonUITestCase.swift:310: Failed to failed to scroll to visible (by AX action) Key, {{348.0, 1067.0}, {51.7, 54.0}}, identifier: 'delete', label: 'delete', error: Error kAXErrorCannotComplete performing AXAction kAXScrollToVisibleAction on element AX element pid: 41943, elementOrHash.elementID: 4685618528.111. (Underlying Error: Error kAXErrorCannotComplete performing AXAction kAXScrollToVisibleAction on element AX element pid: 41943, elementOrHash.elementID: 4685618528.111)"

I don't know where to look for Attachments.

## Assistant

The failure is in search-field clearing when XCTest can't scroll the keyboard delete key into view. I'll inspect that helper and switch to a more reliable clear approach.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NextSeasonUITestCase.swift","offset":260}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeasonUITests/NavigationUITests.swift"}
```

## Assistant

The crash is from treating the search placeholder as real text and repeatedly tapping the delete key. I'll fix placeholder detection and replace keyboard delete taps with a safer clear method.

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

### Tool Run Terminal Command V2

## Assistant

That error pinpoints the problem: **`clearSearchField` was trying to tap the keyboard delete key repeatedly**, and XCTest couldn't scroll that key into view on your simulator.

There was a second issue: SwiftUI's `.searchable` field reports the placeholder **"Search TV shows"** as its `value` when empty. The test treated that as real text and tried to clear it — which triggered the delete-key loop on a field that was already empty.

### Fix
1. **`searchFieldText()`** — ignores placeholder/empty values so we don't clear unnecessarily.
2. **`clearSearchField()`** — uses the **Clear text** button, then **Select All + delete via `typeKey`**, and no longer taps `app.keys["delete"]` in a loop.

Re-run after a clean build (⇧⌘K). The test passes here with that change.

---

### Where to find Attachments in Xcode

1. Open the **Report navigator** — left sidebar, **clock icon**, or press **⌘9**.
2. Select the latest test run (top entry).
3. In the middle pane, expand **NextSeasonUITests** → **NavigationUITests** → **`testFindShowButtonNavigatesToSearch`**.
4. Select the **red failure line** (if there is one).
5. Open the **right inspector** (⌘⌥0 if hidden) — attachments appear in the **Test Report** / attachments area for that failure.

If you don't see attachments, they only get added when a failure goes through `recordFailureContext` (our custom `assertExists` / `assertNotExists` helpers). A crash in `clearSearchField` happened **before** that, which is why you didn't see them.

With the fix above, that delete-key crash should be gone. If anything else fails, the step name in the report (e.g. "Search for a show and open its detail") plus any attachments should make the cause clearer.

## User

That fixed it.  There's also a warning on line 53 of AnalyticsCounters:  "'let' pattern has no effect; sub-pattern didn't bind any variables" that needs to be fixed.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsCounters.swift"}
```

### Tool Ripgrep Raw Search

```
{"pattern":"themeSelected","path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason","caseInsensitive":false,"multiline":false,"toolCallId":"tool_9fd3ec36-0f0e-4731-bf86-18bf1a43cbf","offset":0}
```

## Assistant

Removing the unnecessary `let` on `.themeSelected` — the associated value isn't bound, so `let` has no effect.

### Tool Edit File V2

### Tool Read Lints

```
{"paths":["/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/Services/AnalyticsCounters.swift"]}
```

## Assistant

Removed the unnecessary `let` on line 53. `.themeSelected` carries an associated value, but since the counter doesn't use it, `case let .themeSelected:` didn't bind anything and triggered the warning. It's now `case .themeSelected:` like the other simple cases.

Rebuild and the warning should be gone.
