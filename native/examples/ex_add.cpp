

#include <cstdlib>
#include <iostream>
#include <add/add.h>

auto main(int argc, char* argv[]) -> decltype(int()) {
    std::cout << "2 + 3 = " << add::add(2, 3) << std::endl;

    std::cout << "2.5 + 3.5 = " << add::add(2.5, 3.5) << std::endl;

    return EXIT_SUCCESS;
}