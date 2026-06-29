#!/usr/bin/env bash
#
# run-profile-flows-uninstrumented.sh
# NextSeason
#
# Runs ProfileFlow on device without Instruments; pulls timing JSONL from app container.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.TrialByFyre.NextSeason"
DEVICE="${DEVICE_UDID:-00008140-001178E92EF3001C}"
CORE_DEVICE="${CORE_DEVICE:-438B438F-DEF0-5F41-870C-EA07B4E847EE}"
RUNS="${RUNS:-5}"
FLOWS="${FLOWS:-search,showDetails,addToWishlist}"
INSTRUMENTS_REPORT="${INSTRUMENTS_REPORT:-${ROOT}/.instruments/20260628-222731/report.json}"
TIMING_REMOTE="Documents/profile-flow-timing.jsonl"
STAMP="$(date +%Y%m%d-%H%M%S)"
SESSION="${ROOT}/.instruments/uninstrumented-${STAMP}"
LOG_DIR="${SESSION}/logs"

mkdir -p "${LOG_DIR}"

resolve_app_path() {
    xcodebuild \
        -project "${ROOT}/NextSeason.xcodeproj" \
        -scheme NextSeason \
        -configuration Release \
        -destination "id=${DEVICE}" \
        -showBuildSettings 2>/dev/null \
        | awk '/TARGET_BUILD_DIR =/ { dir=$3 } /FULL_PRODUCT_NAME =/ { name=$3 } END { print dir "/" name }'
}

pull_timings() {
    local dest="$1"
    xcrun devicectl device copy from \
        --device "${CORE_DEVICE}" \
        --domain-type appDataContainer \
        --domain-identifier "${BUNDLE_ID}" \
        --source "${TIMING_REMOTE}" \
        --destination "${dest}" \
        2>/dev/null || true
}

run_flow() {
    local flow="$1"
    local run="$2"
    local dest="${LOG_DIR}/${flow}-run${run}.jsonl"

    DEVICECTL_CHILD_PROFILE_FLOW="${flow}" \
        xcrun devicectl device process launch \
        --device "${CORE_DEVICE}" \
        --terminate-existing \
        "${BUNDLE_ID}" >/dev/null 2>&1 || true

    sleep 12
    pull_timings "${dest}"
}

main() {
    if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
        echo "Building Release..."
        xcodebuild \
            -project "${ROOT}/NextSeason.xcodeproj" \
            -scheme NextSeason \
            -configuration Release \
            -destination "id=${DEVICE}" \
            build >/dev/null
    fi

    local app
    app="$(resolve_app_path)"
    echo "Installing ${app}..."
    xcrun devicectl device install app --device "${CORE_DEVICE}" "${app}"

    echo "Session: ${SESSION}"
    echo "Flows: ${FLOWS} (${RUNS} runs, no Instruments)"
    echo

    IFS=',' read -ra FLOW_LIST <<< "${FLOWS}"
    for flow in "${FLOW_LIST[@]}"; do
        echo ">> ${flow}"
        for run in $(seq 1 "${RUNS}"); do
            echo -n "   run ${run}/${RUNS}... "
            run_flow "${flow}" "${run}"
            if [[ -s "${LOG_DIR}/${flow}-run${run}.jsonl" ]]; then
                echo "ok"
            else
                echo "no timing file"
            fi
        done
    done

    echo
    echo ">> Analyzing..."
    python3 "${ROOT}/Scripts/analyze-uninstrumented-logs.py" \
        --session "${SESSION}" \
        --instruments-report "${INSTRUMENTS_REPORT}" \
        --flows "${FLOWS}"
}

main "$@"
