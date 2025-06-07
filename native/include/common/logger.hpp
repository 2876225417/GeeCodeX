

#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <cstdint>
#include <iostream>
#include <string>
#include <string_view>
#include <utility>
#include <vector>
#include <magic_enum/magic_enum.hpp>
#include <type_traits>

#if defined (USE_STD_FMT)
#include <format>
namespace app_format_ns = std;
template <typename... Args>
using app_format_string = std::format_string<Args...>;
template <typename... Args>
auto make_format_args(Args&&... args) {
    return std::make_format_args(std::forward<Args>(args)...);
}
#elif defined (USE_EXTERNAL_FMT)
#include <fmt/core.h>
#include <fmt/format.h>
namespace app_format_ns = fmt;
template <typename... Args>
using app_format_string = fmt::format_string<Args...>;
template <typename... Args>
auto make_format_args(Args&&... args) {
    return fmt::make_format_args(std::forward<Args>(args)...);
}
#else
#include <sstream>
namespace app_format_ns {
    template <typename... Args>
    auto format(const std::string& fmt_str, Args&&... args) -> std::string {
        std::ostringstream oss;
        oss << fmt_str;
        ((oss << " " << args), ...);
        return oss.str();
    }
} // namespace app_format_ns
using app_format_string_basic = const std::string&;
template <typename... Args>
using app_format_string = app_format_string_basic;
#endif

namespace console_style {
enum class Color: std::int8_t {
    RESET,
    BLACK,
    RED,
    GREEN,
    YELLOW,
    BLUE,
    MAGENTA,
    CYAN,
    WHITE
};


#if defined(USE_CPP_COLORED_DEBUG_OUTPUT)
constexpr auto 
get_color_code(Color color) 
noexcept -> std::string_view{
    switch (color) {
        case Color::RESET  : return "\033[0m";
        case Color::BLACK  : return "\033[30m"; 
        case Color::RED    : return "\033[1;31m"; 
        case Color::GREEN  : return "\033[1;32m"; 
        case Color::YELLOW : return "\033[1;33m";
        case Color::BLUE   : return "\033[1;34m";
        case Color::MAGENTA: return "\033[1;35m";
        case Color::CYAN   : return "\033[0;36m";
        case Color::WHITE  : return "\033[1;37m";
        default: return "";
    }
}

#else
constexpr auto
get_color_code(Color /* color */)
noexcept -> std::string_view{
    return "";
}
#endif
} // namespace console_style


template <bool IsBuildTests>
struct logger_traits { using return_type = void; };

template <>
struct logger_traits<true> { using return_type = bool; };

#ifdef BUILD_TESTS
constexpr bool is_test_build = true;
#else
constexpr bool is_test_build = false;
#endif

using LoggerRetType = typename logger_traits<is_test_build>::return_type;


#if defined(USE_STD_FMT) || defined(USE_EXTERNAL_FMT)
enum class LogLevel: std::int8_t {
    INFO,
    SUCCESS,
    WARNING,
    ERROR,
    FATAL_ERORR
};


template <size_t N>
struct fixed_string {
    std::array<char, N + 1> data_ = {};
    
    constexpr fixed_string(const std::array<char, N + 1>& str) {
    #if __cplusplus <= 202002L
        for (size_t i = 0; i <= N; ++i) 
            data_[i] = str[i];
    #else
        std::copy_n(str.data(), N + 1, data_.data());
    #endif
    }

    constexpr fixed_string(std::string_view sv) {
    #if __cplusplus <= 202002L
        for (size_t i = 0; i < N; ++i)
            data_[i] = sv[i];
    #else
        std::copy_n(sv.data(), N, data_.data());
    #endif
    }

    constexpr operator std::string_view() const {
        return {data_.data(), N};
    }
    
    [[nodiscard]] constexpr auto size() const -> size_t { return N; }
};

template <size_t N, size_t M>
constexpr auto 
operator+( const fixed_string<N>& lhs
         , const fixed_string<M>& rhs
         ) -> fixed_string<N + M> {
    std::array<char, N + M + 1> new_data = {};
#if __cplusplus <= 202002L
    for (size_t i = 0; i <= N; ++i)
         new_data[i] = lhs.data_[i];

    for (size_t i = 0; i <= M; ++i)
        new_data[N + i] = rhs.data_[i];
#else
    new_data[N + M] = '\0';
    std::copy_n(lhs.data_.data(), N, new_data.data());
    std::copy_n(rhs.data_.data(), M, new_data.data() + N);
#endif
    return fixed_string<N + M>(new_data);
}

constexpr auto 
color2level(LogLevel level) 
noexcept -> console_style::Color {
    switch (level) {
        case LogLevel::INFO:        return console_style::Color::CYAN;
        case LogLevel::SUCCESS:     return console_style::Color::YELLOW;
        case LogLevel::WARNING:     return console_style::Color::RED;
        case LogLevel::ERROR:       return console_style::Color::RED;
        case LogLevel::FATAL_ERORR: return console_style::Color::RED;
        default:                    return console_style::Color::RESET;
    }
}

struct log_attributes {
    console_style::Color color_;
    std::string_view     tag_;
};

template <LogLevel level>
struct log_level_traits {
private:
    static constexpr auto name_sv = magic_enum::enum_name<level>();
    
    // 文本输出对齐处理
    static constexpr size_t max_name_len = 7;
    static constexpr size_t padding_size = max_name_len > name_sv.size() ? max_name_len - name_sv.size() : 0;

    static constexpr auto 
    generate_tag() { /* 如 [SUCCESS] */
        fixed_string<1> left_bracket = std::string_view("[");
        fixed_string<1> right_bracket = std::string_view("]");
        // 从 8 个空格中取出对应数量的空格
        fixed_string<padding_size> padding(std::string_view("            ", padding_size));
        
        return left_bracket + fixed_string<name_sv.size()>(name_sv) + right_bracket + padding;
    }
    static constexpr auto generate_tag_object = generate_tag();
public:
    static constexpr log_attributes value {
        .color_ = color2level(level),
        .tag_   = generate_tag_object
    };
};


template<LogLevel level, typename... Args>
auto log( app_format_string<Args...> fmt_str
        , Args&&... args) -> decltype(LoggerRetType())
        {
    auto [color, tag] = log_level_traits<level>::value;
    
    std::cout << console_style::get_color_code(color) << tag
              << console_style::get_color_code(console_style::Color::RESET)
              << app_format_ns::vformat(fmt_str.get(), make_format_args(std::forward<Args>(args)...))
              << std::endl;

    if constexpr (is_test_build) return true;
}

#endif




#endif // LOGGER_HPP