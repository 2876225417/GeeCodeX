#!/bin/bash


cd ../

# LIBS DIR 
SOURCE_DIR="$(pwd)/build/output"

# INSTALL DIR
JNILIBS_DIR="$(pwd)/../android/app/src/main/jniLibs"

ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")


echo "Installing libraries from $SOURCE_DIR to $JNILIBS_DIR"

mkdir -p "$JNILIBS_DIR"

for ABI in "${ABIS[@]}"; do
    echo "Installing for $ABI..."

    mkdir -p "$JNILIBS_DIR/$ABI"

    if [ -d "$SOURCE_DIR/$ABI/lib" ]; then
        cp -f $SOURCE_DIR/$ABI/lib/*.so "$JNILIBS_DIR/$ABI/"
        echo "Installed libraries for $ABI"
    else
        echo "Warning: No libraries found for $ABI in $SOURCE_DIR/$ABI/lib"
    fi
done

echo "Installation completed!"
