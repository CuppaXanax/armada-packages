#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

profile="${1:-sm8250}"
ARMADA_CPU_PROFILE="${profile}" source ./toolchain.env

printf 'ARMADA_CPU_PROFILE=%s\n' "${profile}"
printf 'ARMADA_MARCH=%s\n' "${ARMADA_MARCH}"

podman run --rm --platform linux/aarch64 \
    -e ARMADA_MARCH="${ARMADA_MARCH}" \
    -v "${PWD}/scripts:/armada-scripts:ro,Z" \
    "${BUILDER_IMAGE}" bash /armada-scripts/verify-cpu-profile-container.sh