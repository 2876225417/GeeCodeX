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

# 配置 Eigen3 Gitlab 库
EIGEN_VERSION_TAG="3.4.0"
EIGEN_REPO_URL="https://gitlab.com/libeigen/eigen.git"

# 配置 Eigen 相关路径
SCRIPT_BASE_DIR="$(pwd)"
EIGEN_SOURCE_DIR="${SCRIPT_BASE_DIR}/source/eigen"
EIGEN_BUILD_BASE_DIR="${SCRIPT_BASE_DIR}/build/eigen"
EIGEN_INSTALL_BASE_DIR="${SCRIPT_BASE_DIR}/eigen"


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

    # 编译、安装和编译日志路径
    EIGEN_BUILD_DIR="${EIGEN_BUILD_BASE_DIR}/eigen_$platform"
    echo -e "${GREEN}--- Creating and cleaning Eigen build directory ---${NC}"
    rm -rf "$EIGEN_BUILD_DIR"
    mkdir -p "$EIGEN_BUILD_DIR"

    EIGEN_INSTALL_PREFIX_DIR="${EIGEN_INSTALL_BASE_DIR}/eigen_$platform"
    echo -e "${GREEN}--- Creating and cleaning Eigen install directory ---${NC}"
    rm -rf "$EIGEN_INSTALL_PREFIX_DIR"
    mkdir -p "$EIGEN_INSTALL_PREFIX_DIR"

    EIGEN_LOG_DIR="${SCRIPT_BASE_DIR}/logs/eigen"
    mkdir -p "$EIGEN_LOG_DIR"
    EIGEN_LOG_FILE="${EIGEN_LOG_DIR}/eigen_$platform.txt"

    CMAKE_ARGS=(
        "-DCMAKE_INSTALL_PREFIX"="${EIGEN_INSTALL_PREFIX_DIR}"
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

    cd "$EIGEN_BUILD_DIR"
    echo -e "${YELLOW}--- Configuring Eigen3 for platform: $platform ---${NC}"

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

    if [ "$CMAKE_BUILD_EXIT_CODE" -ne 0 ]; then
        echo -e "${BRED}Error: Failed to build Eigen3 for platform: $platform, EXIT CODE: $CMAKE_BUILD_EXIT_CODE${NC}" >&2
        echo -e "${BRED}Please check detailed log: ${EIGEN_LOG_FILE} ${NC}" >&2
        return 1
    else
        echo -e "${GREEN}Eigen built for platform: $platform successfully${NC}"
        BUILD_SUCCESSFUL_FLAG=true
    fi

    if [ "$BUILD_SUCCESSFUL_FLAG" = true ]; then
        echo -e "${YELLOW}--- Installing Eigen3 for platform: $platform ---${NC}"
        if cmake --install . --config Release >> "$EIGEN_LOG_FILE" 2>&1; then
            CMAKE_INSTALL_EXIT_CODE=0
        else
            CMAKE_INSTALL_EXIT_CODE=$?
        fi

        if [ "$CMAKE_INSTALL_EXIT_CODE" -ne 0 ]; then
            echo -e "${BRED}Error: Failed to install Eigen3 for platform: $platform, EXIT CODE: $CMAKE_INSTALL_EXIT_CODE ${NC}" >&2
            echo -e "${BRED}Please check detailed log: ${EIGEN_LOG_FILE} ${NC}" >&2
            BUILD_SUCCESSFUL_FLAG=false
            return 1
        else
            echo -e "${YELLOW}--- Eigen3 for platform: $platform installed to $EIGEN_INSTALL_PREFIX_DIR ${NC}"

            REPORT_FILE="${EIGEN_INSTALL_PREFIX_DIR}/build_report_${platform}.txt"
            echo "Eigen3 Build Report" > "$REPORT_FILE"
            echo "========================================================" >> "$REPORT_FILE"
            echo "Date: $(date)"                                            >> "$REPORT_FILE"
            echo "Platform: $platform"                                      >> "$REPORT_FILE"
            echo "Eigen Version (Git Tag/Branch): $EIGEN_VERSION_TAG"       >> "$REPORT_FILE"
            if [ -d "$EIGEN_SOURCE_DIR/.git" ]; then
                GIT_COMMIT_HASH=$(cd "$EIGEN_SOURCE_DIR" && git rev-parse --short HEAD)
                echo "Eigen Git Commit: $GIT_COMMIT_HASH"                   >> "$REPORT_FILE"
            fi
            echo "Build Configuration: Release (via CMake)"                 >> "$REPORT_FILE"
            if [ "$platform" = "android" ]; then
                echo "Android API Level: $MIN_SDK_VERSION"                      >> "$REPORT_FILE"
                echo "NDK Path: $ANDROID_NDK_HOME"                              >> "$REPORT_FILE"
                echo "NDK Version (fom source.properties): $NDK_VERSION_STRING" >> "$REPORT_FILE"
                echo "CLANG_CXX_COMPILER: $CLANG_COMPILER_PATH"                 >> "$REPORT_FILE"
                echo "CLANG_C_COMPILER: $CLANG_C_COMPILER_PATH"                 >> "$REPORT_FILE"
                echo "Clang Version: $CLANG_VERSION_STRING"                     >> "$REPORT_FILE"
            fi
            
            echo ""                                                             >> "$REPORT_FILE"
            echo "CMake Arguments Used: "                                       >> "$REPORT_FILE"
            printf "    %s\n" "${CMAKE_ARGS[@]}"                                >> "$REPORT_FILE"
            echo ""                                                             >> "$REPORT_FILE"
            echo -e "${GREEN}Build Report Generated: ${REPORT_FILE}${NC}"    

        fi

    fi

    
    cd "${SCRIPT_BASE_DIR}"
}

build_eigen_for_platform "android"
build_eigen_for_platform "host"


echo ""
echo -e "${YELLOW}===========================================================${NC}"
echo -e "${YELLOW}Eigen3 has been installed: ${EIGEN_INSTALL_BASE_DIR}${NC}"
ls -1 "$EIGEN_INSTALL_BASE_DIR"
echo -e "${YELLOW}Now you can use find_package(Eigen3) in cmake.${NC}"
echo -e "${YELLOW}===========================================================${NC}"


