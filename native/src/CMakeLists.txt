cmake_minimum_required(VERSION 3.16)

set(FFI_LIBRARY_NAME "qwq_books_native")

if(ANDROID)
    set(CUSTOM_OPENCV_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/opencv")

    set(OpenCV_DIR "${CUSTOM_OPENCV_INSTALL_ROOT_DIR}/opencv_android_${CMAKE_ANDROID_ARCH_ABI}/sdk/native/jni")

    if (NOT EXISTS "${OpenCV_DIR}/OpenCVConfig.cmake")
        pretty_message(FATAL_ERROR "OpenCVConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${OpenCV_DIR}. Ensure custom OpenCV builds are in native/3rdparty/opencv/ and path is correct")
    else()
        pretty_message(INFO "Using OpenCV_DIR: ${OpenCV_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()

    find_package(OpenCV REQUIRED COMPONENTS world)
    
    if (NOT OpenCV_FOUND)
        pretty_message(FATAL_ERROR "Custom OpenCV configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    else() 
        pretty_message(SUCCESS "Found Custom OpenCV (${OpenCV_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
        pretty_message(DEBUG   " OpenCV Include Dirs: ${OpenCV_INCLUDE_DIRS}")
        pretty_message(DEBUG   " OpenCV Libraries: ${OpenCV_LIBS}")
    endif()
endif()

if(ANDROID)
    set(CUSTOM_ONNXRUNTIME_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/onnxruntime")
    
    set(onnxruntime_DIR "${CUSTOM_ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_android_${CMAKE_ANDROID_ARCH_ABI}/lib/cmake/onnxruntime")
    
    if (NOT EXISTS "${onnxruntime_DIR}/onnxruntimeConfig.cmake")
        pretty_message(FATAL_ERROR "onnxruntimeConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${onnxruntime_DIR}. Ensure custom ONNXRuntime builds are in native/3rdparty/onnxruntime/ and path is correct")
    else()
        pretty_message(INFO "Using onnxruntime_DIR: ${onnxruntime_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()

    find_package(onnxruntime REQUIRED)

    if (NOT onnxruntime_FOUND)
        pretty_message(FATAL_ERROR "Custom ONNXRuntime configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    else() 
        pretty_message(SUCCESS "Found Custom ONNXRuntime (version ${onnxruntime_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
        get_target_property(ORT_INCLUDE_DIRS onnxruntime::onnxruntime INTERFACE_INCLUDE_DIRECTORIES)
        get_target_property(ORT_LIBRARIES onnxruntime::onnxruntime INTERFACE_LINK_LIBRARIES)
        pretty_message(DEBUG " ONNXRuntime Include Dirs (from target): ${ORT_INCLUDE_DIRS}")
        pretty_message(DEBUG " ONNXRuntime Libraries (from target): ${ORT_LIBRARIES}")
        pretty_message(DEBUG " ONNXRuntime_INCLUDE_DIRS (variable): ${onnxruntime_INCLUDE_DIRS}")
        pretty_message(DEBUG " ONNXRuntime_LIBRARIES (variable): ${onnxruntime_LIBRARIES}")
    endif()
endif()

file(GLOB_RECURSE SOURCES 
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "*.cpp"
)

add_library(${FFI_LIBRARY_NAME} SHARED
    ${SOURCES}
)

target_compile_definitions(${FFI_LIBRARY_NAME} PRIVATE
    QWQ_BOOKS_NATIVE_BUILD_SHARED_LIBS
)

target_include_directories(${FFI_LIBRARY_NAME} 
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
)

if (ANDROID AND OpenCV_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${OpenCV_INCLUDE_DIRS})
endif()

if (ANDROID AND onnxruntime_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${onnxruntime_INCLUDE_DIRS})
endif() 

target_include_directories(${FFI_LIBRARY_NAME}
    INTERFACE
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

if (ANDROID AND OpenCV_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC 
        ${OpenCV_LIBS})

endif()

if (ANDROID AND onnxruntime_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC 
        onnxruntime::onnxruntime)
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
    INCLUDES DESTINATION include
)

# generate cmake
install(EXPORT ${FFI_LIBRARY_NAME}-targets
    FILE ${FFI_LIBRARY_NAME}-targets.cmake
    NAMESPACE ${FFI_LIBRARY_NAME}::
    DESTINATION lib/cmake/${FFI_LIBRARY_NAME}
)


