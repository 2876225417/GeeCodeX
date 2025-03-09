

#pragma once

#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef ADD_EXPORTS
        #define ADD_API __declspec(dllexport)
    #else
        #define ADD_API --declspec(dllimport)
    #endif
#else
    #define ADD_API __attribute__((visibility("default")))
#endif

#define ADD_VERSION_MAJOR 1
#define ADD_VERSION_MINOR 0
#define ADD_VERSION_PATCH 0

