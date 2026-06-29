#!/usr/bin/env bash
#
# profile-performance-suite.sh
# NextSeason
#
# Full on-device Instruments performance battery:
#   - 5 runs per core flow (averaged in analyze-performance-traces.py)
#   - Memory / leaks / CPU / hangs / network / console capture
#   - Stress loops
#
# Usage:
#   ./Scripts/profile-performance-suite.sh
#   DEVICE_UDID=00008140-001178E92EF3001C RUNS=5 ./Scripts/profile-performance-suite.sh
#   SKIP_BUILD=1 ./Scripts/profile-performance-suite.sh
#
# Output: .instruments/<timestamp>/ (gitignored)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="NextSeason"
CONFIGURATION="Release"
DEVICE="${DEVICE_UDID:-}"
RUNS="${RUNS:-5}"
SUBSYSTEM="com.TrialByFyre.NextSeason"

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
    echo "Building ${SCHEME} (${CONFIGURATION}) for ${device}..."
    xcodebuild \
        -project "${ROOT}/NextSeason.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -destination "id=${device}" \
        build
}

install_app_on_device() {
    local app="$1"
    local device_core="${2:-}"
    echo "Installing app on device (required for Instruments attach permissions)..."
    if [[ -n "${device_core}" ]]; then
        xcrun devicectl device install app --device "${device_core}" "${app}"
    else
        xcrun devicectl device install app --device "${DEVICE}" "${app}" 2>/dev/null \
            || xcrun devicectl device install app "${app}"
    fi
}

core_device_uuid() {
    xcrun devicectl list devices 2>/dev/null | awk '
        /connected/ {
            for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) { print $i; exit }
        }
    '
}

start_log_stream() {
    local device="$1"
    local log_file="$2"
    xcrun log stream \
        --device-udid "${device}" \
        --style compact \
        --predicate "subsystem == \"${SUBSYSTEM}\" OR processImagePath CONTAINS \"NextSeason\"" \
        > "${log_file}" 2>&1 &
    echo $!
}

stop_log_stream() {
    local pid="$1"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        kill "${pid}" 2>/dev/null || true
        wait "${pid}" 2>/dev/null || true
    fi
}

