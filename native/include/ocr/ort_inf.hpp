

// ---------------------- //
//     ORT_INF_HPP        //
//   Usage: Detection     //
//   and    Recognition   //
//   inference with ONNX  //
// ---------------------- //

#ifndef ORT_INF_HPP
#define ORT_INF_HPP

#include <array>
#include <onnxruntime_c_api.h>
#include <onnxruntime_cxx_api.h>
#include <opencv2/core/types.hpp>
#include <opencv2/opencv.hpp>

#include <any>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>


// Enable Eigen3 to accelerate mat calculating
// DEFAULT: ENABLE_EIGEN3 FALSE
#ifdef ENABLE_EIGEN3
#include <eigen3/Eigen/Dense>
#endif

// Enable OpenMP 
// DEFAULT: ENABLE_OMP FALSE 
#ifdef ENABLE_OMP
#include <omp.h>
#endif

struct det_post_args{ cv::Mat resized_img; };
struct rec_post_args{};

struct detection_output_params {
    std::vector<float> output_;
    long height_;
    long width_;
};

struct postprocess_pramas {
    float* output_tensor_;
    std::vector<int64_t> output_shape_;
    std::any additional_args_;
};

struct expand_box_params {
    std::vector<cv::Point> box_;
    float horizontal_ratio_;
    float vertical_ratio_;
    cv::Size img_shape_;
};

struct output_values{
    float* output_tensor;
    std::vector<int64_t> output_shape;
};

// Common Inferer
template <typename InputType, typename OutputType>
class common_inferer {
protected:
    // Keep the order of the declaration of ORT members 
    Ort::Env             m_env;
    Ort::SessionOptions  m_session_options;
    Ort::Session         m_session;     
    
    std::string          m_input_name;  
    std::string          m_output_name;
    Ort::MemoryInfo      m_memory_info{nullptr};
    std::vector<int64_t> m_last_input_shape; 
    std::vector<float>   m_input_tensor_values;

#ifdef ENABLE_EIGEN3
    virtual std::tuple<std::vector<float>, cv::Mat>
    preprocess_eigen(InputType&) = 0;
#else // DEFAULT
    virtual auto 
    preprocess(InputType&) -> std::tuple<std::vector<float>, cv::Mat> = 0;
#endif

    virtual auto infer(InputType&) -> OutputType = 0;
    virtual auto postprocess(postprocess_pramas) -> OutputType = 0;
public:
    common_inferer(const std::string& model_path)
        : m_env(ORT_LOGGING_LEVEL_WARNING)
        , m_session_options{}
        , m_session{nullptr}
        , m_memory_info{Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault)}
        {
        const unsigned int num_cpu_cores = std::thread::hardware_concurrency();
        m_session_options.SetIntraOpNumThreads(static_cast<int>(num_cpu_cores) / static_cast<int>(num_cpu_cores));
        m_session_options.SetInterOpNumThreads(1);
        m_session_options.SetExecutionMode(ExecutionMode::ORT_PARALLEL);
        m_session_options.EnableMemPattern();
        m_session_options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
        m_session_options.AddConfigEntry("session.use_device_allocator_for_initializers", "1"); 
        m_session_options.EnableCpuMemArena();
        //m_session_options.DisableCpuMemArena(); This option might cause memory leak!!!
        m_session = Ort::Session(m_env, model_path.c_str(), m_session_options);

        Ort::AllocatorWithDefaultOptions allocator;
        Ort::AllocatedStringPtr input_name_ptr = m_session.GetInputNameAllocated(0, allocator);
        Ort::AllocatedStringPtr output_name_ptr = m_session.GetOutputNameAllocated(0, allocator);
        m_input_name = input_name_ptr.get();
        m_output_name = output_name_ptr.get();
    }
    ~common_inferer() = default;
};


