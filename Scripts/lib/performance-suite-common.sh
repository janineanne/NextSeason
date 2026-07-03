# Shared helpers for on-device Instruments performance scripts.
# Expects ROOT to be set by the caller before sourcing.

SCHEME="${SCHEME:-NextSeason}"
CONFIGURATION="${CONFIGURATION:-Release}"

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

core_device_uuid() {
    xcrun devicectl list devices 2>/dev/null | awk '
        /connected/ {
            for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) { print $i; exit }
        }
    '
}

install_app_on_device() {
    local app="$1"
    local device_core="${2:-}"
    local device_udid="${3:-${DEVICE:-}}"
    echo "Installing app on device (required for Instruments attach permissions)..."
    if [[ -n "${device_core}" ]]; then
        xcrun devicectl device install app --device "${device_core}" "${app}"
    else
        xcrun devicectl device install app --device "${device_udid}" "${app}" 2>/dev/null \
            || xcrun devicectl device install app "${app}"
    fi
}

resolve_performance_app() {
    local device="$1"
    local app=""

    if [[ -n "${APP_PATH:-}" ]]; then
        echo "${APP_PATH}"
        return
    fi

    app="$(resolve_app_path "${device}")"
    if [[ -d "${app}" ]]; then
        echo "${app}"
        return
    fi

    if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
        build_app "${device}"
        app="$(resolve_app_path "${device}")"
    fi

    echo "${app}"
}
