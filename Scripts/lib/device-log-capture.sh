#!/usr/bin/env bash
#
# Shared device unified-log capture helpers for NextSeason scripts.
# Source this file; do not execute directly.
#
# macOS `log stream` does not support --device-udid on current releases.
# When streaming is unavailable, callers collect a recent window via `log collect`.

DEVICE_LOG_CMD="${DEVICE_LOG_CMD:-/usr/bin/log}"

device_log_stream_supports_device() {
    "${DEVICE_LOG_CMD}" help stream 2>&1 | grep -q -- '--device'
}

device_log_collect() {
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

    if "${DEVICE_LOG_CMD}" "${args[@]}" 2>/dev/null; then
        return 0
    fi

    if [[ "${USE_SUDO:-0}" == "1" ]] && sudo "${DEVICE_LOG_CMD}" "${args[@]}" 2>/dev/null; then
        return 0
    fi

    return 1
}

device_log_capture_to_file() {
    local udid="$1"
    local output_file="$2"
    local window="$3"
    local predicate="$4"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local archive="${tmp_dir}/device-capture.logarchive"

    if device_log_collect "${udid}" "${archive}" "${window}" "${predicate}"; then
        "${DEVICE_LOG_CMD}" show "${archive}" --style compact --info >> "${output_file}" 2>/dev/null || true
    fi

    rm -rf "${tmp_dir}"
}

_DEVICE_LOG_CAPTURE_UDID=""
_DEVICE_LOG_CAPTURE_FILE=""
_DEVICE_LOG_CAPTURE_PREDICATE=""
_DEVICE_LOG_CAPTURE_PID=""

# Begin capture for a bounded Instruments/trace run. Truncates the output file.
device_log_capture_begin() {
    local udid="$1"
    local output_file="$2"
    local predicate="$3"

    _DEVICE_LOG_CAPTURE_UDID="${udid}"
    _DEVICE_LOG_CAPTURE_FILE="${output_file}"
    _DEVICE_LOG_CAPTURE_PREDICATE="${predicate}"
    _DEVICE_LOG_CAPTURE_PID=""

    : > "${output_file}"

    if device_log_stream_supports_device; then
        "${DEVICE_LOG_CMD}" stream \
            --device-udid "${udid}" \
            --style compact \
            --predicate "${predicate}" \
            >> "${output_file}" 2>&1 &
        _DEVICE_LOG_CAPTURE_PID=$!
        echo "${_DEVICE_LOG_CAPTURE_PID}"
        return
    fi

    echo "capture"
}

# End capture started with device_log_capture_begin. Pass a window at least as long as the trace.
device_log_capture_end() {
    local window="${1:-2m}"

    if [[ -n "${_DEVICE_LOG_CAPTURE_PID}" ]] && kill -0 "${_DEVICE_LOG_CAPTURE_PID}" 2>/dev/null; then
        kill "${_DEVICE_LOG_CAPTURE_PID}" 2>/dev/null || true
        wait "${_DEVICE_LOG_CAPTURE_PID}" 2>/dev/null || true
        return
    fi

    if [[ -n "${_DEVICE_LOG_CAPTURE_UDID}" && -n "${_DEVICE_LOG_CAPTURE_FILE}" ]]; then
        device_log_capture_to_file \
            "${_DEVICE_LOG_CAPTURE_UDID}" \
            "${_DEVICE_LOG_CAPTURE_FILE}" \
            "${window}" \
            "${_DEVICE_LOG_CAPTURE_PREDICATE}"
    fi
}
