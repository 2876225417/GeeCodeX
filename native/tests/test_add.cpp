

#include <gtest/gtest.h>
#include <add/add.h>

TEST(AddTest, AddIntegers) {
    EXPECT_EQ(add::add(2, 3), 5);
    EXPECT_EQ(add::add(-2, 3), 1);
    EXPECT_EQ(add::add(0, 0), 0);
}

TEST(AddTest, AddDoubles) {
    EXPECT_DOUBLE_EQ(add::add(2.5, 3.5), 6.0);
    EXPECT_DOUBLE_EQ(add::add(-2.5, 3.5), 1.0);
    EXPECT_DOUBLE_EQ(add::add(0.0, 0.0), 0.0);
}
