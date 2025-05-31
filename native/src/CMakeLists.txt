
# src/CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

set(FFI_LIBRARY_NAME "qwq_books_native")

if(ANDROID)
    set(CUSTOM_OPENCV_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/opencv")

    set(OpenCV_DIR "${CUSTOM_OPENCV_INSTALL_ROOT_DIR}/opencv_android_${CMAKE_ANDROID_ARCH_ABI}/sdk/native/jni")

    if (NOT EXISTS "${OpenCV_DIR}/OpenCVConfig.cmake")
        message(FATAL_ERROR "OpenCVConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${OpenCV_DIR}. Ensure custom OpenCV builds are in native/3rdparty/opencv/ and path is correct")
    else()
        message(STATUS "Using OpenCV_DIR: ${OpenCV_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()

    find_package(OpenCV REQUIRED COMPONENTS world)
    
    if (NOT OpenCV_FOUND)
        message(FATAL_ERROR "Custom OpenCV configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    else() 
        message(STATUS "Found Custom OpenCV (${OpenCV_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
        message(STATUS " OpenCV Include Dirs: ${OpenCV_INCLUDE_DIRS}")
        message(STATUS " OpenCV Libraries: ${OpenCV_LIBS}")
    endif()
endif()

file(GLOB_RECURSE SOURCES "*.cpp")
file(GLOB_RECURSE HEADERS "*.h")

add_library(${FFI_LIBRARY_NAME} SHARED
    ${SOURCES}
    ${HEADERS}
)

#target_compile_definitions(add PRIVATE ADD_API)
target_compile_definitions(${FFI_LIBRARY_NAME} PRIVATE QWQ_BOOKS_NATIVE_BUILD_SHARED_LIBS)

target_include_directories(${FFI_LIBRARY_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include/${FFI_LIBRARY_NAME}>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

if (ANDROID AND OpenCV_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PUBLIC 
        $<BUILD_INTERFACE:${OpenCV_INCLUDE_DIRS})

    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC ${OpenCV_LIBS})
endif()
if (ANDROID)
    target_link_libraries(${FFI_LIBRARY_NAME} PRIVATE log)
endif()

set_target_properties(${FFI_LIBRARY_NAME} 
    PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    POSITION_INDEPENDENT_CODE ON
)


# for android
if(ANDROID)
    target_link_options(${FFI_LIBRARY_NAME}
        PRIVATE
        -Wl,--no-undefined
        -Wl,-z,noexecstack
    )
endif()

install(TARGETS ${FFI_LIBRARY_NAME}
    EXPORT ${FFI_LIBRARY_NAME}-targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include/${FFI_LIBRARY_NAME}
)

# generate cmake
install(EXPORT ${FFI_LIBRARY_NAME}-targets
    FILE ${FFI_LIBRARY_NAME}-targets.cmake
    NAMESPACE ${FFI_LIBRARY_NAME}::
    DESTINATION lib/cmake/${FFI_LIBRARY_NAME}
)


