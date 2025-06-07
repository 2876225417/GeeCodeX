#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <common/logger.hpp>

TEST(logger_test, print_all_log_types) {
    testing::internal::CaptureStdout();
    
    log_info("Test Info Message in {}", "CYAN");
    std::string output = testing::internal::GetCapturedStdout();

    using ::testing::HasSubstr;
    EXPECT_THAT(output, HasSubstr("[INFO]"));
    EXPECT_THAT(output, HasSubstr("Test Info Message in CYAN"));

    testing::internal::CaptureStdout();
    



}