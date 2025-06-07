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
# 引入 NDK 工具链配置 
if [ -f "${SCRIPT_DIR}/scripts/common_env.sh" ]; then
    source "${SCRIPT_DIR}/scripts/common_env.sh"
    if [ $? -ne 0 ] || [ -z "$ANDROID_NDK_HOME" ] || [ -z "$ANDROID_SDK_HOME" ]; then
        echo -e "${BRED}Error: NDK or SDK path not set by common_ndk.sh ${NC}" >&2
        exit 1
    fi
else
    echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
    echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME="ANDROID NDK Dev Toolchain."${NC}"
    exit 1
fi
DEFAULT_ANDROID_API="android-24"    # 默认 Android API Level
DEFAULT_CMAKE_BUILD_TYPE="Release"  # 默认 Build Type
BUILD_DIR="${SCRIPT_DIR}/build"     

# ---- 运行参数 ----
BUILD_TESTS="off"
TARGET_ARCH=""

print_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options: ${NC}"
    echo -e "   ${CYAN}--arch=<ARCH>${NC}           Specify the target architecture."
    echo -e "   Supported Android ABIs: ${GREEN}armeabi-v7a, arm64-v8a, x86, x86_64{$NC}"
    echo -e "   Supported Native  Arch: ${GREEN}linux-x86_64${NC}"
    echo ""
    echo -e "   ${CYAN}--build_tests=<on|off>${NC}  Enable or disable building tests. Default is 'off'."
    echo -e "   ${YELLOW}Note: If 'on', the architecture is automatically set to 'linux-x86_64'.${NC}"
    echo -e "   ${CYAN}-h, --help${NC}              Show this help message."
    echo ""
    echo -e "   ${YELLOW}Example (Android cross-compile):${NC}"
    echo -e "   ${CYAN}$0 --arch=arm64_v8a${NC}"
    echo ""
    echo -e "   ${YELLOW}Example (Native Linux build with tests):${NC}"
    echo -e "   ${CYAN}$0 --build_tests=on${NC}"
}

is_supported_arch() {
    local abi_to_check="$1"
    case "$abi_to_check" in
        "armeabi-v7a" | "arm64-v8a" | "x86" | "x86_64" | "linux-x86_64")
            return 0    # true, 支持
            ;;
        *)
            return 1    # false, 不支持
            ;;
    esac 
}

# --- 解析运行参数 ---
for i in "$@"; do
    case $i in
        --arch=*)
        TARGET_ARCH="${i#*=}"
        shift
        ;;
        --build_tests=*)
        BUILD_TESTS="${i#*=}"
        shift
        ;;
        -h|--help)
        print_usage
        exit 0
        ;;
        *)
        # Unknown optios
        echo -e "${BRED}Error: Unknown option '$i'${NC}"
        print_usage
        exit 1
        ;;
    esac
done

if [[ "$BUILD_TESTS" == "on" ]]; then
    if [[ -n "$TARGET_ARCH" && "$TARGET_ARCH" != "linux-x86_64" ]]; then
        echo -e "${YELLOW}Warning: --build_tests=on overrides arch. Forcing architecture to 'linux-x86_64'.${NC}"
    fi
    TARGET_ARCH="linux-x86_64"
fi

if [ -z "$TARGET_ARCH" ]; then
    echo -e "${BRED}Error: Target architecture not specified. Use --arch=<ARCH> or --build_tests=on.${NC}"
    print_usage
    exit 1
fi

if ! is_supported_arch "$TARGET_ARCH"; then
    echo -e "${BRED}Error: Unsupported architecture '$TARGET_ARCH'.${NC}"
    print_usage
    exit 1
fi

# --- 主构建流程 ---
if [ "$TARGET_ARCH" != "linux-x86_64" ]; then
    echo -e "${BGREEN}Start building tests for host${NC}"
else
    echo -e "${BGREEN}Start building Flutter FFI project${NC}"
    echo -e "${GREEN}Target ABI: ${CYAN}$TARGET_ABI${NC}"
    echo -e "${GREEN}NDK directory: ${CYAN}$ANDROID_NDK_HOME${NC}"
fi

# 1. Clean 
echo -e "${YELLOW}Cleaning build directory: ${BUILD_DIR}${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 2. Configure
echo -e "${GREEN}Configuring CMake...${NC}"


BUILD_TESTS_CMAKE="${BUILD_TESTS^^}"
CMAKE_COMMON_ARGS=(
    -S "${SCRIPT_DIR}"
    -B "${BUILD_DIR}"
    -DCMAKE_BUILD_TYPE="${DEFAULT_CMAKE_BUILD_TYPE}"
    -DBUILD_TESTS=${BUILD_TESTS_CMAKE}
    -DBUILD_EXAMPLES=OFF
    -DUSE_CMAKE_COLORED_MESSAGES=ON
    -DUSE_CPP_COLORED_DEBUG_OUTPUT=ON
    -DENABLE_EIGEN3=ON
    -DENABLE_BOOST=OFF
    -DENABLE_EXTERNAL_FMT=ON
)

if [[ "$TARGET_ARCH" == "linux-x86_64" ]]; then
    echo -e "${PURPLE}Configuring for Native Linux Build.${NC}"
    cmake "${CMAKE_COMMON_ARGS[@]}"
else
    echo -e "${PURPLE}Configuring for Android cross-compilation.${NC}"
    echo -e "${GREEN} NDK directory: ${ANDROID_NDK_HOME}${NC}"
    if [ ! -d "$ANDROID_NDK_HOME" ]; then
        echo -e "${BRED}Error: NDK directory not found at '$ANDROID_NDK_HOME'  ${NC}"
    fi
    cmake "${CMAKE_COMMON_ARGS[@]}" \
          -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
          -DANDROID_ABI="${TARGET_ARCH}" \
          -DANDROID_PLATFORM="android-${DEFAULT_ANDROID_API}"
fi

# 3. Build
echo -e "${GREEN}Building...${NC}"
cmake --build "${BUILD_DIR}" --config "${DEFAULT_CMAKE_BUILD_TYPE}" --parallel $(nproc)

echo ""
echo -e "${BGREEN}ABI ${TARGET_ABI} Project's building is finished!${NC}"
