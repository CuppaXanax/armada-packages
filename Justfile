# armada-packages build orchestrator.
#
# Each package's build.sh produces its artifacts in <pkg>/out/ (most run in a
# fedora:44 podman container; kernel builds natively). `image` wraps those into
# the scratch carrier image armada bind-mounts at build time.
#
# Run on an aarch64 host — the kernel/mesa builds under x86 qemu emulation are
# unusably slow.

registry := env("REGISTRY", "localhost/armada-packages")
packages := "extest inputplumber fex mesa mangohud gamescope networkmanager jupiter-hw-support kernel"
rp5_tuned_packages := "fex mesa mangohud gamescope"

import? 'Justfile.local'

[private]
default:
    @just --list

# Build one package's artifacts into <pkg>/out/
[group('build')]
artifacts pkg:
    cd {{pkg}} && ./build.sh

# Build + wrap one package as {{registry}}/<pkg>:latest
[group('build')]
image pkg: (artifacts pkg)
    #!/usr/bin/env bash
    set -euo pipefail
    bash scripts/stage.sh {{pkg}}
    buildah build -f oci/Containerfile -t "{{registry}}/{{pkg}}:latest" .
    echo "==> {{registry}}/{{pkg}}:latest"

# Build one CPU-tuned runtime package for the SM8250 Cortex-A77/A55 baseline.
[group('rp5')]
rp5-artifacts pkg:
    #!/usr/bin/env bash
    set -euo pipefail
    case " {{rp5_tuned_packages}} " in
        *" {{pkg}} "*) ;;
        *) echo "RP5 CPU lane supports: {{rp5_tuned_packages}}" >&2; exit 2 ;;
    esac
    ARMADA_CPU_PROFILE=sm8250 just artifacts "{{pkg}}"

# Build + wrap one SM8250-tuned runtime package as {{registry}}/<pkg>:rp5-test.
[group('rp5')]
rp5-image pkg: (rp5-artifacts pkg)
    #!/usr/bin/env bash
    set -euo pipefail
    bash scripts/stage.sh "{{pkg}}"
    buildah build -f oci/Containerfile -t "{{registry}}/{{pkg}}:rp5-test" .
    echo "==> {{registry}}/{{pkg}}:rp5-test"

# Build artifacts for every package
[group('build')]
all:
    #!/usr/bin/env bash
    set -euo pipefail
    for p in {{packages}}; do just artifacts "$p"; done

# Build images for every package
[group('build')]
images:
    #!/usr/bin/env bash
    set -euo pipefail
    for p in {{packages}}; do just image "$p"; done

# Remove staging dir and all build outputs
[group('build')]
clean:
    rm -rf ctx */out
