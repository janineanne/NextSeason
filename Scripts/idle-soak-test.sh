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
#   POLL_INTERVAL_SECONDS=30 POLL_WINDOW=2m ./Scripts/idle-soak-test.sh
#
# Note: macOS `log stream` does not support --device-udid (only `log collect` does).
# This script polls recent device logs via `log collect --last` instead.
#
# Manual soak scenarios (run each as a separate session):
#   A. Search tab idle: launch app, stay on Search (idle state), 6+ hours
#   B. Wishlist tab idle: populate watchlist, stay on Watchlist, 6+ hours
#   C. Background cycle: foreground 30 min → background 30 min → repeat overnight
#   D. After background refresh: leave app backgrounded across a BGAppRefreshTask window
#      (accelerated soak test: every 10m when BackgroundRefreshConfiguration.forceAcceleratedForSoakTest is true)
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
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-30}"
POLL_WINDOW="${POLL_WINDOW:-2m}"
LOG="/usr/bin/log"

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

log_stream_supports_device() {
    "${LOG}" help stream 2>&1 | grep -q -- '--device'
}

collect_device_logs() {
    local udid="$1"
    local output_path="$2"
    local window="$3"
    local predicate="$4"

    local -a args=(
        collect
        --device-udid "${udid}"
        --last "${window}"
        --output "${output_path}"
        --predicate "${predicate}"
    )

    if "${LOG}" "${args[@]}" 2>/dev/null; then
        return 0
    fi

    if [[ "${USE_SUDO:-0}" == "1" ]] && sudo "${LOG}" "${args[@]}" 2>/dev/null; then
        return 0
    fi

    return 1
}

poll_device_logs() {
    local udid="$1"
    local session_stamp="$2"
    local predicate="subsystem == \"${SUBSYSTEM}\" OR eventMessage CONTAINS \"NextSeason\""
    local poll_archive="${OUTPUT_DIR}/.poll-${session_stamp}.logarchive"

    echo "Using polled device logs (--last ${POLL_WINDOW} every ${POLL_INTERVAL_SECONDS}s)."
    echo "(\`log stream --device-udid\` is not available on this macOS version.)"
    if [[ "${USE_SUDO:-0}" != "1" ]]; then
        echo "If collection fails, retry with: USE_SUDO=1 $0"
    fi
    echo

    while true; do
        rm -rf "${poll_archive}"
        if collect_device_logs "${udid}" "${poll_archive}" "${POLL_WINDOW}" "${predicate}"; then
            "${LOG}" show "${poll_archive}" --style compact --info 2>/dev/null || true
        else
            echo "[$(date "+%Y-%m-%dT%H:%M:%S")] log collect failed (unlock device, trust Mac, or USE_SUDO=1)" >&2
        fi
        sleep "${POLL_INTERVAL_SECONDS}"
    done
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
    echo "Capturing device logs (Ctrl+C to stop and save archive)..."
    echo

    cleanup() {
        echo
        echo "Saving log archive..."
        local archive="${OUTPUT_DIR}/idle-soak-${stamp}.logarchive"
        local predicate="subsystem == \"${SUBSYSTEM}\" OR eventMessage CONTAINS \"NextSeason\""
        if collect_device_logs "${device}" "${archive}" "1h" "${predicate}"; then
            echo "Saved: ${archive}"
            echo "Open with: log show \"${archive}\" --predicate 'subsystem == \"${SUBSYSTEM}\"'"
        else
            echo "log collect failed (unlock device, trust Mac, or USE_SUDO=1). Poll log preserved at ${log_file}"
        fi
        rm -rf "${OUTPUT_DIR}/.poll-${stamp}.logarchive"
    }
    trap cleanup EXIT INT TERM

    if log_stream_supports_device; then
        # Future macOS builds may restore device streaming; keep the fast path when available.
        "${LOG}" stream \
            --device-udid "${device}" \
            --style compact \
            --predicate "subsystem == \"${SUBSYSTEM}\" OR eventMessage CONTAINS \"NextSeason\"" \
            2>&1 | tee "${log_file}"
    else
        poll_device_logs "${device}" "${stamp}" 2>&1 | tee "${log_file}"
    fi
}

main "$@"
