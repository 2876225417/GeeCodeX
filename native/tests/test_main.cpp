
// ----------------------- //
//    Project: Geecodex    //
//                         //
//          TEST           //
//                         //
// ----------------------- //


#if defined(BUILD_TESTS_VERBOSE)

#include <gtest/gtest.h>
#include <iostream>
#include <test_helper.h>


/* Avoid to use common/logger.hpp
 * cause it's a part of target test
 * #include <common/logger.hpp>
 */

class glob_test_env: public ::testing::Environment {
public:
    void SetUp() override {
        std::cout << "==========================================================" << '\n';
        std::cout << "               GLOBAL TEST ENVIRONMENT SETUP              " << '\n';
        std::cout << "==========================================================" << '\n';
        
        std::string cwd = geecodex::native::test::helper::get_current_working_dir();
        std::cout << "Tests are running from directory: " << cwd << '\n';
        std::cout << "----------------------------------------------------------" << '\n';
    }

    void TearDown() override {
        std::cout << "----------------------------------------------------------" << '\n';
        std::cout << "               GLOBAL TEST ENVIRONMENT TEARDOWN           " << '\n';
        std::cout << "==========================================================" << '\n';
    }
};

auto main(int argc, char* argv[]) -> decltype(int()) {
    ::testing::InitGoogleTest(&argc, argv);
    
    ::testing::AddGlobalTestEnvironment(new glob_test_env);

    return RUN_ALL_TESTS();
}


#endif 