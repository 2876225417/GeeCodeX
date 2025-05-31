#!/bin/bash

cd ..

NDK_PATH="$HOME/Android/Sdk/ndk/27.1.12297006"

# Android ABI types
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

# BUILD OUTPUT
OUTPUT_DIR="$(pwd)/build/output"
mkdir -p "$OUTPUT_DIR"

echo "Building libraries..."

for ABI in "${ABIS[@]}"; do
    echo "------------------------------"
    echo "Building for $ABI..."
    echo "------------------------------"

    BUILD_DIR_ABI="build/android_$ABI"
    mkdir -p "$BUILD_DIR_ABI"
    
    cmake -B $BUILD_DIR_ABI \
          -DCMAKE_TOOLCHAIN_FILE=$NDK_PATH/build/cmake/android.toolchain.cmake \
          -DANDROID_ABI=$ABI \
          -DANDROID_PLATFORM=android-21 \
          -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR/$ABI \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_TESTS=OFF \
          -DBUILD_EXAMPLES=OFF \
          .

    cmake --build "$BUILD_DIR_ABI" --config Release --parallel $(nproc)

    cmake --install "$BUILD_DIR_ABI"

    echo "Completed building and installing FFI library for $ABI to $OUTPUT_DIR/$ABI" 
done

echo ""
echo "All FFI library builds completed! Libraries are in $OUTPUT_DIR"
