#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <common/logger.hpp>
#include <stdexcept>

TEST(logger_test, print_all_log_types) {
    testing::internal::CaptureStdout();
    std::string output;    
    using ::testing::HasSubstr;
    
    log<LogLevel::INFO>("Test Info Message in {}", "CYAN");
    output = testing::internal::GetCapturedStdout();
    std::cout << output;
    EXPECT_THAT(output, HasSubstr("[INFO]"));
    EXPECT_THAT(output, HasSubstr("Test Info Message in CYAN"));

    testing::internal::CaptureStdout();
    log<LogLevel::SUCCESS>("Test Success Message in {}", "YELLOW");
    output = testing::internal::GetCapturedStdout();
    std::cout << output;
    EXPECT_THAT(output, HasSubstr("[SUCCESS]"));
    EXPECT_THAT(output, HasSubstr("Test Success Message in YELLOW"));
    
    testing::internal::CaptureStdout();
    log<LogLevel::WARNING>("Test Warning Message in {}", "RED");
    output = testing::internal::GetCapturedStdout();
    std::cout << output;
    EXPECT_THAT(output, HasSubstr("[WARNING]"));
    EXPECT_THAT(output, HasSubstr("Test Warning Message in RED"));

    testing::internal::CaptureStdout();
    log<LogLevel::ERROR>("Test Error Message in {}", "RED");
    output = testing::internal::GetCapturedStdout();
    std::cout << output;
    EXPECT_THAT(output, HasSubstr("[ERROR]"));
    EXPECT_THAT(output, HasSubstr("Test Error Message in RED"));

    testing::internal::CaptureStdout();
    log<LogLevel::FATAL_ERROR>("Test Fatal Error Message in {}", "RED");
    output = testing::internal::GetCapturedStdout();
    std::cout << output;
    EXPECT_THAT(output, HasSubstr("[FATAL ERROR]"));
    EXPECT_THAT(output, HasSubstr("Test Fatal Error Message in RED"));



}