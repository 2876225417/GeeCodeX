


#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <ocr/transform.h>
#include <opencv2/core/mat.hpp>
#include "test_helper.cpp"

TEST(ocr_test, handle_null_ptr) {
    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = nullptr;
    params.data_length_ = 1024;

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_TRUE(result.empty());
    ASSERT_NE(params.err_msg_.find("Input image data is invalid"), std::string::npos);
}

TEST(ocr_test, decode_valid_jpeg) {
    auto img_data = geecodex::native::test::helper::read_file2vec("test_src/chars_1.jpg");

    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = img_data.data();
    params.data_length_ = img_data.size();

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_FALSE(result.empty());
    ASSERT_TRUE(params.err_msg_.empty());
    // ASSERT_EQ(result.cols, /* width */);
    // ASSERT_EQ(result., /* height */);
}