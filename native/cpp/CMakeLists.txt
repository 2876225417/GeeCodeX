
cmake_minimum_required(VERSION 3.16)

project(add)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED JNILIBS_DIR)
    set(JNILIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../android/app/src_main/jniLibs)
endif()

message(STATUS "JNI libs will be intalled to: ${JNILIBS_DIR}")

add_library(add
    SHARED
    add.cpp
)

set_target_properties(add PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

target_link_options(add PRIVATE
    -Wl,--no-undefined
    -Wl,-z,noexecstack
    -static-libstdc++
)

install(TARGETS add
    LIBRARY DESTINATION "${JNILIBS_DIR}/${ANDROID_ABI}"
)