// Detection Indferer
class det_inferer: public common_inferer<cv::Mat, std::vector<cv::Mat>> {
private:
    std::vector<std::vector<cv::Point>> m_boxes_cache;
public:
    inline auto
    postprocess(postprocess_pramas params) -> std::vector<cv::Mat> override {
        const auto& args = std::any_cast<det_post_args>(params.additional_args_);
        cv::Mat resized_img = args.resized_img;
        std::vector<cv::Mat> croppeds{};
        long output_h = params.output_shape_[2];
        long output_w = params.output_shape_[3];

        std::vector<float> output_data(params.output_tensor_, params.output_tensor_ + output_w * output_h);
        auto boxes = process_detection_output({.output_ = output_data, .height_ = output_h, .width_=output_w});

        cv::Mat vis_img;
        cv::cvtColor(resized_img, vis_img, cv::COLOR_RGB2BGR);
        
        croppeds.reserve(boxes.size());
        // Due to the default croppeds are smaller than it should be
        // Then, xpand the cropped in horizontal and vertical
        for (const auto & boxe : boxes) {
            const float horizontal_ratio = 0.2f;
            const float vertical_ratio = 0.5f;

            cv::Rect expanded_rect = expand_box({.box_=boxe, .horizontal_ratio_=horizontal_ratio, .vertical_ratio_=vertical_ratio, .img_shape_=vis_img.size()});
            cv::Mat  cropped = vis_img(expanded_rect).clone();
            croppeds.push_back(cropped);
        }
        return croppeds;
    }

    inline auto infer(cv::Mat& frame) 
    -> std::vector<cv::Mat> override {
        std::vector<cv::Mat> det_croppeds{}; 
        try {
        #ifdef DEBUG
            auto start_preprocess_det = std::chrono::high_resolution_clock::now(); 
        #endif

            cv::Mat resized_img;
            std::vector<float> input_tensor_values;
            
        #ifdef ENABLE_EIGEN3
            std::tie(input_tensor_values, resized_img) = preprocess_eigen3(frame);
        #else
            std::tie(input_tensor_values, resized_img) = preprocess(frame);
        #endif

        #ifdef DEBUG
            auto end_process_det = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_process_det - start_preprocess_det);
        #endif

            std::vector<int64_t> input_shape = {1, 3, resized_img.rows, resized_img.cols};
            
            // Check the current and last input shape
            // If the same, then, no need to create tensor again
            // otherwise, create new tensor
            bool shape_changed = (m_last_input_shape != input_shape);
            if (shape_changed) m_last_input_shape = input_shape;
            
            Ort::Value input_tensor = Ort::Value::CreateTensor<float>(
                m_memory_info, input_tensor_values.data(), input_tensor_values.size(),
                input_shape.data(), input_shape.size());

            std::array<const char*, 1> input_names = {m_input_name.c_str()};
            std::array<const char*, 1> output_names = {m_output_name.c_str()};
            std::vector<Ort::Value> outputs = m_session.Run(
                    Ort::RunOptions{nullptr},
                    input_names.data(), &input_tensor, 1,
                    output_names.data(), 1);


            
            auto* output_tensor = outputs[0].GetTensorMutableData<float>();
            auto output_shape = outputs[0].GetTensorTypeAndShapeInfo().GetShape();
            det_post_args args{resized_img}; 
            return postprocess({.output_tensor_= output_tensor, .output_shape_=output_shape, .additional_args_=args});
        } catch (const Ort::Exception& e) {
            
        } catch (const std::exception& e) {
           
        }
       
