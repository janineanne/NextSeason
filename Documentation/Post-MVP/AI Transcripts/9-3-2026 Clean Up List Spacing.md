# Section spacing issue

## User

I'm trying to eliminate the extra space between the end of the Waiting for a Date section and the start of the Ended section.  I can't see where it's coming from, and I don't see why there isn't one either before the first section or after the second section.

Can you fix this, please?

## Assistant

I'll inspect the watchlist layout and the SwiftUI skill first so I can find where that extra gap between sections is coming from.

The extra gap looks like List section spacing. I’ll check the list style, section headers, and your current watchlist diff to see what’s adding it.

The gap is almost certainly List inter-section spacing from `Section(isExpanded:)`. I’ll confirm that against the screenshot and how the headers are built.

The gap sits outside your debug borders, so it’s List section spacing rather than header or row padding. I’ll check collapse behavior and tests before applying the smallest fix.

The extra gap is List’s default inter-section spacing — it only appears between sections, which is why the first header and the last row look tight. I’ll zero that spacing and remove the debug borders.

The extra gap was not in your headers or rows — that’s why the red and white borders never captured it.

A plain `List` still applies **default inter-section spacing** between `Section`s. That spacing is only inserted *between* sections, which is why:

- the first header sits tight under **Watchlist**
- **Ended** has a large empty band above it
- the last row sits close to the TVMaze attribution

I set `.listSectionSpacing(0)` on the watchlist list so later headers use the same tight spacing as the first one. I also removed the debug borders.

Used: **swiftui-pro**

**What to test**
1. Open Watchlist with at least two sections (for example Waiting for a Date + Ended). The large empty band between them should be gone.
2. Collapse and expand a section — spacing should stay consistent.
3. Confirm the first header still sits close under the title, and the last row still sits close to the TVMaze attribution.

## User

Execute the selected diff-tab create-branch-and-commit action.

## Assistant

I'll create a `cursor/` branch from `main`, then commit only the watchlist spacing fix.

Only the watchlist spacing change is in the working tree. I'll create the branch and commit that file.

Created branch `cursor/watchlist-section-spacing` and committed the watchlist spacing fix.

**Commit:** `70a793a` — Remove extra List spacing between watchlist sections.

The working tree is clean. Nothing was pushed.

## User

The same user who reported this also thought that the section headers themselves were too tall.  They look better without the padding that's currently being applied to them, but that's going to make them a much skinnier tap target.  How short can they be?

## Assistant

I'll check the header layout and Apple's tap-target guidance so I can say how short they can go without becoming hard to hit.

Apple’s floor is **44pt tall**. That’s the HIG minimum for a tappable control, and it’s what this project already uses elsewhere (for example Show Detail). Going shorter than that for the *hit area* is what makes the headers feel hard to tap.

Visually, they can be much thinner than they are now. Right now the height is roughly:

- `.headline` text (about 22pt at default Dynamic Type)
- plus `.padding(.vertical, AppSpacing.tight)` — 8pt above and below
- plus the List’s own header insets

So most of the “too tall” look is padding, not the title.

The shortest they can *look* is the text itself (that ~22pt line at default size, taller if the user has a larger text size). The shortest they can *be as a tap target* is still 44pt.

Those don’t have to be the same measurement. You can drop the visible padding so the gray bar hugs the title, and keep a 44pt hit area with `frame(minHeight: 44)` and `contentShape(Rectangle())`. The header looks skinny; the tap target stays legal.

I would not go below that 44pt hit area. If you want, I can apply that “visually tight, still 44pt to tap” treatment next.

## User

Yes please

## Assistant

I'll drop the header’s vertical padding so the bar hugs the title, and expand the hit area to 44pt without making the header look taller again. Used: **swiftui-pro**.

The headers now hug the title. The 8pt vertical padding is gone, and the extra height is only an invisible hit area so they still meet the 44pt tap target.

At default Dynamic Type the bar is about **22pt** tall (the `.headline` line). About **11pt** of tap slop is added above and below without changing layout. At larger text sizes that slop shrinks, then goes away once the title itself is already 44pt.

**What to test**
1. Headers should look tighter — title and chevron with little extra chrome.
2. Tap slightly above or below the title; the section should still expand/collapse.
3. Try a larger Dynamic Type size and confirm the header grows with the text.
4. Scroll until a header pins. A bit more of the row may show around the skinnier bar.

