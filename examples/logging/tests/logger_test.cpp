#include "logger/logger.hpp"
#include <iostream>
#include <sstream>
#include <fstream>
#include <filesystem>
#include <cassert>

using namespace logger;

void test_logger_initialization() {
    std::cout << "Testing logger initialization...\n";
    
    // Test singleton behavior
    Logger& logger1 = Logger::getInstance();
    Logger& logger2 = Logger::getInstance();
    assert(&logger1 == &logger2);
    
    // Initialize with test file
    const std::string testLogFile = "test_logger.log";
    logger1.initialize("TestLogger", testLogFile);
    
    // Test that we can get the underlying spdlog logger
    auto spdlogger = logger1.getSpdlogger();
    assert(spdlogger != nullptr);
    assert(spdlogger->name() == "TestLogger");
    
    // Clean up test file
    if (std::filesystem::exists(testLogFile)) {
        std::filesystem::remove(testLogFile);
    }
    
    std::cout << "✓ Logger initialization tests passed\n";
}

void test_log_levels() {
    std::cout << "Testing log levels...\n";
    
    Logger& logger = Logger::getInstance();
    
    // Test that we can set different log levels without crashing
    logger.setLevel(LogLevel::Debug);
    logger.setLevel(LogLevel::Info);
    logger.setLevel(LogLevel::Warning);
    logger.setLevel(LogLevel::Error);
    logger.setLevel(LogLevel::Critical);
    
    // Reset to debug for other tests
    logger.setLevel(LogLevel::Debug);
    
    std::cout << "✓ Log level tests passed\n";
}

void test_log_messages() {
    std::cout << "Testing log messages...\n";
    
    Logger& logger = Logger::getInstance();
    
    // Test basic logging methods
    logger.debug("Test debug message");
    logger.info("Test info message");
    logger.warning("Test warning message");
    logger.error("Test error message");
    logger.critical("Test critical message");
    
    // Test macro logging
    LOG_DEBUG("Test debug macro");
    LOG_INFO("Test info macro");
    LOG_WARNING("Test warning macro");
    LOG_ERROR("Test error macro");
    LOG_CRITICAL("Test critical macro");
    
    // Test simple logging (no complex formatting for simplicity)
    LOG_INFO("Simple test message with value 123");
    
    std::cout << "✓ Log message tests passed\n";
}

void test_file_logging() {
    std::cout << "Testing file logging...\n";
    
    const std::string testLogFile = "file_test.log";
    
    // Remove existing test file
    if (std::filesystem::exists(testLogFile)) {
        std::filesystem::remove(testLogFile);
    }
    
    // Create a new logger instance for this test
    Logger& logger = Logger::getInstance();
    logger.initialize("FileTest", testLogFile);
    
    // Log some messages
    logger.info("Test message for file logging");
    logger.error("Test error message for file logging");
    
    // Give time for file to be written
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    
    // Check if file was created and contains our messages
    assert(std::filesystem::exists(testLogFile));
    
    std::ifstream logFile(testLogFile);
    assert(logFile.is_open());
    
    std::string line;
    bool foundInfoMessage = false;
    bool foundErrorMessage = false;
    
    while (std::getline(logFile, line)) {
        if (line.find("Test message for file logging") != std::string::npos) {
            foundInfoMessage = true;
        }
        if (line.find("Test error message for file logging") != std::string::npos) {
            foundErrorMessage = true;
        }
    }
    
    logFile.close();
    
    // Clean up
    std::filesystem::remove(testLogFile);
    
    assert(foundInfoMessage);
    assert(foundErrorMessage);
    
    std::cout << "✓ File logging tests passed\n";
}

int main() {
    std::cout << "Running Logging Tests\n";
    std::cout << "====================\n";
    
    test_logger_initialization();
    test_log_levels();
    test_log_messages();
    test_file_logging();
    
    std::cout << "\n✓ All logging tests passed!\n";
    return 0;
}
