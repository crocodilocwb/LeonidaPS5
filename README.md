# LeonidaPS5

[![License](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](LICENSE)

LeonidaPS5 is an experimental, single-purpose build of the
[KytyPS5](https://github.com/KytyPS5/KytyPS5) PS5 translation layer. Its only goal is
running **Grand Theft Auto VI** (PPSA38500, v01.002) on Linux.

> [!WARNING]
> **This is not a general-purpose PS5 emulator.** Changes here target GTA VI only and may break
> other games. For any other title, use the upstream
> [KytyPS5](https://github.com/KytyPS5/KytyPS5) project. Please do not report LeonidaPS5 issues
> to the KytyPS5 developers.

This repository contains only the emulator's source code.

## Current Status

| Stage                    | Status                                              |
| ------------------------ | --------------------------------------------------- |
| Boot and loading         | Works                                               |
| Main menu                | Reached, interactive                                |
| After the main menu      | Loads into the world: the night sky and city lights render, most of the scene does not |

The first boot compiles every shader as the game asks for it, which makes loading very slow. The
game has a watchdog that terminates it when it stops responding for about 30 seconds, so it has to
be disabled with a `--game-patch` file (not included in this repository). Run with
`--shader-cache` so the compiled shaders and pipelines are kept and rebuilt in parallel on the next
boot.

Tested on Linux with an NVIDIA RTX 3060 (Vulkan 1.4).

## Changes from KytyPS5

Based on KytyPS5 commit
[`b3d8c04`](https://github.com/KytyPS5/KytyPS5/commit/b3d8c04844c89f6623e30044e33b570ba357b2f5)
(2026-11-26).

- **Missing imports:** `sceVideoOutSetGlobalBlendSpace`, `AgcAcbPrimeUtcl2`/`AgcDcbPrimeUtcl2`,
  `AgcDcbMemSemaphore`, the Atomic GDS size queries, the size query for
  `AmmCommandBufferAllocatePaForPrt`, and several `sceAgc*GetSize` functions.
- **Large descriptor tables:** scalar descriptor tables with up to 262,144 rows are scanned on the
  host, and the scan results are cached while the table contents stay the same.
- **Unknown shader patterns:** a shader whose resources cannot be tracked or materialized is
  skipped (logged as `SHADER DISPATCH SKIP`) instead of terminating the emulator. For a pixel
  shader, only that draw is dropped. Rendering may be incomplete when this happens.
- **Shader cache across rebuilds:** the `--shader-cache` store is keyed on a hash of the shader
  recompiler and pipeline cache sources, generated at build time, instead of the executable's
  timestamp. Rebuilds that do not touch those sources keep the stored shaders.
- **MONITORX/MWAITX:** the trapped `mwaitx` sleeps for 20 µs instead of yielding, so a guest
  spin-wait no longer keeps a host core fully busy.
- **Diagnostics:** the fatal fault report prints the readable part of the guest stack and the
  return addresses with the code around them; every skipped shader's guest code is written to
  `_Shaders/failed/`; `KYTY_LOG_THREADS=1` logs each guest thread's creation.
- **Oversized storage buffers:** buffers larger than the GPU's `maxStorageBufferRange` are clamped
  instead of terminating the emulator.
- **Repository:** the upstream CI/release workflows and issue templates were removed.

## Building (Linux)

Requires Clang, CMake, and Ninja. See the
[KytyPS5 build instructions](https://github.com/KytyPS5/KytyPS5#building-on-linux) for the full
list of system packages.

```bash
git submodule update --init --recursive

cmake -S . -B _Build/linux-no-qt -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DKYTY_BUILD_LAUNCHER=OFF

cmake --build _Build/linux-no-qt --target kyty_emulator --parallel
```

Only the Linux command-line build (`kyty_emulator`, no Qt launcher) is tested.

## Running

`--game` takes a folder that contains the game's `eboot.bin`, or a `.zar` archive. `.pkg` files are
not supported; extracting the package is up to you.

```bash
_Build/linux-no-qt/kyty_emulator --game /path/to/PPSA38500 --shader-cache --game-patch /path/to/patch.json
```

Default keyboard controls:

| PS5 control      | Key            |
| ---------------- | -------------- |
| Cross / Circle   | J / L          |
| Square / Triangle| K / I          |
| L1 / R1          | Q / E          |
| L2 / R2          | Z / C          |
| L3 / R3          | Left Shift / Left Ctrl |
| Options          | Enter          |
| D-pad            | Arrow keys     |
| Left stick       | W A S D        |
| Right stick      | T F G H        |

Run `kyty_emulator --help` for all options.

## License

LeonidaPS5 is licensed under the [GNU General Public License version 2](LICENSE)
(`GPL-2.0-only`), the same license as KytyPS5.

The files below were modified from KytyPS5 for LeonidaPS5 on 2026-11-26:

- `CMakeLists.txt`
- `README.md`
- `.gitignore`
- `src/graphics/host_gpu/renderer/pipeline/descriptors.cpp`
- `src/graphics/host_gpu/renderer/pipeline/pipelineCache.cpp`
- `src/graphics/host_gpu/renderer/pipeline/pipelineSerialization.cpp`
- `src/graphics/presentation/videoOut.cpp`, `videoOut.h`
- `src/graphics/shader/recompiler/ir/ShaderIR.h`
- `src/graphics/shader/recompiler/ir/passes/ResourceMaterialization.cpp`
- `src/graphics/shader/recompiler/ir/passes/ResourceTracking.cpp`
- `src/kernel/pthread.cpp`
- `src/libs/agc.cpp`, `agc.h`, `libAgcDriver.cpp`, `libAmpr.cpp`, `libVideoOut.cpp`
- `src/loader/runtimeLinker.cpp`, `x64InstructionEmulator.cpp`
- `src/shader_store_stamp.cmake` (new)

KytyPS5 is based on the original [Kyty](https://github.com/InoriRus/Kyty), which was released
under the MIT License. Kyty's original copyright and license notice are preserved in
[`LICENSES/Kyty-MIT.txt`](LICENSES/Kyty-MIT.txt). Third-party components remain subject to the
licenses included with those components.

## Credits

- [KytyPS5](https://github.com/KytyPS5/KytyPS5) and its contributors. Practically all of the
  emulator is their work, and LeonidaPS5 only adds GTA VI-specific changes on top.
- [InoriRus/Kyty](https://github.com/InoriRus/Kyty), the original project KytyPS5 is based on.
- [shadps4-emu/shadPS4](https://github.com/shadps4-emu/shadPS4), credited by KytyPS5 as a reference
  for PS4 memory behavior, GPU resource aliasing, cache coherency, and the AVPlayer implementation.
