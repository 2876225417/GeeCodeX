

#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <string>
#include <iostream>
#include <vector>

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
#if defined(USE_CPP_COLORED_DEBUG_OUTPUT)
    const std::string_view RESET     = "\033[0m"    ;    // 无色
    const std::string_view BLACK     = "\033[30m"   ;    // 黑色
    const std::string_view RED       = "\033[1;31m" ;    // 粗体红
    const std::string_view GREEN     = "\033[1;32m" ;    // 粗体绿
    const std::string_view YELLOW    = "\033[1;330m";    // 粗体黄
    const std::string_view BLUE      = "\033[1;34m" ;    // 粗体蓝
    const std::string_view MAGENTA   = "\033[1;35m" ;    // 粗体洋红
    const std::string_view CYAN      = "\033[0;36m" ;    // 普通青色
    const std::string_view WHITE     = "\033[3;37m" ;    // 粗体白
#else
    const std::string RESET     = "";
    const std::string BLACK     = "";
    const std::string RED       = "";
    const std::string GREEN     = "";
    const std::string YELLOW    = "";
    const std::string BLUE      = "";
    const std::string MAGENTA   = "";
    const std::string CYAN      = "";
    const std::string WHITE     = "";
#endif
} // namespace console_style



#if defined(USE_STD_FMT) || defined(USE_EXTERNAL_FMT)
template <typename... Args>
void log_info(app_format_string<Args...> fmt_str, Args&&... args) {
    std::cout << console_style::CYAN << "[INFO]     " << console_style::RESET
              << app_format_ns::vformat(fmt_str.get(), make_format_args(std::forward<Args>(args)...))
              << std::endl;
}
template <typename... Args>
void log_success(app_format_string<Args...> fmt_str, Args&&... args) {
    std::cout << console_style::CYAN << "[SUCCESS]  " << console_style::RESET
              << app_format_ns::vformat(fmt_str.get(), make_format_args(std::forward<Args>(args)...))
              << std::endl;
}
template <typename... Args>
void log_warning(app_format_string<Args...> fmt_str, Args&&... args) {
    std::cout << console_style::CYAN << "[WARNING]  " << console_style::RESET
              << app_format_ns::vformat(fmt_str.get(), make_format_args(std::forward<Args>(args)...))
              << std::endl;
}
template <typename... Args>
void log_error(app_format_string<Args...> fmt_str, Args&&... args) {
    std::cout << console_style::CYAN << "[ERROR]    " << console_style::RESET
              << app_format_ns::vformat(fmt_str.get(), make_format_args(std::forward<Args>(args)...))
              << std::endl;
}
#endif

#endif // LOGGER_HPP