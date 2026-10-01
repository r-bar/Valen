#!/usr/bin/env bash
set -euo pipefail

# Build script for the Valen compiler
# Requires: nightly Rust, CMake, C++17 compiler, and the custom rustc's LLVM 21

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUSTC_DIR="/home/ryan/src/third_party/valen-lang/rust"
LLVM_CONFIG="$RUSTC_DIR/build/x86_64-unknown-linux-gnu/llvm/bin/llvm-config"

if [ ! -f "$LLVM_CONFIG" ]; then
  echo "ERROR: llvm-config not found at $LLVM_CONFIG. Build the custom rustc first."
  exit 1
fi

echo "Building Valen compiler using LLVM from custom rustc..."
echo "  LLVM version: $("$LLVM_CONFIG" --version)"
echo "  Rust toolchain: nightly"

cd "$PROJECT_DIR"
LLVM_CONFIG="$LLVM_CONFIG" cargo +nightly build --bin valec --release

echo ""
echo "Build complete! Binary: $PROJECT_DIR/target/release/valec"