

#include <add/add.h>
#include <exception>
#include <internal/utils.h>
#include <opencv2/core.hpp>
#include <limits>
#include <iostream>

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
}
