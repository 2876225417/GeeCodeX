
# tests/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

find_package(GTest REQUIRED)

add_executable(test_add test_add.cpp)
target_link_libraries(test_add PRIVATE 
    add
    GTest::GTest
    GTest::Main
)

add_test(NAME test_add COMMADN test_add)



