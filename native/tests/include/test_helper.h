


#ifndef TEST_HELPER_H
#define TEST_HELPER_H

#include <iostream>
#include <vector>

namespace geecodex::native::test::helper {

auto read_file2vec(const std::string& filename) -> std::vector<uint8_t>;

auto get_current_working_dir() -> std::string;

} // namespace geecodex::native::test::helper
#endif // TEST_HELPER_H