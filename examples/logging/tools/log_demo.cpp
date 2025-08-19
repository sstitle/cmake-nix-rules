#include "logger/logger.hpp"
#include <thread>
#include <chrono>
#include <format>

using namespace logger;

int main() {
    // Create a simple logger
    auto log = CreateLogger(LogLevel::Debug, "LogDemo");
    if (!log) {
        std::cerr << "Failed to create logger!" << std::endl;
        return 1;
    }
    
    std::cout << "Logging Demo - messages will appear in console and LogDemo.log\n";
    std::cout << "==============================================================\n\n";
    
    // Test different log levels
    log->debug("This is a debug message");
    log->info("Application started successfully");
    log->warn("This is a warning message");
    log->error("This is an error message");
    log->critical("This is a critical message");
    
    // Test with std::format
    int value = 42;
    double pi = 3.14159;
    std::string name = "World";
    
    log->info(std::format("Formatted message: value={}, pi={:.2f}, greeting='Hello {}'", value, pi, name));
    
    // Simulate some application work
    for (int i = 1; i <= 5; ++i) {
        log->info(std::format("Processing item {}/5", i));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        if (i == 3) {
            log->warn(std::format("Item {} required special handling", i));
        }
    }
    
    log->info("Demo completed successfully");
    
    return 0;
}
