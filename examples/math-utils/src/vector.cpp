#include "math-utils/vector.hpp"
#include <stdexcept>

namespace math_utils {

Vector3::Vector3(double x, double y, double z) : vec_(x, y, z) {}

Vector3::Vector3(const Eigen::Vector3d& eigen_vec) : vec_(eigen_vec) {}

Vector3 Vector3::operator+(const Vector3& other) const {
    return Vector3(vec_ + other.vec_);
}

Vector3 Vector3::operator-(const Vector3& other) const {
    return Vector3(vec_ - other.vec_);
}

Vector3 Vector3::operator*(double scalar) const {
    return Vector3(vec_ * scalar);
}

double Vector3::magnitude() const {
    return vec_.norm();
}

Vector3 Vector3::normalized() const {
    if (vec_.norm() == 0.0) {
        throw std::runtime_error("Cannot normalize zero vector");
    }
    return Vector3(vec_.normalized());
}

double Vector3::dot(const Vector3& other) const {
    return vec_.dot(other.vec_);
}

Vector3 Vector3::cross(const Vector3& other) const {
    return Vector3(vec_.cross(other.vec_));
}

double Vector3::squaredNorm() const {
    return vec_.squaredNorm();
}

Vector3 Vector3::cwiseProduct(const Vector3& other) const {
    return Vector3(vec_.cwiseProduct(other.vec_));
}

std::ostream& operator<<(std::ostream& os, const Vector3& v) {
    return os << "Vector3(" << v.vec_(0) << ", " << v.vec_(1) << ", " << v.vec_(2) << ")";
}

} // namespace math_utils
