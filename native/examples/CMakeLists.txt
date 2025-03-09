
# examples/CMakeLists.txt


cmake_minimum_required(VERSION 3.16)

add_executable(ex_add ex_add.cpp)
target_link_libraries(ex_add PRIVATE add)

install(TARGETS ex_add DESTINATION bin/examples)
