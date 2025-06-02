

#pragma once

#include <add/config.h>

namespace add {
    FFI_EXPORT int add(int a, int b);
    FFI_EXPORT double add(double a, double b);
    FFI_EXPORT const char* test_opencv_version();
    FFI_EXPORT const char* test_onnxruntime_api_version();
}
