#!/bin/bash
set -euo pipefail

# Load shared functions
source "$(dirname "$0")/common.sh"

# ========= CONFIG =========
INSTALL_DIR_X64="$SCRIPT_DIR/install_ios_x86_64"
INSTALL_DIR_ARM="$SCRIPT_DIR/install_ios_arm64"
BUILD_DIR_X64="$SCRIPT_DIR/build_ios_x86_64"
BUILD_DIR_ARM="$SCRIPT_DIR/build_ios_arm64"
TFLITE_HOST_TOOLS_DIR=$(tflite_host_tools_dir)

# Check if it's a valid directory
if [ ! -d "$TFLITE_HOST_TOOLS_DIR" ]; then
  echo "❌ Error: '$TFLITE_HOST_TOOLS_DIR' is not a directory."
  exit 1
fi

function build_tensorflow() {
    prepare_build_dir $1
    cd $1 # build_dir
    echo "[INFO] Running CMake configuration for TensorFlow Lite iOS $2/$3..."
    cmake  -Wno-dev $TFLITE_SRC_DIR/tensorflow/lite \
      -DPLATFORM=$2 \
      -DCMAKE_SYSTEM_NAME=iOS \
      -DCMAKE_BUILD_TYPE=$BUILD_CONFIGURATION \
      -DCMAKE_MACOSX_BUNDLE=OFF \
      -DCMAKE_OSX_ARCHITECTURES=$3 \
      -DTFLITE_ENABLE_XNNPACK=ON \
      -DTFLITE_ENABLE_GPU=ON \
      -DTFLITE_ENABLE_METAL=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/toolchains/ios.toolchain.cmake \
      -DCMAKE_INSTALL_PREFIX=$4 \
      -DTFLITE_HOST_TOOLS_DIR=$TFLITE_HOST_TOOLS_DIR \
      -DABSL_BUILD_MONOLITHIC_SHARED_LIBS=ON \
      -G Xcode
      
      build_and_install "TensorFlow Lite iOS $2/$3" $1
      
      install_tensorflow_package dylib $4
      
      cd ..
}

clone_tensorflow_if_needed
build_tensorflow $BUILD_DIR_X64 SIMULATOR64 x86_64 $INSTALL_DIR_X64
build_tensorflow $BUILD_DIR_ARM OS64 arm64 $INSTALL_DIR_ARM

