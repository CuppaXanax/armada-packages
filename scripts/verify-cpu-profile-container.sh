#!/usr/bin/env bash
set -euo pipefail

dnf -y install gcc
printf 'compiler='
gcc --version | head -1
printf 'compiler_command:\n'
printf 'int profile_probe;\n' | gcc ${ARMADA_MARCH} -### -x c -c -o /tmp/profile-probe.o - 2>&1
printf 'feature_macros:\n'
macros=$(printf '\n' | gcc ${ARMADA_MARCH} -dM -E -x c -)
printf '%s\n' "${macros}" | grep -E '__ARM_ARCH|__ARM_FEATURE_(DOTPROD|FP16|MATMUL_INT8)' | sort
printf '%s\n' "${macros}" | grep -q '__ARM_FEATURE_DOTPROD'
if printf '%s\n' "${macros}" | grep -q '__ARM_FEATURE_MATMUL_INT8'; then
    echo 'ERROR: selected profile enables I8MM' >&2
    exit 1
fi
echo 'i8mm=absent'