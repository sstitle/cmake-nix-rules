#pragma once

#include <Eigen/Dense>
#include <iostream>

namespace math_utils {

class Vector3 {
public:
    Vector3(double x = 0.0, double y = 0.0, double z = 0.0);
    Vector3(const Eigen::Vector3d& eigen_vec);
    
    // Getters
    double x() const { return vec_(0); }
    double y() const { return vec_(1); }
    double z() const { return vec_(2); }
    
    // Get underlying Eigen vector
    const Eigen::Vector3d& eigen() const { return vec_; }
    Eigen::Vector3d& eigen() { return vec_; }
    
    // Basic operations
    Vector3 operator+(const Vector3& other) const;
    Vector3 operator-(const Vector3& other) const;
    Vector3 operator*(double scalar) const;
    
    // Utility functions
    double magnitude() const;
    Vector3 normalized() const;
    double dot(const Vector3& other) const;
    Vector3 cross(const Vector3& other) const;
    
    // Eigen-specific operations
    double squaredNorm() const;
    Vector3 cwiseProduct(const Vector3& other) const;  // Component-wise multiplication
    
    // Output
    friend std::ostream& operator<<(std::ostream& os, const Vector3& v);

private:
    Eigen::Vector3d vec_;
};

} // namespace math_utils
