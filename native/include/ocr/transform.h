
#ifndef TRANSFORM_H
#define TRANSFORM_H

#include <common/config.h>
#include <opencv2/opencv.hpp>

namespace geecodex::ocr {
    struct encoded2mat {
        uint8_t* encoded_img_;   // 经过编码的图像数据
        int data_length_;        // 数据长度
        std::string err_msg_;    // 错误信息
    };
    inline auto encoded_img_2_cv_mat(encoded2mat&) -> cv::Mat;

} // namespace geecodex::ocr

#endif  // TRANSFROM_H