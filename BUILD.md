# Building Valen

## Prerequisites

- **Nightly Rust** (the project uses `#![feature(...)]` attributes)
  - `rustup toolchain install nightly`
- **Custom rustc** at `/home/ryan/src/third_party/valen-lang/rust/` (LLVM 21.1.8-rust, built with `BUILD_SHARED_LIBS=OFF`)
- **CMake** and a **C++17 compiler** (for the C++ LLVM backend)

## Quick start

```bash
./build_valen.sh
```

## Ad-hoc build command

```bash
LLVM_CONFIG=/home/ryan/src/third_party/valen-lang/rust/build/x86_64-unknown-linux-gnu/llvm/bin/llvm-config \
  cargo +nightly build --bin valec --release
```

## Output

The binary is at `target/release/valec` (~78 MB). It is statically linked with LLVM and has no runtime LLVM dependency.

## Changes from upstream

Two modifications were needed to compile on recent nightly (2026-09-24, rustc 1.100.0-nightly):

1. **`src/lib.rs`** — Removed `#![feature(box_patterns)]`. The feature was removed from nightly and was unused in the codebase.

2. **`build.rs`** — The LLVM linking logic now detects whether LLVM was built in shared or static mode (via `llvm-config --shared-mode`). The custom rustc's LLVM uses static libraries only, so the build script links `static` LLVM libs instead of `dylib` and omits the `-Wl,-rpath` flag.

## Build script

`build_valen.sh` at the project root wraps the full build command with the correct `LLVM_CONFIG` path.