# armada-packages

Upstream-derived packages for [armada](https://github.com/virtudude/armada), a
SteamOS-like Linux distribution for ARM handhelds. Each top-level directory is 
one component: a pinned upstream + `patches/` + a `build.sh`.

`build.sh` fetches the pinned upstream (`BASE.env`), applies `patches/`, and
builds. CI runs each into a `ghcr.io/virtudude/armada-packages/<component>`
image, path-triggered so bumping one doesn't rebuild the rest. armada pulls
those images at build time, pinned by digest.

`PATCHES.md` (per component) records where each patch came from.

## CPU profiles

The existing build baseline remains the default. For an SM8250 test build,
select the Cortex-A77/A55-safe profile explicitly:

```sh
just rp5-artifacts mesa
just rp5-image mesa
```

The RP5 recipes accept only packages that consume `ARMADA_MARCH`:

| Consumer | Use |
|---|---|
| `fex/build.sh` | Injects the flags into RPM C and C++ build flags. |
| `mesa/build.sh` | Injects the flags into RPM C and C++ build flags. |
| `mangohud/build.sh` | Injects the flags into RPM C and C++ build flags. |
| `gamescope/build.sh` | Injects the flags into RPM C and C++ build flags. |

`ARMADA_CPU_PROFILE=sm8250` resolves to
`-march=armv8.2-a+fp16+dotprod -mtune=cortex-a77`. It deliberately excludes
I8MM, which is newer than the Armv8.2-A Cortex-A77/A55 baseline. Verify the
resolved flags and compiler feature macros in the pinned builder with:

```sh
scripts/verify-cpu-profile.sh sm8250
```
