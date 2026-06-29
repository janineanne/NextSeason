#!/usr/bin/env bash
#
# idle-soak-test.sh
# NextSeason
#
# Assists long idle crash reproduction on a connected device:
#   - streams unified logs for NextSeason diagnostics categories
#   - records instructions for 6+ hour soak scenarios
#   - optionally captures a log archive on exit (Ctrl+C)
#
# Usage:
#   ./Scripts/idle-soak-test.sh
#   DEVICE_UDID=00008140-001178E92EF3001C ./Scripts/idle-soak-test.sh
#   SOAK_HOURS=6 ./Scripts/idle-soak-test.sh
#
# Manual soak scenarios (run each as a separate session):
#   A. Search tab idle: launch app, stay on Search (idle state), 6+ hours
#   B. Wishlist tab idle: populate watchlist, stay on Watchlist, 6+ hours
#   C. Background cycle: foreground 30 min → background 30 min → repeat overnight
#   D. After background refresh: leave app backgrounded across a BGAppRefreshTask window (~12h)
#
# If memory rises during soak:
#   Xcode → Debug → Capture Memory Graph (while attached)
#   Instruments → Allocations / Leaks template on Release build
#
# If app crashes:
#   1. Reopen app (MetricKit + breadcrumbs capture prior session activity)
#   2. Settings → Diagnostics → Share Report
#   3. Xcode Organizer → Crashes (TestFlight/device builds)
#   4. This script saves logs to .soak-logs/ on exit

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${ROOT}/.soak-logs"
SUBSYSTEM="com.TrialByFyre.NextSeason"
SOAK_HOURS="${SOAK_HOURS:-6}"

connected_device_udid() {
    xcrun xctrace list devices 2>/dev/null | awk '
        /^== Devices ==$/ { in_devices=1; next }
        /^==/ { in_devices=0 }
        in_devices && /iPhone/ {
            if (match($0, /\(([0-9A-Fa-f-]+)\)[[:space:]]*$/)) {
                print substr($0, RSTART + 1, RLENGTH - 2)
                exit
            }
        }
    '
}

main() {
    local device="${DEVICE_UDID:-$(connected_device_udid)}"
    if [[ -z "${device}" ]]; then
        echo "error: no connected iPhone found. Plug in a device or set DEVICE_UDID." >&2
        exit 1
    fi

    mkdir -p "${OUTPUT_DIR}"
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    local log_file="${OUTPUT_DIR}/idle-soak-${stamp}.log"

    echo "NextSeason idle soak log capture"
    echo "Device: ${device}"
    echo "Target duration: ${SOAK_HOURS}+ hours (manual — keep device plugged in, screen on or allowed to lock per scenario)"
    echo "Log file: ${log_file}"
    echo
    echo "Soak checklist:"
    echo "  [ ] Launch Release or TestFlight build (not Debug, unless debugging attach)"
    echo "  [ ] Scenario A/B/C/D selected"
    echo "  [ ] Optional: populate watchlist before Wishlist soak"
    echo "  [ ] Device: Settings → Privacy → Analytics → Share With App Developers ON"
    echo
    echo "Streaming logs (Ctrl+C to stop and save archive)..."
    echo

    cleanup() {
        echo
        echo "Saving log archive..."
        local archive="${OUTPUT_DIR}/idle-soak-${stamp}.logarchive"
        if xcrun log collect --device-udid "${device}" --output "${archive}" 2>/dev/null; then
            echo "Saved: ${archive}"
            echo "Open with: log show \"${archive}\" --predicate 'subsystem == \"${SUBSYSTEM}\"'"
        else
            echo "log collect failed (may require sudo or device trust). Stream log preserved at ${log_file}"
        fi
    }
    trap cleanup EXIT INT TERM

    # Stream live; also tee to file for correlation with crash timestamps.
    xcrun log stream \
        --device-udid "${device}" \
        --style compact \
        --predicate "subsystem == \"${SUBSYSTEM}\" OR eventMessage CONTAINS \"NextSeason\"" \
        2>&1 | tee "${log_file}"
}

main "$@"
