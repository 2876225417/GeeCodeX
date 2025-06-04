#!/bin/bash

set -e

# 项目编译 build

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR}/scripts/common_color.sh" ]; then
    source "${SCRIPT_DIR}/scripts/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

# NDK 工具链配置
ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.13113456"
DEFAULT_ANDROID_API="android-24"    # 默认 Android API Level
DEFAULT_CMAKE_BUILD_TYPE="Release"  # 默认 Build Type

BUILD_DIR="${SCRIPT_DIR}/build"     

print_usage() {
    echo -e "${YELLOW}Usage: $0 <ABI>${NC}"
    echo -e "Supported ABI: ${GREEN}armeabi-v7a, arm64-v8a, x86, x86_64${NC}"
    echo -e "Example: ${CYAN}$0 arm64-v8a${NC}"
}

is_supported_abi() {
    local abi_to_check="$1"
    case "$abi_to_check" in
        "armeabi-v7a" | "arm64-v8a" | "x86" | "x86_64")
            return 0    # true, 支持
            ;;
        *)
            return 1    # false, 不支持
            ;;
    esac 
}

# --- 解析运行参数 ---
if [ -z "$1" ]; then
    echo -e "${BRED}Error: Not Specify ABI.{$NC}"
    print_usage
    exit 1 
fi

TARGET_ABI="$1"

if ! is_supported_abi "$TARGET_ABI"; then
    echo -e "${BRED}Error: Not Supported ABI '$TARGET_ABI'.${NC}"
    print_usage
    exit 1
fi

# --- 主构建流程 ---
echo -e "${BGREEN}Start building Flutter FFI project${NC}"
echo -e "${GREEN}Target ABI: ${CYAN}$TARGET_ABI${NC}"
echo -e "${GREEN}NDK directory: ${CYAN}$ANDROID_NDK_HOME${NC}"

# 1. Clean 
echo -e "${YELLOW}Cleaning build directory: ${BUILD_DIR}${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 2. Configure
echo -e "${GREEN}Configuring CMake...${NC}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" \
      -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
      -DANDROID_ABI="${TARGET_ABI}" \
      -DANDROID_PLATFORM="${DEFAULT_ANDROID_API}" \
      -DCMAKE_BUILD_TYPE="${DEFAULT_CMAKE_BUILD_TYPE}" \
      -DBUILD_TESTS=OFF \
      -DBUILD_EXAMPLES=OFF \
      -DUSE_COLORED_MESSAGES=ON  # 彩色打印信息 

# 3. Build
echo -e "${GREEN}Building...${NC}"
cmake --build "${BUILD_DIR}" --config "${DEFAULT_CMAKE_BUILD_TYPE}" --parallel $(nproc)

echo ""
echo -e "${BGREEN}ABI ${TARGET_ABI} Project's building is finished!${NC}"
