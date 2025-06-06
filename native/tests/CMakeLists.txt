
# tests/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

include(GoogleTest)

add_executable(native_tests
    test_logger.cpp
)

target_link_libraries(native_tests 
    PRIVATE 
    geecodex
    GTest::gtest_main
)

gtest_discover_tests(native_tests)

