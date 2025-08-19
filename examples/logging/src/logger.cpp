#include "logger/logger.hpp"
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <iostream>

namespace logger {

std::shared_ptr<spdlog::logger> CreateLogger(LogLevel level, const std::string& name) {
    try {
        // Create sinks
        auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        console_sink->set_level(spdlog::level::debug);
        console_sink->set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%n] [%^%l%$] %v");

        auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(name + ".log", true);
        file_sink->set_level(spdlog::level::debug);
        file_sink->set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%n] [%l] %v");

        // Create logger with both sinks
        std::vector<spdlog::sink_ptr> sinks {console_sink, file_sink};
        auto logger = std::make_shared<spdlog::logger>(name, sinks.begin(), sinks.end());
        
        // Set requested level
        spdlog::level::level_enum spdlog_level;
        switch (level) {
            case LogLevel::Debug: spdlog_level = spdlog::level::debug; break;
            case LogLevel::Info: spdlog_level = spdlog::level::info; break;
            case LogLevel::Warning: spdlog_level = spdlog::level::warn; break;
            case LogLevel::Error: spdlog_level = spdlog::level::err; break;
            case LogLevel::Critical: spdlog_level = spdlog::level::critical; break;
        }
        
        logger->set_level(spdlog_level);
        logger->flush_on(spdlog::level::err);
        
        // Register with spdlog
        spdlog::register_logger(logger);
        
        logger->info("Logger '" + name + "' initialized successfully");
        return logger;
    }
    catch (const std::exception& ex) {
        std::cerr << "Failed to initialize logger: " << ex.what() << std::endl;
        return nullptr;
    }
}

} // namespace logger
