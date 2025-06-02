
// 




#ifndef CONFIG_H
#define CONFIG_H

#if defined(_WIN32) || defined(__CYGWIN__)
    #define FLUTTER_FFI_EXPORT __declspec(dllexport)
#elif defined(__GNUC__) || defined(__clang__)
    #define FLUTTER_FFI_EXPORT __attribute__((visibility("default")))
#else
    #define FLUTTER_FFI_EXPORT
#endif



#endif // CONFIG_H