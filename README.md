
# TensorFlow-Lite-builds

The main issue with TensorFlow Lite builds is that seems like the [CMake](https://ai.google.dev/edge/litert/build/cmake) system is no longer maintained by the library's development team, with a proposal to switch to [Bazel](https://www.tensorflow.org/install/source) instead.

Additionally, the default stock build is designed to produce static libraries, which is not always convenient for large-scale projects.

The goal of this project is to enable building TensorFlow Lite as dynamic libraries using CMake.

The resulting build artifacts will follow a standard structure — an include folder and a lib folder — and will be ready to integrate seamlessly into any C++ project.

This repository contains a set of build scripts which allows to produce TensorFlow Lite dynamic libraries for the next platforms:

- ****Windows****: x86_64

- ****macOS****: x86_64 ([Rosetta layer](https://en.wikipedia.org/wiki/Rosetta_%28software%29) is not supported), arm64 (Silicon M-chips)

- ****iOS****: x86_64 (Simulator), arm64 (Device)

- ****Android****: x86_64 (Simulator), arm64-v8a (Device)
---

## Preparation for the build

It is highly recommended to start the build process from scratch for each target platform.

Make sure to remove any intermediate folders from previous builds, such as tensorflow, build__, and install__.

The default build parameters are defined in the common.sh and build_windows.bat scripts:

* Build type - Release (specified by the [BUILD_CONFIGURATION](https://github.com/ArtiomKhachaturian/TensorFlow-Lite-builds/blob/master/common.sh#L3) variable). 
For Android builds, if you change the build type, don't forget to adjust the corresponding CMake settings in the [build_android_all.sh](https://github.com/ArtiomKhachaturian/TensorFlow-Lite-builds/blob/master/build_android_all.sh#L51) script.

* TensorFlow sources - https://github.com/tensorflow/ (defined by the TFLITE_REPO variable)

* Android platform - 29 (set via the [ANDROID_PLATFORM](https://github.com/ArtiomKhachaturian/TensorFlow-Lite-builds/blob/master/build_android_all.sh#L14) variable in build_android_all.sh)

* [Android C++ STL](https://github.com/ArtiomKhachaturian/TensorFlow-Lite-builds/blob/master/build_android_all.sh#L48) - c++__shared (also specified in build_android_all.sh)_

* Universal (fat) libraries are not supported out of the box. However, you can use external tools such as [lipo](https://www.f-ax.de/dev/2021/01/15/build-fat-macos-library.html) to create them manually.
---

## Build scripts  

There is a set of scripts for each supported platform.

### iOS

- `build_ios_all.sh` – iOS artifacts x86_64 & ARM64 targets  

### macOS

- `build_macos.sh` – macOS artifacts for target platform (arm64 on Apple Silicon or x86_64 on Intel)

### Windows

- `build_windows.bat` – Windows artifacts for x86_64

### Android

> Before building for Android, ensure that the `NDK_PATH` environment variable is set and points to a valid [Android NDK installation](https://developer.android.com/ndk/downloads?hl=pl) (minimum version: ****23.x.x****)

- `build_android_all.sh` – Android artifacts for x86_64 & ARM64 targets

---

## Output artifacts

Each script produces build & install folder:

- MacOS: 'build_macos_x86_64'/'install_macos_x86_64', 'build_macos_arm64'/'install_macos_arm64'

- iOS: 'build_ios_x86_64'/'install_ios_x86_64', 'build_ios_arm64'/'install_ios_arm64'

- Android: 'build_android_x86_64'/'install_android_x86_64', 'build_android_arm64-v8a'/'install_android_arm64-v8a'

- Windows: 'build_windows_x86_64'/'install_windows_x86_64'

The installation folder will contain C++ headers and dynamic libraries — which is the intended outcome of this build.

Note that the default CMake installation process includes a few minor issues, such as:

* Incorrect copying of [Ruy](https://github.com/google/ruy) C++ headers

* Missing symbolic link creation for the libabseil_dll.dylib library

These issues can be resolved manually if necessary.

## Requirements

- ****Python****: Version 3.1x or higher

- ****CMake****: Version 3.16 or higher

- ****Xcode****: Version 16.x or higher (for iOS/macOS builds)

- ****Microsoft Visual Studio****: 2022 (for Windows builds)

- ****Android NDK****: Version 23 or higher (27 is recommended)
---

## License

This project is licensed under the Apache License 2.0.  
See the [LICENSE](LICENSE) file for full details.

## Author

[Artiom Khachaturian](https://github.com/ArtiomKhachaturian)
