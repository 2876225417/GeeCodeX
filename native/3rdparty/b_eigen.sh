#!/bin/bash
set -e

SCRIPT_DIR_REALPATH=$(dirname "$(realpath "$0")")

# 引入颜色输出配置
if [ -f "${SCRIPT_DIR_REALPATH}/common_color.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_color.sh"
else
    echo "Warning: NOT FOUND common_color.sh, the output will be without color." >&2
    NC='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BBLACK='' BRED='' BGREEN='' BYELLOW='' BBLUE='' BPURPLE='' BCYAN='' BWHITE=''
fi

# 引入 GIT 配置
COMMON_GIT_SCRIPT="${SCRIPT_DIR_REALPATH}/common_git.sh"
if [ -f "$COMMON_GIT_SCRIPT" ]; then
    source "$COMMON_GIT_SCRIPT"
else
    echo -e "${RED}Error: NOT FOUND common_git.sh under ${COMMON_GIT_SCRIPT}${NC}" >&2 
    exit 1
fi

# 引入 NDK 工具链配置 export ANDROID_NDK_HOME
if [ -f "${SCRIPT_DIR_REALPATH}/common_ndk.sh" ]; then
    source "${SCRIPT_DIR_REALPATH}/common_ndk.sh"
else
    echo -e "${BRED}ERROR: NO ANDROID_NDK_HOME CONFIGURED.${NC}"
    echo -e "${BYELLOW}Tip: Try to export ANDROID_NDK_HOME="ANDROID NDK Dev Toolchain."${NC}"
    exit 1
fi

EIGEN_VERSION_TAG="3.4.0"
EIGEN_REPO_URL="https://gitlab.com/libeigen/eigen.git"

# 配置 Eigen 相关路径
SCRIPT_BASE_DIR="$(pwd)"
EIGEN_SOURCE_DIR="${SCRIPT_BASE_DIR}/source/eigen"

# 配置 Android NDK 工具链(不影响)
ANDROID_ABI_FOR_EIGEN_CONFIG="arm64-v8a"
ANDROID_PLATFORM_FOR_EIGEN_CONFIG="android-24"

# --- 准备源码 ---
echo -e "${YELLOW}--- Preparing Eigen3 source: ${EIGEN_SOURCE_DIR} ---${NC}"
mkdir -p "$EIGEN_SOURCE_DIR"
echo -e "${YELLOW}--- Handling Eigen3 Source Repository ---${NC}"
git_clone_or_update "$EIGEN_REPO_URL" "$EIGEN_SOURCE_DIR" "$EIGEN_VERSION_TAG"

build_eigen_for_platform() {
    local platform="$1"

    # 编译和安装路径
    EIGEN_BUILD_DIR="${SCRIPT_BASE_DIR}/build/eigen/eigen_$platform"
    echo -e "${GREEN}--- Creating and cleaning Eigen build directory ---${NC}"
    rm -rf "$EIGEN_BUILD_DIR"
    mkdir -p "$EIGEN_BUILD_DIR"

    EIGEN_INSTALL_PREFIX_DIR="${SCRIPT_BASE_DIR}/eigen/eigen_$platform"
    echo -e "${GREEN}--- Creating and cleaning Eigen install directory ---${NC}"
    rm -rf "$EIGEN_INSTALL_PREFIX_DIR"
    mkdir -p "$EIGEN_INSTALL_PREFIX_DIR"

    EIGEN_LOG_FILE="${SCRIPT_BASE_DIR}/logs/eigen_$platform.txt"

    CMAKE_ARGS=(
        "-DCMAKE_INSTALL_PREFIX"="${EIGEN_ISNTALL_PREFIX_DIR}"
        "-DCMAKE_BUILD_TYPE=Release"
        "-DEIGEN_BUILD_DOC=OFF"
    )
    
    if [ "$platform" = "android" ]; then
        CMAKE_ARGS+=(
            "-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
            "-DANDROID_ABI=${ANDROID_ABI_FOR_EIGEN_CONFIG}"
            "-DANDROID_PLATFORM=${ANDROID_PLATFORM_FOR_EIGEN_CONFIG}" 
        )
    fi

    echo "CMake Configurations:" > "$EIGEN_LOG_FILE"
    echo "cmake -S \"$EIGEN_SOURCE_DIR\" -B \"$EIGEN_BUILD_DIR\" ${CMAKE_ARGS[*]}" >> "$EIGEN_LOG_FILE"

    if cmake -S "$EIGEN_SOURCE_DIR" -B "$EIGEN_BUILD_DIR" "${CMAKE_ARGS[@]}" >> "$EIGEN_LOG_FILE"; then
        CMAKE_CONFIG_EXIT_CODE=0
    else
        CMAKE_CONFIG_EXIT_CODE=$?
    fi

    if [ "$CMAKE_CONFIG_EXIT_CODE" -ne 0 ]; then
        echo -e "${BRED}Error: Failed to configure cmake for Eigen3(platform: $platform), EXIT CODE: $CMAKE_CONFIG_EXIT_CODE${NC}" >&2
        echo -e "${BRED}Please check detailed log: ${EIGEN_LOG_FILE}${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}--- Building Eigen3 for platform: $platform... --- ${NC}"
    if cmake --build "$EIGEN_BUILD_DIR" --config Release --parallel $(nproc) >> "$EIGEN_LOG_FILE"; then
        CMAKE_BUILD_EXIT_CODE=0
    else
        CMAKE_BUILD_EXIT_CODE=$?
    fi

    



}

build_eigen_for_platform "android"
build_eigen_for_platform "host"


echo ""
echo -e "${YELLOW}===========================================================${NC}"
echo -e "${YELLOW}Eigen3 has been installed: ${EIGEN_INSTALL_PREFIX_DIR_FOR_ANDROID}${NC}"
echo -e "${YELLOW}Now you can use find_package(Eigen3) in cmake.${NC}"
echo -e "${YELLOW}===========================================================${NC}"


