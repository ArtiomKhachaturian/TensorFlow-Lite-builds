#!/bin/bash
set -euo pipefail

MACHINE_ARCH="$(uname -m)"
if [[ "$MACHINE_ARCH" == "x86_64" ]]; then
  echo "[INFO] Detected Intel Mac (x86_64)"
  OSX_ARCH="x86_64"
elif [[ "$MACHINE_ARCH" == "arm64" ]]; then
  echo "[INFO] Detected Apple Silicon Mac (arm64)"
  OSX_ARCH="arm64"
else
  echo "[ERROR] Unknown macOS architecture: $MACHINE_ARCH"
  exit 1
fi

# Load shared functions
source "$(dirname "$0")/common.sh"

# ========= CONFIG =========
INSTALL_DIR="$SCRIPT_DIR/install_macos_$OSX_ARCH"
BUILD_DIR="$SCRIPT_DIR/build_macos_$OSX_ARCH"

clone_tensorflow_if_needed
prepare_build_dir $BUILD_DIR
cd "$BUILD_DIR"

echo "[INFO] Running CMake configuration..."
cmake -Wno-dev $TFLITE_SRC_DIR/tensorflow/lite \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DBUILD_SHARED_LIBS=ON \
  -DABSL_BUILD_MONOLITHIC_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_CONFIGURATION \
  -DTFLITE_ENABLE_XNNPACK=ON \
  -DTFLITE_ENABLE_GPU=ON \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DCMAKE_OSX_ARCHITECTURES="$OSX_ARCH" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="10.15" \
  -G Xcode

cd ..

# ========= BUILD & INSTALL =========
build_and_install "TensorFlow Lite MacOS" $BUILD_DIR
install_tensorflow_package dylib $INSTALL_DIR
