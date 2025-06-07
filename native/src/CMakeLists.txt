cmake_minimum_required(VERSION 3.16)


option(ENABLE_EIGEN3 "Enable Eigen3 for project" ON)
option(ENABLE_BOOST  "Enable Boost  for project" OFF)

pretty_message(VINFO "======================ENABLE LIBS==============================")
pretty_message(VINFO "  ENABLE_EIGEN3:                  ${ENABLE_EIGEN3}")
pretty_message(VINFO "  ENABLE_BOOST:                   ${ENABLE_BOOST}")
pretty_message(VINFO "===============================================================")

set(FFI_LIBRARY_NAME "geecodex")

# ==== OpenCV find_package 配置开始 ====
pretty_message(INFO "===== OpenCV Configurations =====")
set(OPENCV_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/opencv")
if (BUILD_TESTS)
    set(OpenCV_DIR "${OPENCV_INSTALL_ROOT_DIR}/opencv_linux-x86_64/lib/cmake/opencv4")
elseif(ANDROID)
    set(OpenCV_DIR "${OPENCV_INSTALL_ROOT_DIR}/opencv_android_${CMAKE_ANDROID_ARCH_ABI}/sdk/native/jni")
endif()

if (NOT EXISTS "${OpenCV_DIR}/OpenCVConfig.cmake")
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "OpenCVConfig.cmake NOT FOUND for platform: Linux-x86_64 at path: ${OpenCV_DIR}. Ensure custom OpenCV builds are in native/3rdparty/opencv/ and path is correct")
    elseif (ANDROID)
        pretty_message(FATAL_ERROR "OpenCVConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${OpenCV_DIR}. Ensure custom OpenCV builds are in native/3rdparty/opencv/ and path is correct")
    endif()
