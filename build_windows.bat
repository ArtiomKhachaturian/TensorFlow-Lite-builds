@echo off
setlocal enabledelayedexpansion

:: ========= CMAKE CHECK =========
where cmake >nul 2>nul
IF ERRORLEVEL 1 (
    echo "CMake was not found. Please install and add it to system PATH"
    goto :EOF
)

:: ========= CONFIG =========
set BUILD_CONFIGURATION=Release
set TFLITE_SRC_DIR=tensorflow
set TFLITE_VERSION="v2.19.0"
set TFLITE_REPO="https://github.com/tensorflow/%TFLITE_SRC_DIR%.git"
set INSTALL_DIR=%CD%/install_windows_x86_64
set BUILD_DIR=%CD%/build_windows_x86_64
set ARCH=x64

IF NOT EXIST "%TFLITE_SRC_DIR%\" (
    echo "[INFO] Cloning TensorFlow repo..."
    git clone --depth=1 --branch %TFLITE_VERSION% %TFLITE_REPO% && (
        cd "%TFLITE_SRC_DIR%"
        echo "[INFO] Applying patch: linker_issues_fix_v2_19_0.patch"
        git apply --ignore-space-change --ignore-whitespace --whitespace=nowarn ../patches/linker_issues_fix_v2_19_0.patch
        cd ..
        if  errorlevel 1 goto :EOF
    ) || (
        goto :EOF
    )
)

IF NOT EXIST "%BUILD_DIR%\" (
    echo "[INFO] Creating build directory: %BUILD_DIR%"
    mkdir "%BUILD_DIR%"
)

cd "%BUILD_DIR%"
echo "[INFO] Running CMake configuration..."
cmake -Wno-dev ../tensorflow/tensorflow/lite ^
  -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%"  ^
  -DBUILD_SHARED_LIBS=ON ^
  -DABSL_BUILD_MONOLITHIC_SHARED_LIBS=ON ^
  -DCMAKE_BUILD_TYPE=%BUILD_CONFIGURATION% ^
  -DTFLITE_ENABLE_XNNPACK=ON ^
  -DTFLITE_ENABLE_GPU=ON ^
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ^
  -A %ARCH% ^
  -G "Visual Studio 17 2022" && (
    echo "[INFO] Running TensorFlow Lite build..."
:: ========= BUILD & INSTALL =========
    cmake --build "%BUILD_DIR%" --config %BUILD_CONFIGURATION% && (
        echo "[INFO] Installing TensorFlow Lite artifacts to %INSTALL_PATH%..."
        cmake --install "%BUILD_DIR%" --config %BUILD_CONFIGURATION% && (
            for /r "%BUILD_DIR%" %%f in (*.dll) do (
                copy "%%f" "%INSTALL_DIR%/bin"
            )
            for /r "%BUILD_DIR%" %%f in (*.lib) do (
                copy "%%f" "%INSTALL_DIR%/lib"
            )
        )
    )
  )