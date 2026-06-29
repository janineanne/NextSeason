#!/usr/bin/env bash
#
# profile-flows.sh
# NextSeason
#
# Records Release-build Instruments traces on a connected iPhone for:
#   launch, searchEmpty, search, showDetails, viewWishlist, addToWishlist,
#   removeFromWishlist, launch-with-data (after seedWatchlist setup)
#
# Usage:
#   ./Scripts/profile-flows.sh
#   DEVICE_UDID=00008140-001178E92EF3001C ./Scripts/profile-flows.sh
#   SKIP_BUILD=1 ./Scripts/profile-flows.sh
#
# Output traces are written to .instruments/*.trace (gitignored).
# Open in Instruments and inspect the Points of Interest track for flow intervals.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="NextSeason"
CONFIGURATION="Release"
OUTPUT_DIR="${ROOT}/.instruments"
LAUNCH_TIME_LIMIT="${LAUNCH_TIME_LIMIT:-20s}"
FLOW_TIME_LIMIT="${FLOW_TIME_LIMIT:-25s}"
SEED_TIME_LIMIT="${SEED_TIME_LIMIT:-45s}"

usage() {
    sed -n '2,16p' "$0" | tr -d '#'
}

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

build_app() {
    local device="$1"
    echo "Building ${SCHEME} (${CONFIGURATION}) for device ${device}..."
    xcodebuild \
        -project "${ROOT}/NextSeason.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -destination "id=${device}" \
        build
}

profile_launch() {
    local device="$1"
    local app="$2"
    local output="$3"

    echo "Profiling launch -> ${output}"
    xcrun xctrace record \
        --template "App Launch" \
        --device "${device}" \
        --output "${output}" \
        --time-limit "${LAUNCH_TIME_LIMIT}" \
        --no-prompt \
        --launch -- "${app}"
}

profile_flow() {
    local flow="$1"
    local device="$2"
    local app="$3"
    local output="${OUTPUT_DIR}/${flow}.trace"
    local time_limit="${4:-${FLOW_TIME_LIMIT}}"

    echo "Profiling ${flow} -> ${output}"
    xcrun xctrace record \
        --template "Time Profiler" \
        --device "${device}" \
        --output "${output}" \
        --time-limit "${time_limit}" \
        --no-prompt \
        --launch -- "${app}" -ProfileFlow "${flow}"
}

seed_watchlist() {
    local device="$1"
    local app="$2"

    echo "Seeding watchlist (setup for launch-with-data)..."
    profile_flow "seedWatchlist" "${device}" "${app}" "${SEED_TIME_LIMIT}"
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    local device="${DEVICE_UDID:-$(connected_device_udid)}"
    if [[ -z "${device}" ]]; then
        echo "error: no connected iPhone found. Plug in a device or set DEVICE_UDID." >&2
        exit 1
    fi

    mkdir -p "${OUTPUT_DIR}"

    if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
        build_app "${device}"
    fi

    local app
    app="$(resolve_app_path "${device}")"
    if [[ ! -d "${app}" ]]; then
        echo "error: app not found at ${app}. Build first or unset SKIP_BUILD." >&2
        exit 1
    fi

    echo "Device: ${device}"
    echo "App: ${app}"
    echo "Traces: ${OUTPUT_DIR}"
    echo

    # Clean cold launch before any watchlist seeding or mutations.
    profile_launch "${device}" "${app}" "${OUTPUT_DIR}/launch.trace"

    local flow
    for flow in searchEmpty search showDetails viewWishlist addToWishlist removeFromWishlist; do
        profile_flow "${flow}" "${device}" "${app}"
    done

    seed_watchlist "${device}" "${app}"
    profile_launch "${device}" "${app}" "${OUTPUT_DIR}/launch-with-data.trace"

    echo
    echo "Done. Open traces in Instruments:"
    echo "  open \"${OUTPUT_DIR}/launch.trace\""
    echo "  open \"${OUTPUT_DIR}/launch-with-data.trace\""
    echo "Flow signposts appear under Points of Interest (flow.*, search.empty, etc.)."
}

main "$@"
