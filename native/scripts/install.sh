#!/bin/bash


cd ../

FFI_LIBS_INSTALL_DIR_BASE="$(pwd)/build/output"

CUSTOM_OPENCV_INSTALL_DIR_BASE="$(pwd)/3rdparty/opencv"

JNILIBS_DIR_FLUTTER_PROJECT="$(pwd)/../android/app/src/main/jniLibs"

ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

FFI_LIB_NAME="qwq_books_native"

echo "Starting installation of .so files to $JNILIBS_DIR_FLUTTER_PROJECT"
mkdir -p "$JNILIBS_DIR_FLUTTER_PROJECT"

for ABI in "${ABIS[@]}"; do
    echo "-------------------------------"
    echo "Installing for ABI: $ABI..."
    echo "-------------------------------"

    TARGET_ABI_JNI_DIR="$JNILIBS_DIR_FLUTTER_PROJECT/$ABI"
    mkdir -p "$TARGET_ABI_JNI_DIR"

    FFI_LIB_SOURCE_PATH="$FFI_LIBS_INSTALL_DIR_BASE/$ABI/lib/lib${FFI_LIB_NAME}.so"
    if [ -f "$FFI_LIB_SOURCE_PATH" ]; then
        echo "Copying $FFI_LIB_SOURCE_PATH to $TARGET_ABI_JNI_DIR/"
        cp -v "$FFI_LIB_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo "Warning: FFI Library lib${FFI_LIB_NAME}.so NOT FOUND for $ABI at $FFI_LIB_SOURCE_PATH"
    fi

    OPENCV_LIB_SOURCE_PATH="${CUSTOM_OPENCV_INSTALL_DIR_BASE}/opencv_android_${ABI}/sdk/native/libs/${ABI}/libopencv_world.so"
    if [ -f "$OPENCV_LIB_SOURCE_PATH" ]; then
        echo "Copying $OPENCV_LIB_SOURCE_PATH to $TARGET_ABI_JNI_DIR/"
        cp -v "$OPENCV_LIB_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo "Warning: libopencv_world.so NOT FOUND for $ABI at $OPENCV_LIB_SOURCE_PATH"
    fi
    
    OPENCV_LIB_MISC_SOURCE_PATH="${CUSTOM_OPENCV_INSTALL_DIR_BASE}/opencv_android_${ABI}/sdk/native/libs/${ABI}/libopencv_img_hash.so"
    if [ -f "$OPENCV_LIB_SOURCE_PATH" ]; then
        echo "Copying $OPENCV_LIB_MISC_SOURCE_PATH to $TARGET_ABI_JNI_DIR/"
        cp -v "$OPENCV_LIB_MISC_SOURCE_PATH" "$TARGET_ABI_JNI_DIR/"
    else
        echo "Warning: libopencv_img_hash.so NOT FOUND for $ABI at $OPENCV_LIB_SOURCE_PATH"
    fi

done

echo ""
echo "========================================================================="
echo "Installation to jniLibs completed!"
echo "========================================================================="
