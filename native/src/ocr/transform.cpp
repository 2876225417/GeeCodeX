

#include <cstddef>
#include <ocr/transform.h>
#include <opencv2/core.hpp>
#include <opencv2/core/mat.hpp>
#include <opencv2/imgcodecs.hpp>
#include <vector>


namespace geecodex::ocr{
    inline auto 
    encoded_img_2_cv_mat(encoded2mat& trans_params)-> cv::Mat {
        auto [encoded_img, data_length, err_msg] = trans_params;
        err_msg.clear();

        if (encoded_img == nullptr || data_length <= 0) {
            err_msg = "Error: Input image data is invalid or its length is zero";
            std::cerr << err_msg << '\n';
            return cv::Mat{};
        }

        try {
            // Do not use pointer alrithmetic
            std::vector<uchar> img_buffer{encoded_img, encoded_img + data_length};
            cv::Mat img = cv::imdecode(img_buffer, cv::IMREAD_COLOR);

            if (img.empty()) {
                err_msg = "Error: Failed to decode image data by OpenCV. Image data probably not valid.";
                std::cerr << err_msg << '\n';
                return cv::Mat{};
            }
            std::cout << "Decode image data successfully. Size: " 
                      << img.cols << "x" << img.rows
                      << ", channels: " << img.channels() << '\n';
            return img;
        } catch (const cv::Exception& e) {
            err_msg = "";
            std::cerr << err_msg << '\n';
        } catch (const std::exception& e) {
            err_msg = "";
        } catch (...) {
            err_msg = "";
        }
        return cv::Mat{};
    }

} // namespace geecodex::ocr