else()
    if (BUILD_TESTS)    
        pretty_message(INFO "Using OpenCV_DIR: ${OpenCV_DIR} for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(INFO "Using OpenCV_DIR: ${OpenCV_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()

if (BUILD_TESTS)
    find_package(OpenCV REQUIRED)
elseif(ANDROID)
    find_package(OpenCV REQUIRED COMPONENTS world)
endif()

if (NOT OpenCV_FOUND)
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "Custom OpenCV configuration failed for platform: Linux-x86_64.")
    elseif(ANDROID)
        pretty_message(FATAL_ERROR "Custom OpenCV configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    endif()
else() 
    pretty_message(DEBUG   " OpenCV Include Dirs: ${OpenCV_INCLUDE_DIRS}")
    pretty_message(DEBUG   " OpenCV Libraries: ${OpenCV_LIBS}")
    if (BUILD_TESTS)
        pretty_message(SUCCESS "Found OpenCV (Version: ${OpenCV_VERSION}) for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(SUCCESS "Found OpenCV (Version: ${OpenCV_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()
pretty_message(INFO "=================================")
# OpenCV find_package 配置结束

# ONNXRuntime find_package 配置开始
pretty_message(INFO "===== ONNXRuntime Configurations =====")
set(ONNXRUNTIME_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/onnxruntime")



if (BUILD_TESTS)
    set(onnxruntime_DIR "${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_linux-x86_64/lib64/cmake/onnxruntime")
elseif(ANDROID)
    set(onnxruntime_DIR "${ONNXRUNTIME_INSTALL_ROOT_DIR}/onnxruntime_android_${CMAKE_ANDROID_ARCH_ABI}/lib/cmake/onnxruntime")
endif()

if (NOT EXISTS "${onnxruntime_DIR}/onnxruntimeConfig.cmake")
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "onnxruntimeConfig.cmake NOT FOUND for platform: Linux-x86_64 at path: ${onnxruntime_DIR}. Ensure custom ONNXRuntime builds are in native/3rdparty/onnxruntime/ and path is correct")
    elseif (ANDROID)
        pretty_message(FATAL_ERROR "onnxruntimeConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${onnxruntime_DIR}. Ensure custom ONNXRuntime builds are in native/3rdparty/onnxruntime/ and path is correct")
    endif()
else()
    if (BUILD_TESTS)    
        pretty_message(INFO "Using onnxruntime_DIR: ${onnxruntime_DIR} for platform: ")
    elseif (ANDROID)
        pretty_message(INFO "Using onnxruntime_DIR: ${onnxruntime_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()

find_package(onnxruntime REQUIRED)

if (NOT onnxruntime_FOUND)
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "ONNXRuntime configuration failed for platform: Linux-x86_64.")
    elseif (ANDROID)
        pretty_message(FATAL_ERROR "ONNXRuntime configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    endif()
else() 
    pretty_message(DEBUG " ONNXRuntime_INCLUDE_DIRS: ${onnxruntime_INCLUDE_DIRS}")
    pretty_message(DEBUG " ONNXRuntime_LIBRARIES: ${onnxruntime_LIBRARIES}")
    if (BUILD_TESTS)
        pretty_message(SUCCESS "Found ONNXRuntime (Version: ${onnxruntime_VERSION}) for platform: Linux-x86_64")
    elseif (ANDROID)
        get_target_property(ORT_INCLUDE_DIRS onnxruntime::onnxruntime INTERFACE_INCLUDE_DIRECTORIES)
        get_target_property(ORT_LIBRARIES onnxruntime::onnxruntime INTERFACE_LINK_LIBRARIES)
        pretty_message(DEBUG " ONNXRuntime Include Dirs (from target): ${ORT_INCLUDE_DIRS}")
        pretty_message(DEBUG " ONNXRuntime Libraries (from target): ${ORT_LIBRARIES}")
        pretty_message(SUCCESS "Found ONNXRuntime (Version: ${onnxruntime_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()
pretty_message(INFO "======================================")
# ONNXRuntime find_package 配置结束

# Eigen3 find_package 配置开始
pretty_message(INFO "===== Eigen3 Configurations =====")
set(EIGEN3_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/eigen3")
if (BUILD_TESTS)
    set(Eigen3_DIR "${EIGEN3_INSTALL_ROOT_DIR}/eigen3_host/eigen3/share/eigen3/cmake")
elseif(ANDROID)
    set(Eigen3_DIR "${EIGEN3_INSTALL_ROOT_DIR}/eigen3_android/eigen3/share/eigen3/cmake")
endif()

if (NOT EXISTS "${Eigen3_DIR}/Eigen3Config.cmake")
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "Eigen3Config.cmake NOT FOUND for platform: Linux-x86_64 at path: ${Eigen3_DIR}. Ensure custom Eigen3 builds are in native/3rdparty/eigen3/ and path is correct")
    elseif (ANDROID)
        pretty_message(FATAL_ERROR "Eigen3Config.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${Eigen3_DIR}. Ensure custom Eigen3 builds are in native/3rdparty/eigen3/ and path is correct")
    endif()
else()
    if (BUILD_TESTS)    
        pretty_message(INFO "Using Eigen3_DIR: ${Eigen3_DIR} for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(INFO "Using Eigen3_DIR: ${Eigen3_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()

find_package(Eigen3 REQUIRED)


if (NOT Eigen3_FOUND)
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "Eigen3 configuration failed for platform: Linux-x86_64.")
    elseif(ANDROID)
        pretty_message(FATAL_ERROR "Eigen3 configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    endif()
else() 
    pretty_message(DEBUG   " Eigen3 Include Dirs: ${EIGEN3_INCLUDE_DIRS}")
    pretty_message(DEBUG   " Eigen3 Libraries: ${EIGEN3_LIBS}")
    if (BUILD_TESTS)
        pretty_message(SUCCESS "Found Eigen3 (Version: ${EIGEN3_VERSION_STRING}) for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(SUCCESS "Found Eigen3 (Version: ${EIGEN3_VERSION_STRING}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()
pretty_message(INFO "=================================")
# Eigen3 find_package 配置结束


# magic_enum find_package 配置开始
pretty_message(INFO "===== magic_enum Configurations =====")
set(MAGIC_ENUM_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/magic_enum")
if (BUILD_TESTS)
    set(magic_enum_DIR "${MAGIC_ENUM_INSTALL_ROOT_DIR}/magic_enum_host/magic_enum/share/cmake/magic_enum")
elseif(ANDROID)
    set(magic_enum_DIR "${MAGIC_ENUM_INSTALL_ROOT_DIR}/magic_enum_android/magic_enum/share/cmake/magic_enum")
endif()

if (NOT EXISTS "${magic_enum_DIR}/magic_enumConfig.cmake")
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "magic_enumConfig.cmake NOT FOUND for platform: Linux-x86_64 at path: ${magic_enum_DIR}. Ensure custom magic_enum builds are in native/3rdparty/magic_enum/ and path is correct")
    elseif (ANDROID)
        pretty_message(FATAL_ERROR "magic_enumConfig.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${magic_enum_DIR}. Ensure custom magic_enum builds are in native/3rdparty/magic_enum/ and path is correct")
    endif()
else()
    if (BUILD_TESTS)    
        pretty_message(INFO "Using magic_enum_DIR: ${magic_enum_DIR} for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(INFO "Using magic_enum_DIR: ${magic_enum_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()

find_package(magic_enum REQUIRED)

if (NOT magic_enum_FOUND)
    if (BUILD_TESTS)
        pretty_message(FATAL_ERROR "magic_enum configuration failed for platform: Linux-x86_64.")
    elseif(ANDROID)
        pretty_message(FATAL_ERROR "magic_enum configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
    endif()
else() 
    pretty_message(DEBUG   " magic_enum Include Dirs: ${MAGIC_ENUM_INCLUDE_DIRS}")
    pretty_message(DEBUG   " magic_enum Libraries: ${MAGIC_ENUM_LIBS}")
    if (BUILD_TESTS)
        pretty_message(SUCCESS "Found magic_enum (Version: ${magic_enum_VERSION}) for platform: Linux-x86_64")
    elseif (ANDROID)
        pretty_message(SUCCESS "Found magic_enum (Version: ${magic_enum_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    endif()
endif()
pretty_message(INFO "=================================")
# magic_enum find_package 配置结束



# fmt find_package 配置开始
pretty_message(INFO "===== fmt Configurations =====")
set(FMT_INSTALL_ROOT_DIR "${CMAKE_SOURCE_DIR}/3rdparty/fmt")
if (ENABLE_EXTERNAL_FMT OR NOT HAVE_STD_FORMAT)
    if (BUILD_TESTS)
        set(fmt_DIR "${FMT_INSTALL_ROOT_DIR}/fmt_linux-x86_64/lib/cmake/fmt")
    elseif(ANDROID)
        set(fmt_DIR "${FMT_INSTALL_ROOT_DIR}/fmt_android_${CMAKE_ANDROID_ARCH_ABI}/lib/cmake/fmt")
    endif()

    if (NOT EXISTS "${fmt_DIR}/fmt-config.cmake")
        if (BUILD_TESTS)
            pretty_message(FATAL_ERROR "fmt-config.cmake NOT FOUND for platform: Linux-x86_64 at path: ${fmt_DIR}. Ensure custom fmt builds are in native/3rdparty/fmt/ and path is correct")
        elseif (ANDROID)
            pretty_message(FATAL_ERROR "fmt-config.cmake NOT FOUND for ABI: ${CMAKE_ANDROID_ARCH_ABI} at path: ${fmt_DIR}. Ensure custom fmt builds are in native/3rdparty/fmt/ and path is correct")
        endif()
    else()
        if (BUILD_TESTS)    
            pretty_message(INFO "Using fmt_DIR: ${fmt_DIR} for platform: Linux-x86_64")
        elseif (ANDROID)
            pretty_message(INFO "Using fmt_DIR: ${fmt_DIR} for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
        endif()
    endif()

    find_package(fmt REQUIRED)

    if (NOT fmt_FOUND)
        if (BUILD_TESTS)
            pretty_message(FATAL_ERROR "fmt configuration failed for platform: Linux-x86_64.")
        elseif(ANDROID)
            pretty_message(FATAL_ERROR "fmt configuration failed for ABI: ${CMAKE_ANDROID_ARCH_ABI}.")
        endif()
    else() 
        pretty_message(DEBUG   " fmt Include Dirs: ${fmt_INCLUDE_DIRS}")
        pretty_message(DEBUG   " fmt Libraries: ${fmt_LIBS}")
            if (BUILD_TESTS)
            pretty_message(SUCCESS "Found fmt (Version: ${fmt_VERSION}) for platform: Linux-x86_64")
        elseif (ANDROID)
            pretty_message(SUCCESS "Found fmt (Version: ${fmt_VERSION}) for ABI: ${CMAKE_ANDROID_ARCH_ABI}")
        endif()
    endif()
endif()
pretty_message(INFO "==============================")
# fmt find_package 配置结束


if (ANDROID AND ENABLE_BOOST) 


endif()

file(GLOB_RECURSE SOURCES 
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    "*.cpp"
)

add_library(${FFI_LIBRARY_NAME} SHARED
    ${SOURCES}
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${FFI_LIBRARY_NAME} PRIVATE DEBUG)
endif()
target_compile_definitions(${FFI_LIBRARY_NAME} PRIVATE
    QWQ_BOOKS_NATIVE_BUILD_SHARED_LIBS
)

target_include_directories(${FFI_LIBRARY_NAME} 
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
)

if (OpenCV_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${OpenCV_INCLUDE_DIRS})
endif()

if (onnxruntime_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${onnxruntime_INCLUDE_DIRS})
endif() 

if (Eigen3_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${EIGEN3_INCLUDE_DIRS})
endif()

if (magic_enum_FOUND)
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${magic_enum_INCLUDE_DIRS})
endif()

if (fmt_FOUND AND (ENABLE_EXTERNAL_FMT OR NOT HAVE_STD_FORMAT))
    target_include_directories(${FFI_LIBRARY_NAME} PRIVATE
        ${fmt_INCLUDE_DIRS})
endif()

target_include_directories(${FFI_LIBRARY_NAME}
    INTERFACE
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

if (OpenCV_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC 
        ${OpenCV_LIBS})
endif()

if (onnxruntime_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC 
        onnxruntime::onnxruntime)
endif() 

if (Eigen3_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC
        Eigen3::Eigen)
endif()

if (magic_enum_FOUND)
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC
        magic_enum::magic_enum)
endif()

if (fmt_FOUND AND (ENABLE_EXTERNAL_FMT OR NOT HAVE_STD_FORMAT))
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC
        fmt::fmt)
endif()

if (CMAKE_BUILD_TYPE MATCHES "[Dd]eb")
    target_link_libraries(${FFI_LIBRARY_NAME} PUBLIC
        cpptrace::cpptrace)
endif()



if (ANDROID)
    find_library(GLES_LIB GLESv3 REQUIRED)
    find_library(EGL_LIB EGL REQUIRED)

    target_link_libraries(${FFI_LIBRARY_NAME} PRIVATE ${GLES_LIB} ${EGL_LIB})

    pretty_message(INFO "Linking with GLES: ${GLES_LIB}")
    pretty_message(INFO "Linking with EGL:  ${EGL_LIB}")
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


