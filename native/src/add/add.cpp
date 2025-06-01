

#include <add/add.h>
#include <exception>
#include <internal/utils.h>
#include <opencv2/core.hpp>
#include <limits>
#include <iostream>
#include <onnxruntime_cxx_api.h>
#include <onnxruntime_c_api.h>
#include <opencv2/core/base.hpp>
#include <string>


namespace add {
    int add(int a, int b) {
    if ((b > 0 && a > std::numeric_limits<int>::max() - b) || 
        (b < 0 && a < std::numeric_limits<int>::min() - b)) {
                return internal::clamp<int>(
                    a + b,
                    std::numeric_limits<int>::min(),
                    std::numeric_limits<int>::max()
                );
        }
    std::cout << "Add(): " << a << "+" << b << std::endl;
    return a + b + 1;
    }

    double add(double a, double b) {
        return a + b;
    }

    const char* test_opencv_version() {
        static std::string version_info;
        try {
            std::string cv_version = cv::getVersionString();
            version_info = "OpenCV Version (Custom Build): " + cv_version;
            return version_info.c_str();
        } catch (const std::exception& e) {

        }
    }

// ONNXRuntime 测试函数
    const char* test_onnxruntime_api_version() {
        static std::string ort_version_info_holder; // 用于安全返回 C 字符串

        // 获取 OrtApiBase 指针
        const OrtApiBase* api_base = OrtGetApiBase();
        if (!api_base) {
            ort_version_info_holder = "错误: OrtGetApiBase() 返回 NULL。";
            return ort_version_info_holder.c_str();
        }

        // 【关键修改】直接通过 api_base 调用 GetVersionString
        // GetVersionString 是 OrtApiBase 的成员，而不是 OrtApi 的成员
        if (!api_base->GetVersionString) { // 检查函数指针本身是否为 NULL (非常防御性的编程)
            ort_version_info_holder = "错误: api_base->GetVersionString 函数指针为 NULL。";
            return ort_version_info_holder.c_str();
        }

        try {
            const char* version = api_base->GetVersionString(); // <--- 正确的调用方式
            if (!version) {
                ort_version_info_holder = "错误: api_base->GetVersionString() 调用返回 NULL。";
                return ort_version_info_holder.c_str();
            }
            ort_version_info_holder = "ONNXRuntime API Version: " + std::string(version);
        } catch (const std::exception& e) { // 尽管 C API 通常不抛 C++ 异常
            ort_version_info_holder = "调用 ONNXRuntime C API 时发生标准异常: " + std::string(e.what());
        } catch (...) {
            ort_version_info_holder = "调用 ONNXRuntime C API 时发生未知错误。";
        }
        
        return ort_version_info_holder.c_str();
    }
}


extern "C" {
    /*FFI_EXPORT*/ int qwq_add_int(int a, int b) {
        return add::add(a, b);
    }
    /*FFI_EXPORT*/ double qwq_add_double(double a, double b) {
        return add::add(a, b);
    }

    /*FFI_EXPORT*/ const char* qwq_opencv() {
        return add::test_opencv_version();
    }

    /* FFI_EXPORT */ const char* qwq_onnxruntime() {
        return add::test_onnxruntime_api_version();
    }
}