        return det_croppeds;
    }

    #ifdef ENABLE_EIGEN3
    std::tuple<std::vector<float>, cv::Mat>
    preprocess_eigen(cv::Mat& frame)  override {
        if (frame.empty()) { qDebug() << "Invalid input frame"; }

        cv::Mat rgb_img;
        cv::cvtColor(frame, rgb_img, cv::COLOR_BGR2RGB);

        int max_size = 960;
        float scale = max_size / static_cast<float>(std::max(rgb_img.cols, rgb_img.rows));

        int new_w = static_cast<int>(rgb_img.cols * scale) / 32 * 32;
        int new_h = static_cast<int>(rgb_img.rows * scale) / 32 * 32;
        cv::Mat resized_img;
        cv::resize(rgb_img, resized_img, cv::Size(new_w, new_h));

        cv::Mat float_img;
        resized_img.convertTo(float_img, CV_32FC3, 1.f / 255.f);

        // 预分配内存
        if (m_input_tensor_values.size() < 1 * 3 * new_h * new_w) {
            m_input_tensor_values.resize(1 * 3 * new_h * new_w);
        }

        Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>>
            eigen_img((float*)float_img.data, new_h, new_w * 3);

        #pragma omp parallel for collapse(2)
        for (int c = 0; c < 3; c++) {
            for (int h =0; h < new_h; h++) {
                #pragma omp simd
                for (int w = 0; w < new_w; w++) {
                    m_input_tensor_values[c * new_h * new_w + h * new_w + w] = eigen_img(h, w * 3 + c);
                }
            }
        }
        return {m_input_tensor_values, resized_img};
    }
    #else
    auto preprocess(cv::Mat& frame) 
    ->std::tuple<std::vector<float>, cv::Mat> override {
        if (frame.empty()) {  }

        cv::Mat rgb_img;
        cv::cvtColor(frame, rgb_img, cv::COLOR_BGR2RGB);

        const int max_size = 960;
        float scale = max_size / static_cast<float>(std::max(rgb_img.cols, rgb_img.rows));
        
        const int resize_ratio = 32;
        int new_w = static_cast<int>(rgb_img.cols * scale) / resize_ratio * resize_ratio;
        int new_h = static_cast<int>(rgb_img.rows * scale) / resize_ratio * resize_ratio;
        cv::Mat resized_img;
        cv::resize(rgb_img, resized_img, cv::Size(new_w, new_h));

        cv::Mat float_img;
        resized_img.convertTo(float_img, CV_32FC3, 1.f / 255.f);
        
        // Allocate memory
        if (static_cast<int>(m_input_tensor_values.size()) < 1 * 3 * new_h * new_w) {
            m_input_tensor_values.resize(static_cast<unsigned long>(1) * 3 * new_h * new_w);
        }

        for (int c = 0; c < 3; c++) {
            for (int h = 0; h < new_h; h++) {
                for (int w = 0; w < new_w; w++) {
                    m_input_tensor_values[c * new_h * new_w + h * new_w + w] = 
                        float_img.at<cv::Vec3f>(h, w)[c];
                }
            }
        }
        return  { m_input_tensor_values, resized_img };
    }
    #endif

    inline auto
    process_detection_output( detection_output_params det_output 
                            , float threshold = 0.3f
                            ) -> std::vector<std::vector<cv::Point>> {
        cv::Mat score_map( static_cast<int>(det_output.height_), static_cast<int>(det_output.width_)
                         , CV_32F
                         , det_output.output_.data()
                         ) ;

        cv::Mat binary_map;
        cv::threshold(score_map, binary_map, threshold, 255, cv::THRESH_BINARY);
        binary_map.convertTo(binary_map, CV_8UC1);

        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(binary_map, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

        // Reuse boxes cache
        m_boxes_cache.clear();
        m_boxes_cache.reserve(contours.size());
        
        for (const auto& cnt: contours) {
            cv::RotatedRect rect = cv::minAreaRect(cnt);
            std::array<cv::Point2f, 4> vertices;
            rect.points(vertices.data());

            std::vector<cv::Point> box;
            box.reserve(4);
            for (int i = 0; i < 4; i++)
                box.emplace_back( static_cast<int>(vertices[i].x)
                                , static_cast<int>(vertices[i].y));
            m_boxes_cache.push_back(box);
        }
        return m_boxes_cache;
    }

    inline auto
    expand_box(expand_box_params box_params) -> cv::Rect{
        cv::Rect rect = cv::boundingRect(box_params.box_);

        int dx = static_cast<int>(static_cast<float>(rect.width) * box_params.horizontal_ratio_);
        int dy = static_cast<int>(static_cast<float>(rect.height) * box_params.vertical_ratio_);

        int new_x = std::max(0, rect.x - dx);
        int new_y = std::max(0, rect.y - dy);
        int new_w = std::min(box_params.img_shape_.width - new_x, rect.width + 2 * dx);
        int new_h = std::min(box_params.img_shape_.height - new_y, rect.height + 2 * dy);

        return cv::Rect{new_x, new_y, new_w, new_h};
    }

public:
    det_inferer(const std::string& model_path = "det_gen.onnx")
        : common_inferer<cv::Mat, std::vector<cv::Mat>>(model_path) 
        { }

    auto run_inf(cv::Mat& frame) -> std::vector<cv::Mat> { return infer(frame); }
    void set_det_threshold(float threshold) { }
};

