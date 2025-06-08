
# tests/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

include(GoogleTest)

file(GLOB_RECURSE TEST_HEADER 
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "*.cpp"
)

add_executable(native_tests
    test_helper.cpp    
    test_logger.cpp
    test_ocr.cpp
)

target_include_directories(native_tests
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(native_tests 
    PRIVATE 
    geecodex
    GTest::gtest_main
)


gtest_discover_tests(native_tests)

