#include "math-utils/matrix.hpp"
#include <stdexcept>
#include <iomanip>

namespace math_utils {

Matrix3x3::Matrix3x3() : mat_(Eigen::Matrix3d::Zero()) {}

Matrix3x3::Matrix3x3(const Eigen::Matrix3d& eigen_mat) : mat_(eigen_mat) {}

Matrix3x3::Matrix3x3(const std::array<std::array<double, 3>, 3>& data) {
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            mat_(i, j) = data[i][j];
        }
    }
}

Matrix3x3 Matrix3x3::identity() {
    return Matrix3x3(Eigen::Matrix3d::Identity());
}

Matrix3x3 Matrix3x3::zero() {
    return Matrix3x3(Eigen::Matrix3d::Zero());
}

Matrix3x3 Matrix3x3::random() {
    return Matrix3x3(Eigen::Matrix3d::Random());
}

double& Matrix3x3::operator()(int row, int col) {
    if (row < 0 || row >= 3 || col < 0 || col >= 3) {
        throw std::out_of_range("Matrix index out of range");
    }
    return mat_(row, col);
}

const double& Matrix3x3::operator()(int row, int col) const {
    if (row < 0 || row >= 3 || col < 0 || col >= 3) {
        throw std::out_of_range("Matrix index out of range");
    }
    return mat_(row, col);
}

Matrix3x3 Matrix3x3::operator+(const Matrix3x3& other) const {
    return Matrix3x3(mat_ + other.mat_);
}

Matrix3x3 Matrix3x3::operator-(const Matrix3x3& other) const {
    return Matrix3x3(mat_ - other.mat_);
}

Matrix3x3 Matrix3x3::operator*(const Matrix3x3& other) const {
    return Matrix3x3(mat_ * other.mat_);
}

Vector3 Matrix3x3::operator*(const Vector3& vec) const {
    return Vector3(mat_ * vec.eigen());
}

Matrix3x3 Matrix3x3::operator*(double scalar) const {
    return Matrix3x3(mat_ * scalar);
}

Matrix3x3 Matrix3x3::transpose() const {
    return Matrix3x3(mat_.transpose());
}

double Matrix3x3::determinant() const {
    return mat_.determinant();
}

Matrix3x3 Matrix3x3::inverse() const {
    if (std::abs(mat_.determinant()) < 1e-10) {
        throw std::runtime_error("Matrix is not invertible (determinant is zero)");
    }
    return Matrix3x3(mat_.inverse());
}

double Matrix3x3::trace() const {
    return mat_.trace();
}

double Matrix3x3::norm() const {
    return mat_.norm();
}

Eigen::Vector3d Matrix3x3::eigenvalues() const {
    Eigen::EigenSolver<Eigen::Matrix3d> solver(mat_);
    return solver.eigenvalues().real();
}

std::ostream& operator<<(std::ostream& os, const Matrix3x3& m) {
    os << "Matrix3x3:\n";
    for (int i = 0; i < 3; ++i) {
        os << "  [";
        for (int j = 0; j < 3; ++j) {
            os << std::setw(8) << std::fixed << std::setprecision(3) << m.mat_(i, j);
            if (j < 2) os << ", ";
        }
        os << "]\n";
    }
    return os;
}

} // namespace math_utils
