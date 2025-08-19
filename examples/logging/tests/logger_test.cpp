#include "logger/logger.hpp"
#include <iostream>
#include <fstream>
#include <filesystem>
#include <cassert>
#include <format>
#include <thread>

using namespace logger;

void test_logger_creation() {
    std::cout << "Testing logger creation...\n";
    
    auto logger = CreateLogger(LogLevel::Info, "TestLogger");
    assert(logger != nullptr);
    assert(logger->name() == "TestLogger");
    
    std::cout << "✓ Logger creation tests passed\n";
}

void test_log_levels() {
    std::cout << "Testing log levels...\n";
    
    auto debugLogger = CreateLogger(LogLevel::Debug, "DebugLogger");
    auto infoLogger = CreateLogger(LogLevel::Info, "InfoLogger");
    auto warnLogger = CreateLogger(LogLevel::Warning, "WarnLogger");
    
    assert(debugLogger != nullptr);
    assert(infoLogger != nullptr);
    assert(warnLogger != nullptr);
    
    std::cout << "✓ Log level tests passed\n";
}

void test_log_messages() {
    std::cout << "Testing log messages...\n";
    
    auto logger = CreateLogger(LogLevel::Debug, "MessageTest");
    
    // Test basic logging methods
    logger->debug("Test debug message");
    logger->info("Test info message");
    logger->warn("Test warning message");
    logger->error("Test error message");
    logger->critical("Test critical message");
    
    // Test formatted logging with std::format
    int testValue = 123;
    logger->info(std::format("Formatted test message: value={}", testValue));
    
    std::cout << "✓ Log message tests passed\n";
}

void test_file_logging() {
    std::cout << "Testing file logging...\n";
    
    const std::string logFile = "FileTest.log";
    
    // Remove existing test file
    if (std::filesystem::exists(logFile)) {
        std::filesystem::remove(logFile);
    }
    
    // Create a logger
    auto logger = CreateLogger(LogLevel::Info, "FileTest");
    
    // Log some messages
    logger->info("Test message for file logging");
    logger->error("Test error message for file logging");
    
    // Give time for file to be written
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Check if file was created and contains our messages
    assert(std::filesystem::exists(logFile));
    
    std::ifstream file(logFile);
    assert(file.is_open());
    
    std::string content((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
    file.close();
    
    // Clean up
    std::filesystem::remove(logFile);
    
    assert(content.find("Test message for file logging") != std::string::npos);
    assert(content.find("Test error message for file logging") != std::string::npos);
    
    std::cout << "✓ File logging tests passed\n";
}

int main() {
    std::cout << "Running Logging Tests\n";
    std::cout << "====================\n";
    
    test_logger_creation();
    test_log_levels();
    test_log_messages();
    test_file_logging();
    
    std::cout << "\n✓ All logging tests passed!\n";
    return 0;
}