record_trace() {
    local template="$1"
    local device="$2"
    local app="$3"
    local output="$4"
    local time_limit="$5"
    shift 5
    local -a extra_instruments=()
    local -a launch_args=()
    local parsing_launch=0

    for arg in "$@"; do
        if [[ "${arg}" == "--" ]]; then
            parsing_launch=1
            continue
        fi
        if [[ "${parsing_launch}" -eq 1 ]]; then
            launch_args+=("${arg}")
        else
            extra_instruments+=("${arg}")
        fi
    done

    local cmd=(xcrun xctrace record
        --template "${template}"
        --device "${device}"
        --output "${output}"
        --time-limit "${time_limit}"
        --no-prompt
    )
    if ((${#extra_instruments[@]} > 0)); then
        for inst in "${extra_instruments[@]}"; do
            [[ -n "${inst}" ]] && cmd+=(--instrument "${inst}")
        done
    fi
    cmd+=(--launch -- "${app}")
    if ((${#launch_args[@]})); then
        cmd+=("${launch_args[@]}")
    fi
    "${cmd[@]}"
}

record_launch() {
    local device="$1"
    local app="$2"
    local output="$3"
    local profile_flow="${4:-}"

    local cmd=(xcrun xctrace record
        --template "App Launch"
        --instrument "Allocations"
        --instrument "Activity Monitor"
        --device "${device}"
        --output "${output}"
        --time-limit "25s"
        --no-prompt
        --launch -- "${app}"
    )
    if [[ -n "${profile_flow}" ]]; then
        cmd+=(-ProfileFlow "${profile_flow}")
    fi
    "${cmd[@]}"
}

record_flow() {
    local flow="$1"
    local device="$2"
    local app="$3"
    local output="$4"
    local time_limit="${5:-30s}"

    record_trace "Time Profiler" "${device}" "${app}" "${output}" "${time_limit}" \
        "Allocations" "Leaks" "Activity Monitor" -- \
        -ProfileFlow "${flow}"
}

record_network() {
    local flow="$1"
    local device="$2"
    local app="$3"
    local output="$4"
    local har_output="$5"
    local time_limit="${6:-30s}"

    record_trace "Network" "${device}" "${app}" "${output}" "${time_limit}" -- \
        -ProfileFlow "${flow}"
    if [[ -f "${output}" ]]; then
        xcrun xctrace export --input "${output}" --har --output "${har_output}" 2>/dev/null || true
    fi
}

append_manifest() {
    local manifest="$1"
    local flow="$2"
    local trace_rel="$3"
    local log_rel="${4:-}"
    local har_rel="${5:-}"

    python3 - <<PY
import json
from pathlib import Path
p = Path("${manifest}")
data = json.loads(p.read_text()) if p.exists() else {"runs": []}
entry = {"flow": "${flow}", "trace": "${trace_rel}"}
if "${log_rel}":
    entry["log"] = "${log_rel}"
if "${har_rel}":
    entry["har"] = "${har_rel}"
data["runs"].append(entry)
p.write_text(json.dumps(data, indent=2))
PY
}

main() {
    DEVICE="${DEVICE:-$(connected_device_udid)}"
    if [[ -z "${DEVICE}" ]]; then
        echo "error: no connected iPhone. Set DEVICE_UDID or plug in a device." >&2
        exit 1
    fi

    STAMP="$(date +%Y%m%d-%H%M%S)"
    SESSION="${ROOT}/.instruments/${STAMP}"
    TRACE_DIR="${SESSION}/traces"
    LOG_DIR="${SESSION}/logs"
    HAR_DIR="${SESSION}/har"
    mkdir -p "${TRACE_DIR}" "${LOG_DIR}" "${HAR_DIR}"

    if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
        build_app "${DEVICE}"
    fi

    APP="$(resolve_app_path "${DEVICE}")"
    if [[ ! -d "${APP}" ]]; then
        echo "error: app not found at ${APP}" >&2
        exit 1
    fi

    CORE_DEVICE="$(core_device_uuid)"
    install_app_on_device "${APP}" "${CORE_DEVICE}"

    MANIFEST="${SESSION}/manifest.json"
    echo '{"runs": []}' > "${MANIFEST}"

    echo "=== NextSeason performance suite ==="
    echo "Device: ${DEVICE}"
    echo "App: ${APP}"
    echo "Session: ${SESSION}"
    echo "Runs per flow: ${RUNS}"
    echo

    # --- Seed watchlist once for launch-with-data ---
    echo ">> Setup: seed watchlist"
    LOG="${LOG_DIR}/seedWatchlist.log"
    LPID="$(start_log_stream "${DEVICE}" "${LOG}")"
    record_flow "seedWatchlist" "${DEVICE}" "${APP}" "${TRACE_DIR}/seedWatchlist.trace" "60s"
    stop_log_stream "${LPID}"
    append_manifest "${MANIFEST}" "seedWatchlist" "traces/seedWatchlist.trace" "logs/seedWatchlist.log"

    CORE_FLOWS=(
        "launch:cold"
        "launch-with-data:launchWithData"
        "search:search"
        "searchEmpty:searchEmpty"
        "showDetails:showDetails"
        "viewWishlist:viewWishlist"
        "addToWishlist:addToWishlist"
        "removeFromWishlist:removeFromWishlist"
    )

    for entry in "${CORE_FLOWS[@]}"; do
        flow_key="${entry%%:*}"
        profile_flow="${entry##*:}"
        echo ">> Flow: ${flow_key} (${RUNS} runs)"

        for run in $(seq 1 "${RUNS}"); do
            TRACE="${TRACE_DIR}/${flow_key}-run${run}.trace"
            LOG="${LOG_DIR}/${flow_key}-run${run}.log"
            LPID="$(start_log_stream "${DEVICE}" "${LOG}")"

            if [[ "${flow_key}" == "launch" || "${flow_key}" == "launch-with-data" ]]; then
                pf=""
                [[ "${flow_key}" == "launch-with-data" ]] && pf="${profile_flow}"
                record_launch "${DEVICE}" "${APP}" "${TRACE}" "${pf}"
            else
                record_flow "${profile_flow}" "${DEVICE}" "${APP}" "${TRACE}" "35s"
            fi

            stop_log_stream "${LPID}"
            append_manifest "${MANIFEST}" "${flow_key}" "traces/${flow_key}-run${run}.trace" "logs/${flow_key}-run${run}.log"
            echo "   run ${run}/${RUNS} done"
        done
    done

    # --- Network captures (one run each for network-heavy flows) ---
    echo ">> Network captures"
    for net_flow in search showDetails addToWishlist; do
        TRACE="${TRACE_DIR}/network-${net_flow}.trace"
        HAR="${HAR_DIR}/${net_flow}.har"
        LOG="${LOG_DIR}/network-${net_flow}.log"
        LPID="$(start_log_stream "${DEVICE}" "${LOG}")"
        record_network "${net_flow}" "${DEVICE}" "${APP}" "${TRACE}" "${HAR}" "35s"
        stop_log_stream "${LPID}"
        append_manifest "${MANIFEST}" "network-${net_flow}" "traces/network-${net_flow}.trace" "logs/network-${net_flow}.log" "har/${net_flow}.har"
    done

    # --- Stress loops ---
    echo ">> Stress loops"
    for stress in stressSearchDetailsBack stressAddRemoveWishlist stressSearchEmpty; do
        case "${stress}" in
            stressSearchDetailsBack) limit=200s ;;
            stressAddRemoveWishlist) limit=120s ;;
            stressSearchEmpty) limit=140s ;;
            *) limit=120s ;;
        esac
        TRACE="${TRACE_DIR}/${stress}.trace"
        LOG="${LOG_DIR}/${stress}.log"
        LPID="$(start_log_stream "${DEVICE}" "${LOG}")"
        record_flow "${stress}" "${DEVICE}" "${APP}" "${TRACE}" "${limit}"
        stop_log_stream "${LPID}"
        append_manifest "${MANIFEST}" "${stress}" "traces/${stress}.trace" "logs/${stress}.log"
    done

    # --- Launch with existing data: 10 cold launches ---
    echo ">> Stress: launch-with-data (10 launches)"
    for run in $(seq 1 10); do
        TRACE="${TRACE_DIR}/stress-launch-with-data-run${run}.trace"
        LOG="${LOG_DIR}/stress-launch-with-data-run${run}.log"
        LPID="$(start_log_stream "${DEVICE}" "${LOG}")"
        record_launch "${DEVICE}" "${APP}" "${TRACE}" "launchWithData"
        stop_log_stream "${LPID}"
        append_manifest "${MANIFEST}" "stress-launch-with-data" "traces/stress-launch-with-data-run${run}.trace" "logs/stress-launch-with-data-run${run}.log"
        echo "   launch ${run}/10 done"
    done

    echo
    echo ">> Analyzing traces..."
    python3 "${ROOT}/Scripts/analyze-performance-traces.py" "${SESSION}"

    echo
    echo "Done."
    echo "  Report: ${SESSION}/report.md"
    echo "  JSON:   ${SESSION}/report.json"
    echo "  Traces: ${TRACE_DIR}/"
}

main "$@"
