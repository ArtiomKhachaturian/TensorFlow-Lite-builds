#!/bin/bash

BUILD_CONFIGURATION=Release
TENSORFLOW="tensorflow"
TFLITE_VERSION="v2.19.0"
TFLITE_REPO="https://github.com/tensorflow/$TENSORFLOW.git"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TFLITE_SRC_DIR=$SCRIPT_DIR/$TENSORFLOW

function clone_tensorflow_if_needed() {
  if [ ! -d "$TFLITE_SRC_DIR" ]; then
    echo "[INFO] Cloning TensorFlow repo..."
    git clone --depth=1 --branch "$TFLITE_VERSION" "$TFLITE_REPO"
    cd $TFLITE_SRC_DIR
    echo "[INFO] Applying patch: linker_issues_fix_v2_19_0.patch"
    git apply --ignore-space-change --ignore-whitespace --whitespace=nowarn ../patches/tensor_flow_build_patch_2_19_0.patch
    cd ..
  fi
}

# build dir as argument
function prepare_build_dir() {
  if [ ! -d "$1" ]; then
    echo "[INFO] Creating build directory: $1"
    mkdir -p "$1"
    cp $SCRIPT_DIR/patches/abseil_cmake.patch "$1"
  fi
}

# install dir as argument
function build_and_install() {
  echo "[INFO] Building $1..."
  cmake --build "$2" --config $BUILD_CONFIGURATION
  echo "[✅ DONE] $1 built successfully"

  echo "[INFO] Installing $1 artifacts..."
  cmake --install "$2" --config BUILD_CONFIGURATION
  echo "[✅ DONE] $1 artifacts installed successfully"
}

function install_tensorflow_package() {
  # ========= COPY LIBS MANUALLY (IF NEEDED) =========
  mkdir -p "$1/lib"
  find . -name "*.$1" -exec cp {} "$2/lib/" \;
  #find "$1/lib/" -type f -name "*.a" -delete
  rm -f $2/lib/*.a

  # ========= COPY HEADERS =========
  echo "[INFO] Copying header files..."
  INCLUDE_DIR="$2/include"
  mkdir -p "$INCLUDE_DIR"
  # copy C/C++ headers from tensorflow/
  rsync -a --prune-empty-dirs --include='*/' --include='*.h' --exclude='*' $SCRIPT_DIR/tensorflow/tensorflow "$INCLUDE_DIR"
  echo "[INFO] Headers copy complete."

  echo "[✅ DONE] TensorFlow Lite built successfully into: $2"
}

function tflite_host_tools_dir() {
    if [[ "$OSTYPE" == "msys"* ]]; then
        echo "$SCRIPT_DIR/toolchains/host_tools/windows"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local arch=$(uname -m)
        if [[ "$arch" == "arm64" ]]; then
            echo "$SCRIPT_DIR/toolchains/host_tools/mac/arm64"
        elif [[ "$arch" == "x86_64" ]]; then
            echo "$SCRIPT_DIR/toolchains/host_tools/mac/x86_64"
        else
            echo "Unsupported architecture: $arch" >&2
            return 1
        fi
    else
        echo "Unsupported operation system: $OSTYPE" >&2
        return 1
    fi
}
