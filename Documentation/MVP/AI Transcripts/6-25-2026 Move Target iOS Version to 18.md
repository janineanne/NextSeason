# iOS 18 support feasibility

## User

How hard would it be to make the app support iOS 18?

## Assistant

I'll scan the project for the deployment target and any APIs that require iOS 26 or newer.

Trying a build with deployment target overridden to iOS 18 to see if anything fails to compile.

Build succeeded. Running tests with the iOS 18 deployment target next.

**Short answer: it would be easy.** The iOS 26 requirement is mostly a project setting, not something the code depends on heavily.

## What the project does today

The deployment target is set to **iOS 26.5** in the Xcode project. That choice was documented from the start in `AGENTS.md` and `Architecture.md` as a deliberate greenfield target — not because the app uses a lot of iOS 26-only APIs.

The app is built with familiar modern SwiftUI patterns that land well before iOS 26:

| Feature | Minimum iOS |
|---|---|
| `@Observable`, `@Bindable`, SwiftData | 17+ |
| `@Attribute(.unique)` on `TrackedShowEntity` | **18+** |
| `NavigationStack`, `ContentUnavailableView`, `.searchable` | 16–17+ |
| Background refresh (`BGTaskScheduler`) | 13+ |

There are no `@available` checks, no iOS 26-only modifiers (glass effects, new Tab API, etc.), and no APIs that obviously require iOS 19+ or 26+.

## What I verified

I built the app with `IPHONEOS_DEPLOYMENT_TARGET=18.0` overridden — **BUILD SUCCEEDED**, and the built app reports `MinimumOSVersion = 18.0`. All **NextSeasonTests** unit tests passed with that setting.

So the code itself likely needs **no changes** to support iOS 18.

## What you’d actually need to do

1. **Change the deployment target** — update `IPHONEOS_DEPLOYMENT_TARGET` from `26.5` to `18.0` in `project.pbxproj` (project-level Debug and Release configs).
2. **Update docs** — `AGENTS.md`, `Architecture.md`, and any release-readiness notes that say “iOS 26+”.
3. **Test on iOS 18** — you don’t currently have an iOS 18 simulator runtime installed (only iOS 26.5). You’d want to download one in Xcode → Settings → Platforms and do a manual pass, especially around:
   - Nav-bar `.searchable` + keyboard dismiss behavior in `SearchView`
   - SwiftData persistence / duplicate prevention via `@Attribute(.unique)`
   - Notification permission flows
   - Visual polish (materials, list styling) on the older OS

That’s roughly **an hour of config + doc updates**, plus **a few hours of QA** if you want confidence before shipping.

## Floor: iOS 18, not 17

If you went lower than iOS 18, you’d hit a real constraint: `@Attribute(.unique)` on `tvMazeID` in `TrackedShowEntity` requires iOS 18. Supporting iOS 17 would mean replacing that with app-level duplicate checks or a different persistence approach — a small but real code change.

## Trade-offs to consider

**Pros of dropping to iOS 18:**
- Much wider App Store reach
- The codebase is already compatible

**Cons:**
- You take on an older-OS testing matrix
- Some UI may look or behave slightly differently (search bar, list backgrounds, materials)
- You’d be walking back an intentional “latest OS only” decision from project kickoff

## Bottom line

Supporting **iOS 18 is low effort** — essentially a deployment-target flip plus testing. The app was written for iOS 26 as a policy choice, not because it needs iOS 26 APIs. If your goal is portfolio reach or App Store distribution, iOS 18 is a reasonable and straightforward floor.

If you want, I can make the deployment-target change and update the docs in one pass.

## User

Yes, please do

## Assistant

I'll lower the deployment target to iOS 18 and update the project docs that still say iOS 26+.

Updating the deployment target and docs, then verifying the build.

Done. The minimum deployment target is now **iOS 18.0**.

### Changes

1. **`NextSeason.xcodeproj/project.pbxproj`** — `IPHONEOS_DEPLOYMENT_TARGET` changed from `26.5` to `18.0` (Debug and Release project configs).

2. **`AGENTS.md`** — Updated the target to iOS 18.0 or later.

3. **`Documentation/MVP/Architecture.md`** — Updated guiding principles and the SwiftData section to reflect iOS 18 as the floor (noting that `@Attribute(.unique)` requires iOS 18).

Historical AI transcripts were left unchanged.

### Verification

Build succeeded with the new deployment target. No code changes were required.

### What you should test

1. **Install an iOS 18 simulator** (Xcode → Settings → Platforms) — you don’t have one installed yet.
2. **Run the app on iOS 18** and spot-check:
   - Search + keyboard dismiss
   - Watchlist add/remove/undo
   - SwiftData persistence across relaunch
   - Notification permission prompts
3. **Run unit tests** (`NextSeasonTests`) — they passed in my earlier check with the iOS 18 target.
