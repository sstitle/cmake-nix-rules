#include "math-utils/vector.hpp"
#include "math-utils/matrix.hpp"
#include "logger/logger.hpp"
#include <iostream>
#include <format>

using namespace math_utils;

int main() {
    // Create a simple logger
    auto log = logger::CreateLogger(logger::LogLevel::Info, "MathCalculator");
    
    log->info("Math Utils Calculator started");
    
    std::cout << "Math Utils Calculator Demo\n";
    std::cout << "==========================\n\n";
    
    // Vector operations
    log->info("Starting vector operations");
    std::cout << "Vector Operations:\n";
    Vector3 v1(1.0, 2.0, 3.0);
    Vector3 v2(4.0, 5.0, 6.0);
    
    log->debug("Created vectors for demonstration");
    
    std::cout << "v1 = " << v1 << "\n";
    std::cout << "v2 = " << v2 << "\n";
    std::cout << "v1 + v2 = " << (v1 + v2) << "\n";
    std::cout << "v1 - v2 = " << (v1 - v2) << "\n";
    std::cout << "v1 * 2.0 = " << (v1 * 2.0) << "\n";
    std::cout << "v1.magnitude() = " << v1.magnitude() << "\n";
    std::cout << "v1.dot(v2) = " << v1.dot(v2) << "\n";
    std::cout << "v1.cross(v2) = " << v1.cross(v2) << "\n\n";
    
    // Matrix operations
    std::cout << "Matrix Operations:\n";
    Matrix3x3 m1 = Matrix3x3::identity();
    Matrix3x3 m2({{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}});
    
    std::cout << "Identity matrix:\n" << m1 << "\n";
    std::cout << "Custom matrix:\n" << m2 << "\n";
    std::cout << "Matrix * Vector:\n" << (m2 * v1) << "\n";
    std::cout << "Matrix transpose:\n" << m2.transpose() << "\n";
    std::cout << "Matrix determinant: " << m2.determinant() << "\n";
    std::cout << "Matrix trace: " << m2.trace() << "\n";
    std::cout << "Matrix norm: " << m2.norm() << "\n\n";
    
    // Test invertible matrix
    Matrix3x3 m3({{{2, 0, 0}, {0, 2, 0}, {0, 0, 2}}});
    std::cout << "Invertible matrix:\n" << m3 << "\n";
    std::cout << "Its inverse:\n" << m3.inverse() << "\n";
    
    // Show Eigen-specific features
    std::cout << "Eigen-enhanced Vector Operations:\n";
    std::cout << "v1.squaredNorm() = " << v1.squaredNorm() << "\n";
    std::cout << "v1.cwiseProduct(v2) = " << v1.cwiseProduct(v2) << "\n\n";
    
    // Random matrix operations
    std::cout << "Random Matrix (Eigen feature):\n";
    Matrix3x3 random = Matrix3x3::random();
    std::cout << random << "\n";
    
    try {
        std::cout << "Random matrix eigenvalues:\n";
        Eigen::Vector3d eigenvals = random.eigenvalues();
        std::cout << "  λ1 = " << eigenvals(0) << "\n";
        std::cout << "  λ2 = " << eigenvals(1) << "\n";
        std::cout << "  λ3 = " << eigenvals(2) << "\n";
    } catch (const std::exception& e) {
        log->error(std::format("Error computing eigenvalues: {}", e.what()));
        std::cout << "Error computing eigenvalues: " << e.what() << "\n";
    }
    
    log->info("Math Utils Calculator completed successfully");
    return 0;
}
