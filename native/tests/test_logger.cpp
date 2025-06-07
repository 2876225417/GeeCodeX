#include <gtest/gtest.h>

#include <common/logger.hpp>

TEST(logger_test, print_all_log_types) {
    log_info("This is nfo");
    SUCCEED();

}