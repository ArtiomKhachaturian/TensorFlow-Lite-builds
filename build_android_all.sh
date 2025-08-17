#!/bin/bash
set -euo pipefail

# Android NDK_PATH must be set with ndk > 23
if [[ -z "$NDK_PATH" ]]; then
    echo "❌ NDK_PATH is unknown, provide share via envoronment variable"
    exit 1
fi

# Load shared functions
source "$(dirname "$0")/common.sh"

# ========= CONFIG =========
ANDROID_PLATFORM=29
INSTALL_DIR_X64="$SCRIPT_DIR/install_android_x86_64"
INSTALL_DIR_ARM="$SCRIPT_DIR/install_android_arm64-v8a"
BUILD_DIR_X64="$SCRIPT_DIR/build_android_x86_64"
BUILD_DIR_ARM="$SCRIPT_DIR/build_android_arm64-v8a"
TFLITE_HOST_TOOLS_DIR=$(tflite_host_tools_dir)

# Check if it's a valid directory
if [ ! -d "$TFLITE_HOST_TOOLS_DIR" ]; then
  echo "❌ Error: '$TFLITE_HOST_TOOLS_DIR' is not a directory."
  exit 1
fi

function get_llvm_strip_tool() {
    if [[ "$OSTYPE" == "msys"* ]]; then
        echo "$NDK_PATH/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-strip.exe"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip"
    else
        echo "Unsupported operation system: $OSTYPE" >&2
        return 1
    fi
}

function build_tensorflow() {
    echo "[INFO] Running CMake configuration for TensorFlow Lite Android $2..."
    prepare_build_dir $1
    cd $1 # build_dir
    # https://developer.android.com/ndk/guides/cmake
    cmake  -Wno-dev $TFLITE_SRC_DIR/tensorflow/lite \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
      -DCMAKE_ANDROID_NDK=$NDK_PATH \
      -DANDROID_ABI=$2 \
      -DANDROID_STL=c++_shared \
      -DANDROID_PLATFORM=$ANDROID_PLATFORM \
      -DCMAKE_BUILD_TYPE=$BUILD_CONFIGURATION \
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -fvisibility=hidden -ffunction-sections -fdata-sections" \
      -DCMAKE_SHARED_LINKER_FLAGS_RELEASE="-Wl,--gc-sections -s" \
      -DCMAKE_CXX_FLAGS_RELEASE="-O3 -DNDEBUG -flto" \
      -DCMAKE_SHARED_LINKER_FLAGS_RELEASE="-flto" \
      -DTFLITE_ENABLE_XNNPACK=ON \
      -DTFLITE_ENABLE_GPU=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=$3 \
      -DTFLITE_HOST_TOOLS_DIR=$TFLITE_HOST_TOOLS_DIR \
      -DABSL_BUILD_MONOLITHIC_SHARED_LIBS=ON
      
    build_and_install "TensorFlow Lite Android $2" $1
    install_tensorflow_package so $3
      
    STRIP=$(get_llvm_strip_tool)
    for f in "$3/lib"/*.so; do
        if [ -f "$f" ]; then
            echo "Stripping $f"
            "$STRIP" --strip-unneeded "$f"
        fi
    done
    
    cd ..
}

clone_tensorflow_if_needed
build_tensorflow $BUILD_DIR_X64 x86_64 $INSTALL_DIR_X64
build_tensorflow $BUILD_DIR_ARM arm64-v8a $INSTALL_DIR_ARM

