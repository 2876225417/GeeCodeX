
# src/CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

file(GLOB_RECURSE SOURCES "*.cpp")
file(GLOB_RECURSE HEADERS "*.h")

add_library(add SHARED
    ${SOURCES}
    ${HEADERS}
)

target_compile_options(add PRIVATE ADD_API)

target_include_directories(add
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

set_target_properties(add 
    PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    POSITION_INDEPENDENT_CODE ON
)


# for android
if(ANDROID)
    target_link_options(add
        PRIVATE
        -Wl, --no-undefine
        -Wl, -z,noexecstack
        -static-libstdc++
    )
endif()

install(TARGETS add
    EXPORT add-targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

install(EXPORT add-targets
    FILE add-targets.cmake
    NAMESPACE add::
    DESTINATION lib/cmake/add
)


