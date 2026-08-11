# NextSeason Scripts

Shell and Python helpers for on-device profiling, crash diagnostics, and asset generation. Most scripts require a connected iPhone and a **Release** build of the app.

Output directories (`.instruments/`) are gitignored.

## Prerequisites

- macOS with Xcode and command-line tools
- iPhone connected via USB, unlocked, and trusted
- For performance scripts: Instruments permissions (the suite installs the app on device before recording)

## Common environment variables

| Variable | Used by | Description |
|---|---|---|
| `DEVICE_UDID` | Most device scripts | xctrace device UDID. Auto-detected when omitted (except where noted). |
| `SKIP_BUILD=1` | Build-aware scripts | Skip the Release build step; app must already exist. |
| `APP_PATH` | Performance suite scripts | Explicit path to `NextSeason.app` instead of auto-resolution. |
| `USE_SUDO=1` | Log capture scripts | Retry `log collect` with sudo if device log access fails. |

---

## Performance profiling

### `profile-performance-suite.sh`

Full on-device Instruments battery. Records multiple runs of core app flows, network captures, stress loops, and device console logs, then analyzes everything.

**What it does:**

- Builds and installs a Release build (unless `SKIP_BUILD=1`)
- Runs 5× each core flow: launch, launch-with-data, search, searchEmpty, showDetails, viewWishlist, addToWishlist, removeFromWishlist
- Records network traces for search, showDetails, and addToWishlist
- Runs stress loops (search/details/back, add/remove wishlist, empty search) and 10× launch-with-data
- Writes traces, logs, HAR files, and a manifest under `.instruments/<timestamp>/`
- Calls `analyze-performance-traces.py` to produce `report.md` and `report.json`

**Usage:**

```bash
./Scripts/profile-performance-suite.sh
DEVICE_UDID=... RUNS=5 ./Scripts/profile-performance-suite.sh
SKIP_BUILD=1 ./Scripts/profile-performance-suite.sh
```

**Output:** `.instruments/<timestamp>/` (traces in `traces/`, report at `report.md`)

---

### `resume-performance-suite.sh`

Resumes an interrupted performance suite session. Skips flows already recorded in the session's `manifest.json` or with existing trace files, then finishes network captures, stress loops, and analysis.

**Usage:**

```bash
./Scripts/resume-performance-suite.sh .instruments/20260628-222731
APP_PATH=/path/to/NextSeason.app SKIP_BUILD=1 ./Scripts/resume-performance-suite.sh SESSION_DIR
DEVICE_UDID=... ./Scripts/resume-performance-suite.sh SESSION_DIR
```

---

### `profile-flows.sh`

Lighter-weight Instruments profiling for individual flows. Records one trace per flow (not multiple runs) and writes them directly under `.instruments/`.

**What it does:**

- Cold launch trace
- Traces for searchEmpty, search, showDetails, viewWishlist, addToWishlist, removeFromWishlist
- Seeds the watchlist, then records launch-with-data
- Open traces in Instruments and inspect the **Points of Interest** track for flow signposts

**Usage:**

```bash
./Scripts/profile-flows.sh
DEVICE_UDID=... ./Scripts/profile-flows.sh
SKIP_BUILD=1 ./Scripts/profile-flows.sh
```

**Optional:** `LAUNCH_TIME_LIMIT`, `FLOW_TIME_LIMIT`, `SEED_TIME_LIMIT` (defaults: 20s, 25s, 45s)

**Output:** `.instruments/*.trace`

---

### `run-profile-flows-uninstrumented.sh`

Runs ProfileFlow automation on device **without** Instruments overhead. Pulls timing data from the app container and compares results against an Instruments report.

**What it does:**

- Builds and installs Release (unless `SKIP_BUILD=1`)
- Launches flows via `devicectl` with `DEVICECTL_CHILD_PROFILE_FLOW`
- Pulls `Documents/profile-flow-timing.jsonl` from the app container after each run
- Calls `analyze-uninstrumented-logs.py` to write a comparison report

**Usage:**

```bash
./Scripts/run-profile-flows-uninstrumented.sh
FLOWS=search,showDetails,addToWishlist RUNS=5 ./Scripts/run-profile-flows-uninstrumented.sh
INSTRUMENTS_REPORT=.instruments/<timestamp>/report.json ./Scripts/run-profile-flows-uninstrumented.sh
```

**Environment variables:**

| Variable | Default | Description |
|---|---|---|
| `DEVICE_UDID` | *(hardcoded fallback)* | xctrace destination for build resolution |
| `CORE_DEVICE` | *(hardcoded fallback)* | `devicectl` device UUID for install/launch |
| `RUNS` | `5` | Runs per flow |
| `FLOWS` | `search,showDetails,addToWishlist` | Comma-separated flow names |
| `INSTRUMENTS_REPORT` | `.instruments/20260628-222731/report.json` | Baseline Instruments report for comparison |

**Output:** `.instruments/uninstrumented-<timestamp>/` with `comparison.md` and `comparison.json`

---

### `analyze-performance-traces.py`

Parses `.trace` files from a performance suite session and emits aggregated metrics.

**What it does:**

- Reads `manifest.json` in the session directory
- Exports data from each trace via `xctrace export`
- Aggregates wall-clock time, memory, CPU, hangs, leaks, network, and console issues per flow
- Writes `report.json` and `report.md` with pass/fail/warn verdicts

**Usage:**

```bash
python3 Scripts/analyze-performance-traces.py .instruments/<timestamp>
```

Normally invoked automatically by `profile-performance-suite.sh` and `resume-performance-suite.sh`.

---

### `analyze-uninstrumented-logs.py`

Compares uninstrumented ProfileFlow timing logs against an Instruments baseline report.

**Usage:**

```bash
python3 Scripts/analyze-uninstrumented-logs.py \
  --session .instruments/uninstrumented-<timestamp> \
  --instruments-report .instruments/<timestamp>/report.json \
  --flows search,showDetails,addToWishlist
```

Normally invoked automatically by `run-profile-flows-uninstrumented.sh`.

---

## Compatibility index

### `generate-tvdb-tvmaze-compatibility-db.py`

Walks TVMaze’s paginated show index and regenerates the bundled
`NextSeason/Resources/Compatibility/tvdb_tvmaze_compatibility.sqlite` mapping
(TheTVDB id → TVMaze id).

**When to run:** manually before an App Store release (or whenever the catalog
should be refreshed in source control). Not hooked into normal Xcode builds.
Safe to invoke from future CI.

**Usage:**

```bash
./Scripts/generate-tvdb-tvmaze-compatibility-db.py
./Scripts/generate-tvdb-tvmaze-compatibility-db.py --output /tmp/out.sqlite
```

Respects TVMaze rate limits with polite pacing. The generated file is
TVMaze-derived (CC BY-SA); see `NextSeason/Resources/Compatibility/ATTRIBUTION.md`.

---

## Diagnostics

### `verify-crash-reporting.sh`

Checks Release build settings required for symbolicated crash logs in Xcode Organizer (TestFlight and on-device builds).

**What it does:**

- Verifies `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym` and `COPY_PHASE_STRIP=NO` for Release
- Prints bundle ID, version, and a manual Organizer checklist

**Usage:**

```bash
./Scripts/verify-crash-reporting.sh
```

Exits with code 1 if any automated check fails.

---

## Shared libraries (`lib/`)

These are sourced by other scripts, not run directly.

| File | Purpose |
|---|---|
| `lib/performance-suite-common.sh` | Device detection, app path resolution, build, and install helpers for performance scripts |
| `lib/device-log-capture.sh` | Unified device log capture during Instruments runs (stream or polled `log collect`) |
