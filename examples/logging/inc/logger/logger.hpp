#pragma once

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <memory>
#include <string>
#include <format>

namespace logger {

enum class LogLevel {
    Debug,
    Info,
    Warning,
    Error,
    Critical
};

// Simple logger creation function
std::shared_ptr<spdlog::logger> CreateLogger(LogLevel level, const std::string& name);

} // namespace logger