#include <fstream>
// Recognition Inferer
class rec_inferer: public common_inferer<cv::Mat, std::string> {
private:
    std::vector<std::string> m_char_dict;
    const int TARGET_HEIGHT = 48;
    
    std::vector<int> m_sequence_preds;
    std::vector<std::string> m_result_cache;

    void load_chars(const std::string& dict_path) {
        m_char_dict.clear();
        std::ifstream file(dict_path.c_str());
        std::string line;
        if (!file.is_open()) throw std::runtime_error("Can not open chars dict: " + dict_path);

        while (std::getline(file, line)) {
            line.erase(0, line.find_first_not_of(" \t"));
            line.erase(line.find_last_not_of(" \t") + 1);
            
            if (!line.empty()) m_char_dict.push_back(line);
        }
    }

    // preprocess
    #ifdef ENABLE_EIGEN
    inline std::tuple<std::vector<float>, cv::Mat>
    preprocess_eigen(cv::Mat& frame) override {
        cv::Mat img = frame.clone();
        if (img.empty()) throw std::runtime_error("Invalid input frame");

        cv::cvtColor(img, img, cv::COLOR_BGR2RGB);
        
        int width = static_cast<int>(img.cols * (static_cast<float>(TARGET_HEIGHT) / img.rows));

        cv::Mat resized_img;
        cv::resize(img, resized_img, cv::Size(width, TARGET_HEIGHT));

        resized_img.convertTo(resized_img, CV_32F, 1.f / 255.f);

        // 预分配内存
        if (m_input_tensor_values.size() < TARGET_HEIGHT * width * 3) {
            m_input_tensor_values.resize(TARGET_HEIGHT * width * 3);
        }

        Eigen::Map<Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>>
            eigen_img((float*)resized_img.data, TARGET_HEIGHT, width * 3);

        #pragma omp parallel for collapse(2) 
        for (int c = 0; c < 3; c++) {
            for (int h = 0; h < TARGET_HEIGHT; h++) {
                #pragma omp simd
                for (int w = 0; w < width; w++) {
                    m_input_tensor_values[c * TARGET_HEIGHT * width + h * width + w] = eigen_img(h, w * 3 + c);
                }
            }
        }
        return {m_input_tensor_values, resized_img};
    }
    #else
    inline auto 
    preprocess(cv::Mat& frame) -> std::tuple<std::vector<float>, cv::Mat> override {
        cv::Mat img = frame.clone();
        if (img.empty()) throw std::runtime_error("Invalid input frame!");

        cv::cvtColor(img, img, cv::COLOR_BGR2RGB);

        int width = static_cast<int>(static_cast<float>(img.cols) * (static_cast<float>(TARGET_HEIGHT) / static_cast<float>(img.rows)));
        
        cv::Mat resized_img;
        cv::resize(img, resized_img, cv::Size(width, TARGET_HEIGHT));

        resized_img.convertTo(resized_img, CV_32F, 1.f / 255.f);

        // Allocate memory
        if (static_cast<int>(m_input_tensor_values.size()) < TARGET_HEIGHT * width * 3) {
            m_input_tensor_values.resize(static_cast<unsigned long>(TARGET_HEIGHT) * width * 3);
        }
        
        size_t idx = 0;
        for (int c = 0; c < 3; c++) {
            for (int h = 0; h < resized_img.rows; h++) {
                for (int w = 0; w < resized_img.cols; w++) {
                    m_input_tensor_values[idx++] = resized_img.at<cv::Vec3f>(h, w)[c];
                }
            }
        } 
        return { m_input_tensor_values, resized_img};
    }
    #endif

