#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

INITIAL_COPYRIGHT_YEAR=2023

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
	echo "Unable to find helper script at ${HELPER}"
	exit 1
fi
source "${HELPER}"

function vendor_imports() {
	cat <<EOF >>"$1"
		"device/xiaomi/mt6833-common",
                "device/xiaomi/everpal",
                "vendor/xiaomi/everpal",
		"hardware/mediatek",
		"hardware/mediatek/libmtkperf_client",
		"hardware/xiaomi"
EOF
}

function lib_to_package_fixup_vendor_variants() {
    if [ "$2" != "vendor" ]; then
        return 1
    fi

    case "$1" in
        vendor.mediatek.hardware.videotelephony@1.0)
            echo "${1}_vendor"
            ;;
        *)
            return 1
            ;;
    esac
}

function lib_to_package_fixup() {
    lib_to_package_fixup_clang_rt_ubsan_standalone "$1" ||
        lib_to_package_fixup_proto_3_9_1 "$1" ||
        lib_to_package_fixup_vendor_variants "$@"
}

# Initialize the helper for common
setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true

# Warning headers and guards
write_headers "camellia everpal light"

# The standard common blobs
write_makefiles "${MY_DIR}/proprietary-files.txt" true

# Finish
write_footers

if [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
	# Reinitialize the helper for device
	setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false

	# Warning headers and guards
	write_headers

	# The standard device blobs
	write_makefiles "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" true

	# Finish
	write_footers
fi
