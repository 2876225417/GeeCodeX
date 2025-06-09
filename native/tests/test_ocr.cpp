


#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <ocr/ort_inf.hpp>
#include <ocr/transform.h>
#include <opencv2/core/hal/interface.h>
#include <opencv2/core/mat.hpp>
#include <test_helper.h>

TEST(ocr_test, handle_null_ptr) {
    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = nullptr;
    params.data_length_ = 1024;

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_TRUE(result.empty());
    ASSERT_NE(params.err_msg_.find("Input image data is invalid"), std::string::npos);
}

TEST(ocr_test, decode_valid_jpeg) {
    
    /* Here using relative path to find pic sources 
     * also can use CMake to copy the assets to the tests working directory
     * ex. native/build/tests
     */
    auto img_data = 
        geecodex::native::test::helper::read_file2vec("../../tests/test_src/chars_1.jpg");

    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = img_data.data();
    params.data_length_ = img_data.size();

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_FALSE(result.empty());
    ASSERT_TRUE(params.err_msg_.empty());
    ASSERT_EQ(result.cols, 501/* width */);
    ASSERT_EQ(result.rows, 697/* height */);
    ASSERT_EQ(result.channels(), 3/* channels */);
    ASSERT_EQ(result.type(), CV_8UC3/* type */);
}

TEST(ocr_test, handle_zero_length) {
    std::vector<uint8_t> dummy_data{0x01}; // valid pointer
    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = dummy_data.data();
    params.data_length_ = 0;

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_TRUE(result.empty());
    ASSERT_NE(params.err_msg_.find("length is zero"), std::string::npos);
}

TEST(ocr_test, decode_corrupted_jpeg) {
    auto img_data = geecodex::native::test::helper::read_file2vec("../../tests/test_src/chars_1.jpg");
    std::vector<uint8_t> corrupted_data(img_data.begin(), img_data.begin() + 20);

    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = corrupted_data.data();
    params.data_length_ = corrupted_data.size();

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);
    
    ASSERT_TRUE(result.empty());
    ASSERT_NE(params.err_msg_.find("Failed to decode"), std::string::npos);
}

#ifdef SKIP_TEST
TEST(ocr_test, decode_grayscale_image) {
    auto img_data = geecodex::native::test::helper::read_file2vec("../../tests/test_src/grayscale.jpg");

    geecodex::ocr::encoded2mat params;
    params.encoded_img_ = img_data.data();
    params.data_length_ = img_data.size();

    cv::Mat result = geecodex::ocr::encoded_img_2_cv_mat(params);

    ASSERT_FALSE(result.empty());
    ASSERT_TRUE(params.err_msg_.empty());

    ASSERT_EQ(result.channels(), 3);
}
#endif

TEST(ocr_test, load_chars_from_src) {

}

TEST(ocr_test, init_onnxruntime_env) {

}

TEST(ocr_test, run_onnx_inf) {

}