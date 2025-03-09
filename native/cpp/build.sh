#!/bin/bash

# build each libs

NDK_PATH="$HOME/Android/Sdk/ndk/27.1.12297006"

# Target ABI
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# build dir
OUTPUT_DIR="${pwd}/output"
mkdir -p "$OUTPUT_DIR"

ehco "Building libraries..."

for ABI in "${ABIS[@]}"; do
    echo "Building for $ABI..."

    BUILD_DIR="build_$ABI"
    mkdir -p $BUILD_DIR

    cmake -B $BUILD_DIR \
          -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
          -DANROID_ABI=$ABI \
          -DANDROID_PLATFORM=android-21 \
          -DCMAKE_INSTALL_PREFIX=$(pwd)/output \
          -DCMAKE_BUILD_TYPE=Release

    cmake --build $BUILD_DIR --config Release

    cmake --install $BUILD_DIR
    
    echo "Completed building for $ABI"
done

echo "All builds completeed! Libraries are in $OUTPUT_DIR"




