#!/usr/bin/env bash
#
# verify-crash-reporting.sh
# NextSeason
#
# Verifies Release build settings required for symbolicated crash logs in
# Xcode Organizer (TestFlight and on-device builds).
#
# Usage: ./Scripts/verify-crash-reporting.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${ROOT}/NextSeason.xcodeproj"
SCHEME="NextSeason"

echo "Checking crash reporting prerequisites for ${SCHEME}..."
echo

read_project_release_setting() {
    local key="$1"
    awk -v key="${key}" '
        /Release.*= \{/ { in_release=1 }
        in_release && $0 ~ key " = " {
            sub(/.*= /, "")
            sub(/;/, "")
            gsub(/"/, "")
            print
            exit
        }
        in_release && /^\t\t\};/ { in_release=0 }
    ' "${PROJECT}/project.pbxproj"
}

read_build_setting() {
    local config="$1"
    local key="$2"
    xcodebuild \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -configuration "${config}" \
        -showBuildSettings 2>/dev/null \
        | awk -v key="${key}" '$1 == key "=" { print $3; exit }'
}

fail=0

check_setting() {
    local config="$1"
    local key="$2"
    local expected="$3"
    local actual
    actual="$(read_build_setting "${config}" "${key}")"
    if [[ -z "${actual}" && "${config}" == "Release" ]]; then
        actual="$(read_project_release_setting "${key}")"
    fi
    if [[ "${actual}" == "${expected}" ]]; then
        echo "  OK  ${config} ${key}=${actual}"
    else
        echo "  FAIL ${config} ${key}=${actual:-<unset>} (expected ${expected})" >&2
        fail=1
    fi
}

echo "Release target settings:"
check_setting "Release" "DEBUG_INFORMATION_FORMAT" "dwarf-with-dsym"
check_setting "Release" "COPY_PHASE_STRIP" "NO"

bundle_id="$(read_build_setting "Release" "PRODUCT_BUNDLE_IDENTIFIER")"
marketing_version="$(read_build_setting "Release" "MARKETING_VERSION")"
build_number="$(read_build_setting "Release" "CURRENT_PROJECT_VERSION")"

echo
echo "Bundle: ${bundle_id:-unknown}"
echo "Version: ${marketing_version:-?} (${build_number:-?})"
echo
echo "Organizer checklist (manual):"
echo "  1. Archive with Product → Archive (Release configuration)."
echo "  2. Distribute to TestFlight; dSYMs upload automatically with the build."
echo "  3. After a crash on a TestFlight/device build, open Xcode → Window → Organizer → Crashes."
echo "  4. Select the build version; crash reports appear once the device uploads diagnostics."
echo "  5. Enable Settings → Privacy & Security → Analytics & Improvements → Share With App Developers."
echo "  6. Filter Console logs: subsystem == \"${bundle_id:-com.TrialByFyre.NextSeason}\""
echo "  7. MetricKit crash summaries log on the launch AFTER a crash (category: crash)."
echo

if [[ "${fail}" -ne 0 ]]; then
    echo "One or more settings checks failed." >&2
    exit 1
fi

echo "All automated checks passed."
