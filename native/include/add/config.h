

#pragma once

#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef ADD_EXPORTS
        #define FFI_EXPORT __declspec(dllexport)
    #else
        #define FFI_EXPORT __declspec(dllimport)
    #endif
#elif defined(__GNUC__) || defined(__clang__)
    #define FFI_EXPORT __attribute__((visibility("default")))
#else
    #define FFI_EXPORT
#endif


