

#include <add/add.h>
#include <internal/utils.h>

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
}


extern "C" {
    ADD_API int qwq_add_int(int a, int b) {
        return add::add(a, b);
    }
    ADD_API double qwq_add_double(double a, double b) {
        return add::add(a, b);
    }
}
