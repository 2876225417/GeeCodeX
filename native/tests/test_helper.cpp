

#include <cstdint>
#include <exception>
#include <filesystem>
#include <fstream>
#include <ios>
#include <iostream>
#include <stdexcept>
#include <unistd.h>
#include <vector>

#include <test_helper.h>

namespace geecodex::native::test::helper {

auto read_file2vec(const std::string& filename) -> std::vector<uint8_t>  {
    std::ifstream file(filename, std::ios::binary | std::ios::ate);
    if (!file.is_open())
        throw std::runtime_error("Failed to open test file: " + filename);
    
    std::streamsize size = file.tellg();
    file.seekg(0, std::ios::beg);
    std::vector<uint8_t> buffer(size);
    file.read(reinterpret_cast<char*>(buffer.data()), size);
    return buffer;
}

auto get_current_working_dir() -> std::string {
    try {
        return std::filesystem::current_path().string(); 
    } catch (const std::filesystem::filesystem_error& e) {
        std::cerr << "Error getting current working directory: " << e.what() << '\n'  ;
        return "";
    }
}
} // namespace geecodex::native::test::helper