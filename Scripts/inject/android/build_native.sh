#!/bin/bash
# Build libinject.so for ARM64 using Android NDK
# Usage: ./build_native.sh [path_to_ndk]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NDK="${1:-$ANDROID_NDK_HOME}"

if [ -z "$NDK" ] || [ ! -d "$NDK" ]; then
    echo "ERROR: Set ANDROID_NDK_HOME or pass NDK path as argument"
    exit 1
fi

BUILD_DIR="$SCRIPT_DIR/native/build_arm64"
mkdir -p "$BUILD_DIR"

cmake -S "$SCRIPT_DIR/native" -B "$BUILD_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja

cmake --build "$BUILD_DIR" --config Release

if [ -f "$BUILD_DIR/libinject.so" ]; then
    echo ""
    echo "SUCCESS: $BUILD_DIR/libinject.so"
    ls -la "$BUILD_DIR/libinject.so"
else
    echo "FAILED: libinject.so not found"
    exit 1
fi