    // postprocess
    inline auto  
    postprocess(postprocess_pramas postprocess_params) -> std::string override {
        m_sequence_preds.clear();
        long sequence_length = postprocess_params.output_shape_[1];
        long num_classes = postprocess_params.output_shape_[2];

        #ifdef ENABLE_EIGEN3
        Eigen::Map<const Eigen::Matrix<float, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>>
            output_eigen(output_tensor, sequence_length, num_classes);

        for(int t = 0; t < sequence_length; ++t) {
            Eigen::Index max_idx;
            output_eigen.row(t).maxCoeff(&max_idx);
            m_sequence_preds.push_back(static_cast<int>(max_idx));
        } 
        #else
        for (int t = 0; t < sequence_length; ++t) {
            float max_prob = -1.f;
            int max_idx = -1;

            for (int c = 0; c < num_classes; ++c) {
                float prob = postprocess_params.output_tensor_[t * num_classes + c];
                if (prob > max_prob) {
                    max_prob = prob;
                    max_idx = c;
                }
            }
            m_sequence_preds.push_back(max_idx);
        }
        #endif

        m_result_cache.clear();
        int last_char_idx = -1;
        
        for (int idx: m_sequence_preds) {
            if (idx != last_char_idx) {
                int adjusted_idx = idx - 1;
                if (adjusted_idx >= 0 && adjusted_idx < m_char_dict.size()) {
                    std::string current_char = m_char_dict[adjusted_idx];
                    if (current_char != "■" && current_char != "<blank>" && current_char != " ") {
                        m_result_cache.push_back(current_char);
                    }
                    last_char_idx = idx;
                }
            }
        }

        std::string final_str;
        for (const auto& c: m_result_cache) final_str += c;
        return final_str;
   }

    inline std::string
    infer(cv::Mat& frame) override {
        try {
        #ifdef DBEUG
            auto start_preprocess = std::chrono::high_resolution_clock::now();
        #endif
            cv::Mat resized_img;
            
            #ifdef ENABLE_EIGEN
            std::tie(m_input_tensor_values, resized_img) = preprocess_eigen(frame);  
            #else
            std::tie(m_input_tensor_values, resized_img) = preprocess(frame);
            #endif
        #ifdef DEBUG
            auto end_preprocess = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end_preprocess - start_preprocess);
        #endif
        
            std::vector<int64_t> input_shape = {1, 3, resized_img.rows, resized_img.cols};
            
            bool shape_changed = (m_last_input_shape != input_shape);
            if (shape_changed) {
                m_last_input_shape = input_shape;
            }

            Ort::Value input_tensor = Ort::Value::CreateTensor<float>(
                m_memory_info, m_input_tensor_values.data(), m_input_tensor_values.size(),
                input_shape.data(), input_shape.size()
            );

            std::array<const char*, 1> input_names = {m_input_name.c_str()};
            std::array<const char*, 1> output_names = {m_output_name.c_str()}; 

            std::vector<Ort::Value> outputs = m_session.Run(
                Ort::RunOptions{nullptr},
                input_names.data(), &input_tensor, 1,
                output_names.data(), 1
            );

            auto* output_tensor = outputs[0].GetTensorMutableData<float>();
            auto output_shape = outputs[0].GetTensorTypeAndShapeInfo().GetShape();
    
            return postprocess({.output_tensor_=output_tensor, .output_shape_=output_shape, .additional_args_={}});
        } catch (const Ort::Exception& e) {

        } catch (const std::exception& e) {
                   }
        return {};
    }
    
    
public:
    rec_inferer(const std::string& model_path = "rec_gen.onnx")
        : common_inferer<cv::Mat, std::string>(model_path)
        { load_chars("chars.txt"); }

    std::string run_inf(cv::Mat& frame) { return infer(frame); }
    void set_char_dict(const std::string& char_dict_path) { }
};

#endif // ORT_INF_HPP