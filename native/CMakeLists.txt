cmake_minimum_required(VERSION 3.16)

project(qwq_books_natives LANGUAGES CXX VERSION 0.0.1)


set(CMAKE_CXX_STANDARD 23)
set(CMAKE_C_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(PrettyPrint)

pretty_message(INFO  "Configuring project: ${PROJECT_NAME} v${PROJECT_VERSION}")
pretty_message(VINFO "======================Compiler Info============================")
if (ANDROID)
pretty_message(VINFO "  CMAKE_TOOLCHAIN_FILE:           ${CMAKE_TOOLCHAIN_FILE}")
endif()
pretty_message(VINFO "  CMAKE_CXX_STANDARD:             ${CMAKE_CXX_STANDARD}")
pretty_message(VINFO "  CMAKE_CXX_COMPILER:             ${CMAKE_CXX_COMPILER}")
pretty_message(VINFO "  CMAKE_CXX_COMPILER_VERSION:     ${CMAKE_CXX_COMPILER_VERSION}")
pretty_message(VINFO "  CMAKE_CXX_BYTE_ORDER:           ${CMAKE_CXX_BYTE_ORDER}")
pretty_message(VINFO "  CMAKE_CXX_COMPILER_ABI:         ${CMAKE_CXX_COMPILER_ABI}")
pretty_message(VINFO "  CMAKE_BUILD_TYPE:               ${CMAKE_BUILD_TYPE}")
pretty_message(VINFO "  BUILD_TESTS:                    ${BUILD_TESTS}")
pretty_message(VINFO "===============================================================")

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

if (MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

add_subdirectory(src)

# for debug
if (CMAKE_BUILD_TYPE MATCHES "[Dd]eb")
    pretty_message(INFO "cpptrace will be built for build type with debug info.")
    include(FetchContent)
    FetchContent_Declare(
        cpptrace
        GIT_REPOSITORY https://github.com/jeremy-rifkin/cpptrace.git
        GIT_TAG        v0.8.3 
    )
    FetchContent_MakeAvailable(cpptrace)
    add_compile_definitions(BUILD_DEBUG=1)
endif()



# for tests
option(BUILD_TESTS "Build tests" OFF)
if(BUILD_TESTS)
    pretty_message(INFO "Tests will be built.")
    enable_testing()
    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.17.0
    )
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
    add_compile_definitions(BUILD_TESTS=1)
    add_subdirectory(tests)
else()
    pretty_message(INFO "Tests will not be built.")
endif()

# for examples 
option(BUILD_EXAMPLES "Build examples" OFF)
if(BUILD_EXAMPLES)
    pretty_message(INFO "Examples will be built.")
    add_subdirectory(examples)
else()
    pretty_message(INFO "Examples will not be built.")
endif()

install(DIRECTORY include/ 
    DESTINATION include 
    FILES_MATCHING PATTERN "*.h"
)
