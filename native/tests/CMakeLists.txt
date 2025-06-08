
# tests/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

option(BUILD_TESTS_VERBOSE "Build tests verbose" OFF)
if (BUILD_TESTS AND BUILD_TESTS_VERBOSE)
    add_compile_definitions(BUILD_TESTS_VERBOSE=1)
endif()

include(GoogleTest)

file(GLOB_RECURSE TEST_SOURCE 
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "*.cpp"
)

set(TEST_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_executable(native_tests
    ${TEST_SOURCE}

    test_logger.cpp
    test_ocr.cpp

    test_main.cpp
)

target_include_directories(native_tests
    PRIVATE
    ${TEST_HEADER}
)

target_link_libraries(native_tests 
    PRIVATE 
    geecodex
    GTest::gtest_main
)


gtest_discover_tests(native_tests)

