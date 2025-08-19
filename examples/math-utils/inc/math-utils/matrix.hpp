#pragma once

#include "vector.hpp"
#include <Eigen/Dense>
#include <array>

namespace math_utils {

class Matrix3x3 {
public:
    Matrix3x3();
    Matrix3x3(const Eigen::Matrix3d& eigen_mat);
    Matrix3x3(const std::array<std::array<double, 3>, 3>& data);
    
    // Static constructors
    static Matrix3x3 identity();
    static Matrix3x3 zero();
    static Matrix3x3 random();  // New: using Eigen's random
    
    // Element access
    double& operator()(int row, int col);
    const double& operator()(int row, int col) const;
    
    // Get underlying Eigen matrix
    const Eigen::Matrix3d& eigen() const { return mat_; }
    Eigen::Matrix3d& eigen() { return mat_; }
    
    // Matrix operations
    Matrix3x3 operator+(const Matrix3x3& other) const;
    Matrix3x3 operator-(const Matrix3x3& other) const;
    Matrix3x3 operator*(const Matrix3x3& other) const;
    Vector3 operator*(const Vector3& vec) const;
    Matrix3x3 operator*(double scalar) const;
    
    // Utility functions
    Matrix3x3 transpose() const;
    double determinant() const;
    Matrix3x3 inverse() const;
    
    // Eigen-specific operations
    double trace() const;
    double norm() const;
    Eigen::Vector3d eigenvalues() const;
    
    // Output
    friend std::ostream& operator<<(std::ostream& os, const Matrix3x3& m);

private:
    Eigen::Matrix3d mat_;
};

} // namespace math_utils
