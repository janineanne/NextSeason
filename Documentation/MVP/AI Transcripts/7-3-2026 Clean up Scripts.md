# Performance suite script issue

## User

Scripts/resume-performance-suite.sh has a hardcoded reference to a specific directory under DerivedData, which seems wrong.  Is there some way to make that more generic or a script parameter?  Or should this script be removed?

## Assistant

Inspecting the script and how it's used in the project.

You're right to flag it — that hardcoded path is a smell, not something you'd want to keep long term.

## What the script does

`resume-performance-suite.sh` is a companion to `profile-performance-suite.sh`. If a full performance run is interrupted (network captures, stress loops, etc.), you pass it an existing session directory under `.instruments/<timestamp>/` and it skips flows already recorded in `manifest.json`, then finishes the rest and runs analysis.

That’s a real use case: the main suite can run for a long time, and re-running everything from scratch is expensive.

## What’s wrong today

Two values are hardcoded as defaults:

```9:10:Scripts/resume-performance-suite.sh
DEVICE="${DEVICE_UDID:-00008140-001178E92EF3001C}"
APP="${APP_PATH:-/Users/janine/Library/Developer/Xcode/DerivedData/NextSeason-edzsejwlkhbozadhjlqbhyrvklkf/Build/Products/Release-iphoneos/NextSeason.app}"
```

The DerivedData hash (`NextSeason-edzsejwlkhbozadhjlqbhyrvklkf`) is machine- and workspace-specific. It will break after a clean DerivedData wipe, a different clone path, or on another machine. The device UDID default has the same problem.

The main suite script already avoids this:

```42:51:Scripts/profile-performance-suite.sh
resolve_app_path() {
    local device="$1"
    xcodebuild \
        -project "${ROOT}/NextSeason.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -destination "id=${device}" \
        -showBuildSettings 2>/dev/null \
        | awk '/TARGET_BUILD_DIR =/ { dir=$3 } /FULL_PRODUCT_NAME =/ { name=$3 } END { print dir "/" name }'
}
```

It also auto-detects the connected device via `connected_device_udid()` instead of assuming a fixed UDID.

## Recommendation: keep it, fix the defaults

Don’t remove the script unless you’ve decided you’ll never resume interrupted runs. The resume path is documented and useful.

Make it generic the same way the main suite does:

1. **Environment overrides (keep):** `APP_PATH` and `DEVICE_UDID` for explicit control.
2. **Smart defaults (add):** if unset, auto-detect device and resolve the app with `xcodebuild -showBuildSettings`.
3. **Optional build step:** if the app isn’t found, either error with a clear message or honor `SKIP_BUILD=1` / run a build like the main script.
4. **Optional CLI arg:** `APP_PATH` as a second positional arg is nice but not required if resolution works.

A small shared lib (e.g. `Scripts/lib/performance-suite-common.sh`) with `connected_device_udid`, `resolve_app_path`, and maybe `build_app` would keep both scripts in sync and avoid copy-paste drift.

Usage would look like:

```bash
./Scripts/resume-performance-suite.sh .instruments/20260628-222731
# or override when needed:
APP_PATH=/path/to/NextSeason.app DEVICE_UDID=... ./Scripts/resume-performance-suite.sh ...
```

## When removal would make sense

Only if you’re dropping the resume workflow entirely — e.g. you always re-run `profile-performance-suite.sh` from scratch and never care about partial sessions. Given the suite’s length, that’s unlikely to be worth it.

---

**Bottom line:** the script is worth keeping; the hardcoded DerivedData path looks like a quick debug leftover from when a run was resumed mid-session. Align it with `profile-performance-suite.sh`’s resolution logic (and optionally extract shared helpers) rather than deleting it.

I can apply that refactor in a follow-up if you want.

## User

Yes, please apply the refactor

## Assistant

Extracting shared performance-suite helpers and updating both scripts to use dynamic app/device resolution.

Creating a shared lib and updating both performance suite scripts to use it.

Refactor is in place. Here’s what changed:

## Changes

**New `Scripts/lib/performance-suite-common.sh`**
Shared helpers used by both performance scripts:
- `connected_device_udid` — auto-detect a connected iPhone
- `resolve_app_path` — locate the app via `xcodebuild -showBuildSettings`
- `build_app` — build Release for the target device
- `resolve_performance_app` — honors `APP_PATH`, resolves dynamically, builds unless `SKIP_BUILD=1`
- `core_device_uuid` / `install_app_on_device` — unchanged from the main suite

**Updated `Scripts/profile-performance-suite.sh`**
Sources the shared lib and uses `resolve_performance_app` instead of inline build/resolve logic. Behavior is the same.

**Updated `Scripts/resume-performance-suite.sh`**
- Removed hardcoded DerivedData path and device UDID
- Auto-detects device and resolves app path (same as the main suite)
- Validates session directory and `manifest.json` exist
- Supports `DEVICE_UDID`, `APP_PATH`, and `SKIP_BUILD` env overrides
- Prints resolved device and app at startup

## Usage

```bash
./Scripts/resume-performance-suite.sh .instruments/20260628-222731

# Optional overrides:
APP_PATH=/path/to/NextSeason.app SKIP_BUILD=1 ./Scripts/resume-performance-suite.sh SESSION_DIR
DEVICE_UDID=... ./Scripts/resume-performance-suite.sh SESSION_DIR
```

## What to test

1. With a device connected and a Release build present, run resume against an existing `.instruments/<timestamp>/` session — it should print the resolved app path (not a fixed DerivedData hash).
2. With no build present, run without `SKIP_BUILD=1` — it should build, then continue.
3. With `APP_PATH` set explicitly, confirm that path is used instead of auto-resolution.

## User

Can you add a README.md to the Scripts folder and document each script? Mainly what it does and how to use it.

## Assistant

Reading all scripts in `Scripts` to document them accurately.

Creating `Scripts/README.md` documenting each script.

Added `Scripts/README.md` with documentation for every script in the folder.

It covers:

- **Prerequisites** and shared environment variables (`DEVICE_UDID`, `SKIP_BUILD`, `APP_PATH`, etc.)
- **Performance profiling** — `profile-performance-suite.sh`, `resume-performance-suite.sh`, `profile-flows.sh`, `run-profile-flows-uninstrumented.sh`, and both Python analyzers
- **Diagnostics** — `idle-soak-test.sh`, `verify-crash-reporting.sh`
- **Assets** — `render-icon-preview.swift`
- **Shared libs** — brief notes on `lib/performance-suite-common.sh` and `lib/device-log-capture.sh`

Each entry includes what the script does, example commands, relevant env vars, and where output is written. For `run-profile-flows-uninstrumented.sh`, the doc notes its hardcoded device/report defaults so you know to override them when needed.
